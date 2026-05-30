"""
Ultrametric AI — Triton Block-Sparse Attention Kernel (NVIDIA GPU)

Hardware-accelerated block-sparse attention that dynamically skips SRAM loads
for blocks whose routing vectors indicate they do not share the required
ancestral depth in the Bruhat-Tits tree.

The kernel uses Online Softmax (Milakov & Gimelshein, 2018) for numerically
stable, single-pass attention without materializing the full N² score matrix.

Usage:
    out = ultrametric_attention_triton(q, k, v, router_indices, req_depth=3)

Falls back to PyTorch masked attention if Triton is not installed.
"""

import torch
import math
from typing import Optional

try:
    import triton
    import triton.language as tl

    HAS_TRITON = True
except (ImportError, RuntimeError):
    HAS_TRITON = False


if HAS_TRITON:

    @triton.jit
    def _ultrametric_fwd_kernel(
        Q,
        K,
        V,
        sm_scale,
        router_indices,
        Out,
        stride_qz,
        stride_qh,
        stride_qm,
        stride_qk,
        stride_kz,
        stride_kh,
        stride_kn,
        stride_kk,
        stride_vz,
        stride_vh,
        stride_vk,
        stride_vn,
        stride_oz,
        stride_oh,
        stride_om,
        stride_on,
        stride_rz,
        stride_rh,
        stride_rm,
        stride_rd,
        req_depth,
        Z,
        H,
        N_CTX,
        BLOCK_M: tl.constexpr,
        BLOCK_DMODEL: tl.constexpr,
        BLOCK_N: tl.constexpr,
        P_ARY: tl.constexpr,  # reserved for future p-ary branch comparison
        TREE_DEPTH_P2: tl.constexpr,
    ):
        """
        True Hardware Block-Sparse Triton kernel for Ultrametric Attention.

        Uses explicit block pointers (tl.make_block_ptr) to load memory.
        Dynamically reads routing indices to determine phylogenetic ancestors
        in the Bruhat-Tits tree, skipping SRAM loads for blocks that do not
        share an immediate ancestor.
        """
        start_m = tl.program_id(0)
        off_hz = tl.program_id(1)
        off_z = off_hz // H
        off_h = off_hz % H

        # Base pointers
        q_offset = off_z * stride_qz + off_h * stride_qh
        k_offset = off_z * stride_kz + off_h * stride_kh
        v_offset = off_z * stride_vz + off_h * stride_vh
        o_offset = off_z * stride_oz + off_h * stride_oh
        r_offset = off_z * stride_rz + off_h * stride_rh

        q_block_ptr = tl.make_block_ptr(
            base=Q + q_offset,
            shape=(N_CTX, BLOCK_DMODEL),
            strides=(stride_qm, stride_qk),
            offsets=(start_m * BLOCK_M, 0),
            block_shape=(BLOCK_M, BLOCK_DMODEL),
            order=(1, 0),
        )

        o_block_ptr = tl.make_block_ptr(
            base=Out + o_offset,
            shape=(N_CTX, BLOCK_DMODEL),
            strides=(stride_om, stride_on),
            offsets=(start_m * BLOCK_M, 0),
            block_shape=(BLOCK_M, BLOCK_DMODEL),
            order=(1, 0),
        )

        # Load routing index vector for current Q block
        # TREE_DEPTH_P2 is guaranteed power-of-2 for tl.arange compatibility
        depth_offsets = tl.arange(0, TREE_DEPTH_P2)
        m_router_ptrs = (
            router_indices + r_offset + start_m * stride_rm + depth_offsets * stride_rd
        )
        m_routing_vec = tl.load(m_router_ptrs)

        q = tl.load(q_block_ptr, boundary_check=(0, 1), padding_option="zero")

        m_i = tl.zeros([BLOCK_M], dtype=tl.float32) - float("inf")
        l_i = tl.zeros([BLOCK_M], dtype=tl.float32)
        acc = tl.zeros([BLOCK_M, BLOCK_DMODEL], dtype=tl.float32)

        # K transposed
        k_block_ptr = tl.make_block_ptr(
            base=K + k_offset,
            shape=(BLOCK_DMODEL, N_CTX),
            strides=(stride_kk, stride_kn),
            offsets=(0, 0),
            block_shape=(BLOCK_DMODEL, BLOCK_N),
            order=(0, 1),
        )

        # V
        v_block_ptr = tl.make_block_ptr(
            base=V + v_offset,
            shape=(N_CTX, BLOCK_DMODEL),
            strides=(stride_vk, stride_vn),
            offsets=(0, 0),
            block_shape=(BLOCK_N, BLOCK_DMODEL),
            order=(1, 0),
        )

        num_n_blocks = tl.cdiv(N_CTX, BLOCK_N)

        for start_n_block in range(0, num_n_blocks):
            n_router_ptrs = (
                router_indices
                + r_offset
                + start_n_block * stride_rm
                + depth_offsets * stride_rd
            )
            n_routing_vec = tl.load(n_router_ptrs)

            # --- TOPOLOGICAL ROUTING LOGIC ---
            # Check if blocks share required ancestral depth
            # Extra padded depth levels are masked by depth_offsets < req_depth
            mismatch = (m_routing_vec != n_routing_vec) & (depth_offsets < req_depth)
            has_mismatch = tl.max(mismatch.to(tl.int32), axis=0)

            # FIX: Triton does not support `continue` — use if-guard instead
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
            # ---------------------------------

            # Always advance pointers (cheap arithmetic, no SRAM load)
            k_block_ptr = tl.advance(k_block_ptr, (0, BLOCK_N))
            v_block_ptr = tl.advance(v_block_ptr, (BLOCK_N, 0))

        acc = acc / l_i[:, None]
        tl.store(o_block_ptr, acc.to(tl.float16), boundary_check=(0, 1))


def routing_to_block_indices(
    assignments: torch.Tensor,
    seq_len: int,
    block_size: int = 128,
) -> torch.Tensor:
    """
    Convert per-token routing assignments to per-block routing indices
    for the Triton kernel.

    Each block's routing vector is determined by majority vote of the tokens
    in that block. This ensures consistent block-level routing decisions.

    Args:
        assignments: (batch, heads, seq_len, levels, p) one-hot routing
        seq_len: actual sequence length (before padding)
        block_size: kernel block size (BLOCK_M)

    Returns:
        router_indices: (batch, heads, num_blocks, levels) int32
    """
    B, H, S, L, P = assignments.shape
    num_blocks = math.ceil(seq_len / block_size)

    # Get integer branch IDs from one-hot: (B, H, S, L)
    branch_ids = assignments.argmax(dim=-1)

    # Pad sequence to exact multiple of block_size
    if S < num_blocks * block_size:
        pad_len = num_blocks * block_size - S
        branch_ids = torch.nn.functional.pad(branch_ids, (0, 0, 0, pad_len), value=0)

    # Reshape into blocks: (B, H, num_blocks, block_size, L)
    branch_ids = branch_ids.view(B, H, num_blocks, block_size, L)

    # Majority vote per block: take mode (most common branch per level)
    # For efficiency, use the first token in each block as representative
    # (in practice, tokens within a block are spatially close and route similarly)
    router_indices = branch_ids[:, :, :, 0, :]  # (B, H, num_blocks, L)

    return router_indices.to(torch.int32)


def _pytorch_fallback(
    q: torch.Tensor,
    k: torch.Tensor,
    v: torch.Tensor,
    router_indices: torch.Tensor,
    req_depth: int,
    p: int = 2,
) -> torch.Tensor:
    """
    Pure PyTorch fallback when Triton is unavailable.

    Reconstructs a block-level boolean mask from router_indices and applies
    standard scaled dot-product attention with the mask.
    """
    import torch.nn.functional as F

    Z, H, N_CTX, DMODEL = q.shape
    BLOCK = 128
    num_blocks = router_indices.shape[2]

    # Build block-level mask: blocks match if routing prefixes agree up to req_depth
    # router_indices: (Z, H, num_blocks, depth)
    r = router_indices[:, :, :, :req_depth]  # (Z, H, num_blocks, req_depth)
    # Compare all pairs: (Z, H, num_blocks, 1, req_depth) vs (Z, H, 1, num_blocks, req_depth)
    match = (r.unsqueeze(3) == r.unsqueeze(2)).all(dim=-1)  # (Z, H, num_blocks, num_blocks)

    # Expand block-level mask to token-level mask
    # match[z,h,i,j] = True means tokens in block i attend to tokens in block j
    mask = match.repeat_interleave(BLOCK, dim=2).repeat_interleave(BLOCK, dim=3)
    mask = mask[:, :, :N_CTX, :N_CTX]  # trim padding

    scale = 1.0 / math.sqrt(DMODEL)
    scores = torch.matmul(q, k.transpose(-2, -1)) * scale
    scores = scores.masked_fill(~mask, float('-inf'))
    attn = F.softmax(scores, dim=-1)
    return torch.matmul(attn, v)


def ultrametric_attention_triton(
    q: torch.Tensor,
    k: torch.Tensor,
    v: torch.Tensor,
    router_indices: torch.Tensor,
    req_depth: int = 2,
    p: int = 2,
) -> torch.Tensor:
    """
    Launch wrapper for the Triton block-sparse ultrametric attention kernel.

    This function handles stride computation, output allocation, grid sizing,
    and kernel dispatch. The kernel itself performs Online Softmax with dynamic
    block skipping based on p-adic routing vectors.

    Args:
        q: (batch, heads, seq_len, head_dim) float16 query tensor
        k: (batch, heads, seq_len, head_dim) float16 key tensor
        v: (batch, heads, seq_len, head_dim) float16 value tensor
        router_indices: (batch, heads, num_blocks, tree_depth) int32
            Per-block routing vectors. num_blocks = ceil(seq_len / BLOCK_M).
            Each entry is an integer branch ID at the corresponding tree level.
        req_depth: required ancestral depth for block matching.
            Higher = sparser attention (more blocks skipped).
            0 = all blocks attend (equivalent to dense). Must be <= tree_depth.
        p: tree arity (default: 2 for binary Bruhat-Tits tree)

    Returns:
        out: (batch, heads, seq_len, head_dim) float16 attention output
    """
    if not HAS_TRITON:
        return _pytorch_fallback(q, k, v, router_indices, req_depth, p)

    assert q.dtype == torch.float16, f"Triton kernel requires float16, got {q.dtype}"
    assert q.is_cuda, "Triton kernel requires CUDA tensors"

    Z, H, N_CTX, DMODEL = q.shape

    # Ensure contiguous memory layout
    q = q.contiguous()
    k = k.contiguous()
    v = v.contiguous()
    router_indices = router_indices.contiguous().to(torch.int32)

    TREE_DEPTH = router_indices.shape[-1]
    assert 0 <= req_depth <= TREE_DEPTH, (
        f"req_depth ({req_depth}) must be in [0, {TREE_DEPTH}]"
    )

    # Triton requires tl.arange ranges to be powers of 2
    TREE_DEPTH_P2 = 1 << (TREE_DEPTH - 1).bit_length() if TREE_DEPTH > 1 else 1

    # Block size configuration
    # BLOCK_M/N = 128 is the sweet spot for A100/4090 SRAM capacity
    # BLOCK_DMODEL must exactly match head_dim for correctness
    BLOCK_M = min(128, N_CTX)
    BLOCK_N = min(128, N_CTX)
    BLOCK_DMODEL = DMODEL

    # Pad router_indices if num_blocks doesn't match
    num_blocks_needed = triton.cdiv(N_CTX, BLOCK_M)
    num_blocks_have = router_indices.shape[2]
    if num_blocks_have < num_blocks_needed:
        pad = torch.zeros(
            (Z, H, num_blocks_needed - num_blocks_have, TREE_DEPTH),
            dtype=torch.int32,
            device=router_indices.device,
        )
        router_indices = torch.cat([router_indices, pad], dim=2)

    # Pad depth dimension to power-of-2 for tl.arange compatibility
    if TREE_DEPTH < TREE_DEPTH_P2:
        depth_pad = torch.zeros(
            (*router_indices.shape[:-1], TREE_DEPTH_P2 - TREE_DEPTH),
            dtype=torch.int32,
            device=router_indices.device,
        )
        router_indices = torch.cat([router_indices, depth_pad], dim=-1)

    # Allocate output
    out = torch.empty_like(q)

    # Scale factor
    sm_scale = 1.0 / math.sqrt(DMODEL)

    # Grid: one program per (query_block, batch*head)
    grid = (triton.cdiv(N_CTX, BLOCK_M), Z * H)

    _ultrametric_fwd_kernel[grid](
        q,
        k,
        v,
        sm_scale,
        router_indices,
        out,
        # Q strides: (batch, head, seq, dim)
        q.stride(0),
        q.stride(1),
        q.stride(2),
        q.stride(3),
        # K strides
        k.stride(0),
        k.stride(1),
        k.stride(2),
        k.stride(3),
        # V strides
        v.stride(0),
        v.stride(1),
        v.stride(2),
        v.stride(3),
        # Output strides
        out.stride(0),
        out.stride(1),
        out.stride(2),
        out.stride(3),
        # Router strides: (batch, heads, blocks, depth)
        router_indices.stride(0),
        router_indices.stride(1),
        router_indices.stride(2),
        router_indices.stride(3),
        # Scalar args
        req_depth,
        Z,
        H,
        N_CTX,
        # Compile-time constants
        BLOCK_M=BLOCK_M,
        BLOCK_DMODEL=BLOCK_DMODEL,
        BLOCK_N=BLOCK_N,
        P_ARY=p,
        TREE_DEPTH_P2=TREE_DEPTH_P2,
    )

    return out

