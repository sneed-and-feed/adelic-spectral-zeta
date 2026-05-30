# Ultrametric AI v2: Feature Roadmap

This document outlines the theoretical and architectural roadmap for scaling Dynamic Ultrametric Attention to Llama-class sizes and resolving remaining long-context edge cases. The strategies below were derived from a combination of first-principles mathematics and cutting-edge literature on sparse attention.

---

## 1. True Adelic Routing (Multi-Prime Arity)

Standard hierarchical sparse attention relies on perfect binary trees ($p=2$), which imposes a rigid power-of-2 grid on the token hierarchy. This disrupts natural linguistic boundaries (words, subwords) that do not natively cluster into binary segments.

**The Strategy:** Assign different prime arities ($p=2, 3, 5$) to different attention heads. Running these mixed-radix trees in parallel mimics the true adèle ring (which considers all prime places simultaneously).

### Implementation Roadmap
*   **Router Refactoring:** Update `DynamicTopologyRouter` to accept a `prime_arity` parameter. Tree indexing logic must generalize from binary ($2i+1, 2i+2$) to $p$-ary: the $j$-th child of node $i$ is `p * i + 1 + j`, and the parent is `(i - 1) // p`.
*   **Triton Optimizations:** Pass $p$ as a `tl.constexpr` to the `triton.jit` kernel. This enables the compiler to unroll loops over $p$ children and replace expensive dynamic integer divisions with optimized magic-number arithmetic at compile time.
*   **Multi-Head Configuration:** Distribute primes across the `MultiHeadAttention` module (e.g., in a 12-head model, assign 4 heads to $p=2$, 4 to $p=3$, and 4 to $p=5$).

---

## 2. Shifted Ultrametric Trees Across Layers

In a standard ultrametric tree, tokens across the sequence midpoint (e.g., $N/2 - 1$ and $N/2$) are physically adjacent but separated by the maximum ultrametric distance (the root split).

**The Strategy:** Inspired by the Swin Transformer, we can alternate the ultrametric tree boundaries across layers by applying cyclic shifts.

### Implementation Roadmap
*   **The Odd-Shift Rule:** To minimize the distance between previously root-split tokens, the cyclic shift $S$ *must be an odd integer*. This pairs the split boundary tokens into the lowest possible level (LCA depth 1).
*   **The Macro-Shift:** To maximize global cross-pollination across subtrees, the optimal shift is $S = \frac{N}{4} \pm 1$.
*   **Wrap-Around Discontinuity:** A cyclic shift rotates the sequence, mapping the very last token next to the very first token. A Swin-style cyclic attention mask must be applied to prevent attention from crossing this artificial wrap-around boundary.
*   **Layer Alternation:** Layer $l$ uses $S=0$. Layer $l+1$ applies the shift, runs the ultrametric kernel, and then applies the inverse shift.

---

## 3. Interaction with RoPE / ALiBi

Hierarchical block-sparse routing creates a mathematical conflict with strict 1D Archimedean distance decays like RoPE, causing "staircase-step" attention artifacts.

**The Strategy:** Decouple local syntax from global semantics.

### Implementation Roadmap
*   **Local Window Absorption:** The current hybrid architecture (dense local window + sparse ultrametric routing) perfectly resolves this. The dense local window absorbs the exact 1D RoPE dynamics required for syntax and grammar.
*   **Long-Range Decoupling:** For the long-range ultrametric branch, standard RoPE decay should be flattened, allowing the tree topology to solely dictate semantic routing.
*   **Chunk-Indexed RoPE (Alternative):** Alternatively, assign the *same* relative position ID to all tokens within a distant tree block, treating the topological node as a single positional entity to eliminate staircase artifacts.

---

## 4. The Sparse Backward Pass — ✅ IMPLEMENTED

Training currently uses dense $O(N^2)$ attention because the Gumbel-Softmax gates are soft and gradients must flow through all possible paths.

**The Strategy:** Implement a "phase-transition" training curriculum. As $\tau \to 0$, the Gumbel gates polarize. In the final 20% of training, we can transition to a block-sparse backward pass to save massive FLOPs.

### Implementation Status
*   ✅ **Phase Transition Curriculum:** `CurriculumSparseAttention` (`torch.autograd.Function`) dispatches to dense FlashAttention during Phase 1 (0–80%) and to Triton block-sparse kernels during Phase 2 (80–100%).
*   ✅ **Triton Backward Kernels:** `_ultrametric_bwd_dq_kernel` and `_ultrametric_bwd_dk_dv_kernel` implemented in `kernel.py`. They use precomputed block coordinate lists (`q_to_k_indices`, `k_to_q_indices`) with `tl.constexpr` loop bounds to iterate only over active blocks.
*   ✅ **PyTorch Autograd Wrapper:** `CurriculumSparseAttention.apply(q, k, v, router_indices, req_depth, p, use_sparse_backend=True)` seamlessly wraps the forward/backward dispatch.

### A100 Benchmark Results

| Phase | Execution Time (ms) | Description |
|:------|--------------------:|:------------|
| Phase 1 (Dense) | 5.95 | PyTorch `F.scaled_dot_product_attention` (FlashAttention-2) |
| Phase 2 (Sparse) | 133.43 | Triton block-sparse with precomputed coordinate lists |

**Finding: IO-Bound Bottleneck.** The sparse backward kernels are asymptotically superior ($O(N \log N)$ FLOPs vs. $O(N^2)$) but are **slower** at 8192 tokens on the A100. The root cause is that FlashAttention-2 leverages the A100's Tensor Memory Accelerator (TMA) for peak-bandwidth linear SRAM tile loads, while our block-sparse kernel performs indirect memory gathers at dynamically computed offsets, disabling TMA and forcing scalar global memory loads. At 64 blocks of size 128, the FLOP savings from skipping ~60 of 64 blocks are overwhelmed by the per-block memory access overhead.

**Predicted Crossover.** The sparse backward pass is expected to become wall-clock competitive at context lengths in the 32K–64K+ regime, where matrix multiplication compute strictly dominates memory controller latency. Alternatively, future GPU architectures with hardware support for sparse TMA instructions would eliminate the IO bottleneck entirely.
