"""
Ultrametric AI — Triton Kernel Benchmark v2 (FIXED)

Cell 1: !pip install triton
Cell 2: Paste this entire file
"""

import torch
import torch.nn.functional as F
import math
import json
import triton
import triton.language as tl


def next_pow2(n):
    """Round up to next power of 2."""
    if n <= 1:
        return 1
    return 1 << (n - 1).bit_length()


# ============================================================
# TRITON KERNEL — FIXED
#   1. Replaced `continue` with `if should_compute:` guard
#   2. TREE_DEPTH_P2 is always a power of 2
# ============================================================

@triton.jit
def _ultrametric_fwd_kernel(
    Q, K, V, sm_scale,
    router_indices, Out,
    stride_qz, stride_qh, stride_qm, stride_qk,
    stride_kz, stride_kh, stride_kn, stride_kk,
    stride_vz, stride_vh, stride_vk, stride_vn,
    stride_oz, stride_oh, stride_om, stride_on,
    stride_rz, stride_rh, stride_rm, stride_rd,
    req_depth, Z, H, N_CTX,
    BLOCK_M: tl.constexpr, BLOCK_DMODEL: tl.constexpr,
    BLOCK_N: tl.constexpr, P_ARY: tl.constexpr,
    TREE_DEPTH_P2: tl.constexpr,
):
    start_m = tl.program_id(0)
    off_hz = tl.program_id(1)
    off_z = off_hz // H
    off_h = off_hz % H

    q_offset = off_z * stride_qz + off_h * stride_qh
    k_offset = off_z * stride_kz + off_h * stride_kh
    v_offset = off_z * stride_vz + off_h * stride_vh
    o_offset = off_z * stride_oz + off_h * stride_oh
    r_offset = off_z * stride_rz + off_h * stride_rh

    q_block_ptr = tl.make_block_ptr(
        base=Q + q_offset, shape=(N_CTX, BLOCK_DMODEL),
        strides=(stride_qm, stride_qk),
        offsets=(start_m * BLOCK_M, 0),
        block_shape=(BLOCK_M, BLOCK_DMODEL), order=(1, 0))

    o_block_ptr = tl.make_block_ptr(
        base=Out + o_offset, shape=(N_CTX, BLOCK_DMODEL),
        strides=(stride_om, stride_on),
        offsets=(start_m * BLOCK_M, 0),
        block_shape=(BLOCK_M, BLOCK_DMODEL), order=(1, 0))

    # TREE_DEPTH_P2 is guaranteed power-of-2 for tl.arange
    depth_offsets = tl.arange(0, TREE_DEPTH_P2)
    m_router_ptrs = router_indices + r_offset + start_m * stride_rm + depth_offsets * stride_rd
    m_routing_vec = tl.load(m_router_ptrs)

    q = tl.load(q_block_ptr, boundary_check=(0, 1), padding_option="zero")

    m_i = tl.zeros([BLOCK_M], dtype=tl.float32) - float("inf")
    l_i = tl.zeros([BLOCK_M], dtype=tl.float32)
    acc = tl.zeros([BLOCK_M, BLOCK_DMODEL], dtype=tl.float32)

    k_block_ptr = tl.make_block_ptr(
        base=K + k_offset, shape=(BLOCK_DMODEL, N_CTX),
        strides=(stride_kk, stride_kn), offsets=(0, 0),
        block_shape=(BLOCK_DMODEL, BLOCK_N), order=(0, 1))

    v_block_ptr = tl.make_block_ptr(
        base=V + v_offset, shape=(N_CTX, BLOCK_DMODEL),
        strides=(stride_vk, stride_vn), offsets=(0, 0),
        block_shape=(BLOCK_N, BLOCK_DMODEL), order=(1, 0))

    num_n_blocks = tl.cdiv(N_CTX, BLOCK_N)

    for start_n_block in range(0, num_n_blocks):
        n_router_ptrs = (router_indices + r_offset
                         + start_n_block * stride_rm
                         + depth_offsets * stride_rd)
        n_routing_vec = tl.load(n_router_ptrs)

        # Check if blocks share required ancestral depth
        # Only compare levels [0, req_depth) — extra padded levels are masked out
        mismatch = (m_routing_vec != n_routing_vec) & (depth_offsets < req_depth)
        has_mismatch = tl.max(mismatch.to(tl.int32), axis=0)

        # FIX: use if-guard instead of `continue` (unsupported in Triton)
        if has_mismatch == 0:
            k = tl.load(k_block_ptr, boundary_check=(0, 1), padding_option="zero")
            v = tl.load(v_block_ptr, boundary_check=(0, 1), padding_option="zero")

            qk = tl.dot(q, k) * sm_scale
            m_i_new = tl.maximum(m_i, tl.max(qk, 1))
            alpha = tl.exp(m_i - m_i_new)
            p = tl.exp(qk - m_i_new[:, None])
            acc = acc * alpha[:, None] + tl.dot(p.to(tl.float16), v)
            l_i = l_i * alpha + tl.sum(p, 1)
            m_i = m_i_new

        # Always advance pointers (cheap arithmetic, no SRAM load)
        k_block_ptr = tl.advance(k_block_ptr, (0, BLOCK_N))
        v_block_ptr = tl.advance(v_block_ptr, (BLOCK_N, 0))

    acc = acc / l_i[:, None]
    tl.store(o_block_ptr, acc.to(tl.float16), boundary_check=(0, 1))


# ============================================================
# ROUTING + WRAPPER
# ============================================================

def make_tree_routing(num_blocks, tree_depth_p2, real_depth, batch, heads, p=2, device='cuda'):
    """Assign each block its natural binary tree path, padded to power-of-2 depth."""
    router = torch.zeros(batch, heads, num_blocks, tree_depth_p2, dtype=torch.int32, device=device)
    for d in range(real_depth):
        shift = real_depth - 1 - d
        for b_idx in range(num_blocks):
            router[:, :, b_idx, d] = (b_idx >> shift) % p
    # Padded levels stay 0 (they're masked out by depth_offsets < req_depth)
    return router


def compute_sparsity(num_blocks, real_depth, req_depth, p=2):
    """Fraction of block pairs skipped."""
    total = num_blocks * num_blocks
    matched = 0
    for i in range(num_blocks):
        for j in range(num_blocks):
            match = True
            for d in range(req_depth):
                shift = real_depth - 1 - d
                if (i >> shift) % p != (j >> shift) % p:
                    match = False
                    break
            if match:
                matched += 1
    return 1.0 - matched / total


def triton_attention(q, k, v, router_indices, req_depth, tree_depth_p2, p=2):
    """Launch the fixed Triton kernel."""
    Z, H, N_CTX, DMODEL = q.shape
    BLOCK_M = min(128, N_CTX)
    BLOCK_N = min(128, N_CTX)

    q, k, v = q.contiguous(), k.contiguous(), v.contiguous()
    router_indices = router_indices.contiguous()
    out = torch.empty_like(q)
    sm_scale = 1.0 / math.sqrt(DMODEL)

    grid = (triton.cdiv(N_CTX, BLOCK_M), Z * H)

    _ultrametric_fwd_kernel[grid](
        q, k, v, sm_scale, router_indices, out,
        q.stride(0), q.stride(1), q.stride(2), q.stride(3),
        k.stride(0), k.stride(1), k.stride(2), k.stride(3),
        v.stride(0), v.stride(1), v.stride(2), v.stride(3),
        out.stride(0), out.stride(1), out.stride(2), out.stride(3),
        router_indices.stride(0), router_indices.stride(1),
        router_indices.stride(2), router_indices.stride(3),
        req_depth, Z, H, N_CTX,
        BLOCK_M=BLOCK_M, BLOCK_DMODEL=DMODEL, BLOCK_N=BLOCK_N,
        P_ARY=p, TREE_DEPTH_P2=tree_depth_p2)
    return out


# ============================================================
# DENSE BASELINE
# ============================================================

def dense_attention(q, k, v):
    scale = 1.0 / math.sqrt(q.shape[-1])
    scores = torch.matmul(q, k.transpose(-2, -1)) * scale
    attn = F.softmax(scores, dim=-1)
    return torch.matmul(attn, v)


# ============================================================
# BENCHMARK
# ============================================================

def bench(fn, warmup=10, runs=30):
    with torch.no_grad():
        for _ in range(warmup):
            fn()
        torch.cuda.synchronize()
        times = []
        for _ in range(runs):
            torch.cuda.reset_peak_memory_stats()
            s = torch.cuda.Event(enable_timing=True)
            e = torch.cuda.Event(enable_timing=True)
            s.record(); fn(); e.record()
            torch.cuda.synchronize()
            times.append(s.elapsed_time(e))
    return sorted(times)[len(times)//2], torch.cuda.max_memory_allocated()/1024**2


def main():
    device = 'cuda'
    print(f"GPU: {torch.cuda.get_device_name(0)}")
    print(f"Triton: {triton.__version__}")

    embed_dim = 512
    num_heads = 8
    head_dim = embed_dim // num_heads
    batch = 8
    p = 2

    seq_lengths = [256, 512, 1024, 2048, 4096, 8192]

    print()
    print("=" * 95)
    print(f"  TRITON BLOCK-SPARSE ULTRAMETRIC KERNEL — FIXED")
    print(f"  embed={embed_dim}, heads={num_heads}, head_dim={head_dim}, batch={batch}")
    print("=" * 95)

    # First, verify correctness at small scale
    print("\n--- Correctness check (seq=256, should match dense within 1e-2) ---")
    sl = 256
    num_blocks = sl // 128
    real_depth = max(int(math.ceil(math.log2(max(num_blocks, 2)))), 1)
    td_p2 = next_pow2(real_depth)
    q = torch.randn(1, 1, sl, head_dim, device=device, dtype=torch.float16)
    k = torch.randn_like(q)
    v = torch.randn_like(q)
    # req_depth=0 means ALL blocks match → equivalent to dense
    router = make_tree_routing(num_blocks, td_p2, real_depth, 1, 1, p, device)
    out_dense = dense_attention(q, k, v)
    out_triton = triton_attention(q, k, v, router, req_depth=0, tree_depth_p2=td_p2)
    diff = (out_dense - out_triton).abs().max().item()
    print(f"  req_depth=0 (all blocks attend): max diff = {diff:.6f}", "✅" if diff < 0.01 else "❌")
    del q, k, v, router
    torch.cuda.empty_cache()

    # Benchmark
    print()
    results = []
    for sl in seq_lengths:
        BLOCK_M = min(128, sl)
        num_blocks = sl // BLOCK_M
        real_depth = max(int(math.ceil(math.log2(max(num_blocks, 2)))), 1)
        td_p2 = next_pow2(real_depth)

        depths_to_test = sorted(set([1, max(real_depth // 2, 1), real_depth]))

        for req_depth in depths_to_test:
            if req_depth > real_depth:
                continue

            sparsity = compute_sparsity(num_blocks, real_depth, req_depth, p)

            q = torch.randn(batch, num_heads, sl, head_dim, device=device, dtype=torch.float16)
            k = torch.randn_like(q)
            v = torch.randn_like(q)
            router = make_tree_routing(num_blocks, td_p2, real_depth, batch, num_heads, p, device)

            try:
                d_ms, d_mb = bench(lambda: dense_attention(q, k, v))
            except torch.cuda.OutOfMemoryError:
                d_ms, d_mb = float('inf'), float('inf')
                print(f"  Dense OOM at seq_len={sl}!")

            try:
                t_ms, t_mb = bench(lambda: triton_attention(q, k, v, router, req_depth, td_p2))
            except Exception as ex:
                print(f"  ⚠️  Triton error at seq={sl}, depth={req_depth}/{real_depth}: {ex}")
                t_ms, t_mb = float('inf'), float('inf')

            speedup = d_ms / t_ms if t_ms > 0 and t_ms != float('inf') else 0
            mem_save = (1 - t_mb / d_mb) * 100 if d_mb > 0 and d_mb != float('inf') else 0

            row = {
                "seq_len": sl, "num_blocks": num_blocks,
                "depth": f"{req_depth}/{real_depth}", "td_p2": td_p2,
                "sparsity": f"{sparsity:.0%}",
                "dense_ms": round(d_ms, 2), "triton_ms": round(t_ms, 2),
                "speedup": f"{speedup:.2f}x",
                "dense_mb": round(d_mb, 1), "triton_mb": round(t_mb, 1),
                "mem_save": f"{mem_save:.1f}%",
            }
            results.append(row)

            fire = "🔥" if speedup > 1.0 else "  "
            print(f"{fire} seq={sl:>5} | blk={num_blocks:>3} | d={req_depth}/{real_depth}"
                  f" | sparse={sparsity:>4.0%}"
                  f" | dense={d_ms:>7.2f}ms | triton={t_ms:>7.2f}ms"
                  f" | {speedup:>5.2f}x | mem:{mem_save:>5.1f}%")

            del q, k, v, router
            torch.cuda.empty_cache()

    print()
    print("=" * 95)
    print("  SUMMARY")
    print("=" * 95)
    hdr = f"{'SeqLen':>7} | {'Blocks':>6} | {'Depth':>5} | {'Sparse':>7} | {'Dense ms':>9} | {'Triton ms':>10} | {'Speedup':>8} | {'MemSave':>8}"
    print(hdr)
    print("-" * len(hdr))
    for r in results:
        s = float(r['speedup'].replace('x',''))
        fire = "🔥" if s > 1.0 else "  "
        print(f"{r['seq_len']:>7} | {r['num_blocks']:>6} | {r['depth']:>5} | {r['sparsity']:>7}"
              f" | {r['dense_ms']:>9} | {r['triton_ms']:>10} | {fire}{r['speedup']:>6} | {r['mem_save']:>8}")

    with open("benchmark_triton_v2_results.json", "w") as f:
        json.dump(results, f, indent=2)
    print(f"\n✅ Saved")


if __name__ == "__main__":
    main()
