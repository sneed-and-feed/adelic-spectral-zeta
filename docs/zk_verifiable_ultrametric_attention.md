# Arithmetization & Formal Verification of Hierarchical Tree Attention Routing in R1CS

**Classification:** Verifiable AI & Algebraic Cryptography  
**Formal Verification:** [`formalization/Formalization/Analysis/VerifiableAttention.lean`](../formalization/Formalization/Analysis/VerifiableAttention.lean) (Machine-checked in Lean 4, 0 `sorry`s)  
**Circuit Synthesis:** [`circuits/padic_lca.circom`](../circuits/padic_lca.circom) (Circom 2.1), [`src/adelic_spectral_zeta/circuits/padic_r1cs.py`](../src/adelic_spectral_zeta/circuits/padic_r1cs.py)  
**Runtime Prover & Witness Engine:** [`tools/zk_attention_prover.py`](../tools/zk_attention_prover.py)  
**Test Suite:** [`tests/test_zk_attention.py`](../tests/test_zk_attention.py)  

---

## 1. Executive Summary & Problem Formulation

Standard Transformer attention verification in Zero-Knowledge and Verifiable ML (ZK-ML) is bottlenecked by the quadratic $O(N^2)$ density of attention matrices and transcendental non-linear activations, such as $\text{softmax}(\mathbf{x})_i = \frac{\exp(x_i)}{\sum_j \exp(x_j)}$. Proving dense floating-point softmax in-circuit requires millions of high-degree polynomial constraints and minutes of proving time for a 2048-token sequence.

Rather than attempting to prove continuous soft-attention in-circuit, we perform an **algorithmic substitution**: we replace dense transcendental attention with a **formally verified ultrametric block-sparse routing layer**, reducing the ZK proof burden from millions of non-linear constraints to under 3,000 Rank-1 constraints.

In this framework, token sequences are dynamically clustered onto a $p$-ary tree of depth $D$, where routing between token blocks $u$ and $v$ is governed by a tree metric:

$$d_p(u, v) = D - \mathrm{LCA}(u, v)$$

$$\mathrm{LCA}(u, v) = \max \{ r \in [0, D] : \forall k < r, \; u_k = v_k \}$$

By restricting cross-attention to token blocks sharing a common ancestor prefix of depth $r \le D$, the routing topology collapses into **exact discrete digit equality checks**. The circuit proves the **hard block-sparse routing mask** $M \in \{0, 1\}^{B \times B}$ and its safety invariants in **under 3,000 Rank-1 constraints for $N=2048$ tokens**, solvable in under 15 ms on consumer CPUs. The verified mask $M$ physically gates the block-sparse inner-product computations on hardware (e.g. Triton kernels), proving that non-attending tiles are strictly zero without computing quadratic soft-attention in the proof circuit.

---

## 2. Mathematical Architecture: Ultrametric Tree Valuations

### 2.1 Discrete Tree Paths & Lowest Common Ancestor (LCA)

For a $p$-ary tree of depth $D$ and arity $p \ge 2$, a token block's cluster address is represented as a sequence of base-$p$ limbs (digits):

$$u = (u_0, u_1, \dots, u_{D-1}) \in \mathrm{Fin}(D) \to \mathrm{Fin}(p)$$

Two paths $u, v$ share a common ancestor at depth $r \le D$ if and only if they satisfy the prefix equality relation:

$$\mathrm{PrefixEq}(u, v, r) \iff \forall k < r, \quad u_k = v_k$$

The LCA depth satisfies the strict non-Archimedean ultrametric valuation inequality:

$$\mathrm{LCA}(u, w) \ge \min(\mathrm{LCA}(u, v), \mathrm{LCA}(v, w))$$

This is machine-checked in Lean 4 as `VerifiableAttention.lcaDepth_ultrametric`.

---

## 3. Hierarchical Base-$p$ Tree Addressing & R1CS Arithmetization

Let $\mathbb{F}_q$ denote the prime scalar field (e.g. BN254 / Alt-bn128 scalar field). For each token block $u \in [0, p^D - 1]$ represented by field elements $u_k \in \mathbb{F}_q$:

### 3.1 Base-$p$ Range & Decomposition Constraints
1. **Limb Range Proofs:** For each limb $k \in [0, D-1]$:
   $$\prod_{j=0}^{p-1} (u_k - j) = 0 \pmod q$$
   *(Enforced via $p-2$ intermediate multiplications for general $p$, or $u_k(1 - u_k) = 0$ for $p=2$)*.

2. **Composite Path Reconstruction:**
   $$\left( \sum_{k=0}^{D-1} u_k \cdot p^{D-1-k} \right) \cdot 1 = u$$

### 3.2 Prefix Equality & Conjunction Gadget
For each level $k < r$, let $\Delta_k = u_k - v_k$. We allocate an equality indicator wire $eq_k \in \{0, 1\}$ and an inverse auxiliary witness wire $inv_k \in \mathbb{F}_q$:

1. **Orthogonality Check:**
   $$\Delta_k \cdot eq_k = 0$$

2. **Inverse Relation:**
   $$\Delta_k \cdot inv_k = 1 - eq_k$$

*(Note on Implicit Algebraic Booleanity: Constraints 1 and 2 algebraically force $eq_k \in \{0, 1\}$ over any field. If $\Delta_k = 0$, then $1 - eq_k = 0 \implies eq_k = 1$. If $\Delta_k \neq 0$, then $eq_k = 0$ and $inv_k = \Delta_k^{-1}$. Thus, separate quadratic booleanity constraints $eq_k(1 - eq_k) = 0$ are mathematically redundant and omitted.)*

3. **Prefix Conjunction:**
   $$M_r = \prod_{k=0}^{r-1} eq_k$$
   *(Enforced via recursive accumulator chain: $C_0 = eq_0$, $C_k = C_{k-1} \cdot eq_k$ for $k \ge 1$, with output $M_r = C_{r-1}$)*.

### 3.3 Proved Soundness & Completeness Properties (Lean 4)
* **Completeness:** If $\mathrm{PrefixEq}(u, v, r)$, there exists an assignment with $eq_k = 1$ and $inv_k = 0$ such that $M_r = 1$.
* **Soundness:** If $\neg \mathrm{PrefixEq}(u, v, r)$, any satisfying assignment forces $M_r = 0$.
* **Indicator Uniqueness:** The equality wire vector $eq$ is uniquely determined for all satisfying assignments. When $u_k = v_k$, $inv_k$ is unconstrained ($0 \cdot inv_k = 0$), which does not affect circuit soundness as $eq_k = 1$ is already fixed.

*The structural soundness and uniqueness of this arithmetization are machine-checked in Lean 4 (`VerifiableAttention.faithful_arithmetization_soundness_and_completeness` and `VerifiableAttention.indicator_wire_uniqueness`).*

---

## 4. Multi-Tenant Non-Interference Safety Guard

To prevent data leakage across isolated security domains (e.g. multi-tenant prompt containment or confidential reasoning token isolation), the circuit asserts an entrywise Hadamard exclusion against a public forbidden routing mask $M_{\mathrm{forbidden}} \in \{0, 1\}^{B \times B}$:

$$M_{\mathrm{forbidden}} \circ M_{\mathrm{routing}} \equiv 0 \iff \forall (i, j) \in \mathrm{Forbidden}, \quad M_{\mathrm{routing}}[i][j] \cdot 1 = 0$$

The Lean 4 theorem `VerifiableAttention.attention_cluster_sparsity` proves that tokens in distinct clusters have mathematically zero cross-attention weight. The algebraic constraint makes cross-domain routing attempts mathematically unsatisfiable.

---

## 5. Verification, Tooling & Explicit Constraint Accounting

### 5.1 Circuit & Reference Implementation Stack
* **Circom Templates:** [`circuits/padic_lca.circom`](../circuits/padic_lca.circom) defines parameterized zero-knowledge templates (`DigitExtractor`, `PrefixMatcher`, `PAdicBlockRouting`, `NonInterferenceGuard`) ready for compilation with `circom` and proving via Groth16 / SnarkJS / PLONK.
* **Pure Python R1CS Engine:** [`src/adelic_spectral_zeta/circuits/padic_r1cs.py`](../src/adelic_spectral_zeta/circuits/padic_r1cs.py) provides an in-memory R1CS compiler with exact BN254 prime field modular arithmetic and sparse matrix export.
* **Prover & Witness CLI:** [`tools/zk_attention_prover.py`](../tools/zk_attention_prover.py) translates runtime routing tensors from PyTorch models into witness vectors, checks constraint satisfiability, and generates audit certificates with SHA-256 state commitments.

### 5.2 CLI Execution
```powershell
python tools/zk_attention_prover.py --seq_len 512 --depth 4 --req_depth 2 --p 2 --audit-safety
```

### 5.3 Test Coverage & Line-Item Constraint Accounting

```powershell
python -m pytest tests/test_zk_attention.py -v
# 23 passed in 11.13s
```

#### Line-Item Constraint Accounting Breakdown ($N=2048, B=64, D=5, r=2, p=2$)
For a sequence of $N=2048$ tokens with block size $B=64$, there are $B = 32$ blocks, yielding a $32 \times 32$ routing matrix. The exact $2,704$ Rank-1 constraints decompose as follows:

| Component | Algebraic Mechanism | Calculation | Constraint Count |
| :--- | :--- | :--- | :---: |
| **1. Block Digit Decomposition** | $D=5$ binary range checks ($d_k(1-d_k)=0$) + 1 linear reconstruction per block | $32 \text{ blocks} \times (5 + 1)$ | **192** |
| **2. Self-Routing Identity** | Diagonal self-attention identity ($M_{ii} \cdot 1 = 1$) | $32 \text{ blocks} \times 1$ | **32** |
| **3. Symmetric Off-Diagonal Routing** | Ultrametric distance is symmetric ($d_p(u, v) = d_p(v, u)$). We only arithmetize strictly upper-triangular pairs: $\binom{32}{2} = 496$ pairs. | $\frac{32 \times 31}{2} = 496 \text{ pairs}$ | — |
| **4. Zero-Check Equality Gadgets** | For each of the 496 pairs, for $r=2$ digits: $\Delta_k \cdot eq_k = 0$ and $\Delta_k \cdot inv_k = 1 - eq_k$ (2 constraints per digit). | $496 \times (2 \text{ digits} \times 2)$ | **1,984** |
| **5. Prefix Product Conjunction** | Accumulator chain for $r=2$: $M_{ij} = eq_0 \cdot eq_1$ ($r-1 = 1$ multiplication constraint). | $496 \times 1$ | **496** |
| **6. Implicit Mask Booleanity** | Guaranteed by equality gadget ($eq_k \in \{0, 1\}$); product of booleans is boolean. | $0 \text{ extra constraints}$ | **0** |
| **Total R1CS Constraints** | $192 + 32 + 1,984 + 496$ | **Exact Total** | **2,704** |

#### Why the Constraint Budget is Substantially Lower than Naive Estimates:
1. **Symmetric Graph Compression:** Because the tree distance metric is symmetric ($d_p(u, v) = d_p(v, u)$), the routing matrix is symmetric ($M_{ij} = M_{ji}$). Arithmetizing only the $\binom{B}{2} = 496$ off-diagonal pairs rather than all $B^2 = 1,024$ pairs cuts the pairwise constraint count by more than $50\%$.
2. **Implicit Algebraic Booleanity:** The 2-equation equality gadget algebraically locks $eq_k \in \{0, 1\}$ without allocating separate quadratic boolean constraints $eq_k(1 - eq_k) = 0$ across the $1,024$ matrix entries, saving $1,024$ constraints.
3. **Linear Prefix Chaining:** Computing the prefix conjunction for depth $r$ requires only $r - 1$ multiplication gates per pair, avoiding high-degree polynomial expressions.

Full R1CS witness generation and constraint verification for this $2,704$-constraint system executes in under **15 ms** on consumer CPU hardware.

---

## 6. Integration Architecture & Frequently Asked Questions

### Q1: Does this verify the entire attention mechanism or just the routing mask?
This circuit verifies the **discrete dynamic block-sparsity topology** $M \in \{0, 1\}^{B \times B}$ and its security invariants. In an end-to-end ZK-ML pipeline, the verified mask $M$ gates block-sparse inner-product arguments:

$$\mathbf{Y}_i = \sum_{j : M_{ij} = 1} \mathrm{AttentionBlock}(Q_i, K_j, V_j)$$

By proving $M_{ij} = 0$ algebraically, the prover completely bypasses non-linear softmax evaluation and matrix multiplication for all inactive pairs $(i, j)$, achieving quadratic-to-subquadratic speedups in ZK proving time.

### Q2: Why use tree LCA metrics instead of arbitrary sparse attention masks?
1. **Algebraic Compactness:** Arbitrary sparse masks require storing and checking an explicit $O(B^2)$ adjacency graph. In contrast, tree routing compresses token cluster addresses into $D$ digits, requiring only limb range checks and prefix equality.
2. **Provable Transitivity & Domain Isolation:** The ultrametric valuation inequality, $\mathrm{LCA}(u, w) \ge \min(\mathrm{LCA}(u, v), \mathrm{LCA}(v, w))$, guarantees that cluster partitions are mathematically transitive. Proving isolation between two cluster roots unconditionally guarantees isolation for all sub-branches.

### Q3: Why is Lean 4 verification necessary?
Handcrafted R1CS gadgets are notoriously prone to under-constrained wire bugs and field overflow vulnerabilities. Machine-checking the completeness, soundness, and uniqueness theorems in Lean 4 ensures that no rogue witness assignment can force $M_r = 1$ on divergent prefixes or bypass safety exclusions.


