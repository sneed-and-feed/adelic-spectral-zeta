# Golfing Strategy: Per-Head Sparse Attention in Triton

## Answer to the Open Architectural Question

**Yes, Triton block-sparse attention kernels can efficiently support per-head sparsity patterns.** It is not an anti-pattern, and in fact, several recent frameworks and papers (e.g., *S2-Attention*, *HASTE*, *Stream*, and *RRAttention*) rely heavily on per-head, dynamic, and block-sparse attention schemes implemented in Triton.

### 1. The Branch Divergence Myth
The concern regarding "catastrophic branch divergence" across heads stems from a misunderstanding of how Triton maps attention to GPU hardware. In standard Triton attention kernels (like FlashAttention or its block-sparse variants), the grid is launched over dimensions such as `(num_q_blocks, num_heads, batch_size)`. 
*   **No Inter-Head Warp Divergence:** Since each thread block (program) is strictly assigned to a single head (`pid_h = tl.program_id(1)`), threads within the same warp only ever process data for that specific head. If Head 0 and Head 1 have completely different tree depths (`req_depth`), their respective thread blocks simply execute a different number of loop iterations over the KV cache.
*   **Load Imbalance vs. Divergence:** The primary risk is not branch divergence, but **SM load imbalance** (the straggler effect). If Head 0 computes a dense attention matrix (depth 1) while Head 1 computes a highly sparse matrix (depth 4), the SM processing Head 0 will take significantly longer. However, because modern GPUs concurrently schedule thousands of thread blocks, this imbalance is usually hidden unless the sparsity distribution is pathologically skewed across the entire batch.

### 2. Memory Layout and Block Pointer Iteration
To efficiently handle per-head block sparsity without excessive padding overhead, the memory layout and block iteration are typically managed via one of two strategies:

#### A. Block-CSR (Compressed Sparse Row) Layout
Instead of passing a dense boolean mask of shape `[batch, heads, q_blocks, k_blocks]`, the optimal Triton approach uses a Block-CSR or explicit index array format:
*   **Layout:** An integer tensor `block_indices` of shape `[batch, heads, max_active_blocks]` and an array `block_counts` of shape `[batch, heads, q_blocks]`.
*   **Iteration:** Inside the Triton kernel, the KV loop bounds are dynamically fetched:
    ```python
    num_blocks = tl.load(block_counts + batch_offset + head_offset + q_block_idx)
    for i in range(num_blocks):
        k_block_idx = tl.load(block_indices + ... + i)
        # Advance block pointers based on k_block_idx
    ```
This entirely avoids padding the inner loop. Threads only iterate over valid blocks for their specific head and query.

#### B. Hierarchical / Masked Layout (The S2-Attention Approach)
Libraries like *S2-Attention* (which specifically advertises "kernel optimization for sparse attention customizable at both per-head and per-context-range levels") compute block sparsity masks on the fly or load them from a sharded layout. If evaluating the Gumbel-Sigmoid tree routing is fast, the kernel can even compute the valid block ranges mathematically inside the loop (e.g., using `req_depth` as a tensor of shape `[heads]`), bounding the `tl.range` or masking block pointers dynamically without fetching an index array.

### 3. Conclusion for Ultrametric Attention
You should **not** enforce a per-layer majority vote for `req_depth`. Forcing uniform sparsity across all heads destroys the expressivity of the Gumbel-Sigmoid routing and is computationally suboptimal if many heads prefer high sparsity.

**Implementation Roadmap:**
1.  **Define Per-Head Depths:** Pass `req_depth` into the Triton kernel as a 1D tensor of shape `[num_heads]`.
2.  **Dynamic Loop Bounds:** Inside the kernel, let each `program_id` load its head's specific `req_depth`:
    ```python
    head_depth = tl.load(req_depth_ptr + pid_h)
    ```
3.  **Pointer Arithmetic:** Use `head_depth` to compute the step size or valid key blocks for the `tl.make_block_ptr` advance logic.
4.  **Avoid Dense Masks:** Do not instantiate a full dense mask in global memory. Either evaluate the Bruhat-Tits tree routing implicitly via block indices (Block-CSR) or analytically bound the KV loop based on `head_depth`.

By structuring the block pointer iteration around `head_depth`, the kernel will remain highly performant. The SMs will organically balance the workload of deep (sparse) vs. shallow (dense) heads.

## Literature Evidence
*   **S2-Attention: Hardware-Aware Context Sharding Among Attention Heads**: Explicitly introduces a Triton library optimizing sparse attention customizable at the per-head level.
*   **Stream: Scaling up Mechanistic Interpretability to Long Context in LLMs via Sparse Attention**: Estimates per-head sparse attention masks in $O(T \log T)$ time and implements dynamic sparse attention efficiently.
*   **RRAttention / HASTE**: Both propose per-head thresholding and dynamic routing without requiring uniform layer-wise sparsity masks.
