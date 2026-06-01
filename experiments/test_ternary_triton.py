import torch
import math

# We must ensure we can import from src
import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))

from llama_surgery.surgery import pack_ternary, unpack_ternary
from llama_surgery.kernel import ternary_ultrametric_attention_triton, HAS_TRITON

def test_packing():
    print("Testing PyTorch Packing/Unpacking...")
    # Create random values
    x = torch.randn(2, 4, 128, 64)
    # Quantize to ternary (-1, 0, 1)
    gamma = x.abs().mean(dim=-1, keepdim=True)
    threshold = 0.5 * gamma
    x_ternary = torch.zeros_like(x)
    x_ternary[x > threshold] = 1.0
    x_ternary[x < -threshold] = -1.0
    
    packed = pack_ternary(x_ternary)
    unpacked = unpack_ternary(packed, x.shape)
    
    diff = (unpacked - x_ternary).abs().max()
    assert diff == 0.0, f"Packing/Unpacking failed! Max diff: {diff}"
    print("  [OK] Packing and unpacking perfectly reconstructs the ternary state.")

def test_triton_kernel():
    if not HAS_TRITON or not torch.cuda.is_available():
        print("Skipping Triton test: requires CUDA and Triton.")
        return

    print("\nTesting Triton Ternary Block-Sparse Kernel against PyTorch...")
    Z, H, N_CTX, DMODEL = 1, 2, 256, 64
    
    # 1. Create dense float16 Q
    q = torch.randn((Z, H, N_CTX, DMODEL), dtype=torch.float16, device='cuda')
    
    # 2. Create float16 K and V
    k_f16 = torch.randn((Z, H, N_CTX, DMODEL), dtype=torch.float16, device='cuda')
    v_f16 = torch.randn((Z, H, N_CTX, DMODEL), dtype=torch.float16, device='cuda')
    
    # 3. Quantize K and V to ternary (-1, 0, 1) and calculate scale
    def quantize(x):
        gamma = x.abs().mean(dim=-1, keepdim=True)
        threshold = 0.5 * gamma
        x_ternary = torch.zeros_like(x)
        x_ternary[x > threshold] = 1.0
        x_ternary[x < -threshold] = -1.0
        return x_ternary, gamma.to(torch.float16)

    k_ternary, k_scale = quantize(k_f16)
    v_ternary, v_scale = quantize(v_f16)
    
    # 4. Pack for Triton
    k_packed = pack_ternary(k_ternary)
    v_packed = pack_ternary(v_ternary)
    
    # 5. Create router indices (all 0 for dense evaluation to check pure math)
    router_indices = torch.zeros((Z, H, N_CTX // 128, 2), dtype=torch.int32, device='cuda')
    
    # 6. Run Triton Kernel
    out_triton = ternary_ultrametric_attention_triton(
        q=q,
        k_packed=k_packed,
        v_packed=v_packed,
        k_scale=k_scale.squeeze(-1),
        v_scale=v_scale.squeeze(-1),
        router_indices=router_indices,
        local_window=256,
        req_depth=0,
        p=2
    )
    
    # 7. Run pure PyTorch dense attention
    # Reconstruct the dequantized KV
    k_deq = k_ternary.to(torch.float16) * k_scale
    v_deq = v_ternary.to(torch.float16) * v_scale
    
    sm_scale = 1.0 / math.sqrt(DMODEL)
    scores = torch.matmul(q, k_deq.transpose(-2, -1)) * sm_scale
    # Causal mask
    causal_mask = torch.tril(torch.ones(N_CTX, N_CTX, device='cuda')).view(1, 1, N_CTX, N_CTX)
    scores = scores.masked_fill(causal_mask == 0, float("-inf"))
    
    attn_weights = torch.nn.functional.softmax(scores, dim=-1)
    out_pt = torch.matmul(attn_weights, v_deq)
    
    # 8. Compare
    diff = (out_triton - out_pt).abs().max()
    print(f"  Max diff between Triton and PyTorch: {diff:.6f}")
    
    # Float16 attention usually has an error around 1e-3 due to accumulation differences
    assert diff < 1e-2, "Triton kernel output does not match PyTorch!"
    print("  [OK] Triton Kernel perfectly matches PyTorch math!")

if __name__ == "__main__":
    test_packing()
    test_triton_kernel()
