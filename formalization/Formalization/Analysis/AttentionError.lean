import Mathlib.Data.Real.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Finset.Basic
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Formalization.Analysis.SparsityBound

open scoped BigOperators Matrix
open Classical

set_option linter.unusedSectionVars false

noncomputable section AttentionError

/-!
# Formal Attention Approximation Bounds

This module formalizes the Frobenius norm and row-wise error bounds between
dense softmax attention and p-adic tree cluster truncated attention:
  ‖Attn_dense(Q, K, V) - Attn_tree(Q, K, V)‖_F ≤ C * p^(-D) * ‖∇V‖
under Lipschitz continuity / bounded gradient of the value embedding manifold.

## Proof Architecture
1. **Row-Stochastic Attention**: `IsRowStochastic` specifies valid attention distributions.
2. **Value Embedding**: `rowVec`, `vecNormSq`, `vecNorm`, `LipschitzEmbedding`, `BoundedGradient`.
3. **p-adic Tree Tail Bound**: `PAdicTailBound` bounds the truncated mass by `C * p^(-D)`.
4. **Tree Truncation Operator**: `treeTruncatedAttention` normalizes cluster-truncated attention.
5. **Main Theorems**:
   - `row_norm_bound`: Pointwise row error bound.
   - `attention_frobenius_error_bound`: Full Frobenius norm error bound.
   - `attention_avg_frobenius_error_bound`: Normalized/RMS Frobenius error bound.
   - `attention_frobenius_error_bound_lipschitz`: Error bound with explicit Lipschitz constant.
   - `attention_tree_cluster_frobenius_error_bound`: End-to-end bound for tree clusters.
-/

variable {I J : Type*} [Fintype I] [Fintype J]

/-- Canonical embedding of a finite function into EuclideanSpace with ℓ₂ norm. -/
def toEuclid (f : J → ℝ) : EuclideanSpace ℝ J :=
  (WithLp.linearEquiv 2 ℝ (J → ℝ)).symm f

/-- The i-th row vector of a matrix as an element of EuclideanSpace. -/
def rowVec (M : Matrix I J ℝ) (i : I) : EuclideanSpace ℝ J :=
  toEuclid (M i)

/-- An attention matrix is row-stochastic if all entries are non-negative and every row sums to 1. -/
def IsRowStochastic (A : Matrix I I ℝ) : Prop :=
  (∀ i j, 0 ≤ A i j) ∧ (∀ i, ∑ j, A i j = 1)

/-- Attention output operator: multiplies attention weights by the value embedding matrix. -/
def attn (A : Matrix I I ℝ) (V : Matrix I J ℝ) : Matrix I J ℝ :=
  A * V

/-- The ℓ₁ difference between row distributions of two attention matrices at row i. -/
def rowDiffL1 (A B : Matrix I I ℝ) (i : I) : ℝ :=
  ∑ j, |A i j - B i j|

/-- Lipschitz continuity of the value embedding with respect to a token metric `dist`. -/
def LipschitzEmbedding (V : Matrix I J ℝ) (dist : I → I → ℝ) (L_V : ℝ) : Prop :=
  ∀ i j, ‖rowVec V i - rowVec V j‖ ≤ L_V * dist i j

/-- Bounded gradient / variation of the value embedding vectors. -/
def BoundedGradient (V : Matrix I J ℝ) (grad_V : ℝ) : Prop :=
  ∀ i j, ‖rowVec V i - rowVec V j‖ ≤ grad_V

/-- Total truncated probability mass is bounded by C * p^(-D) across all queries. -/
def PAdicTailBound (A B : Matrix I I ℝ) (p : ℕ) (D : ℕ) (C : ℝ) : Prop :=
  ∀ i, rowDiffL1 A B i ≤ C * ((p : ℝ) ^ D)⁻¹

/-- Squared Frobenius norm of a matrix. -/
def frobeniusNormSq (M : Matrix I J ℝ) : ℝ :=
  ∑ i, ‖rowVec M i‖ ^ 2

/-- Frobenius norm of a matrix. -/
def frobeniusNorm (M : Matrix I J ℝ) : ℝ :=
  Real.sqrt (frobeniusNormSq M)

/-- Average / root-mean-square Frobenius norm normalized by √|I|. -/
def avgFrobeniusNorm (M : Matrix I J ℝ) : ℝ :=
  frobeniusNorm M / Real.sqrt (Fintype.card I : ℝ)

/-- Truncated and re-normalized attention restricted to a tree cluster `T i` for each query `i`. -/
def treeTruncatedAttention (A : Matrix I I ℝ) (T : I → Finset I) : Matrix I I ℝ :=
  fun i j =>
    let m := ∑ k ∈ T i, A i k
    if j ∈ T i then A i j / m else 0

/-! ### Structural Properties and Bounds -/

lemma norm_linear_comb_le (c : I → ℝ) (v : I → EuclideanSpace ℝ J) :
    ‖∑ j, c j • v j‖ ≤ ∑ j, |c j| * ‖v j‖ :=
  (norm_sum_le _ _).trans_eq (by simp only [norm_smul, Real.norm_eq_abs])

lemma row_mul_eq_sum (A : Matrix I I ℝ) (V : Matrix I J ℝ) (i : I) :
    (A * V) i = ∑ j, A i j • V j := by
  ext k
  simp only [Matrix.mul_apply, Finset.sum_apply, Pi.smul_apply, smul_eq_mul]

lemma rowVec_mul (A : Matrix I I ℝ) (V : Matrix I J ℝ) (i : I) :
    rowVec (A * V) i = ∑ j, A i j • rowVec V j := by
  dsimp [rowVec]
  rw [row_mul_eq_sum]
  exact map_sum (WithLp.linearEquiv 2 ℝ (J → ℝ)).symm _ _

lemma row_sub (A B : Matrix I J ℝ) (i : I) : (A - B) i = A i - B i := rfl

lemma rowVec_sub (A B : Matrix I J ℝ) (i : I) : rowVec (A - B) i = rowVec A i - rowVec B i :=
  map_sub (WithLp.linearEquiv 2 ℝ (J → ℝ)).symm (A i) (B i)

lemma sum_sub_smul_eq_zero (A B : Matrix I I ℝ) (hA : IsRowStochastic A) (hB : IsRowStochastic B)
    (i : I) (c : EuclideanSpace ℝ J) :
    ∑ j, (A i j - B i j) • c = 0 := by
  rw [← Finset.sum_smul, Finset.sum_sub_distrib, hA.2 i, hB.2 i, sub_self, zero_smul]

/-- Center-invariance: for any center vector c, the row difference can be centered at c. -/
lemma row_diff_centered (A B : Matrix I I ℝ) (V : Matrix I J ℝ)
    (hA : IsRowStochastic A) (hB : IsRowStochastic B) (i : I) (c : EuclideanSpace ℝ J) :
    rowVec (A * V - B * V) i = ∑ j, (A i j - B i j) • (rowVec V j - c) := by
  simp_rw [rowVec_sub, rowVec_mul, smul_sub, Finset.sum_sub_distrib,
    sum_sub_smul_eq_zero A B hA hB, sub_zero, sub_smul, Finset.sum_sub_distrib]

/-- Pointwise bound: the error in row i is bounded by the ℓ₁ variation times gradient norm. -/
lemma row_norm_bound (A B : Matrix I I ℝ) (V : Matrix I J ℝ)
    (hA : IsRowStochastic A) (hB : IsRowStochastic B)
    (grad_V : ℝ) (hV : BoundedGradient V grad_V) (i : I) :
    ‖rowVec (A * V - B * V) i‖ ≤ rowDiffL1 A B i * grad_V := by
  rw [row_diff_centered A B V hA hB i (rowVec V i)]
  dsimp [rowDiffL1]
  rw [Finset.sum_mul]
  exact (norm_linear_comb_le _ _).trans
    (Finset.sum_le_sum fun j _ => mul_le_mul_of_nonneg_left (hV j i) (abs_nonneg _))

/-- Lipschitz embeddings over bounded diameter spaces have bounded gradients. -/
lemma boundedGradient_of_lipschitz (V : Matrix I J ℝ) (dist : I → I → ℝ) (L_V diam : ℝ)
    (hLip : LipschitzEmbedding V dist L_V)
    (hdiam : ∀ i j, dist i j ≤ diam)
    (hL : 0 ≤ L_V) :
    BoundedGradient V (L_V * diam) :=
  fun i j => (hLip i j).trans (mul_le_mul_of_nonneg_left (hdiam i j) hL)

/-! ### Tree Truncation Mass and Stochasticity -/

lemma sum_add_sum_compl (T : Finset I) (f : I → ℝ) :
    (∑ j ∈ T, f j) + (∑ j ∈ Tᶜ, f j) = ∑ j, f j :=
  Finset.sum_add_sum_compl T f

lemma cluster_mass_le_one (A : Matrix I I ℝ) (hA : IsRowStochastic A) (T : Finset I) (i : I) :
    (∑ k ∈ T, A i k) ≤ 1 :=
  (Finset.sum_le_univ_sum_of_nonneg (hA.1 i)).trans_eq (hA.2 i)

lemma treeTruncatedAttention_rowStochastic (A : Matrix I I ℝ) (hA : IsRowStochastic A)
    (T : I → Finset I) (hm : ∀ i, 0 < ∑ k ∈ T i, A i k) :
    IsRowStochastic (treeTruncatedAttention A T) := by
  refine ⟨fun i j => ?_, fun i => ?_⟩
  · dsimp [treeTruncatedAttention]
    split_ifs
    · exact div_nonneg (hA.1 i j) (hm i).le
    · rfl
  · dsimp [treeTruncatedAttention]
    rw [Finset.sum_ite_mem, Finset.univ_inter, ← Finset.sum_div, div_self (hm i).ne']

lemma tree_truncated_rowDiffL1_eq_two_eps (A : Matrix I I ℝ) (hA : IsRowStochastic A)
    (T : I → Finset I) (i : I) (hm : 0 < ∑ k ∈ T i, A i k) :
    rowDiffL1 A (treeTruncatedAttention A T) i = 2 * (∑ j ∈ (T i)ᶜ, A i j) := by
  let m := ∑ k ∈ T i, A i k
  let eps := ∑ j ∈ (T i)ᶜ, A i j
  have hm_le := cluster_mass_le_one A hA (T i) i
  have h_sum : m + eps = 1 := by
    dsimp [m, eps]
    rw [sum_add_sum_compl (T i) (fun j => A i j), hA.2 i]
  have h_split : (∑ j, |A i j - treeTruncatedAttention A T i j|) =
      (∑ j ∈ T i, |A i j - treeTruncatedAttention A T i j|) +
      (∑ j ∈ (T i)ᶜ, |A i j - treeTruncatedAttention A T i j|) :=
    (Finset.sum_add_sum_compl (T i) _).symm
  rw [rowDiffL1, h_split]
  have h_in : (∑ j ∈ T i, |A i j - treeTruncatedAttention A T i j|) = eps := by
    have h_term : ∀ j ∈ T i, |A i j - treeTruncatedAttention A T i j| = A i j * (1 / m - 1) := by
      intro j hj
      dsimp [treeTruncatedAttention, m]
      simp [hj]
      have : A i j - A i j / m ≤ 0 := by rw [sub_nonpos, le_div_iff₀ hm]; nlinarith [hm_le, hA.1 i j]
      rw [abs_of_nonpos this]
      ring
    rw [Finset.sum_congr rfl h_term, ← Finset.sum_mul]
    linear_combination (mul_one_div_cancel hm.ne') - h_sum
  have h_out : (∑ j ∈ (T i)ᶜ, |A i j - treeTruncatedAttention A T i j|) = eps := by
    refine Finset.sum_congr rfl fun j hj => ?_
    dsimp [treeTruncatedAttention, m]
    simp [Finset.mem_compl.mp hj, abs_of_nonneg (hA.1 i j)]
  rw [h_in, h_out]
  ring

lemma pAdicTailBound_of_tree_tail (A : Matrix I I ℝ) (hA : IsRowStochastic A)
    (T : I → Finset I) (p D : ℕ) (C : ℝ)
    (hm : ∀ i, 0 < ∑ k ∈ T i, A i k)
    (htail : ∀ i, (∑ j ∈ (T i)ᶜ, A i j) ≤ (C / 2) * ((p : ℝ) ^ D)⁻¹) :
    PAdicTailBound A (treeTruncatedAttention A T) p D C := fun i => by
  rw [tree_truncated_rowDiffL1_eq_two_eps A hA T i (hm i)]
  linarith [htail i]

/-! ### Main Error Bound Theorems -/

/-- Main Frobenius norm error bound between dense attention and p-adic tree truncated attention. -/
theorem attention_frobenius_error_bound (A B : Matrix I I ℝ) (V : Matrix I J ℝ)
    (hA : IsRowStochastic A) (hB : IsRowStochastic B)
    (p : ℕ) (D : ℕ) (C : ℝ) (h_tail : PAdicTailBound A B p D C)
    (grad_V : ℝ) (hV : BoundedGradient V grad_V)
    (hC : 0 ≤ C) (hgrad : 0 ≤ grad_V) :
    frobeniusNorm (A * V - B * V) ≤
      Real.sqrt (Fintype.card I : ℝ) * C * ((p : ℝ) ^ D)⁻¹ * grad_V := by
  let bound := C * ((p : ℝ) ^ D)⁻¹ * grad_V
  have hbound_nonneg : 0 ≤ bound := by
    dsimp [bound]
    positivity
  have h_row_bound : ∀ i, ‖rowVec (A * V - B * V) i‖ ≤ bound := fun i =>
    (row_norm_bound A B V hA hB grad_V hV i).trans (by nlinarith [h_tail i])
  have h_sq_le : frobeniusNormSq (A * V - B * V) ≤ (Fintype.card I : ℝ) * bound ^ 2 := by
    dsimp [frobeniusNormSq]
    have hsum : (∑ i : I, ‖rowVec (A * V - B * V) i‖ ^ 2) ≤ ∑ i : I, bound ^ 2 :=
      Finset.sum_le_sum fun i _ => by nlinarith [norm_nonneg (rowVec (A * V - B * V) i), h_row_bound i]
    rw [Finset.sum_const, Finset.card_univ, nsmul_eq_mul] at hsum
    exact hsum
  have h_sqrt_le : Real.sqrt (frobeniusNormSq (A * V - B * V)) ≤
      Real.sqrt ((Fintype.card I : ℝ) * bound ^ 2) :=
    Real.sqrt_le_sqrt h_sq_le
  rw [Real.sqrt_mul (Nat.cast_nonneg _), Real.sqrt_sq hbound_nonneg] at h_sqrt_le
  dsimp [frobeniusNorm, bound]
  linarith

/-- Frobenius norm error bound under explicit Lipschitz manifold embedding condition. -/
theorem attention_frobenius_error_bound_lipschitz (A B : Matrix I I ℝ) (V : Matrix I J ℝ)
    (hA : IsRowStochastic A) (hB : IsRowStochastic B)
    (p : ℕ) (D : ℕ) (C : ℝ) (h_tail : PAdicTailBound A B p D C)
    (dist : I → I → ℝ) (diam : ℝ) (hdiam : ∀ i j, dist i j ≤ diam)
    (L_V : ℝ) (hLip : LipschitzEmbedding V dist L_V)
    (hC : 0 ≤ C) (hL : 0 ≤ L_V) (hdiam_nonneg : 0 ≤ diam) :
    frobeniusNorm (A * V - B * V) ≤
      Real.sqrt (Fintype.card I : ℝ) * C * ((p : ℝ) ^ D)⁻¹ * (L_V * diam) :=
  attention_frobenius_error_bound A B V hA hB p D C h_tail (L_V * diam)
    (boundedGradient_of_lipschitz V dist L_V diam hLip hdiam hL) hC (mul_nonneg hL hdiam_nonneg)

/-- Normalized average Frobenius norm error bound (invariant under sequence length scaling). -/
theorem attention_avg_frobenius_error_bound (A B : Matrix I I ℝ) (V : Matrix I J ℝ)
    (hA : IsRowStochastic A) (hB : IsRowStochastic B)
    (p : ℕ) (D : ℕ) (C : ℝ) (h_tail : PAdicTailBound A B p D C)
    (grad_V : ℝ) (hV : BoundedGradient V grad_V)
    (hC : 0 ≤ C) (hgrad : 0 ≤ grad_V)
    (hI : Nonempty I) :
    avgFrobeniusNorm (A * V - B * V) ≤ C * ((p : ℝ) ^ D)⁻¹ * grad_V := by
  have h_sqrt_pos : 0 < Real.sqrt (Fintype.card I : ℝ) := Real.sqrt_pos.mpr (by positivity)
  have h_frob := attention_frobenius_error_bound A B V hA hB p D C h_tail grad_V hV hC hgrad
  dsimp [avgFrobeniusNorm]
  rw [div_le_iff₀ h_sqrt_pos]
  linarith

/-- Complete end-to-end bound for tree-cluster truncated attention. -/
theorem attention_tree_cluster_frobenius_error_bound (A : Matrix I I ℝ) (V : Matrix I J ℝ)
    (hA : IsRowStochastic A) (T : I → Finset I) (hm : ∀ i, 0 < ∑ k ∈ T i, A i k)
    (p : ℕ) (D : ℕ) (C : ℝ)
    (htail : ∀ i, (∑ j ∈ (T i)ᶜ, A i j) ≤ (C / 2) * ((p : ℝ) ^ D)⁻¹)
    (grad_V : ℝ) (hV : BoundedGradient V grad_V)
    (hC : 0 ≤ C) (hgrad : 0 ≤ grad_V) :
    frobeniusNorm (A * V - treeTruncatedAttention A T * V) ≤
      Real.sqrt (Fintype.card I : ℝ) * C * ((p : ℝ) ^ D)⁻¹ * grad_V :=
  attention_frobenius_error_bound A (treeTruncatedAttention A T) V hA
    (treeTruncatedAttention_rowStochastic A hA T hm) p D C
    (pAdicTailBound_of_tree_tail A hA T p D C hm htail) grad_V hV hC hgrad

end AttentionError
