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

## 4. The Sparse Backward Pass

Training currently uses dense $O(N^2)$ attention because the Gumbel-Softmax gates are soft and gradients must flow through all possible paths.

**The Strategy:** Implement a "phase-transition" training curriculum. As $\tau \to 0$, the Gumbel gates polarize. In the final 20% of training, we can transition to a block-sparse backward pass to save massive FLOPs.

### Implementation Roadmap
*   **Phase Transition Curriculum:** At 80% of training, apply a hard threshold to the gates (`gates > 0.5`) using a Straight-Through Estimator.
*   **Triton Backward Kernel:** Write a custom `triton_block_sparse_bwd` kernel that only loads and accumulates gradients ($\nabla Q, \nabla K, \nabla V$) for the active blocks indicated by the polarized gates.
*   **PyTorch Autograd Wrapper:** Wrap the forward and backward kernels in a custom `torch.autograd.Function`. During the first 80%, it dispatches to dense FlashAttention. During the final 20%, it dispatches to the Triton sparse backward kernel, bypassing the $O(N^2)$ gradient bottleneck entirely. (Validated by literature such as AdaSplash-2 and RAT+).
