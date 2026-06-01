import torch
import torch.nn as nn
import torch.nn.functional as F
import math
from transformers import AutoModelForCausalLM, AutoTokenizer
from torch.utils.data import DataLoader

try:
    from datasets import load_dataset
    HAS_DATASETS = True
except ImportError:
    HAS_DATASETS = False

# Import our custom surgery library
from llama_surgery import inject_surgery
from llama_surgery.layer import UltrametricAttention, apply_rotary_pos_emb
from llama_surgery.topology import get_ultrametric_mask
from llama_surgery.surgery import TernaryQuantize, pack_ternary
from llama_surgery.kernel import HAS_TRITON, routing_to_block_indices, ternary_ultrametric_attention_triton


# ==============================================================================
# 1. Attention Monkey Patch for Ternary QAT and Triton Execution
# ==============================================================================

_original_forward = UltrametricAttention.forward

def _qat_ternary_forward(self, x, num_interior=0, dynamic_mask=None, routing=None, routing_assignments=None, mode="auto"):
    """
    A patched forward pass that integrates 1.58-bit Ternary Quantization.
    """
    batch_size, total_len, _ = x.size()
    seq_len = total_len - num_interior

    q = self.q_proj(x).view(batch_size, total_len, self.num_heads, self.head_dim).transpose(1, 2)
    k = self.k_proj(x).view(batch_size, total_len, self.num_key_value_heads, self.head_dim).transpose(1, 2)
    v = self.v_proj(x).view(batch_size, total_len, self.num_key_value_heads, self.head_dim).transpose(1, 2)

    # Resolve execution mode
    if mode == "auto":
        if HAS_TRITON and getattr(self.config, "use_triton_sparse_attention", False) and not q.requires_grad:
            mode = "triton_ternary"
        elif seq_len >= 128:
            mode = "chunked"
        else:
            mode = "dense"

    # Quantize K and V for training
    k_f32 = k.float()
    v_f32 = v.float()
    gamma_k = k_f32.abs().mean(dim=-1, keepdim=True).to(k.dtype)
    gamma_v = v_f32.abs().mean(dim=-1, keepdim=True).to(v.dtype)

    # Use the Straight-Through Estimator during Dense training passes
    k_ternary_base = TernaryQuantize.apply(k) # returns [-1, 0, 1] * gamma
    v_ternary_base = TernaryQuantize.apply(v)

    # Apply RoPE (before or after? standard is after projection)
    if num_interior > 0:
        q_seq = q[:, :, num_interior:, :]
        k_seq = k_ternary_base[:, :, num_interior:, :]
        cos, sin = self.rope(q_seq)
        q_seq, k_seq = apply_rotary_pos_emb(q_seq, k_seq, cos, sin)
        q = torch.cat([q[:, :, :num_interior, :], q_seq], dim=2)
        k_ternary_base = torch.cat([k_ternary_base[:, :, :num_interior, :], k_seq], dim=2)
    else:
        cos, sin = self.rope(q)
        q, k_ternary_base = apply_rotary_pos_emb(q, k_ternary_base, cos, sin)

    if mode == "triton_ternary" and HAS_TRITON and routing_assignments is not None:
        # Evaluate using the TRUE 1.58-bit Triton block-sparse kernel!
        router_indices = routing_to_block_indices(routing_assignments, seq_len=total_len, block_size=128)
        
        # We need the pure [-1, 0, 1] states for packing, so we divide out gamma (or use the original tensor and threshold)
        k_pure_ternary = (k_ternary_base / gamma_k).clamp(-1, 1).round()
        v_pure_ternary = (v_ternary_base / gamma_v).clamp(-1, 1).round()

        k_packed = pack_ternary(k_pure_ternary)
        v_packed = pack_ternary(v_pure_ternary)

        out = ternary_ultrametric_attention_triton(
            q=q,
            k_packed=k_packed,
            v_packed=v_packed,
            k_scale=gamma_k.squeeze(-1),
            v_scale=gamma_v.squeeze(-1),
            router_indices=router_indices,
            local_window=128,
            req_depth=2,
            p=self.p
        )
        
        out = out.transpose(1, 2).contiguous().view(batch_size, total_len, self.embed_dim)
        return self.o_proj(out), None
        
    elif mode == "chunked":
        mask = self._resolve_mask(batch_size, total_len, seq_len, num_interior, dynamic_mask, routing, x.device)
        return self._chunked_sparse_attention(q, k_ternary_base, v_ternary_base, mask, batch_size, total_len)
    else:
        mask = self._resolve_mask(batch_size, total_len, seq_len, num_interior, dynamic_mask, routing, x.device)
        return self._dense_attention(q, k_ternary_base, v_ternary_base, mask, batch_size, total_len)

def apply_qat_monkey_patch():
    print("[QAT] Applying 1.58-bit Ternary Quantization monkey-patch to UltrametricAttention.forward.")
    UltrametricAttention.forward = _qat_ternary_forward


# ==============================================================================
# 2. Training Loop with 'skip-bad-step' Logic
# ==============================================================================

def train_router_qat(model, dataloader, steps=100, device="cuda"):
    for name, param in model.named_parameters():
        if "router" not in name:
            param.requires_grad = False
        else:
            param.requires_grad = True
            param.data = param.data.to(torch.float32)

    model.train()
    optimizer = torch.optim.AdamW(filter(lambda p: p.requires_grad, model.parameters()), lr=5e-3)
    scaler = torch.amp.GradScaler(device)
    
    print(f"\n[QAT Training] Starting 1.58-bit Ternary QAT for {steps} steps...")
    
    step = 0
    while step < steps:
        for batch in dataloader:
            if step >= steps:
                break
                
            input_ids = batch['input_ids'].to(device)
            attention_mask = batch['attention_mask'].to(device)
            
            with torch.amp.autocast(device):
                outputs = model(input_ids, labels=input_ids)
                loss = outputs.loss
                
                router_loss = 0.0
                for module in model.modules():
                    if hasattr(module, "router_loss") and module.router_loss is not None:
                        router_loss += module.router_loss
                        
                total_loss = loss + 0.1 * router_loss
                
            scaler.scale(total_loss).backward()
            scaler.unscale_(optimizer)
            
            grad_norm = torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=5.0)
            
            if torch.isnan(grad_norm) or torch.isinf(grad_norm) or grad_norm > 10.0:
                print(f"  [Step {step}] DIVERGENCE DETECTED (grad_norm={grad_norm.item():.2f}). Skipping.")
                optimizer.zero_grad()
                step += 1
                continue
                
            scaler.step(optimizer)
            scaler.update()
            optimizer.zero_grad()
            
            if step % 10 == 0:
                print(f"  [Step {step}] Loss: {total_loss.item():.4f} | Grad Norm: {grad_norm.item():.2f}")
                
            step += 1


# ==============================================================================
# 3. Evaluation Logic
# ==============================================================================

def compute_perplexity(model, tokenizer, text, device="cuda"):
    model.eval()
    model.to(device)
    
    inputs = tokenizer(text, return_tensors="pt", truncation=True, max_length=2048)
    input_ids = inputs["input_ids"].to(device)
    
    with torch.no_grad(), torch.amp.autocast(device):
        outputs = model(input_ids, labels=input_ids)
        nll = outputs.loss.item()
        
    return math.exp(nll)


def main():
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Running 1.58-bit Ternary QAT Experiment on {device}")
    
    model_id = "TinyLlama/TinyLlama-1.1B-Intermediate-Step-1431k-3T"
    tokenizer = AutoTokenizer.from_pretrained(model_id)
    tokenizer.pad_token = tokenizer.eos_token
    
    # Dataset Preparation
    if HAS_DATASETS:
        print("\nLoading HuggingFaceH4/ultrachat_200k dataset slice...")
        dataset = load_dataset("HuggingFaceH4/ultrachat_200k", split="train_sft[:5%]")
        def tokenize_function(examples):
            texts = [" ".join([msg["content"] for msg in convo]) for convo in examples["messages"]]
            return tokenizer(texts, padding="max_length", truncation=True, max_length=256)
        tokenized_dataset = dataset.map(tokenize_function, batched=True, remove_columns=dataset.column_names)
        def collate_fn(batch):
            return {
                'input_ids': torch.tensor([b['input_ids'] for b in batch]),
                'attention_mask': torch.tensor([b['attention_mask'] for b in batch])
            }
        dataloader = DataLoader(tokenized_dataset, batch_size=4, collate_fn=collate_fn)
    else:
        print("\n[WARNING] 'datasets' library not found. Falling back to dummy text.")
        train_text = "The geometry of language is not a linear sequence of events, but a complex web."
        encodings = tokenizer([train_text] * 16, truncation=True, padding=True, max_length=128, return_tensors="pt")
        class DummyDataset(torch.utils.data.Dataset):
            def __len__(self): return 16
            def __getitem__(self, idx): return {'input_ids': encodings['input_ids'][idx], 'attention_mask': encodings['attention_mask'][idx]}
        dataloader = DataLoader(DummyDataset(), batch_size=4)

    test_text = (
        "The geometry of language is not a linear sequence of events, but a complex, "
        "multifaceted web of relationships. When we speak or write, we traverse a "
        "topological space where concepts are linked not just by their adjacency in time, "
        "but by their semantic and syntactic depth. A rigid binary tree forces every decision "
        "into a left-or-right dichotomy, creating artificial boundaries between related ideas. "
    ) * 30 
    
    print("\n--- Phase 1: Baseline 1.58-bit Dense (No Surgery) ---")
    model = AutoModelForCausalLM.from_pretrained(model_id, torch_dtype=torch.float16 if device == "cuda" else torch.float32)
    model.to(device)
    
    apply_qat_monkey_patch()
    
    model.config.surgical_p = 2
    model.config.use_triton_sparse_attention = False # Force PyTorch Dense for baseline
    model = inject_surgery(model)
    
    _orig_resolve = UltrametricAttention._resolve_mask
    UltrametricAttention._resolve_mask = lambda self, bs, tl, *args, **kwargs: torch.ones((bs, 1, tl, tl), dtype=torch.bool, device=model.device)
    
    ppl_dense_ternary = compute_perplexity(model, tokenizer, test_text, device)
    print(f"Result: Dense Ternary Perplexity = {ppl_dense_ternary:.2f} (This should be high without QAT!)")
    
    UltrametricAttention._resolve_mask = _orig_resolve
    del model
    torch.cuda.empty_cache()
    
    print("\n--- Phase 2: Ultrametric 1.58-bit QAT (Training) ---")
    model = AutoModelForCausalLM.from_pretrained(model_id, torch_dtype=torch.float16 if device == "cuda" else torch.float32)
    model.config.surgical_p = 2
    model = inject_surgery(model)
    model.to(device)
    
    train_router_qat(model, dataloader, steps=100, device=device)
    
    print("\n--- Phase 3: Ultrametric 1.58-bit Triton Evaluation ---")
    model.config.use_triton_sparse_attention = True # Enable the Triton kernel for eval
    
    ppl_ultra_ternary = compute_perplexity(model, tokenizer, test_text, device)
    print(f"\nResult: Ultrametric Ternary (Triton) Perplexity = {ppl_ultra_ternary:.2f}")
    
    print("\n--- SUMMARY ---")
    print(f"Baseline Dense 1.58-bit PPL: {ppl_dense_ternary:.2f}")
    print(f"Ultrametric QAT 1.58-bit PPL: {ppl_ultra_ternary:.2f}")
    
if __name__ == "__main__":
    main()
