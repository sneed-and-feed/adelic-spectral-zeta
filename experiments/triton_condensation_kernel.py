import torch
import triton
import triton.language as tl
import time

@triton.jit
def _adelic_max_sim_kernel(
    new_k_ptr, centroids_k_ptr,
    max_val_ptr, max_idx_ptr,
    M, N, D, protect_size,
    stride_zk_n, stride_mk_n, stride_dk_n,  # new_k strides
    stride_zc_k, stride_nc_k, stride_dc_k,  # centroids_k strides
    stride_zv, stride_mv,                   # output strides
    BLOCK_M: tl.constexpr, BLOCK_N: tl.constexpr, BLOCK_D: tl.constexpr
):
    pid_z = tl.program_id(0)
    pid_m = tl.program_id(1)

    # Offsets for M (new tokens)
    offs_m = pid_m * BLOCK_M + tl.arange(0, BLOCK_M)
    offs_d = tl.arange(0, BLOCK_D)

    # Base pointers for this batch/head
    new_k_block_ptr = new_k_ptr + pid_z * stride_zk_n
    centroids_k_block_ptr = centroids_k_ptr + pid_z * stride_zc_k

    # Load new_k block: shape [BLOCK_M, BLOCK_D]
    new_k_ptrs = new_k_block_ptr + (offs_m[:, None] * stride_mk_n + offs_d[None, :] * stride_dk_n)
    mask_m = offs_m[:, None] < M
    mask_d = offs_d[None, :] < D
    new_k = tl.load(new_k_ptrs, mask=mask_m & mask_d, other=0.0)

    # Running maximums for this block of M new tokens
    m_i = tl.full([BLOCK_M], -float('inf'), dtype=tl.float32)
    idx_i = tl.full([BLOCK_M], -1, dtype=tl.int32)

    # Loop over N (centroids)
    for start_n in range(0, N, BLOCK_N):
        offs_n = start_n + tl.arange(0, BLOCK_N)
        
        # Load centroids_k block: shape [BLOCK_N, BLOCK_D]
        centroids_k_ptrs = centroids_k_block_ptr + (offs_n[:, None] * stride_nc_k + offs_d[None, :] * stride_dc_k)
        mask_n = offs_n[:, None] < N
        centroids_k = tl.load(centroids_k_ptrs, mask=mask_n & mask_d, other=0.0)
        
        # Dot product [BLOCK_M, BLOCK_D] @ [BLOCK_D, BLOCK_N] -> [BLOCK_M, BLOCK_N]
        # We transpose centroids_k in SRAM for the dot product
        sim = tl.dot(new_k, tl.trans(centroids_k), out_dtype=tl.float32)
        
        # Apply masks
        # 1. Protect size mask (don't match against the first `protect_size` centroids)
        protect_mask = offs_n[None, :] < protect_size
        sim = tl.where(protect_mask, -float('inf'), sim)
        
        # 2. Out-of-bounds mask
        valid_n_mask = offs_n[None, :] < N
        sim = tl.where(valid_n_mask, sim, -float('inf'))
        
        # 3. Out-of-bounds mask for M (prevent NaNs from unused rows)
        sim = tl.where(mask_m, sim, -float('inf'))
        
        # Find local max in this chunk
        local_max = tl.max(sim, axis=1)
        local_idx = tl.argmax(sim, axis=1)
        local_idx_absolute = local_idx + start_n
        
        # Update global max
        update_mask = local_max > m_i
        m_i = tl.where(update_mask, local_max, m_i)
        idx_i = tl.where(update_mask, local_idx_absolute, idx_i)

    # Write back to HBM
    out_max_ptr = max_val_ptr + pid_z * stride_zv + offs_m * stride_mv
    out_idx_ptr = max_idx_ptr + pid_z * stride_zv + offs_m * stride_mv
    
    write_mask = offs_m < M
    tl.store(out_max_ptr, m_i, mask=write_mask)
    tl.store(out_idx_ptr, idx_i, mask=write_mask)

def triton_max_similarity(new_k, centroids_k, protect_size=17):
    B, H, M, D = new_k.shape
    _, _, N, _ = centroids_k.shape
    
    # Flatten Batch and Heads
    new_k_flat = new_k.view(B * H, M, D)
    centroids_k_flat = centroids_k.view(B * H, N, D)
    
    # Allocate outputs
    max_vals = torch.empty((B * H, M), device=new_k.device, dtype=torch.float32)
    max_idxs = torch.empty((B * H, M), device=new_k.device, dtype=torch.int32)
    
    # Choose block sizes
    BLOCK_M = triton.next_power_of_2(M) if M < 64 else 64
    BLOCK_N = 128
    BLOCK_D = triton.next_power_of_2(D)
    
    grid = (B * H, triton.cdiv(M, BLOCK_M))
    
    _adelic_max_sim_kernel[grid](
        new_k_flat, centroids_k_flat,
        max_vals, max_idxs,
        M, N, D, protect_size,
        new_k_flat.stride(0), new_k_flat.stride(1), new_k_flat.stride(2),
        centroids_k_flat.stride(0), centroids_k_flat.stride(1), centroids_k_flat.stride(2),
        max_vals.stride(0), max_vals.stride(1),
        BLOCK_M=BLOCK_M, BLOCK_N=BLOCK_N, BLOCK_D=BLOCK_D
    )
    
    return max_vals.view(B, H, M), max_idxs.view(B, H, M).long()

def pytorch_max_similarity(new_k, centroids_k, protect_size=17):
    # Standard O(N*M) PyTorch implementation
    sim_matrix = torch.matmul(centroids_k, new_k.transpose(-1, -2))
    sim_matrix = sim_matrix.transpose(-1, -2) # shape: [B, H, M, N]
    
    if protect_size > 0:
        sim_matrix[:, :, :, :protect_size] = -float('inf')
        
    max_val, max_idx = torch.max(sim_matrix, dim=-1)
    return max_val, max_idx

def test_kernel():
    print("Testing Adèlic Cache Triton Kernel...")
    if not torch.cuda.is_available():
        print("CUDA is required to run Triton! Please run this script on a GPU instance (e.g. Google Colab).")
        return

    B, H, M, N, D = 1, 32, 512, 128, 128
    protect_size = 17

    print(f"Shapes -> new_k: {[B, H, M, D]}, centroids_k: {[B, H, N, D]}")
    
    new_k = torch.randn(B, H, M, D, device='cuda', dtype=torch.float16)
    centroids_k = torch.randn(B, H, N, D, device='cuda', dtype=torch.float16)
    
    # 1. Correctness Check
    print("Verifying correctness...")
    pt_max, pt_idx = pytorch_max_similarity(new_k.float(), centroids_k.float(), protect_size)
    tr_max, tr_idx = triton_max_similarity(new_k, centroids_k, protect_size)
    
    diff = torch.abs(pt_max - tr_max).max().item()
    idx_match = (pt_idx == tr_idx).all().item()
    
    print(f"Max Difference: {diff:.6f}")
    print(f"Indices Match: {idx_match}")
    assert diff < 1e-2, "Values mismatch!"
    assert idx_match, "Indices mismatch!"
    print("Correctness PASSED!")
    
    # 2. Benchmark
    print("\nBenchmarking speed for heavily loaded cache (N=4096, M=4096)...")
    B, H, M, N, D = 1, 32, 4096, 4096, 128
    new_k = torch.randn(B, H, M, D, device='cuda', dtype=torch.float16)
    centroids_k = torch.randn(B, H, N, D, device='cuda', dtype=torch.float16)
    
    # Warmup
    for _ in range(5):
        pytorch_max_similarity(new_k, centroids_k, protect_size)
        triton_max_similarity(new_k, centroids_k, protect_size)
        
    torch.cuda.synchronize()
    start = time.time()
    for _ in range(100):
        pytorch_max_similarity(new_k, centroids_k, protect_size)
    torch.cuda.synchronize()
    pt_time = (time.time() - start) / 100 * 1000

    torch.cuda.synchronize()
    start = time.time()
    for _ in range(100):
        triton_max_similarity(new_k, centroids_k, protect_size)
    torch.cuda.synchronize()
    tr_time = (time.time() - start) / 100 * 1000
    
    print(f"PyTorch Time: {pt_time:.3f} ms")
    print(f"Triton Time:  {tr_time:.3f} ms")
    print(f"Speedup:      {pt_time / tr_time:.2f}x")

if __name__ == "__main__":
    test_kernel()
