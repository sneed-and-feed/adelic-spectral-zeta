import torch
import triton
import sys
import os

# Ensure src is in the path
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.ultrametric.kernel_decode import ultrametric_decode

def dense_fallback(
    q, k_cache, v_cache, 
    block_tables, context_lens, 
    router_indices, q_router_indices,
    req_depth
):
    batch_size, num_heads, head_dim = q.shape
    BLOCK_SIZE = k_cache.shape[2]
    out = torch.zeros_like(q)
    sm_scale = 1.0 / (head_dim ** 0.5)
    
    for b in range(batch_size):
        ctx_len = context_lens[b].item()
        if ctx_len == 0:
            continue
            
        for h in range(num_heads):
            q_vec = q[b, h] # [head_dim]
            q_ri = q_router_indices[b, h] # [tree_depth]
            
            num_blocks = (ctx_len + BLOCK_SIZE - 1) // BLOCK_SIZE
            
            m_i = float('-inf')
            l_i = 0.0
            acc = torch.zeros(head_dim, device=q.device)
            
            for logical_idx in range(num_blocks):
                phys_idx = block_tables[b, logical_idx].item()
                kv_ri = router_indices[phys_idx, h]
                
                # Check match
                mismatch = False
                for d in range(req_depth):
                    if q_ri[d] != kv_ri[d]:
                        mismatch = True
                        break
                
                if not mismatch:
                    k_block = k_cache[phys_idx, h] # [BLOCK_SIZE, head_dim]
                    v_block = v_cache[phys_idx, h]
                    
                    # Masking
                    seq_offsets = logical_idx * BLOCK_SIZE + torch.arange(BLOCK_SIZE, device=q.device)
                    mask = seq_offsets < ctx_len
                    
                    qk = torch.sum(q_vec.unsqueeze(0) * k_block, dim=1) * sm_scale
                    qk = torch.where(mask, qk, float('-inf'))
                    
                    m_i_new = max(m_i, qk.max().item())
                    if m_i_new == float('-inf'):
                        continue
                        
                    alpha = torch.exp(torch.tensor(m_i - m_i_new))
                    p = torch.exp(qk - m_i_new)
                    
                    acc = acc * alpha + torch.sum(p.unsqueeze(1) * v_block, dim=0)
                    l_i = l_i * alpha + p.sum().item()
                    m_i = m_i_new
            
            if l_i > 0:
                out[b, h] = acc / l_i
                
    return out

def run_benchmark():
    batch_size = 32
    num_heads = 8
    head_dim = 128
    block_size = 128
    tree_depth = 16
    max_context = 16384
    
    num_blocks = 8192
    
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    if device.type != "cuda":
        print("CUDA not available. Benchmark requires GPU.")
        sys.exit(1)
        
    torch.manual_seed(42)
    
    Q = torch.randn((batch_size, num_heads, head_dim), device=device, dtype=torch.float16)
    K_cache = torch.randn((num_blocks, num_heads, block_size, head_dim), device=device, dtype=torch.float16)
    V_cache = torch.randn((num_blocks, num_heads, block_size, head_dim), device=device, dtype=torch.float16)
    
    context_lens = torch.randint(max_context // 2, max_context, (batch_size,), device=device, dtype=torch.int32)
    max_logical_blocks = (max_context + block_size - 1) // block_size
    
    block_tables = torch.randint(0, num_blocks, (batch_size, max_logical_blocks), device=device, dtype=torch.int32)
    
    # Trees
    p = 2
    router_indices = torch.randint(0, p, (num_blocks, num_heads, tree_depth), device=device, dtype=torch.int32)
    q_router_indices = torch.randint(0, p, (batch_size, num_heads, tree_depth), device=device, dtype=torch.int32)
    
    # Correctness check
    print("Running correctness check...")
    req_depth = 2
    out_triton = ultrametric_decode(
        Q, K_cache, V_cache, block_tables, context_lens, router_indices, q_router_indices, req_depth
    )
    out_fallback = dense_fallback(
        Q, K_cache, V_cache, block_tables, context_lens, router_indices, q_router_indices, req_depth
    )
    
    max_diff = (out_triton - out_fallback).abs().max().item()
    print(f"Max diff: {max_diff}")
    assert max_diff < 1e-2, f"Correctness check failed! Max diff: {max_diff}"
    print("Correctness check passed.")
    
    # Benchmark
    print("\nRunning benchmark...")
    
    def test_fn(rd):
        return ultrametric_decode(
            Q, K_cache, V_cache, block_tables, context_lens, router_indices, q_router_indices, rd
        )
        
    for rd in [0, 1, 2, 3, 4]:
        ms = triton.testing.do_bench(lambda: test_fn(rd))
        
        # Calculate theoretical dense payload
        total_blocks_processed = 0
        for b in range(batch_size):
            total_blocks_processed += (context_lens[b].item() + block_size - 1) // block_size
            
        # For each block: K and V, each block_size * head_dim * 2 bytes (float16)
        bytes_per_block = block_size * head_dim * 2 * 2
        total_dense_bytes = total_blocks_processed * num_heads * bytes_per_block
        
        eff_bw = total_dense_bytes / (ms * 1e-3) / 1e9
        
        print(f"req_depth={rd}: {ms:.3f} ms | Effective BW: {eff_bw:.1f} GB/s")

if __name__ == "__main__":
    run_benchmark()
