# Mathlib Upstream Modular Architecture

This document specifies the two-tier Lean 4 architecture designed to cleanly separate generic, universally reusable mathematical components from domain-specific adelic spectral and dynamical formalizations.

---

## 1. Architectural Overview

The formalization codebase is partitioned into two distinct library targets configured in `formalization/lakefile.lean`:

```
                                  Mathlib 4 (v4.8.0)
                                         ▲
                                         │  (imports)
                        ┌────────────────┴────────────────┐
                        │                                 │
         MathlibUpstream Library               Formalization Library
     (Generic, Universal Components)    (Adelic Spectral Triples & Collatz)
     • Cyclic Shift Matrix Charpolys    • Adelic Topology & 2-adic Dynamics
     • Unitary Discrete Fourier TF      • Schreier Graph Spectral Towers
     • Cyclic Block Factorizations      • Aronszajn-Krein Deficiency Spaces
     • Base-2 Logarithmic Bounds        • Dynamical & Ihara Zeta Factorization
     • Perron-Frobenius Positivity      • Quantum Scars & Entanglement
     • Tree Prefix Sparsity             • Non-archimedean Trace Formulas
                        │                                 ▲
                        └─────────────────────────────────┘
                                     (imports)
```

Both libraries build simultaneously under `lake build` with **0 errors and 0 `sorry`s**.

---

## 2. Upstream Component Specifications (`MathlibUpstream/`)

Every component in `MathlibUpstream` is formatted strictly according to Mathlib 4 guidelines, utilizing general mathematical structures (e.g., arbitrary commutative rings $R$, arbitrary dimensions $L$, general metric spaces) rather than project-specific constants.

### 2.1. Cyclic Shift Matrix Characteristic Polynomials
- **Module**: `MathlibUpstream.LinearAlgebra.Matrix.CyclicShift`
- **Target Upstream**: `Mathlib.LinearAlgebra.Matrix.Charpoly.Cyclic`
- **Scope**: Characteristic polynomials of weighted shift and circulant-type matrices over an arbitrary commutative ring $R$.
- **Key Definitions**:
  - `shiftMatrix n W`: Nilpotent $n \times n$ subdiagonal shift matrix with arbitrary edge weights $W : \text{Fin } n \to R$.
  - `upperBidiagonal n W`: Upper-bidiagonal polynomial matrix computing off-diagonal cofactor minors.
  - `cyclicWeightMatrix W`: $L \times L$ cyclic shift matrix on $\mathbb{Z}/L\mathbb{Z}$ with entry $(i, j) = W(j)$ if $i = j + 1 \pmod L$.
- **Key Theorems**:
  - `charpoly_shiftMatrix`: $\operatorname{charpoly}(\text{shiftMatrix } n\ W) = X^n$.
  - `det_upperBidiagonal`: $\det(\text{upperBidiagonal } n\ W) = \prod_{i=0}^{n-1} (-C(W_i))$.
  - `charpoly_cyclicWeightMatrix`: For any $L \ge 1$ and weights $W : \mathbb{Z}/L\mathbb{Z} \to R$,
    $$\operatorname{charpoly}(\text{cyclicWeightMatrix } W) = X^L - C\left(\prod_{k=0}^{L-1} W_k\right)$$

### 2.2. Unitary Discrete Fourier Transform on Finite Cyclic Groups
- **Module**: `MathlibUpstream.Analysis.DFT`
- **Target Upstream**: `Mathlib.Analysis.Fourier.FourierTransform` / `Mathlib.NumberTheory.LegendreSymbol.AddCharacter`
- **Scope**: Exact normalization, character orthogonality, and unitary inversions of the Discrete Fourier Transform over $\mathbb{Z}/N\mathbb{Z}$ with values in $\mathbb{C}$.
- **Key Definitions**:
  - `zmodChar_C N zeta hzeta`: Additive character $\chi : \mathbb{Z}/N\mathbb{Z} \to \mathbb{C}^\times$ induced by a primitive $N$-th root of unity $\zeta$.
  - `dftMatrix zeta hzeta`: Normalized $N \times N$ matrix with entries $F_{j, k} = \frac{1}{\sqrt{N}} \chi(j \cdot k)$.
  - `dftMatrix_star zeta hzeta`: Conjugate-transpose adjoint $F^\dagger$.
- **Key Theorems**:
  - `dft_mul_star`: $F \cdot F^\dagger = I_{N \times N}$.
  - `dft_star_mul`: $F^\dagger \cdot F = I_{N \times N}$.

### 2.3. Universal Cyclic Block Polynomial Factorizations
- **Module**: `MathlibUpstream.Algebra.Polynomial.CyclicBlockFactorization`
- **Target Upstream**: `Mathlib.Algebra.Polynomial.BigOperators`
- **Scope**: General algebraic identities for products of cyclic characteristic polynomial factors.
- **Key Theorems**:
  - `cyclic_block_polynomial_prod`: For any commutative ring $R$, cycle length $L$, and weights $W_1, W_2 \in R$:
    $$(1 - C(W_1) X^L)(1 - C(W_2) X^L) = 1 - C(W_1 + W_2) X^L + C(W_1 W_2) X^{2L}$$
  - `cyclic_block_fredholm_product`: When $W_1 + W_2 = 0$ and $W_1 W_2 = c$, the cross terms cancel:
    $$(1 - C(W_1) X^L)(1 - C(W_2) X^L) = 1 + C(c) X^{2L}$$
  - `cyclic_block_fredholm_two`: Specialization to $c = 2$, yielding $(1 - C(W_1) X^L)(1 - C(W_2) X^L) = 1 + 2 X^{2L}$.

### 2.4. Real Logarithmic Bounds and Base-2 Real Analysis
- **Module**: `MathlibUpstream.Analysis.SpecialFunctions.LogBounds`
- **Target Upstream**: `Mathlib.Analysis.SpecialFunctions.Log.Basic`
- **Scope**: Base-2 logarithm $\log_2(x) = \ln(x) / \ln(2)$ and real algebraic bounds involving $\sqrt{2}$ and powers.
- **Key Theorems**:
  - `log2_two`: $\log_2(2) = 1$.
  - `log2_mul`, `log2_div`: Homomorphism properties $\log_2(xy) = \log_2 x + \log_2 y$, $\log_2(x/y) = \log_2 x - \log_2 y$.
  - `log2_sqrt_two`: $\log_2(\sqrt{2}) = 1/2$.
  - `log2_two_sqrt_two`: $\log_2(2\sqrt{2}) = 3/2$.
  - `sqrt_two_lt_two`, `two_sqrt_two_lt_four`: Ordering and non-negativity lemmas.

### 2.5. Spectral Positivity and Perron-Frobenius Theory
- **Module**: `MathlibUpstream.LinearAlgebra.Matrix.Positivity`
- **Target Upstream**: `Mathlib.LinearAlgebra.Matrix.Spectrum` / `Mathlib.LinearAlgebra.Matrix.PosDef`
- **Scope**: Graph connectivity, walks, eigenvector uniqueness, and spectral radius bounds for real symmetric non-negative matrices.
- **Key Theorems**:
  - `pow_pos_of_walk`: A walk in the support graph ensures strict positivity of matrix power entries: $0 < (A^{\text{length}(w)})_{i, j}$.
  - `eigenvector_unique_of_connected`: 1-dimensionality of the positive eigenspace for connected support graphs.
  - `eigenvalue_le_of_symm_of_nonneg`: The Perron-Frobenius positive eigenvalue dominates all other real eigenvalues ($|\lambda| \le \mu$).
  - `eigenvalue_le_maxEig_add_one`: Variational bound on identity-shifted operators via Hermitian spectral decomposition.

### 2.6. Combinatorial Prefix-Sharing and Tree Path Sparsity
- **Module**: `MathlibUpstream.Combinatorics.PrefixSparsity`
- **Target Upstream**: `Mathlib.Combinatorics.SimpleGraph.Tree` / `Mathlib.Data.Fintype.BigOperators`
- **Scope**: Exact counting of paths in complete $p$-ary trees sharing an ancestor at depth $r$, with exact rational sparsity ratios.
- **Key Theorems**:
  - `card_shared_prefix`: Exact cardinality $p^r \cdot p^{d-r} \cdot p^{d-r} = p^{2d-r}$.
  - `fraction_eq_p_inv_r`: Exact shared fraction $\frac{p^{2d-r}}{p^{2d}} = \frac{1}{p^r}$.
  - `sparsity_bound`: For any $p > 0$ and $r \le d$, $\text{sparsity}(d, p, r) = 1 - \frac{1}{p^r}$.
  - Specializations: $\text{sparsity}(d, 2, 1) = 1/2$ (50%), $\text{sparsity}(d, 2, 3) = 7/8$ (87.5%), $\text{sparsity}(d, 2, 6) = 63/64$ (98.4375%).

---

## 3. Project-Specific Tier (`Formalization/`)

The `Formalization` library builds upon `MathlibUpstream` and Mathlib 4 to formalize the adelic spectral triple, deficiency spaces, and 2-adic dynamics:

| Module Group | Formalization Files | Core Content |
|---|---|---|
| **Adelic & Topological Framework** | `AdelicTopology.lean`, `AdelicTopologicalQEC.lean`, `ProfiniteTower.lean` | Restricted direct product adele ring $\mathbb{A}_{\mathbb{Q}}$, topological quantum error correction, projective limit topologies. |
| **Schreier Spectral & Graph Theory** | `SchreierSpectral.lean`, `SchreierConnectivity.lean`, `SchreierSpectralGap.lean` | Perron-Frobenius spectral analysis of 2-adic quotient graphs, gap bounds $\Delta \ge 2 - \sqrt{2}$. |
| **Dynamical & Arithmetic Zeta Functions** | `IharaZeta.lean`, `IharaBass.lean`, `DynamicalZetaFactorization.lean`, `RationalZeta.lean` | Ihara-Bass determinant formulas, transfer operator Fredholm determinants, rational dynamical zeta identities. |
| **Aronszajn-Krein Deficiency Indexing** | `SpectralGRH.lean`, `InductiveTower.lean`, `DetailSpaceDecomposition.lean` | Symmetric boundary extensions, deficiency spaces $\mathcal{K}_\pm$, wave operator trace matching. |
| **Quantum Scars & Many-Body Phases** | `QuantumScars.lean`, `ManyBodyPhaseTransition.lean`, `BruhatTitsEntanglement.lean` | Non-thermal eigenstates, entanglement entropy scaling, Satake spherical representations. |

---

## 4. Build Configuration & Compilation

The project package is configured via `formalization/lakefile.lean`:

```lean
import Lake
open Lake DSL

package «formalization» where

require mathlib from git "https://github.com/leanprover-community/mathlib4" @ "v4.8.0"

@[default_target]
lean_lib «MathlibUpstream» where

@[default_target]
lean_lib «Formalization» where
```

### Build Commands
- **Full Project Build**:
  ```bash
  lake build
  ```
- **MathlibUpstream Only**:
  ```bash
  lake build MathlibUpstream
  ```
- **Formalization Only**:
  ```bash
  lake build Formalization
  ```

---

## 5. Mathlib Upstreaming Plan

| Upstream Module | Target Mathlib Directory | Prerequisites / Dependencies | Status |
|---|---|---|---|
| `CyclicShift.lean` | `Mathlib.LinearAlgebra.Matrix.Charpoly` | `Mathlib.Data.Matrix.Basic`, `Mathlib.LinearAlgebra.Matrix.Charpoly.Basic` | Ready for PR |
| `DFT.lean` | `Mathlib.Analysis.Fourier` / `Mathlib.NumberTheory.LegendreSymbol` | `Mathlib.NumberTheory.LegendreSymbol.AddCharacter`, `Mathlib.Data.Complex.Basic` | Ready for PR |
| `CyclicBlockFactorization.lean` | `Mathlib.Algebra.Polynomial` | `Mathlib.Algebra.Polynomial.Basic` | Ready for PR |
| `LogBounds.lean` | `Mathlib.Analysis.SpecialFunctions.Log` | `Mathlib.Analysis.SpecialFunctions.Log.Basic` | Ready for PR |
| `Positivity.lean` | `Mathlib.LinearAlgebra.Matrix` | `Mathlib.LinearAlgebra.Matrix.Spectrum`, `Mathlib.Combinatorics.SimpleGraph.Basic` | Ready for PR |
| `PrefixSparsity.lean` | `Mathlib.Combinatorics` | `Mathlib.Data.Fintype.BigOperators`, `Mathlib.Logic.Equiv.Fin` | Ready for PR |
