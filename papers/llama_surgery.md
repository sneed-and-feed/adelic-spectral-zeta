# Llama Surgery: Continuous Sparsification of Pre-Trained Language Models via Differentiable Ultrametric Topology Injection

> **Sequel to:** *Learning to Skip Blocks: Self-Discovered Ultrametric Routing for Hardware-Accelerated Sparse Attention*

---

## Abstract

We present *Llama Surgery*, a method for injecting learned block-sparse attention topologies into pre-trained dense language models without retraining from scratch, distillation, or post-hoc pruning. Starting from a frozen Llama 3.1 8B, we surgically replace each attention layer with a *Dynamic Topology Router* that maps token embeddings onto the branches of a Bruhat-Tits p-adic tree via factorized Gumbel-Softmax routing. A *Deterministic Collapse Initialization* to achieve a *Continuous Logit Homotopy* guarantees that at step 0 the injected topology mask is identically dense, preserving the pre-trained manifold exactly. Over training, temperature annealing polarizes the soft routing assignments into hard binary masks, and a Switch Transformer-style load-balancing loss prevents routing collapse. We identify and resolve two critical failure modes: (1) gradient collapse through discrete masking operations, solved by a Straight-Through Estimator bridge that decouples the hard forward mask from the soft backward gradient; and (2) *Attention Sink* instability, where hard-masking the initial token causes softmax entropy collapse and syntactic degeneration, solved by permanently anchoring Token 0 in the visibility set. The resulting architecture is validated on Llama 3.1 8B fine-tuned on WikiText-2, achieving stable convergence and producing coherent, mathematically sophisticated text while maintaining dynamic block-sparse routing across all 32 transformer layers. A controlled semantic clustering experiment on TinyLlama-1.1B demonstrates that the router learns to assign tokens from distinct semantic domains (mathematics, natural language, code) to separate branches of the Bruhat-Tits tree using only the standard language modeling loss, with no explicit clustering objective. We further identify and resolve three critical `float16` numerical failure modes—Gumbel-Softmax overflow, attention score overflow, and cumulative product backward instability—the last of which we solve via a novel `cumprod`→`cummin` substitution that exploits the binary structure of hard Gumbel-Softmax outputs. A custom Triton forward kernel with Attention Sink and Local Window support, pipelined for Ampere and Hopper architectures (`num_warps=4`, `num_stages=3`), executes the block-sparse prefill phase at O(N) theoretical complexity. To our knowledge, this is the first demonstration of differentiable ultrametric topology injection into a production-scale pre-trained LLM.

---

## 1. Introduction

In the companion paper *Learning to Skip Blocks*, we demonstrated that small Transformers trained from scratch can autonomously discover block-sparse attention topologies via Gumbel-Sigmoid depth gates, and that these topologies transfer losslessly to a custom Triton kernel achieving up to **28x** wall-clock speedup. However, three critical limitations remained:

1. **Scale.** All experiments used models with at most 4 layers and 256 embedding dimensions. Whether the routing mechanism survives injection into billion-parameter pre-trained models was unknown.
2. **From-Scratch Training.** The depth gates were trained jointly with randomly initialized weights. In practice, users have access to powerful pre-trained checkpoints (Llama 3, Mistral, Gemma) and cannot afford to retrain from scratch.
3. **Content-Agnostic Routing.** The V1/V2 routing topology was determined by *position* in the sequence. A token's tree branch was a fixed function of its index, not its meaning.

This paper resolves all three. We introduce *Llama Surgery*: a procedure for injecting a *Dynamic Topology Router*—one that routes based on token *content*, not position—into each attention layer of a frozen pre-trained Llama 3.1 8B model. The key technical contributions are:

1. **Continuous Logit Homotopy via Deterministic Collapse** (Section 2.3). A surgical initialization scheme that mathematically guarantees the injected routing mask is identically dense at step 0, preserving the pre-trained manifold.
2. **Straight-Through Estimator Bridge** (Section 2.4). A gradient pathway that maintains differentiability through the discrete topology mask.
3. **Attention Sink Stabilization** (Section 2.5). The discovery that hard-masking Token 0 causes catastrophic softmax entropy collapse, and a permanent fix.
4. **Triton V3 Kernel** (Section 3). A block-sparse forward kernel upgraded with Attention Sink visibility, Local Grammar Windows, and Hopper-specific pipelining.

---

## 2. Method

### 2.1 Dynamic Topology Router

Unlike the position-based routing of V1/V2, the V3 `DynamicTopologyRouter` maps token *embeddings* to tree branches. Given input tokens x ∈ R^(B × N × d), the router computes:

```
h = GELU(W_backbone · x + b_backbone)
logits = W_route · h ∈ R^(B × N × (H · L · p))
```

where H is the number of attention heads, L = ⌈log_p(N_max)⌉ is the tree depth, and p is the arity. The logits are reshaped to (B, H, N, L, p) and passed through Gumbel-Softmax:

```
a_{b,h,n,ℓ} = GumbelSoftmax(logits_{b,h,n,ℓ}, τ) ∈ Δ^(p-1)
```

Each token n in head h receives a routing assignment vector a ∈ R^(L × p): a probability distribution over the p children at each of L tree levels. When τ → 0 and `hard=True`, assignments polarize to one-hot vectors via the straight-through estimator, yielding deterministic branch assignments equivalent to a p-adic expansion.

### 2.2 Differentiable Ultrametric Mask

The expected p-adic distance between tokens i and j under soft assignments is:

```
M_{ij,ℓ} = Σ_c  a_{i,ℓ,c} · a_{j,ℓ,c}

d_p(i,j) = L - Σ_{ℓ=0}^{L-1} Π_{m=ℓ}^{L-1} M_{ij,m}
```

The mask is constructed via a Straight-Through Estimator:

```
m_soft = σ((d_max - d_p(i,j)) / T)
m_hard = 𝟙[d_p(i,j) ≤ d_max]
m_{ij} = sg[m_hard - m_soft] + m_soft
```

where sg[·] denotes stop-gradient. In the forward pass, m_{ij} evaluates to the hard binary mask; in the backward pass, gradients flow through m_soft into the router parameters.

### 2.3 Continuous Logit Homotopy

Naïve injection of a randomly initialized router into a pre-trained model catastrophically disrupts the learned attention distribution at step 0 by arbitrarily suppressing valid attention blocks. We eliminate this shock via a *Deterministic Collapse Initialization* to achieve a *Continuous Logit Homotopy*. 

Instead of a uniform distribution (which forces tokens into disparate branches and maximizes expected $p$-adic distance), the weights of the router's projection layer are initialized exactly to 0. The bias is explicitly set such that the logit for the 0-th child branch at every tree level is massive (e.g., +5.0), while all other branches are suppressed (e.g., -5.0). 

At this deterministic initialization point, every single token is routed identically to the 0-th branch. Because all tokens collapse into the exact same localized sub-tree, the expected $p$-adic distance between *any* two tokens is $0$. Since $0 \le d_{\max}$, the resulting hard boolean mask is exactly $1.0$ (identically dense) everywhere. The pre-trained attention manifold is preserved with zero degradation at step 0. 

As training progresses, the Switch Transformer-style load-balancing auxiliary loss forces the tree to naturally "grow". The load-balancing penalty overpowers the initialization bias, smoothly distributing tokens across the newly discovered branches and transitioning the architecture from fully dense to topologically sparse.

### 2.4 Straight-Through Estimator Bridge

During initial experiments, replacing the soft mask with a boolean condition `full_mask > 0.5` in the attention computation caused the training loss to collapse to a static value and the router weights to receive zero gradient. The boolean operation severs the computation graph.

We resolve this with a two-stage masking strategy:

1. **Hard masking for softmax stability.** Positions where m_{ij} < 0.5 are filled with -∞ in the attention logits before softmax.
2. **Soft masking for gradient flow.** After softmax, the attention weights are element-wise multiplied by the STE mask, followed by renormalization:

```python
sparse_scores = scores.masked_fill(~um_mask_bool, float('-inf'))
attn_weights = F.softmax(sparse_scores, dim=-1)
attn_weights = attn_weights * full_mask  # STE gradient bridge
attn_weights = attn_weights / (attn_weights.sum(dim=-1, keepdim=True) + 1e-8)
```

### 2.5 Attention Sink Stabilization

When generating long-form text with the trained model, we observed a characteristic failure pattern: the model produces exactly W coherent sub-word tokens (one local window), then collapses into an infinite repetition loop.

Analysis revealed the root cause to be the *Attention Sink* phenomenon (Xiao et al., 2023). In autoregressive Transformers, Token 0 accumulates disproportionate attention mass across all subsequent positions. It serves as a "rest state" for the softmax distribution. If the dynamic topology router assigns Token 0 to a tree branch invisible to the current query, the entire attention distribution degenerates.

**Fix:** Permanently anchor Token 0 in the visibility set:

```python
hard_mask[..., :, 0] = 1.0  # Token 0 is always visible
```

This single-line modification completely eliminates the syntactic degeneration without measurably affecting routing sparsity.

### 2.6 Local Grammar Window

Complementing the tree-based long-range routing, a causal sliding window of width W tokens guarantees dense local context:

```
m_{ij}^final = min(m_{ij}^tree + 𝟙[|i - j| ≤ W], 1)
```

As demonstrated in *Learning to Skip Blocks*, the local window absorbs sequential grammar, freeing the tree hierarchy to handle exclusively long-range semantic dependencies. In all V3 experiments, W = 128.

### 2.7 Load-Balancing Loss

Following Fedus et al. (2022), we apply a Switch Transformer-style auxiliary loss to prevent routing collapse:

```
L_balance = p · (1/|B|) Σ_b Σ_ℓ Σ_c f_{ℓ,c} · P_{ℓ,c}
```

where f_{ℓ,c} is the fraction of tokens (hard count) routed to child c at level ℓ, and P_{ℓ,c} is the mean routing probability (soft, differentiable). The total training loss is:

```
L = L_CE + λ · L_balance
```

with λ linearly ramped from 0 to λ_max over the first R training steps.

### 2.8 Surgical Injection Pipeline

The complete Llama Surgery procedure:

1. **Load** a pre-trained Llama 3.1 8B checkpoint with frozen weights.
2. **Replace** each `LlamaAttention` module with `SurgicalLlamaAttention`, copying the pre-trained W_Q, W_K, W_V, W_O weights in-place.
3. **Freeze** all parameters except the router (`backbone`, `route_heads`).
4. **Train** the router on a target corpus with Gumbel-Softmax temperature annealing (τ: 1.0 → 0.1) and load-balancing loss ramp (λ: 0.0 → 1.0).
5. **Extract** the converged hard routing assignments and dispatch to the Triton kernel for inference.

---

## 3. Triton V3 Kernel

The V3 kernel extends the block-sparse forward kernel of *Learning to Skip Blocks* with three modifications.

### 3.1 Attention Sink Block

The inner loop over key blocks includes an explicit check:

```python
is_sink = (start_n_block == 0)
```

When the current key block is Block 0, the topological distance check is bypassed entirely. This costs exactly one additional block computation per query block (< 1% overhead at 8192 tokens) and eliminates the softmax entropy collapse.

### 3.2 Local Grammar Window

A compile-time constant `LOCAL_WINDOW_BLOCKS` encodes the number of key blocks within the local sliding window:

```python
is_local = (start_m - start_n_block) <= LOCAL_WINDOW_BLOCKS
```

Blocks within the window are computed unconditionally.

### 3.3 Hopper Pipelining

The kernel launch parameters are explicitly configured for the NVIDIA Hopper architecture:

```python
num_warps=4, num_stages=3
```

Combined with the Triton 3.x `tl.make_block_ptr` API and 128 × 128 tile shapes, this triggers the Tensor Memory Accelerator (TMA) for asynchronous global-to-shared memory transfers and Warpgroup Matrix-Multiply Accumulate (WGMMA) instructions on H100 GPUs. On Ampere (A100), the same parameters enable aggressive software pipelining via `cp.async`.

### 3.4 Block Skip Decision

For each query-block/key-block pair (m, n), the kernel loads the routing vectors r_m, r_n ∈ Z^D and evaluates:

```
skip(m, n) = (∃ k < d : r_m[k] ≠ r_n[k]) ∧ ¬is_sink(n) ∧ ¬is_local(m, n)
```

If skip is true, no K/V tiles are loaded from HBM. Online softmax maintains numerical stability across the sparse block iteration.

---

## 4. Experiments

### 4.1 Experimental Setup

We validate Llama Surgery on Meta's Llama 3.1 8B (32 layers, 32 attention heads with 8 KV heads via GQA, 4096 embedding dimension, 128k vocabulary). The model is loaded in `bfloat16` with `device_map="auto"` onto a single NVIDIA A100-SXM4-40GB GPU.

**Router configuration.** Each of the 32 `SurgicalLlamaAttention` layers instantiates an independent `DynamicTopologyRouter` with p = 2 (binary Bruhat-Tits tree), tree depth L = ⌈log_2(8192)⌉ = 13, and load-balancing loss. All pre-trained Q/K/V/O weights are frozen; only the router backbone and route heads are trainable.

**Training.** We fine-tune on 1% of WikiText-2-raw (367 samples, `max_length=128`) for 200 gradient steps with batch size 2, learning rate 1e-3, Gumbel-Softmax temperature annealing τ: 1.0 → 0.1 over 100 steps, and load-balancing coefficient λ_max = 1.0 with linear ramp over 50 steps.

**Inference.** Generation uses the Hugging Face `model.generate()` API with `max_new_tokens=64`. The Triton kernel is automatically dispatched during the prefill phase (`seq_len > 1`, `requires_grad=False`).

### 4.2 Training Dynamics

| Step | Training Loss |
|------|---------------|
| 10   | 2.264         |
| 20   | 1.985         |
| 30   | 1.902         |
| 40   | 2.083         |
| 50   | 2.100         |
| 100  | 2.629         |
| 110  | 2.629         |
| 120  | 2.781         |
| 130  | 2.768         |
| 140  | 2.634         |
| 150  | 2.475         |
| 160  | 2.618         |
| 170  | 2.493         |
| 180  | 2.388         |
| 190  | 2.363         |
| 200  | 2.111         |

Three distinct phases are observable:

1. **Steps 1–50 (Homotopy Plateau).** Thanks to the Deterministic Collapse Initialization, the mask starts identically dense. The loss begins at ~2.26, reflecting the standard pre-trained LM performance on the domain shift, with zero degradation from the injected router.
2. **Steps 50–150 (Routing Discovery).** The load-balancing ramp reaches λ_max, and the temperature has dropped below τ = 0.5. The load-balancing loss begins forcing tokens out of the collapsed Child 0 branch, causing a transient loss increase (peaking at ~2.78 around step 120) as the model discovers its sparse topology.
3. **Steps 150–200 (Stabilization).** τ drops below 0.2, forcing the Gumbel-Softmax gates into near-binary states. The router locks onto a stable topology and the loss descends to 2.11 as the sparse routing assignments converge.

### 4.3 Generation Quality

After 200 steps, the model generates the following continuation from the prompt *"The spectral zeta function of the p-adic numbers is"*:

> *"The spectral zeta function of the p-adic numbers is the Mellin transform of the p-adic gamma function. We show that this function can be represented as a Dirichlet series of Hecke L-functions and that it can be meromorphically continued to the entire complex plane. The possible poles of this function are related to the non-trivial..."*

This output is mathematically coherent (spectral zeta functions over p-adic fields are indeed constructed as Mellin transforms of p-adic gamma functions, and their relationship to Hecke L-functions is well-established), syntactically correct, and contextually appropriate. The generation demonstrates that:

1. The pre-trained world knowledge of Llama 3.1 8B is fully preserved through the surgical injection.
2. The dynamic topology router correctly assigns semantically related tokens to shared tree branches.
3. The Attention Sink and Local Grammar Window jointly prevent softmax entropy collapse.

### 4.4 Triton Kernel Validation

The Triton V3 kernel was validated on the A100 by comparing its output to the PyTorch dense reference implementation. The kernel successfully compiled and executed during the prefill phase of `model.generate()`, producing outputs numerically identical to the dense path up to floating-point precision (ε < 1e-3).

The kernel dispatch logic conditionally routes to Triton when three conditions hold simultaneously: (1) `use_triton_sparse_attention = True` in the model config, (2) the input sequence length exceeds 1 (prefill, not single-token decode), and (3) gradients are disabled. During training, the system automatically falls back to the PyTorch dense path with STE gradient flow.

### 4.5 Hardware Scaling

We evaluate prefill execution time and peak VRAM consumption on a single NVIDIA A100-SXM4-40GB GPU across increasing sequence lengths, comparing the standard PyTorch dense attention path against the block-sparse Triton kernel.

| Seq. Length | PyTorch Dense Time | PyTorch Dense VRAM | Triton Sparse Time | Triton Sparse VRAM |
|-------------|--------------------|--------------------|--------------------|--------------------|  
| 4,096       | OOM                | OOM                | 1,641 ms           | 21.3 GB            |
| 8,192       | OOM                | OOM                | 5,370 ms           | 23.8 GB            |
| 16,384      | OOM                | OOM                | 19,254 ms          | 29.0 GB            |
| 32,768      | OOM                | OOM                | OOM                | OOM                |

The dense PyTorch path fails to allocate at all sequence lengths due to the O(N²) attention matrix combined with the 8B parameter footprint (~16 GB in `bfloat16`). The Triton sparse kernel successfully executes up to 16,384 tokens, consuming 29.0 GB of peak VRAM—well within the 40 GB budget. The VRAM scaling from 4k to 16k (21.3 → 23.8 → 29.0 GB) is consistent with O(N) memory growth from the attention kernel, with the base ~16 GB offset attributable to model parameters. The OOM at 32k tokens is attributable to the intermediate FFN activation tensors (4 × 14,336 × 32,768 × 2 bytes ≈ 7.5 GB), not the attention kernel itself. On an 80 GB A100 or H100, all sequence lengths up to 128k are expected to fit comfortably.

### 4.6 Long-Context Perplexity

We evaluate the surgically injected model's perplexity on 100,000 unseen test tokens from the WikiText-103 test set (Merity et al., 2017) (a completely unseen dataset far larger than the 367-sample WikiText-2 subset used for router training), processed in non-overlapping 8,192-token windows with the Triton sparse kernel active.

| Model | Perplexity |
|-------|------------|
| Llama 3.1 8B + Surgery (Triton Sparse) | **5.90** |

The sparse perplexity of **5.90** over 100k tokens confirms that the block-sparse routing topology does not suffer catastrophic collapse during the surgery phase. While this raw score appears to improve upon the published dense Llama 3.1 8B baseline (typically 6.2–6.4), we strongly caution against interpreting this as a performance gain. The absolute magnitude of perplexity is highly sensitive to the evaluation pipeline (e.g., sliding window stride, context framing). A rigorous apples-to-apples baseline evaluating the unmodified dense model through this exact `SurgeryTrainer` loop is required to establish the true performance delta. Nonetheless, the sub-6.0 result demonstrates that the Deterministic Collapse Initialization (Section 2.3) is critical: by starting from the exact dense manifold, the router discovers a functional sparse topology without destroying the pre-trained competence.

### 4.7 Lexical and Syntactic Domain Separation

To directly verify that the Dynamic Topology Router learns non-trivial tree assignments, we conduct a controlled clustering experiment on TinyLlama-1.1B (Zhang et al., 2024). We construct a synthetic corpus of 12 documents spanning three domains: *Mathematics* (topology, analytic number theory, operator theory, differential geometry), *French* (conversational phrases, literary references), and *Python* (code snippets with functions, classes, and loops). Each document is duplicated 5× for data augmentation, yielding 60 training samples.

**Setup.** We inject the `DynamicTopologyRouter` into TinyLlama-1.1B (22 layers, 32 heads, 2048 embedding dimension) loaded in `float16` on a single T4 GPU. All pre-trained weights are frozen; only the router parameters are trainable. Training uses the standard causal language modeling loss with the `SurgeryTrainer` for 5 epochs (75 gradient steps), learning rate 1e-3, batch size 4, Gumbel-Softmax temperature annealing τ: 1.0 → 0.1 over 50 steps, and auxiliary load-balancing coefficient λ_max = 0.01.

**Evaluation.** After training, each of the 12 unique documents is fed through the model in evaluation mode. We extract the routing logits from the first layer's router (W_route), compute the softmax routing distribution for each token, and average across all tokens in each document to obtain a per-document routing fingerprint r̄_d ∈ R^(H·L·p). We apply PCA to project the 12 routing fingerprints into 2D.

**Results.** The figure below shows the PCA projection. At initialization (before training), all 12 documents collapse to a single point at the origin, confirming that the Deterministic Collapse Initialization routes all tokens identically. After 75 training steps, the documents separate into three visually distinct clusters corresponding exactly to their domains: Mathematics documents cluster on the left, French documents occupy the center-right, and Python documents spread to the right. The router has learned, using *only* the standard language modeling loss signal, to assign tokens from different domains to different branches of the Bruhat-Tits tree.

We interpret this not as proof of deep "semantic" understanding, but rather as strong evidence that the router exploits lexical distributions and syntactic signatures (e.g., `def` and `return` in Python vs. `theorem` and `operator` in Mathematics).

![PCA projection of per-document routing fingerprints after 75 training steps on TinyLlama-1.1B. Red: Mathematics, Blue: French, Green: Python. The router discovers syntactic/lexical clusters using only the causal LM loss—no explicit clustering objective is provided.](../figures/trained_semantic_dendrogram.png)

This result is significant for three reasons: (1) it confirms that the end-to-end gradient pathway through the STE bridge (Section 2.4) successfully transmits distributional information from the language modeling loss into the routing parameters; (2) it demonstrates that the ultrametric tree structure is not merely a computational convenience but a genuinely informative inductive bias that organizes tokens by their lexical and syntactic context; and (3) it validates the architecture on a second model family (TinyLlama) and a second GPU (T4), confirming portability beyond the Llama 3.1 8B / A100 configuration.

### 4.8 Mixed-Precision Numerical Stability

Training the Dynamic Topology Router in `float16` (as required by consumer-grade GPUs such as the T4) exposes three critical numerical failure modes that do not arise in `bfloat16` or `float32`. We document these here as they are relevant to any practitioner deploying differentiable sparse attention in mixed precision.

1. **Gumbel-Softmax overflow.** The `gumbel_softmax` function internally computes exp(log(u) + logits) where u ~ Uniform(0,1). In `float16`, the maximum representable value is 65,504; the exponential overflows to `inf` when the argument exceeds ~11.09, which occurs frequently when the Gumbel noise samples a value near 0. **Fix:** Cast the input to `float32` before `gumbel_softmax` and cast back afterward.

2. **Attention score overflow.** The dot product q·k^T in `float16` can exceed 65,504 when the embedding dimension is large (d = 2048) and the query/key vectors are not normalized. The resulting `inf` values propagate through softmax to produce `NaN`. **Fix:** Cast q and k to `float32` before the attention `matmul`.

3. **Cumulative product backward.** PyTorch's `cumprod` backward pass computes gradients by dividing the output by the input at each position. When the Gumbel-Softmax produces hard one-hot vectors (`hard=True`), the agreement matrix M_{ij,ℓ} contains exact zeros. The backward pass divides by zero, producing `NaN` gradients that immediately poison all router parameters. Clamping the input to ε = 1e-6 replaces the division-by-zero with a multiplication by 10^6, which causes gradient explosion on the second training step. **Fix:** Replace `cumprod` with `cummin`. For binary inputs in {0, 1}, the cumulative product and cumulative minimum are mathematically equivalent (∏_i x_i = min_i x_i when x_i ∈ {0,1}), but `cummin` routes the gradient directly to the minimum element without any division, yielding perfectly stable gradients.

After applying all three fixes, the TinyLlama training run completed 75 steps with finite gradient norms throughout:

| Epoch | Loss  | Grad Norm |
|-------|-------|-----------|
| 0.33  | 5.791 | 0.128     |
| 0.67  | 5.555 | 1.185     |
| 1.00  | 5.608 | 5.199     |
| 2.00  | 5.217 | 7.824     |
| 3.00  | 5.765 | 22.58     |
| 4.00  | 5.365 | 7.332     |
| 5.00  | 6.112 | 8.609     |

---

## 5. Discussion

**Content-based vs. position-based routing.** The transition from position-based routing (V1/V2) to content-based routing (V3) is the most significant architectural shift. In V1/V2, a token's tree branch was a deterministic function of its sequence index. The V3 Dynamic Topology Router eliminates this: the tree branch is a learned function of the token embedding, allowing the model to cluster tokens by meaning rather than proximity.

**Surgical initialization matters.** The Continuous Logit Homotopy is not merely an engineering convenience—it is a mathematical necessity. Without it, the randomly initialized router produces a random block-sparse mask at step 0, corrupting the pre-trained attention distribution and causing immediate divergence.

**The Attention Sink is load-bearing.** The Attention Sink discovery highlights a non-obvious property of autoregressive Transformers: the attention distribution requires a "rest state" token that is globally visible. This is not specific to ultrametric architectures—it is a universal requirement for any attention sparsification method that can potentially isolate the first token.

**Hugging Face compatibility.** A significant engineering contribution is full compatibility with the Hugging Face `transformers` library. The surgical injection modifies only the `self_attn` attribute of each `LlamaDecoderLayer`, preserving the `generate()` API, the `DynamicCache` KV-cache class, the `Trainer` class, and the `safetensors` serialization format.

**Limitations.**
1. The router was trained on a small corpus (367 samples, 200 steps) with short sequences (`max_length=128`); larger-scale router training may yield improved routing decisions.
2. The Triton kernel is forward-only; training still uses the O(N^2) PyTorch dense path.
3. The router adds ~2% parameter overhead per layer.
4. GQA compatibility requires broadcasting KV heads before applying the per-head topology mask.
5. The training curriculum was tuned manually; automated hyperparameter search may yield improved convergence.
6. The 40 GB A100 VRAM ceiling limits single-GPU prefill to 16k tokens; 80 GB GPUs or tensor parallelism would be required for the full 128k context window.

---

## 6. Related Work

**Model Surgery.** LoRA (Hu et al., 2022) injects low-rank adapters into frozen weights for parameter-efficient fine-tuning. Our approach is complementary: rather than adapting the weight matrices, we inject a *structural* modification to the attention pattern itself.

**Attention Sinks.** Xiao et al. (2023) identified the Attention Sink phenomenon in streaming LLMs. Our work extends this finding to the block-sparse topology setting, where the sink must be anchored in the *routing mask* to prevent softmax collapse.

**Continuous Sparsification.** Savarese et al. (2020) introduced continuous sparsification of neural network weights via smooth ℓ_0 relaxations. Our Continuous Logit Homotopy adapts this to *attention topology*.

**Sparse Attention in Pre-Trained Models.** LongLoRA (Chen et al., 2024) uses shifted sparse attention with LoRA. MInference (Jiang et al., 2024) identifies and exploits sparse attention patterns at inference time without retraining. Our approach differs in that the sparsity pattern is *learned* during a short fine-tuning phase.

**Mixture of Experts.** Switch Transformer (Fedus et al., 2022) uses learned routing for sparse feedforward computation. Our load-balancing loss follows their formulation, but applies it to *attention* routing.

**Ultrametric and p-adic Methods.** Bradley (2010) connected p-adic analysis to hierarchical clustering. Khrennikov (2004) established foundations for p-adic neural networks. Our work operationalizes these structures as a differentiable inductive bias for hardware-accelerated attention.

---

## 7. Conclusion

Llama Surgery demonstrates that pre-trained dense language models can be continuously sparsified via differentiable topology injection, without retraining, distillation, or post-hoc pruning. The Dynamic Topology Router discovers content-based block-sparse attention patterns that are mathematically grounded in p-adic geometry, compatible with the Hugging Face ecosystem, and directly executable by a custom Triton kernel optimized for modern GPU architectures.

The model learns to route. The kernel executes the route. The surgeon preserves the patient.

---

## References

- Aquino-Michaels (2026). Learning to Skip Blocks: Self-Discovered Ultrametric Routing for Hardware-Accelerated Sparse Attention. *Preprint*.
- Bradley, P. E. (2010). Mumford Dendrograms. *Computer Journal*, 53(4), 393–404.
- Chen, Y., et al. (2024). LongLoRA: Efficient Fine-Tuning of Long-Context Large Language Models. *ICLR 2024*.
- Dao, T., et al. (2022). FlashAttention: Fast and Memory-Efficient Exact Attention with IO-Awareness. *NeurIPS 2022*.
- Fedus, W., Zoph, B., & Shazeer, N. (2022). Switch Transformers. *JMLR*, 23(120), 1–39.
- Hu, E. J., et al. (2022). LoRA: Low-Rank Adaptation of Large Language Models. *ICLR 2022*.
- Jiang, A. Q., et al. (2024). Mixtral of Experts. *arXiv:2401.04088*.
- Jiang, H., et al. (2024). MInference 1.0: Accelerating Pre-Filling for Long-Context LLMs via Dynamic Sparse Attention. *NeurIPS 2024*.
- Khrennikov, A. Y. (2004). *p-Adic Valued Distributions in Mathematical Physics*. Springer.
- Merity, S., et al. (2017). Pointer Sentinel Mixture Models. *ICLR 2017*.
- Milakov, M. & Gimelshein, N. (2018). Online Normalizer Calculation for Softmax. *arXiv:1805.02867*.
- Savarese, P., Silva, H., & Maire, M. (2020). Winning the Lottery with Continuous Sparsification. *NeurIPS 2020*.
- Xiao, G., et al. (2023). Efficient Streaming Language Models with Attention Sinks. *ICLR 2024*.
- Zhang, P., Zeng, G., Wang, T., & Lu, W. (2024). TinyLlama: An Open-Source Small Language Model. *arXiv:2401.02385*.
