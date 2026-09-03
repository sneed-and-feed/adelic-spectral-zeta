import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Abel
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum
import Formalization.Spectral.RegularIharaZeta

/-!
# Dynamical Ihara Bridge

This module formalizes the algebraic bridge connecting directed dynamical transfer
operators (such as the 2-adic Collatz relation matrix $D_n$) to the symmetrized
4-regular Schreier graph adjacency matrix $A_n = D_n + D_n^T$, its Ihara-Bass
characteristic matrix, and the spectral duality between directed periodic orbits
and undirected non-backtracking geodesics.

## Mathematical Content
1. **Symmetrized Operator Definition & Symmetry**:
   - `symmetrizedAdjMatrix D = D + D.transpose`
   - Proof that `(symmetrizedAdjMatrix D).transpose = symmetrizedAdjMatrix D`

2. **Trace Relations Between Directed and Symmetrized Operators**:
   - Trace of degree 1: $\operatorname{Tr}(A) = 2 \operatorname{Tr}(D)$
   - Trace of degree 2: $\operatorname{Tr}(A^2) = 2 \operatorname{Tr}(D^2) + 2 \operatorname{Tr}(D D^T)$
   - Component sum formula for $\operatorname{Tr}(D D^T)$

3. **Schreier Ihara-Bass Matrix on Symmetrized Operator**:
   - `schreierIharaBassMatrix D u = regularIharaBassMatrix 4 (symmetrizedAdjMatrix D) u`
   - Explicit polynomial expansion: $(1 + 3 u^2) I - u (D + D^T)$
   - Transpose symmetry of the Schreier Ihara-Bass matrix

4. **Perron Eigenvector & Spectral Duality**:
   - `HasUniformRowSum D k`: constant row sum property
   - Regularity theorem: if $D$ and $D^T$ have uniform row sum 2, then $A$ has uniform row sum 4
   - Perron spectral kernel: at $u = 1/3$, the Ihara-Bass matrix annihilates the all-ones vector $\mathbf{1}$
   - General $d$-regular Ihara-Bass Perron kernel theorem at $u = 1/(d-1)$

## References
- Ihara, Y. (1966). *On discrete subgroups of the two by two projective linear group over p-adic fields*.
- Bass, H. (1992). *The Ihara-Selberg zeta function of a tree lattice*.
- Terras, A. (2010). *Zeta Functions of Graphs: A Stroll through the Garden*.
-/

open Matrix
open scoped Matrix

namespace DynamicalIharaBridge

section IharaBridge

variable {V : Type*} [Fintype V]

-- ============================================================================
-- 1. Symmetrized Operator Definition & Symmetry
-- ============================================================================

/-- The symmetrized adjacency matrix associated to a directed transfer operator $D$:
$$ A = D + D^T $$ -/
noncomputable def symmetrizedAdjMatrix {V : Type*} [Fintype V] {R : Type*} [CommRing R]
    (D : Matrix V V R) : Matrix V V R :=
  D + D.transpose

/-- Symmetrized operator entry formula. -/
lemma symmetrizedAdjMatrix_apply {R : Type*} [CommRing R]
    (D : Matrix V V R) (i j : V) :
    symmetrizedAdjMatrix D i j = D i j + D j i := by
  simp [symmetrizedAdjMatrix, Matrix.add_apply, Matrix.transpose_apply]

/-- The symmetrized adjacency matrix is self-transpose (symmetric). -/
theorem symmetrizedAdjMatrix_transpose {V : Type*} [Fintype V] {R : Type*} [CommRing R]
    (D : Matrix V V R) :
    (symmetrizedAdjMatrix D).transpose = symmetrizedAdjMatrix D := by
  unfold symmetrizedAdjMatrix
  rw [Matrix.transpose_add, Matrix.transpose_transpose, add_comm]

/-- Symmetrization of the zero operator is zero. -/
@[simp]
lemma symmetrizedAdjMatrix_zero {R : Type*} [CommRing R] :
    symmetrizedAdjMatrix (0 : Matrix V V R) = 0 := by
  simp [symmetrizedAdjMatrix]

/-- Symmetrization is additive. -/
lemma symmetrizedAdjMatrix_add {R : Type*} [CommRing R]
    (D₁ D₂ : Matrix V V R) :
    symmetrizedAdjMatrix (D₁ + D₂) = symmetrizedAdjMatrix D₁ + symmetrizedAdjMatrix D₂ := by
  unfold symmetrizedAdjMatrix
  rw [Matrix.transpose_add]
  abel

/-- Symmetrization commutes with scalar multiplication. -/
lemma symmetrizedAdjMatrix_smul {R : Type*} [CommRing R]
    (c : R) (D : Matrix V V R) :
    symmetrizedAdjMatrix (c • D) = c • symmetrizedAdjMatrix D := by
  unfold symmetrizedAdjMatrix
  rw [Matrix.transpose_smul, smul_add]

-- ============================================================================
-- 2. Trace Relations Between Directed and Symmetrized Operators
-- ============================================================================

/-- **Trace of Symmetrized Operator ($m = 1$)**:
The trace of the symmetrized operator equals twice the trace of the directed operator:
$$ \operatorname{Tr}(D + D^T) = 2 \operatorname{Tr}(D) $$ -/
lemma trace_symmetrized_eq_two_mul_trace {R : Type*} [CommRing R]
    (D : Matrix V V R) :
    (symmetrizedAdjMatrix D).trace = 2 * D.trace := by
  unfold symmetrizedAdjMatrix
  rw [Matrix.trace_add, Matrix.trace_transpose, two_mul]

/-- **Trace of Symmetrized Operator Squared ($m = 2$)**:
The trace of the squared symmetrized operator decomposes into directed 2-cycles and bidirectional edges:
$$ \operatorname{Tr}((D + D^T)^2) = 2 \operatorname{Tr}(D^2) + 2 \operatorname{Tr}(D D^T) $$ -/
lemma trace_symmetrized_sq [DecidableEq V] {R : Type*} [CommRing R]
    (D : Matrix V V R) :
    (symmetrizedAdjMatrix D ^ 2).trace = 2 * (D ^ 2).trace + 2 * (D * D.transpose).trace := by
  unfold symmetrizedAdjMatrix
  rw [sq, sq]
  rw [add_mul, mul_add, mul_add]
  rw [Matrix.trace_add, Matrix.trace_add, Matrix.trace_add]
  rw [Matrix.trace_mul_comm D.transpose D]
  have h_trans_sq : (D.transpose * D.transpose).trace = (D * D).trace := by
    rw [← Matrix.transpose_mul, Matrix.trace_transpose]
  rw [h_trans_sq]
  ring

/-- Expansion of $\operatorname{Tr}(D D^T)$ as the sum of squared matrix elements:
$$ \operatorname{Tr}(D D^T) = \sum_{i, j} D(i, j)^2 $$ -/
lemma trace_mul_transpose_eq_sum_sq {R : Type*} [CommRing R]
    (D : Matrix V V R) :
    (D * D.transpose).trace = ∑ i : V, ∑ j : V, (D i j)^2 := by
  simp only [Matrix.trace, Matrix.diag, Matrix.mul_apply, Matrix.transpose_apply, sq]

-- ============================================================================
-- 3. Schreier Ihara-Bass Matrix on Symmetrized Operator
-- ============================================================================

/-- The Schreier Ihara-Bass characteristic matrix for a 4-regular Schreier graph
induced by a directed transfer operator $D$:
$$ \mathcal{B}(D, u) = (1 + 3 u^2) I - u (D + D^T) $$ -/
noncomputable def schreierIharaBassMatrix [DecidableEq V] {R : Type*} [CommRing R]
    (D : Matrix V V R) (u : R) : Matrix V V R :=
  regularIharaBassMatrix 4 (symmetrizedAdjMatrix D) u

/-- **Explicit Form of the Schreier Ihara-Bass Matrix**:
$$ \mathcal{B}(D, u) = (1 + 3 u^2) I - u (D + D^T) $$ -/
theorem schreierIharaBassMatrix_eq [DecidableEq V] {R : Type*} [CommRing R]
    (D : Matrix V V R) (u : R) :
    schreierIharaBassMatrix D u = (1 + 3 * u^2) • 1 - u • (D + D.transpose) := by
  unfold schreierIharaBassMatrix regularIharaBassMatrix symmetrizedAdjMatrix
  have h4 : ((4 : ℕ) : R) - 1 = (3 : R) := by
    push_cast
    ring
  rw [h4]

/-- The Schreier Ihara-Bass matrix is self-transpose (symmetric). -/
theorem schreierIharaBassMatrix_transpose [DecidableEq V] {R : Type*} [CommRing R]
    (D : Matrix V V R) (u : R) :
    (schreierIharaBassMatrix D u).transpose = schreierIharaBassMatrix D u := by
  rw [schreierIharaBassMatrix_eq]
  rw [Matrix.transpose_sub, Matrix.transpose_smul, Matrix.transpose_smul, Matrix.transpose_one]
  rw [Matrix.transpose_add, Matrix.transpose_transpose, add_comm D.transpose D]

-- ============================================================================
-- 4. Perron Eigenvector & Spectral Duality
-- ============================================================================

/-- A matrix has uniform row sum $k$ if the sum of entries along each row equals $k$. -/
def HasUniformRowSum {R : Type*} [CommRing R]
    (D : Matrix V V R) (k : R) : Prop :=
  ∀ i : V, (∑ j : V, D i j) = k

/-- A matrix has uniform column sum $k$ if its transpose has uniform row sum $k$. -/
def HasUniformColSum {R : Type*} [CommRing R]
    (D : Matrix V V R) (k : R) : Prop :=
  HasUniformRowSum D.transpose k

/-- If $D$ has uniform row sum $k$, then multiplying $D$ by the all-ones vector yields $k \mathbf{1}$. -/
lemma mulVec_ones_of_hasUniformRowSum {R : Type*} [CommRing R]
    (D : Matrix V V R) (k : R) (h : HasUniformRowSum D k) :
    D *ᵥ (fun _ => (1 : R)) = fun _ => k := by
  ext i
  simp only [Matrix.mulVec, dotProduct, mul_one]
  exact h i

/-- If $D$ has uniform row sum 2 and uniform column sum 2 (i.e. $D^T$ has row sum 2),
then the symmetrized operator $A = D + D^T$ has uniform row sum 4 (4-regularity). -/
lemma symmetrized_row_sum_four {R : Type*} [CommRing R]
    {D : Matrix V V R}
    (h_row : HasUniformRowSum D 2) (h_col : HasUniformRowSum D.transpose 2) :
    HasUniformRowSum (symmetrizedAdjMatrix D) 4 := by
  intro i
  simp only [symmetrizedAdjMatrix, Matrix.add_apply]
  rw [Finset.sum_add_distrib]
  rw [h_row i, h_col i]
  norm_num

/-- **Perron Spectral Zero of the 4-Regular Ihara-Bass Matrix**:
At $u = 1/3$, the Ihara-Bass characteristic factor $(1 + 3 u^2) I - u A$ on a 4-regular
Schreier graph annihilates the Perron eigenvector $\mathbf{1}$:
$$ \left( \left(1 + 3 \left(\frac{1}{3}\right)^2\right) I - \frac{1}{3} (D + D^T) \right) \mathbf{1} = \left(\frac{4}{3} - \frac{4}{3}\right) \mathbf{1} = \mathbf{0} $$
-/
theorem ihara_bass_perron_kernel [DecidableEq V]
    {D : Matrix V V ℚ}
    (h_row : HasUniformRowSum D 2) (h_col : HasUniformRowSum D.transpose 2) :
    (schreierIharaBassMatrix D (1/3 : ℚ)) *ᵥ (fun _ => (1 : ℚ)) = 0 := by
  have h_sym4 : HasUniformRowSum (symmetrizedAdjMatrix D) 4 :=
    symmetrized_row_sum_four h_row h_col
  rw [schreierIharaBassMatrix_eq]
  have h_scalar : (1 + 3 * (1 / 3 : ℚ) ^ 2) = (4 / 3 : ℚ) := by norm_num
  rw [h_scalar]
  rw [Matrix.sub_mulVec, Matrix.smul_mulVec, Matrix.smul_mulVec]
  rw [Matrix.one_mulVec]
  have h_ones : (D + D.transpose) *ᵥ (fun _ => (1 : ℚ)) = (fun _ => 4) := by
    exact mulVec_ones_of_hasUniformRowSum (symmetrizedAdjMatrix D) 4 h_sym4
  rw [h_ones]
  ext i
  simp only [Pi.sub_apply, Pi.smul_apply, smul_eq_mul, Pi.zero_apply]
  norm_num

/-- **General $d$-Regular Ihara-Bass Perron Kernel Theorem**:
For any $d$-regular adjacency matrix $A$ with uniform row sum $d$ and $d \ge 2$,
the regular Ihara-Bass matrix at $u = 1 / (d - 1)$ annihilates the constant vector $\mathbf{1}$:
$$ \left( \left(1 + (d - 1) \left(\frac{1}{d-1}\right)^2\right) I - \frac{1}{d-1} A \right) \mathbf{1} = \left( \frac{d}{d-1} - \frac{d}{d-1} \right) \mathbf{1} = \mathbf{0} $$
-/
theorem regular_ihara_bass_perron_kernel_general [DecidableEq V]
    (d : ℕ) (hd : d ≥ 2) {A : Matrix V V ℚ}
    (h_row : HasUniformRowSum A (d : ℚ)) :
    (regularIharaBassMatrix d A (1 / ((d : ℚ) - 1))) *ᵥ (fun _ => (1 : ℚ)) = 0 := by
  have hd_sub_ne : (d : ℚ) - 1 ≠ 0 := by
    have : (d : ℚ) ≥ 2 := by exact_mod_cast hd
    linarith
  have h_scalar : 1 + ((d : ℚ) - 1) * (1 / ((d : ℚ) - 1)) ^ 2 = (d : ℚ) / ((d : ℚ) - 1) := by
    rw [sq, ← mul_assoc, mul_one_div_cancel hd_sub_ne, one_mul]
    field_simp [hd_sub_ne]
    ring
  unfold regularIharaBassMatrix
  rw [h_scalar]
  rw [Matrix.sub_mulVec, Matrix.smul_mulVec, Matrix.smul_mulVec]
  rw [Matrix.one_mulVec]
  have h_ones : A *ᵥ (fun _ => (1 : ℚ)) = (fun _ => (d : ℚ)) := by
    exact mulVec_ones_of_hasUniformRowSum A (d : ℚ) h_row
  rw [h_ones]
  ext i
  simp only [Pi.sub_apply, Pi.smul_apply, smul_eq_mul, Pi.zero_apply]
  field_simp [hd_sub_ne]
  ring

end IharaBridge

end DynamicalIharaBridge
