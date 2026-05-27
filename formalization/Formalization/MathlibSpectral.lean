import Mathlib.Data.Matrix.Basic
import Mathlib.Combinatorics.SimpleGraph.Basic
import Mathlib.Combinatorics.SimpleGraph.Connectivity
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Group.Abs
import Mathlib.LinearAlgebra.Matrix.Spectrum
import Mathlib.Analysis.InnerProductSpace.PiL2

open Matrix
open Classical

namespace Matrix

variable {n : Type _} [Fintype n] [DecidableEq n] [Nonempty n]


/-- The support graph of a non-negative symmetric matrix, where edges correspond to positive entries. -/
def supportGraph (A : Matrix n n ℝ) (h_symm : ∀ i j, A i j = A j i) : SimpleGraph n where
  Adj i j := 0 < A i j ∧ i ≠ j
  symm := by
    intro i j h
    exact ⟨by rw [h_symm j i]; exact h.1, h.2.symm⟩
  loopless := by intro i h; exact h.2 rfl

/-- The powers of a non-negative matrix have non-negative entries. -/
@[simp]
lemma pow_nonneg {A : Matrix n n ℝ} (hA_nn : ∀ i j, 0 ≤ A i j) (k : ℕ) :
    ∀ i j, 0 ≤ (A ^ k) i j := by
  induction k with
  | zero =>
    intro i j
    by_cases h : i = j
    · rw [h, pow_zero, one_apply_eq]
      exact zero_le_one
    · rw [pow_zero, one_apply_ne h]
  | succ k ih =>
    intro i j
    rw [pow_succ', mul_apply]
    apply Finset.sum_nonneg
    intro x _
    exact mul_nonneg (hA_nn i x) (ih x j)

/-- If there is a walk in the support graph of a non-negative symmetric matrix, 
the corresponding entry in the matrix power is strictly positive. -/
lemma pow_pos_of_walk {A : Matrix n n ℝ}
    (hA_symm : ∀ i j, A i j = A j i) (hA_nn : ∀ i j, 0 ≤ A i j)
    {i j : n} (w : SimpleGraph.Walk (supportGraph A hA_symm) i j) :
    0 < (A ^ w.length) i j := by
  induction w with
  | nil =>
    simp only [SimpleGraph.Walk.length_nil, pow_zero, one_apply_eq]
    exact zero_lt_one
  | cons h w_rest ih =>
    rename_i u v w
    rw [SimpleGraph.Walk.length_cons, pow_succ', mul_apply]
    have h_pos : 0 < A u v := h.1
    have h_term : 0 < A u v * (A ^ w_rest.length) v w := mul_pos h_pos ih
    have h_nonneg : ∀ k ∈ Finset.univ, 0 ≤ A u k * (A ^ w_rest.length) k w := by
      intro k _
      apply mul_nonneg (hA_nn _ _)
      exact pow_nonneg hA_nn w_rest.length k w
    exact Finset.sum_pos' h_nonneg ⟨v, Finset.mem_univ v, h_term⟩

/-- Bounding the powers of a non-negative matrix by the powers of the matrix plus the identity. -/
lemma pow_le_add_one_pow {A : Matrix n n ℝ} (hA_nn : ∀ i j, 0 ≤ A i j) (k : ℕ) :
    ∀ i j, (A ^ k) i j ≤ ((A + 1) ^ k) i j := by
  induction k with
  | zero =>
    intro i j
    rfl
  | succ k ih =>
    intro i j
    rw [pow_succ', pow_succ', mul_apply, mul_apply]
    apply Finset.sum_le_sum
    intro l _
    have h1 : A i l ≤ (A + 1) i l := by
      by_cases hil : i = l
      · rw [hil, add_apply, one_apply_eq]
        exact le_add_of_nonneg_right zero_le_one
      · rw [add_apply, one_apply_ne hil, add_zero]
    have h2 : (A ^ k) l j ≤ ((A + 1) ^ k) l j := ih l j
    have h3 : 0 ≤ (A ^ k) l j := pow_nonneg hA_nn k l j
    have hA1_nn : ∀ x y, 0 ≤ (A + 1) x y := fun x y => by
      by_cases h : x = y
      · rw [h, add_apply, one_apply_eq]
        exact add_nonneg (hA_nn y y) zero_le_one
      · rw [add_apply, one_apply_ne h, add_zero]
        exact hA_nn x y
    exact mul_le_mul h1 h2 h3 (hA1_nn i l)


/-- A non-negative eigenvector that is zero at one vertex must be zero along any connected walk. -/
lemma eq_zero_of_walk_of_eigenvector {A : Matrix n n ℝ}
    (hA_symm : ∀ i j, A i j = A j i) (hA_nn : ∀ i j, 0 ≤ A i j)
    (u : n → ℝ) (hu_nn : ∀ i, 0 ≤ u i)
    (lam : ℝ) (hu_eig : A.mulVec u = lam • u)
    {i j : n}
    (w : SimpleGraph.Walk (supportGraph A hA_symm) i j) :
    u i = 0 → u j = 0 := by
  induction w with
  | nil => intro h; exact h
  | cons h rest ih =>
    clear i j
    rename_i u_start u_next u_end
    intro hui
    have h_adj_pos : 0 < A u_start u_next := h.1
    have h_eq : (A.mulVec u) u_start = lam * u u_start := by
      have := congr_fun hu_eig u_start
      rw [Pi.smul_apply, smul_eq_mul] at this
      exact this
    dsimp [mulVec, dotProduct] at h_eq
    rw [hui, mul_zero] at h_eq
    have h_sum_nn : ∀ l ∈ Finset.univ, 0 ≤ A u_start l * u l := fun l _ => mul_nonneg (hA_nn u_start l) (hu_nn l)
    have h_term_zero : A u_start u_next * u u_next = 0 := by
      have h_le : A u_start u_next * u u_next ≤ ∑ l, A u_start l * u l := Finset.single_le_sum h_sum_nn (Finset.mem_univ u_next)
      linarith [h_sum_nn u_next (Finset.mem_univ u_next)]
    have hux_zero : u u_next = 0 := by
      cases mul_eq_zero.mp h_term_zero with
      | inl h1 => exact False.elim (ne_of_gt h_adj_pos h1)
      | inr h2 => exact h2
    exact ih hux_zero

/-- The eigenspace of the Perron-Frobenius eigenvalue is one-dimensional for a connected support graph. -/
lemma eigenvector_unique_of_connected {A : Matrix n n ℝ}
    (hA_symm : ∀ i j, A i j = A j i) (hA_nn : ∀ i j, 0 ≤ A i j)
    (hA_conn : SimpleGraph.Connected (supportGraph A hA_symm))
    (μ : ℝ) (v w : n → ℝ) (hv_pos : ∀ i, 0 < v i)
    (hv_eig : A.mulVec v = μ • v) (hw_eig : A.mulVec w = μ • w) :
    ∃ c : ℝ, w = c • v := by
  let ratios := fun i => w i / v i
  let t := Finset.inf' Finset.univ Finset.univ_nonempty ratios
  use t
  have h_diff_nn : ∀ k, 0 ≤ (w - t • v) k := by
    intro k
    simp only [Pi.sub_apply, Pi.smul_apply, smul_eq_mul]
    have hk : t ≤ ratios k := Finset.inf'_le ratios (Finset.mem_univ k)
    rw [sub_nonneg]
    have h_mul : t * v k ≤ (w k / v k) * v k := mul_le_mul_of_nonneg_right hk (le_of_lt (hv_pos k))
    rwa [div_mul_cancel₀ _ (ne_of_gt (hv_pos k))] at h_mul
  have h_diff_eig : A.mulVec (w - t • v) = μ • (w - t • v) := by
    rw [mulVec_sub, mulVec_smul, hw_eig, hv_eig, smul_sub, smul_comm]
  by_cases h_diff_zero : w - t • v = 0
  · exact sub_eq_zero.mp h_diff_zero
  · exfalso
    obtain ⟨i₀, _, hi₀⟩ := Finset.exists_mem_eq_inf' Finset.univ_nonempty ratios
    have h_min_achieved : (w - t • v) i₀ = 0 := by
      simp only [Pi.sub_apply, Pi.smul_apply, smul_eq_mul]
      have ht_eq : t = w i₀ / v i₀ := hi₀
      rw [ht_eq, div_mul_cancel₀ _ (ne_of_gt (hv_pos i₀)), sub_self]
    have h_all_zero : ∀ k, (w - t • v) k = 0 := by
      intro k
      have h_reach : SimpleGraph.Reachable (supportGraph A hA_symm) i₀ k := hA_conn.preconnected i₀ k
      obtain ⟨w_walk⟩ := h_reach
      exact eq_zero_of_walk_of_eigenvector hA_symm hA_nn (w - t • v) h_diff_nn μ h_diff_eig w_walk h_min_achieved
    have h_diff_zero_again : w - t • v = 0 := by ext k; exact h_all_zero k
    exact h_diff_zero h_diff_zero_again


/-- An eigenvector of a strictly positive matrix corresponding to a positive eigenvalue has constant sign. -/
lemma eigenvector_constant_sign_of_pos {B : Matrix n n ℝ} (hB : ∀ i j, 0 < B i j)
    (μ : ℝ) (hμ : 0 < μ) (w : n → ℝ) (hw_nonzero : w ≠ 0)
    (hw_eig : B.mulVec w = μ • w) (h_abs_eig : B.mulVec (|w|) = μ • (|w|)) :
    (∀ i, 0 < w i) ∨ (∀ i, w i < 0) := by
  let z : n → ℝ := |w| - w
  have hz_nn : ∀ i, 0 ≤ z i := fun i => sub_nonneg.mpr (le_abs_self (w i))
  have hz_eig : B.mulVec z = μ • z := by
    rw [mulVec_sub, h_abs_eig, hw_eig, smul_sub]
  by_cases hz_zero : z = 0
  · left
    have hw_pos_some : ∃ j, 0 < w j := by
      by_contra h_all
      push_neg at h_all
      have hw_zero : w = 0 := by
        ext i
        have hz_i : z i = 0 := congr_fun hz_zero i
        have hw_abs : |w i| = w i := eq_of_sub_eq_zero hz_i
        have h_nonpos : w i ≤ 0 := h_all i
        exact le_antisymm h_nonpos (by rw [←hw_abs]; exact abs_nonneg _)
      exact hw_nonzero hw_zero
    have hw_eq_abs : w = |w| := by
      ext i
      have hz_i : z i = 0 := by rw [hz_zero]; rfl
      exact eq_of_sub_eq_zero hz_i |>.symm
    have h_B_w_pos : ∀ i, 0 < (B.mulVec w) i := by
      intro i
      dsimp [mulVec, dotProduct]
      have h_nn : ∀ j ∈ Finset.univ, 0 ≤ B i j * w j := by
        intro j _
        have hw_nn_j : 0 ≤ w j := by rw [hw_eq_abs]; exact abs_nonneg _
        exact mul_nonneg (le_of_lt (hB i j)) hw_nn_j
      obtain ⟨j, hj_pos⟩ := hw_pos_some
      have h_pos : 0 < B i j * w j := mul_pos (hB i j) hj_pos
      exact Finset.sum_pos' h_nn ⟨j, Finset.mem_univ j, h_pos⟩
    intro i
    have := h_B_w_pos i
    rw [hw_eig] at this
    exact pos_of_mul_pos_right this (le_of_lt hμ)
  · right
    have hz_pos_some : ∃ j, 0 < z j := by
      by_contra h_all
      push_neg at h_all
      apply hz_zero
      ext i
      exact le_antisymm (h_all i) (hz_nn i)
    have h_B_z_pos : ∀ i, 0 < (B.mulVec z) i := by
      intro i
      dsimp [mulVec, dotProduct]
      have h_nn : ∀ j ∈ Finset.univ, 0 ≤ B i j * z j := by
        intro j _
        exact mul_nonneg (le_of_lt (hB i j)) (hz_nn j)
      obtain ⟨j, hj_pos⟩ := hz_pos_some
      have h_pos : 0 < B i j * z j := mul_pos (hB i j) hj_pos
      exact Finset.sum_pos' h_nn ⟨j, Finset.mem_univ j, h_pos⟩
    intro i
    have := h_B_z_pos i
    rw [hz_eig] at this
    have hz_i_pos := pos_of_mul_pos_right this (le_of_lt hμ)
    have : |w i| - w i > 0 := hz_i_pos
    by_cases hwi : 0 ≤ w i
    · rw [abs_of_nonneg hwi] at this
      linarith
    · exact not_le.mp hwi


/-- The absolute value of an eigenvector is also an eigenvector for a non-negative symmetric matrix. -/
lemma abs_eigenvector_of_symm {B : Matrix n n ℝ} (hB_symm : ∀ i j, B i j = B j i)
    (hB_nn : ∀ i j, 0 ≤ B i j)
    (μ : ℝ) (hμ_pos : 0 < μ) (v : n → ℝ) (hv_pos : ∀ i, 0 < v i) (hv_eig : B.mulVec v = μ • v)
    (w : n → ℝ) (hw_eig : B.mulVec w = μ • w) :
    B.mulVec (|w|) = μ • (|w|) := by
  let abs_w := fun i => |w i|
  let u := fun i => (B.mulVec abs_w) i - μ * abs_w i
  have hu_nn : ∀ i, 0 ≤ u i := by
    intro i
    dsimp [u, abs_w, mulVec, dotProduct]
    rw [sub_nonneg]
    have hw_eq : μ * w i = ∑ j, B i j * w j := by
      have : (B.mulVec w) i = μ * w i := by rw [hw_eig, Pi.smul_apply, smul_eq_mul]
      exact this.symm
    have hw_abs : μ * |w i| = |μ * w i| := by
      rw [abs_mul, abs_of_pos hμ_pos]
    rw [hw_abs, hw_eq]
    exact le_trans (Finset.abs_sum_le_sum_abs _ _) (Finset.sum_le_sum fun j _ => by
      rw [abs_mul, abs_of_nonneg (hB_nn i j)])
  have h_dot : dotProduct v u = 0 := by
    dsimp [u, abs_w, mulVec, dotProduct]
    have h1 : ∑ i, v i * (∑ j, B i j * |w j| - μ * |w i|) = 
              ∑ i, v i * (∑ j, B i j * |w j|) - ∑ i, v i * (μ * |w i|) := by
      rw [←Finset.sum_sub_distrib]
      apply Finset.sum_congr rfl
      intro i _
      rw [mul_sub]
    rw [h1]
    have h2 : ∑ i, v i * (∑ j, B i j * |w j|) = ∑ j, (∑ i, v i * B i j) * |w j| := by
      have h2a : ∑ i, v i * (∑ j, B i j * |w j|) = ∑ i, ∑ j, v i * (B i j * |w j|) := by
        apply Finset.sum_congr rfl
        intro i _
        rw [Finset.mul_sum]
      have h2b : ∑ i, ∑ j, v i * (B i j * |w j|) = ∑ j, ∑ i, v i * (B i j * |w j|) := Finset.sum_comm
      have h2c : ∑ j, ∑ i, v i * (B i j * |w j|) = ∑ j, (∑ i, v i * B i j) * |w j| := by
        apply Finset.sum_congr rfl
        intro j _
        have h_assoc : ∑ i, v i * (B i j * |w j|) = ∑ i, (v i * B i j) * |w j| := by
          apply Finset.sum_congr rfl
          intro i _
          ring
        rw [h_assoc, ←Finset.sum_mul]
      rw [h2a, h2b, h2c]
    rw [h2]
    have h3 : ∀ j, ∑ i, v i * B i j = μ * v j := by
      intro j
      have : ∑ i, B j i * v i = μ * v j := by
        have h_eig := congr_fun hv_eig j
        exact h_eig
      rw [←this]
      apply Finset.sum_congr rfl
      intro i _
      rw [hB_symm j i, mul_comm]
    have h4 : ∑ j, (μ * v j) * |w j| - ∑ i, v i * (μ * |w i|) = 0 := by
      have : ∑ j, (μ * v j) * |w j| = ∑ i, v i * (μ * |w i|) := by
        apply Finset.sum_congr rfl
        intro x _
        ring
      rw [this, sub_self]
    have h_final : ∑ j, (∑ i, v i * B i j) * |w j| - ∑ i, v i * (μ * |w i|) = 0 := by
      have : ∑ j, (∑ i, v i * B i j) * |w j| = ∑ j, (μ * v j) * |w j| := by
        apply Finset.sum_congr rfl
        intro j _
        rw [h3 j]
      rw [this, h4]
    exact h_final
  have hu_zero : ∀ i, u i = 0 := by
    intro i
    by_contra h_nz
    have h_pos : 0 < u i := lt_of_le_of_ne (hu_nn i) (Ne.symm h_nz)
    have h_dot_pos : 0 < dotProduct v u := by
      apply Finset.sum_pos'
      · intro j _
        exact mul_nonneg (le_of_lt (hv_pos j)) (hu_nn j)
      · use i, Finset.mem_univ i
        exact mul_pos (hv_pos i) h_pos
    have h_dot_zero : dotProduct v u = 0 := h_dot
    rw [h_dot_zero] at h_dot_pos
    exact lt_irrefl 0 h_dot_pos
  ext i
  have := hu_zero i
  dsimp [u, abs_w] at this
  rw [Pi.smul_apply, smul_eq_mul]
  exact eq_of_sub_eq_zero this

/-- The Perron-Frobenius eigenvalue dominates all other eigenvalues for a non-negative symmetric matrix. -/
lemma eigenvalue_le_of_symm_of_nonneg {B : Matrix n n ℝ} (hB_symm : ∀ i j, B i j = B j i)
    (hB_nn : ∀ i j, 0 ≤ B i j)
    (μ : ℝ) (v : n → ℝ) (hv_pos : ∀ i, 0 < v i) (hv_eig : B.mulVec v = μ • v)
    (lam : ℝ) (w : n → ℝ) (hw_nonzero : w ≠ 0) (hw_eig : B.mulVec w = lam • w) :
    lam ≤ μ := by
  let abs_w := fun i => |w i|
  have h_w_abs_nn : ∀ i, 0 ≤ abs_w i := fun i => abs_nonneg _
  have h_ineq : ∀ i, |lam| * abs_w i ≤ (B.mulVec abs_w) i := by
    intro i
    have h_eq : lam * w i = (B.mulVec w) i := by rw [hw_eig, Pi.smul_apply, smul_eq_mul]
    have h_abs : |lam| * abs_w i = |(B.mulVec w) i| := by
      rw [←abs_mul, h_eq]
    rw [h_abs]
    dsimp [mulVec, dotProduct]
    exact le_trans (Finset.abs_sum_le_sum_abs _ _) (Finset.sum_le_sum fun j _ => by
      rw [abs_mul, abs_of_nonneg (hB_nn i j)])
  have h_dot1 : dotProduct v (fun i => |lam| * abs_w i) ≤ dotProduct v (B.mulVec abs_w) := by
    apply Finset.sum_le_sum
    intro i _
    exact mul_le_mul_of_nonneg_left (h_ineq i) (le_of_lt (hv_pos i))
  have h_dot2 : dotProduct v (B.mulVec abs_w) = μ * dotProduct v abs_w := by
    have h_symm_dot : dotProduct v (B.mulVec abs_w) = dotProduct (B.mulVec v) abs_w := by
      dsimp [mulVec, dotProduct]
      have : ∑ i, v i * ∑ j, B i j * abs_w j = ∑ i, ∑ j, v i * B i j * abs_w j := by
        apply Finset.sum_congr rfl
        intro i _
        rw [Finset.mul_sum]
        apply Finset.sum_congr rfl
        intro j _
        ring
      rw [this]
      have : ∑ i, ∑ j, v i * B i j * abs_w j = ∑ j, ∑ i, B j i * v i * abs_w j := by
        rw [Finset.sum_comm]
        apply Finset.sum_congr rfl
        intro j _
        apply Finset.sum_congr rfl
        intro i _
        rw [hB_symm i j]
        ring
      rw [this]
      apply Finset.sum_congr rfl
      intro i _
      rw [←Finset.sum_mul]
    rw [h_symm_dot, hv_eig]
    dsimp [dotProduct]
    have h_assoc : ∑ i, (μ * v i) * abs_w i = ∑ i, μ * (v i * abs_w i) := by
      apply Finset.sum_congr rfl
      intro i _
      ring
    rw [h_assoc, ←Finset.mul_sum]
  have h_dot3 : dotProduct v (fun i => |lam| * abs_w i) = |lam| * dotProduct v abs_w := by
    dsimp [dotProduct]
    have h_assoc : ∑ i, v i * (|lam| * abs_w i) = ∑ i, |lam| * (v i * abs_w i) := by
      apply Finset.sum_congr rfl
      intro i _
      ring
    rw [h_assoc, ←Finset.mul_sum]
  rw [h_dot3, h_dot2] at h_dot1
  have h_dot_pos : 0 < dotProduct v abs_w := by
    apply Finset.sum_pos'
    · intro j _
      exact mul_nonneg (le_of_lt (hv_pos j)) (h_w_abs_nn j)
    · have hw_pos_some : ∃ j, 0 < abs_w j := by
        by_contra h_all
        push_neg at h_all
        have hw_zero : w = 0 := by
          ext i
          have : abs_w i ≤ 0 := h_all i
          have : abs_w i = 0 := le_antisymm this (h_w_abs_nn i)
          exact abs_eq_zero.mp this
        exact hw_nonzero hw_zero
      obtain ⟨j, hj⟩ := hw_pos_some
      use j, Finset.mem_univ j
      exact mul_pos (hv_pos j) hj
  have h_le : |lam| ≤ μ := (mul_le_mul_right h_dot_pos).mp h_dot1
  exact le_trans (le_abs_self lam) h_le
/-- A real Hermitian matrix is symmetric. -/
lemma IsHermitian.transpose_eq {n : Type*} [Fintype n] [DecidableEq n]
    (A : Matrix n n ℝ) (h : A.IsHermitian) : Aᵀ = A := by
  have hH : Aᴴ = A := h
  simp only [Matrix.conjTranspose, Matrix.transpose_map, star_trivial] at hH
  exact hH

/-- The dot product commutes with matrix multiplication for a symmetric matrix. -/
lemma dotProduct_mulVec_of_symm {n : Type*} [Fintype n] [DecidableEq n]
    (A : Matrix n n ℝ) (h : A.IsHermitian) (u v : n → ℝ) :
    dotProduct u (A.mulVec v) = dotProduct (A.mulVec u) v := by
  rw [dotProduct_mulVec]
  have hAt : Aᵀ = A := IsHermitian.transpose_eq A h
  suffices u ᵥ* A = A *ᵥ u by rw [this]
  conv_lhs => rw [← transpose_transpose A]
  rw [vecMul_transpose, hAt]

/-- The inner product on Euclidean space coincides with the standard dot product. -/
lemma euclideanSpace_inner_eq_dotProduct {n : Type*} [Fintype n] [DecidableEq n]
    (u : EuclideanSpace ℝ n) (w : n → ℝ) :
    ⟪u, (EuclideanSpace.equiv n ℝ).symm w⟫_ℝ = dotProduct (u : n → ℝ) w := by
  simp only [EuclideanSpace.inner_eq_star_dotProduct, dotProduct]
  apply Finset.sum_congr rfl
  intro i _
  simp only [star_trivial, EuclideanSpace.equiv]
  congr 1

/-- Bound on eigenvalues shifted by the identity matrix, using the Hermitian spectral theorem. -/
lemma eigenvalue_le_maxEig_add_one {n : Type*} [Fintype n] [DecidableEq n] [Nonempty n]
    {A : Matrix n n ℝ} (hA_herm : A.IsHermitian)
    {μ_B : ℝ} {v_B : n → ℝ}
    (hA_vB : A.mulVec v_B = (μ_B - 1) • v_B)
    (h_vB_neq : v_B ≠ 0)
    (max_eig : ℝ) (h_max : ∀ k, hA_herm.eigenvalues k ≤ max_eig) :
    μ_B ≤ max_eig + 1 := by
  let eig := hA_herm.eigenvalues
  let evec := hA_herm.eigenvectorBasis
  let v_E : EuclideanSpace ℝ n := (EuclideanSpace.equiv n ℝ).symm v_B
  let c := fun k => evec.repr v_E k
  have h_c_inner : ∀ k, c k = ⟪evec k, v_E⟫_ℝ := fun k => evec.repr_apply_apply v_E k
  have h_inner_dot : ∀ k, ⟪evec k, v_E⟫_ℝ = dotProduct (evec k : n → ℝ) v_B :=
    fun k => euclideanSpace_inner_eq_dotProduct (evec k) v_B
  have smul_dot : ∀ (r : ℝ) (u v : n → ℝ), dotProduct u (r • v) = r * dotProduct u v := by
    intros; simp [dotProduct, Finset.mul_sum, mul_comm, mul_left_comm]
  have dot_smul : ∀ (r : ℝ) (u v : n → ℝ), dotProduct (r • u) v = r * dotProduct u v := by
    intros; simp [dotProduct, Finset.mul_sum, mul_assoc]
  have h_dot : ∀ k, (μ_B - 1) * c k = eig k * c k := by
    intro k
    rw [h_c_inner, h_inner_dot]
    have step1 : dotProduct (evec k : n → ℝ) (A.mulVec v_B) =
                  (μ_B - 1) * dotProduct (evec k : n → ℝ) v_B := by
      rw [hA_vB]; exact smul_dot (μ_B - 1) (evec k : n → ℝ) v_B
    have step2 : dotProduct (evec k : n → ℝ) (A.mulVec v_B) =
                  eig k * dotProduct (evec k : n → ℝ) v_B := by
      rw [dotProduct_mulVec_of_symm A hA_herm]
      have h3 : A.mulVec (evec k : n → ℝ) = eig k • (evec k : n → ℝ) :=
        hA_herm.mulVec_eigenvectorBasis k
      rw [h3]
      exact dot_smul (eig k) (evec k : n → ℝ) v_B
    linarith [step1.symm.trans step2]
  have h_some_nonzero : ∃ k, c k ≠ 0 := by
    by_contra h; push_neg at h
    have hv_E_zero : v_E = 0 := evec.repr.map_eq_zero_iff.mp (by ext k; exact h k)
    exact h_vB_neq ((EuclideanSpace.equiv n ℝ).symm.injective
      (hv_E_zero.trans (map_zero _).symm))
  obtain ⟨k, hk⟩ := h_some_nonzero
  linarith [h_max k, (mul_right_cancel₀ hk (h_dot k)).symm]


end Matrix
