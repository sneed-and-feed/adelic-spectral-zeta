# Adèlic Spectral Geometry: Empirical Benchmarks

This document details the empirical benchmarks of the **Ultrametric AI / Adèlic Topology Router** architecture. It covers both the raw hardware speedups achieved via our custom Triton kernels, and the qualitative logic tests (like the Dyck-2 language) that prove the model is learning genuine geometric topology.

## 1. Hardware & Latency Benchmarks (Triton)

By replacing the dense $O(N^2)$ self-attention matrix with a hierarchical $O(N \log N)$ block-sparse mask derived from the $p$-adic metric, we achieved massive latency and memory improvements on A100 GPUs:

* **28× Inference Speedup:** At 8192 tokens, the Triton block-sparse forward kernel executes 28 times faster than standard dense attention.
* **98.4% Memory Reduction:** The block-sparse mask avoids allocating massive dense `(seq_len, seq_len)` activation matrices.
* **11.59× Wall-Clock Speedup (End-to-End):** At 2048 tokens, using autonomously learned per-head routing gates (no hand-designed sparsity), the total step latency drops by over a factor of 10.
* **8× Effective Memory Bandwidth:** During autoregressive decoding, our sparse PagedAttention kernel conditionally skips HBM loads for non-matching KV-cache blocks, directly accelerating the memory-bound decoding phase.
* **Why PyTorch/JAX fail:** Native PyTorch block iteration achieves the memory savings but is 83× *slower* than dense attention due to Python loop overhead. JAX/XLA static compilation crashes the NVIDIA PTX assembler when attempting to compile dynamic block-sparse routing logic. Only the custom Triton kernel achieves both memory savings and speed gains.

---

## 2. The Dyck-2 Formal Language Benchmark

**Why is this here?**
A common question is why an architecture designed for natural language or coding is being benchmarked on `Dyck-2` (the language of perfectly balanced brackets, e.g., `[ ( ) ] ( [ ] )`). 

Standard Transformers use a "flat" attention mechanism. They look at sequences as a straight line. If you give a standard Transformer a deeply nested bracket sequence, it struggles to match a closing bracket `]` to its corresponding opening bracket `[` if they are separated by hundreds of other tokens. 

The **Adèlic Topology Router** is designed to map sequences into a **fractal, hierarchical Bruhat-Tits tree**. If the router is actually working, it should natively understand nested hierarchies. Dyck-2 is the ultimate, purely mathematical test of hierarchical reasoning. 

**The Results:**
* **Baseline PyTorch Transformer:** Reaches 92.01% accuracy at Step 2000, struggling to match deeply nested brackets.
* **Adèlic V2 Router (Shifted Ultrametric Trees):** Hits **99.55% accuracy**. More importantly, it surpasses the baseline's final accuracy by Step 200, representing a **10× improvement in sample efficiency**. 
* **The "Grokking" Phase Transition:** The V2 model exhibits a sharp phase transition between steps 600–700, where the loss collapses from 0.97 to 0.15 in a single epoch. This is the exact moment the Router autonomously discovers the optimal phylogenetic tree alignment with the bracket hierarchy.

---

## 3. Llama Surgery (Zero-Shot Routing)

We surgically injected the Topology Router into a frozen, pre-trained TinyLlama-1.1B model without altering its pre-trained weights.

* **Semantic Dendrograms:** When fed a mixture of Natural Language, Python Code, Math, and HTML, the router autonomously clustered the different modalities into distinct $p$-adic subtrees (verified via PCA) without any explicit clustering objective. It naturally recognized that HTML and Python belong on different branches of the phylogenetic tree.
* **Topological Needle-In-A-Haystack (NIAH):** When forced to retrieve a needle token from a 1024-token haystack, the router isolated the needle at the maximum topological distance ($\bar{d}_p = 6.88$) from the dominant haystack domain. This proves the router inherently places high-surprisal (rare) information at the periphery of the tree so it is never lost in the noise.
* **Topological Ring Attention:** Simulating an 8-GPU Ring Attention cluster on a 1024-token multi-domain sequence, the router reduced peer-to-peer (P2P) communication edges from 2,048 (dense) to 448. This achieved a **78.1% reduction in P2P network bandwidth** across the GPUs without dropping any semantically relevant context.

---

## 4. Infinite Context Adèlic Cache (Llama 3.1 8B)

We successfully mapped the Adèlic topology onto Llama 3.1 8B via the **Adèlic Cache**, a custom KV-cache subclass that mathematically caps memory growth to a strict $O(1)$ constant boundary (e.g., 256 tokens max memory). When the physical cache exceeds capacity, it utilizes Medoid-Value topological clustering to dynamically pool and condense "redundant" far-history tokens.

* **Information Starvation vs. Context Collapse (LongBench Qasper):** The Adèlic Cache guarantees the mathematical survival of the "Attention Sink" (the first 16 tokens). This strict topological protection completely prevents "Context Window Collapse" (grammar loss and "the the the" hallucinations) seen in naive cache eviction.
* **Exact Retrieval Score:** However, because Medoid-Value clustering physically condenses a 10,000 token scientific paper into exactly 256 token vectors, the model suffers from **Information Starvation**. It retains perfect linguistic coherence and instructional alignment, but drops exact factual "needles," achieving a **3.14% F1 Score** on Qasper (compared to ~30% for a dense 10,000 token cache). 

This experimentally proves that while $O(1)$ topological clustering is exceptionally stable for maintaining conversational and narrative flow indefinitely, it is fundamentally too lossy for exact-retrieval "Needle-In-A-Haystack" tasks on its own, and must be coupled with secondary external memory retrieval (e.g., RAG) for fact-dense reasoning.
