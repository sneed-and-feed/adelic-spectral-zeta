import torch
import torch.nn as nn
import torch.nn.functional as F
import math
from transformers import AutoModelForCausalLM, AutoTokenizer
from datasets import Dataset
from torch.utils.data import DataLoader

# Import our custom surgery library
from llama_surgery import inject_surgery
from llama_surgery.layer import UltrametricAttention
from llama_surgery.topology import get_ultrametric_mask

# ==============================================================================
# 1. 4-bit Fake Quantizer with Straight-Through Estimator (STE)
# ==============================================================================

class FakeQuantize4Bit(torch.autograd.Function):
    """
    Symmetric 4-bit fake quantization.
    Forward pass: dynamically scales the tensor, rounds it to integers [-8, 7], 
                  and scales it back to float.
    Backward pass: passes gradients straight through (STE) to ignore the non-differentiable rounding.
    """
    @staticmethod
    @torch.cuda.amp.custom_fwd(cast_inputs=torch.float32)
    def forward(ctx, x):
        # Cast to float32 internally to prevent FP16 inf/NaN overflows during division
        x_f32 = x.float()
        scale = x_f32.abs().max(dim=-1, keepdim=True).values / 7.0
        scale = scale.clamp(min=1e-5) # Prevent division by zero
        
        x_q = torch.round(x_f32 / scale).clamp(-8, 7)
        x_dq = x_q * scale
        return x_dq.to(x.dtype)

    @staticmethod
    @torch.cuda.amp.custom_bwd
    def backward(ctx, grad_output):
        # Straight-Through Estimator: just pass the gradient back
        return grad_output

def quantize_4bit(x):
    return FakeQuantize4Bit.apply(x)


# ==============================================================================
# 2. Attention Monkey Patch
# ==============================================================================

_original_forward = UltrametricAttention.forward

def _qat_forward(self, x, num_interior=0, dynamic_mask=None, routing=None, routing_assignments=None, mode="auto"):
    """
    A patched version of the forward pass that forces the Key and Value 
    tensors through the 4-bit fake quantizer right after projection,
    ensuring it applies to all modes (dense, chunked, triton).
    """
    batch_size, total_len, _ = x.size()
    seq_len = total_len - num_interior

    q = self.q_proj(x).view(batch_size, total_len, self.num_heads, self.head_dim).transpose(1, 2)
    k = self.k_proj(x).view(batch_size, total_len, self.num_heads, self.head_dim).transpose(1, 2)
    v = self.v_proj(x).view(batch_size, total_len, self.num_heads, self.head_dim).transpose(1, 2)
    
    # APPLY 4-BIT FAKE QUANTIZATION TO KV CACHE
    k = quantize_4bit(k)
    v = quantize_4bit(v)

    # Apply RoPE
    from llama_surgery.layer import apply_rotary_pos_emb
    if num_interior > 0:
        q_seq = q[:, :, num_interior:, :]
        k_seq = k[:, :, num_interior:, :]
        cos, sin = self.rope(q_seq)
        q_seq, k_seq = apply_rotary_pos_emb(q_seq, k_seq, cos, sin)
        q = torch.cat([q[:, :, :num_interior, :], q_seq], dim=2)
        k = torch.cat([k[:, :, :num_interior, :], k_seq], dim=2)
    else:
        cos, sin = self.rope(q)
        q, k = apply_rotary_pos_emb(q, k, cos, sin)

    # Resolve execution mode
    from llama_surgery.kernel import HAS_TRITON
    if mode == "auto":
        if HAS_TRITON and x.is_cuda and seq_len >= 256 and routing_assignments is not None and num_interior == 0:
            mode = "triton"
        elif seq_len >= 128:
            mode = "chunked"
        else:
            mode = "dense"

    if mode == "triton" and HAS_TRITON and routing_assignments is not None:
        return self._triton_attention(q, k, v, routing_assignments, batch_size, total_len)
    elif mode == "chunked":
        mask = self._resolve_mask(batch_size, total_len, seq_len, num_interior, dynamic_mask, routing, x.device)
        return self._chunked_sparse_attention(q, k, v, mask, batch_size, total_len)
    else:
        mask = self._resolve_mask(batch_size, total_len, seq_len, num_interior, dynamic_mask, routing, x.device)
        return self._dense_attention(q, k, v, mask, batch_size, total_len)

def apply_qat_monkey_patch():
    print("[QAT] Applying 4-bit Fake Quantization monkey-patch to UltrametricAttention.forward.")
    UltrametricAttention.forward = _qat_forward


# ==============================================================================
# 3. Training Loop with 'skip-bad-step' Logic
# ==============================================================================

def train_router_qat(model, tokenizer, train_text, steps=100, device="cuda"):
    for name, param in model.named_parameters():
        if "router" not in name:
            param.requires_grad = False
        else:
            param.requires_grad = True

    model.train()
    optimizer = torch.optim.AdamW(filter(lambda p: p.requires_grad, model.parameters()), lr=5e-3)
    scaler = torch.amp.GradScaler(device)
    
    encodings = tokenizer([train_text] * 8, truncation=True, padding=True, max_length=128)
    dataset = Dataset.from_dict({
        'input_ids': encodings['input_ids'],
        'attention_mask': encodings['attention_mask']
    })
    
    def collate_fn(batch):
        return {
            'input_ids': torch.tensor([b['input_ids'] for b in batch]).to(device),
            'attention_mask': torch.tensor([b['attention_mask'] for b in batch]).to(device)
        }
        
    dataloader = DataLoader(dataset, batch_size=4, collate_fn=collate_fn)
    
    print(f"\n[QAT Training] Starting 4-bit Quantization-Aware Training for {steps} steps...")
    
    step = 0
    while step < steps:
        for batch in dataloader:
            if step >= steps:
                break
                
            input_ids = batch['input_ids']
            
            with torch.amp.autocast(device):
                outputs = model(input_ids, labels=input_ids)
                loss = outputs.loss
                
                # Explicitly collect auxiliary router loss
                router_loss = 0.0
                for module in model.modules():
                    if hasattr(module, "router_loss") and module.router_loss is not None:
                        router_loss += module.router_loss
                        
                total_loss = loss + 0.05 * router_loss
                
            scaler.scale(total_loss).backward()
            scaler.unscale_(optimizer)
            
            grad_norm = torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=5.0)
            
            if torch.isnan(grad_norm) or torch.isinf(grad_norm) or grad_norm > 10.0:
                print(f"  [Step {step}] DIVERGENCE DETECTED (grad_norm={grad_norm.item():.2f}). Skipping step to prevent NaN collapse.")
                optimizer.zero_grad()
                step += 1  # Increment step even on skip to avoid infinite loops
                continue
                
            scaler.step(optimizer)
            scaler.update()
            optimizer.zero_grad()
            
            if step % 10 == 0:
                print(f"  [Step {step}] Loss: {total_loss.item():.4f} | Grad Norm: {grad_norm.item():.2f}")
                
            step += 1


# ==============================================================================
# 4. Evaluation Logic
# ==============================================================================

def compute_perplexity(model, tokenizer, text, device="cuda"):
    model.eval()
    model.to(device)
    
    inputs = tokenizer(text, return_tensors="pt", truncation=True, max_length=2048)
    input_ids = inputs["input_ids"].to(device)
    
    with torch.no_grad():
        outputs = model(input_ids, labels=input_ids)
        nll = outputs.loss.item()
        
    return math.exp(nll)


def main():
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Running 4-bit QAT Experiment on {device}")
    
    model_id = "TinyLlama/TinyLlama-1.1B-Intermediate-Step-1431k-3T"
    tokenizer = AutoTokenizer.from_pretrained(model_id)
    tokenizer.pad_token = tokenizer.eos_token
    
    train_text = "The geometry of language is not a linear sequence of events, but a complex, multifaceted web."
    test_text = (
        "The geometry of language is not a linear sequence of events, but a complex, "
        "multifaceted web of relationships. When we speak or write, we traverse a "
        "topological space where concepts are linked not just by their adjacency in time, "
        "but by their semantic and syntactic depth. A rigid binary tree forces every decision "
        "into a left-or-right dichotomy, creating artificial boundaries between related ideas. "
    ) * 30 
    
    print("\n--- Phase 1: Baseline 4-bit Dense (No Surgery) ---")
    model = AutoModelForCausalLM.from_pretrained(model_id, torch_dtype=torch.float16 if device == "cuda" else torch.float32)
    model.to(device)
    
    # Force 4-bit quantizer onto the dense baseline
    apply_qat_monkey_patch()
    
    # We inject surgery with p=2 but temporarily force the mask to be fully dense 
    # to simulate the baseline dense model with 4-bit quantization.
    model.config.surgical_p = 2
    model = inject_surgery(model)
    
    _orig_resolve = UltrametricAttention._resolve_mask
    UltrametricAttention._resolve_mask = lambda self, bs, tl, *args, **kwargs: torch.ones((bs, 1, tl, tl), dtype=torch.bool, device=model.device)

    
    ppl_dense_4bit = compute_perplexity(model, tokenizer, test_text, device)
    print(f"Result: Dense 4-bit Perplexity = {ppl_dense_4bit:.2f} (This should be destroyed/high!)")
    
    UltrametricAttention._resolve_mask = _orig_resolve
    
    del model
    torch.cuda.empty_cache()
    
    print("\n--- Phase 2: Ultrametric 4-bit QAT ---")
    model = AutoModelForCausalLM.from_pretrained(model_id, torch_dtype=torch.float16 if device == "cuda" else torch.float32)
    model.config.surgical_p = 2
    model = inject_surgery(model)
    model.to(device)
    
    # Train the router while 4-bit quantization is active!
    train_router_qat(model, tokenizer, train_text, steps=100, device=device)
    
    ppl_ultra_4bit = compute_perplexity(model, tokenizer, test_text, device)
    print(f"\nResult: Ultrametric 4-bit Perplexity = {ppl_ultra_4bit:.2f}")
    
    print("\n--- SUMMARY ---")
    print(f"Baseline Dense 4-bit KV PPL: {ppl_dense_4bit:.2f}")
    print(f"Ultrametric QAT 4-bit KV PPL: {ppl_ultra_4bit:.2f}")
    
if __name__ == "__main__":
    main()
