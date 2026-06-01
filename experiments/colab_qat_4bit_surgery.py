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
    def forward(ctx, x):
        # 4-bit symmetric quantization: range is [-8, 7]
        # max_val = 7.0
        scale = x.abs().max(dim=-1, keepdim=True).values / 7.0
        scale = scale.clamp(min=1e-5) # Prevent division by zero
        
        x_q = torch.round(x / scale).clamp(-8, 7)
        x_dq = x_q * scale
        return x_dq

    @staticmethod
    def backward(ctx, grad_output):
        # Straight-Through Estimator: just pass the gradient back
        return grad_output

def quantize_4bit(x):
    return FakeQuantize4Bit.apply(x)


# ==============================================================================
# 2. Attention Monkey Patch
# ==============================================================================

# Keep a reference to the original method just in case we need to unpatch
_original_dense_attention = UltrametricAttention._dense_attention

def _qat_dense_attention(self, q, k, v, mask, batch_size, total_len):
    """
    A patched version of the dense attention math that forces the Key and Value 
    tensors through the 4-bit fake quantizer before computing attention.
    """
    # Fake quantize the KV cache to 4-bits!
    k_qat = quantize_4bit(k)
    v_qat = quantize_4bit(v)
    
    # Continue with standard attention using the quantized tensors
    scores = torch.matmul(q, k_qat.transpose(-2, -1)) * self.scale
    if mask.dtype == torch.bool:
        scores = scores.masked_fill(~mask, float("-inf"))
    else:
        scores = scores + torch.log(mask.clamp(min=1e-9))
        
    attn_weights = F.softmax(scores, dim=-1)
    attn_weights = self.attn_dropout(attn_weights)
    
    out = torch.matmul(attn_weights, v_qat)
    out = out.transpose(1, 2).contiguous().view(batch_size, total_len, self.embed_dim)
    
    return self.o_proj(out)

def apply_qat_monkey_patch():
    """Injects the 4-bit quantizer into the UltrametricAttention class."""
    print("[QAT] Applying 4-bit Fake Quantization monkey-patch to UltrametricAttention.")
    UltrametricAttention._dense_attention = _qat_dense_attention


# ==============================================================================
# 3. Training Loop with 'skip-bad-step' Logic
# ==============================================================================

def train_router_qat(model, tokenizer, train_text, steps=100, device="cuda"):
    """
    Trains the router while the KV cache is actively being quantized to 4-bits.
    Implements Anon's 'skip-bad-step' logic to prevent QAT gradient explosions.
    """
    # Freeze all parameters EXCEPT the router
    for name, param in model.named_parameters():
        if "router" not in name:
            param.requires_grad = False
        else:
            param.requires_grad = True

    model.train()
    optimizer = torch.optim.AdamW(filter(lambda p: p.requires_grad, model.parameters()), lr=5e-3)
    
    # Create dummy dataset
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
            outputs = model(input_ids, labels=input_ids)
            loss = outputs.loss
            
            # The surgery framework automatically adds auxiliary router loss
            # if we are in training mode.
            
            loss.backward()
            
            # --- THE SKIP-BAD-STEP FIX ---
            # QAT + Gumbel-Softmax = violent gradient explosions.
            # We clip gradients. If the norm is insane or NaN, we skip the step.
            grad_norm = torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=5.0)
            
            if torch.isnan(grad_norm) or torch.isinf(grad_norm) or grad_norm > 10.0:
                print(f"  [Step {step}] DIVERGENCE DETECTED (grad_norm={grad_norm.item():.2f}). Skipping step to prevent NaN collapse.")
                optimizer.zero_grad()
                continue # Skip the bad step!
                
            optimizer.step()
            optimizer.zero_grad()
            
            if step % 10 == 0:
                print(f"  [Step {step}] Loss: {loss.item():.4f} | Grad Norm: {grad_norm.item():.2f}")
                
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
    
    # We test it with the patch active. Because we haven't injected surgery, 
    # the model is just using the standard UltrametricAttention fallback (if we inject it first).
    # Wait, if we haven't injected surgery, the model uses standard LlamaAttention!
    # So we MUST inject surgery with p=None (which acts as a wrapper) to use the patched dense attention.
    model.config.surgical_p = None
    model = inject_surgery(model)
    
    ppl_dense_4bit = compute_perplexity(model, tokenizer, test_text, device)
    print(f"Result: Dense 4-bit Perplexity = {ppl_dense_4bit:.2f} (This should be destroyed/high!)")
    
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
