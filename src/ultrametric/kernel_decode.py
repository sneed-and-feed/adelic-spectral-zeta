import torch
import triton
import triton.language as tl

@triton.jit
def _ultrametric_decode_kernel(
    Q, K_cache, V_cache, 
    block_tables, context_lens, 
    router_indices, q_router_indices,
    Out,
    stride_q_b, stride_q_h, stride_q_d,
    stride_k_b, stride_k_h, stride_k_bs, stride_k_d,
    stride_v_b, stride_v_h, stride_v_bs, stride_v_d,
    stride_bt_b, stride_bt_l,
    stride_ri_b, stride_ri_h, stride_ri_d,
    stride_qri_b, stride_qri_h, stride_qri_d,
    stride_o_b, stride_o_h, stride_o_d,
    sm_scale,
    req_depth,
    BLOCK_SIZE: tl.constexpr,
    HEAD_DIM: tl.constexpr,
    TREE_DEPTH_P2: tl.constexpr
):
    batch_idx = tl.program_id(0)
    head_idx = tl.program_id(1)

    # Context length for this batch element
    ctx_len = tl.load(context_lens + batch_idx)
    if ctx_len == 0:
        return

    # Load query vector
    q_offset = batch_idx * stride_q_b + head_idx * stride_q_h
    d_offsets = tl.arange(0, HEAD_DIM)
    q_ptrs = Q + q_offset + d_offsets * stride_q_d
    q = tl.load(q_ptrs)

    # Load query routing vector
    q_ri_offset = batch_idx * stride_qri_b + head_idx * stride_qri_h
    tree_offsets = tl.arange(0, TREE_DEPTH_P2)
    q_ri_ptrs = q_router_indices + q_ri_offset + tree_offsets * stride_qri_d
    q_routing_vec = tl.load(q_ri_ptrs)

    # Initialize Online Softmax variables
    m_i = tl.zeros([1], dtype=tl.float32) - float('inf')
    l_i = tl.zeros([1], dtype=tl.float32)
    acc = tl.zeros([HEAD_DIM], dtype=tl.float32)

    num_logical_blocks = tl.cdiv(ctx_len, BLOCK_SIZE)
    
    for logical_idx in range(num_logical_blocks):
        # Load physical block index
        bt_ptr = block_tables + batch_idx * stride_bt_b + logical_idx * stride_bt_l
        physical_block_idx = tl.load(bt_ptr)

        # Load block routing vector
        kv_ri_offset = physical_block_idx * stride_ri_b + head_idx * stride_ri_h
        kv_ri_ptrs = router_indices + kv_ri_offset + tree_offsets * stride_ri_d
        kv_routing_vec = tl.load(kv_ri_ptrs)

        # Topology check
        mismatch = (q_routing_vec != kv_routing_vec) & (tree_offsets < req_depth)
        has_mismatch = tl.max(mismatch.to(tl.int32), axis=0)

        if has_mismatch == 0:
            # Load K and V
            k_offset = physical_block_idx * stride_k_b + head_idx * stride_k_h
            v_offset = physical_block_idx * stride_v_b + head_idx * stride_v_h

            bs_offsets = tl.arange(0, BLOCK_SIZE)
            
            k_ptrs = K_cache + k_offset + bs_offsets[:, None] * stride_k_bs + d_offsets[None, :] * stride_k_d
            v_ptrs = V_cache + v_offset + bs_offsets[:, None] * stride_v_bs + d_offsets[None, :] * stride_v_d

            # Mask for the last block
            seq_offsets = logical_idx * BLOCK_SIZE + bs_offsets
            mask = seq_offsets < ctx_len

            k = tl.load(k_ptrs, mask=mask[:, None], other=0.0)
            v = tl.load(v_ptrs, mask=mask[:, None], other=0.0)

            # q: [HEAD_DIM], k: [BLOCK_SIZE, HEAD_DIM]
            # qk: [BLOCK_SIZE]
            qk = tl.sum(q[None, :] * k, axis=1) * sm_scale
            # masked out elements should be -inf
            qk = tl.where(mask, qk, float('-inf'))

            # Online Softmax
            m_i_new = tl.maximum(m_i, tl.max(qk, axis=0))
            alpha = tl.exp(m_i - m_i_new)
            p = tl.exp(qk - m_i_new)
            
            acc = acc * alpha + tl.sum(p[:, None] * v, axis=0)
            l_i = l_i * alpha + tl.sum(p, axis=0)
            m_i = m_i_new

    # Epilogue
    out_offset = batch_idx * stride_o_b + head_idx * stride_o_h
    out_ptrs = Out + out_offset + d_offsets * stride_o_d
    tl.store(out_ptrs, acc / l_i)

def ultrametric_decode(
    q, k_cache, v_cache, 
    block_tables, context_lens, 
    router_indices, q_router_indices,
    req_depth
):
    batch_size, num_heads, head_dim = q.shape
    tree_depth = q_router_indices.shape[-1]
    
    assert tree_depth & (tree_depth - 1) == 0, "Tree depth must be a power of 2 for this kernel"
    
    out = torch.empty_like(q)
    sm_scale = 1.0 / (head_dim ** 0.5)

    BLOCK_SIZE = k_cache.shape[2]
    
    grid = (batch_size, num_heads)
    
    _ultrametric_decode_kernel[grid](
        q, k_cache, v_cache, 
        block_tables, context_lens, 
        router_indices, q_router_indices,
        out,
        q.stride(0), q.stride(1), q.stride(2),
        k_cache.stride(0), k_cache.stride(1), k_cache.stride(2), k_cache.stride(3),
        v_cache.stride(0), v_cache.stride(1), v_cache.stride(2), v_cache.stride(3),
        block_tables.stride(0), block_tables.stride(1),
        router_indices.stride(0), router_indices.stride(1), router_indices.stride(2),
        q_router_indices.stride(0), q_router_indices.stride(1), q_router_indices.stride(2),
        out.stride(0), out.stride(1), out.stride(2),
        sm_scale, req_depth,
        BLOCK_SIZE=BLOCK_SIZE,
        HEAD_DIM=head_dim,
        TREE_DEPTH_P2=tree_depth
    )
    return out
