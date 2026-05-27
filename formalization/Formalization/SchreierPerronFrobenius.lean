import Mathlib.Data.Matrix.Basic
import Mathlib.LinearAlgebra.Matrix.Spectrum
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Group.Abs
import Formalization.SchreierConnectivity
import Formalization.SchreierSpectral
import SpectralPositivity.Matrix.PerronFrobenius

open Matrix
open Classical

namespace SchreierSpectral

variable {d : ℕ} (hd : d ≥ 3)

variable {n : Type _} [Fintype n] [DecidableEq n] [Nonempty n]

lemma matrix_pow_pos_of_walk {A : Matrix n n ℝ}
    (hA_symm : ∀ i j, A i j = A j i) (hA_nn : ∀ i j, 0 ≤ A i j)
    {i j : n} (w : SimpleGraph.Walk (SchreierSpectral.supportGraph A hA_symm) i j) :
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
      have hA_nn_pow : (A ^ w_rest.length).Nonneg := Matrix.Nonneg.pow hA_nn _
      exact hA_nn_pow _ _
    exact Finset.sum_pos' h_nonneg ⟨v, Finset.mem_univ v, h_term⟩

lemma B_matrix_pow_ge_A_pow {A : Matrix n n ℝ} (hA_nn : ∀ i j, 0 ≤ A i j) (k : ℕ) :
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
    have h3 : 0 ≤ (A ^ k) l j := Matrix.Nonneg.pow hA_nn k l j
    have hA1_nn : ∀ x y, 0 ≤ (A + 1) x y := fun x y => by
      by_cases h : x = y
      · rw [h, add_apply, one_apply_eq]
        exact add_nonneg (hA_nn y y) zero_le_one
      · rw [add_apply, one_apply_ne h, add_zero]
        exact hA_nn x y
    exact mul_le_mul h1 h2 h3 (hA1_nn i l)

lemma B_matrix_isIrreducible : Matrix.IsIrreducible (realWeightedMatrix hd + 1) := by
  have h_nn : ∀ i j, 0 ≤ realWeightedMatrix hd i j := weightedMatrix_nonneg hd
  have h_symm : ∀ i j, realWeightedMatrix hd i j = realWeightedMatrix hd j i := realWeightedMatrix_symm hd
  refine ⟨fun i j => add_nonneg (h_nn i j) (by by_cases h : i = j <;> simp [h]), ?_, ?_⟩
  · intro i j
    have h_conn := weighted_support_connected hd
    have h_reach := h_conn.preconnected i j
    obtain ⟨w⟩ := h_reach
    by_cases hij : i = j
    · use 1
      refine ⟨by norm_num, ?_⟩
      rw [hij, pow_one, add_apply, one_apply_eq]
      exact add_pos_of_nonneg_of_pos (h_nn j j) zero_lt_one
    · use w.length
      refine ⟨?_, ?_⟩
      · have : 0 ≠ w.length := by
          intro h_len
          have : w.length = 0 := h_len.symm
          have heq := SimpleGraph.Walk.eq_of_length_eq_zero this
          exact hij heq
        exact Nat.pos_of_ne_zero this.symm
      · have h1 : 0 < (realWeightedMatrix hd ^ w.length) i j := matrix_pow_pos_of_walk h_symm h_nn w
        have h2 : (realWeightedMatrix hd ^ w.length) i j ≤ ((realWeightedMatrix hd + 1) ^ w.length) i j :=
          B_matrix_pow_ge_A_pow h_nn w.length i j
        exact lt_of_lt_of_le h1 h2
  · use 0
    have : ((realWeightedMatrix hd + 1) : Matrix _ _ ℝ) 0 0 = realWeightedMatrix hd 0 0 + 1 := by
      rw [add_apply, one_apply_eq]
    rw [this]
    exact add_pos_of_nonneg_of_pos (h_nn 0 0) zero_lt_one



lemma eigenvector_constant_sign_matrix {B : Matrix n n ℝ} (hB : ∀ i j, 0 < B i j)
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
    have h_B_w_pos := Matrix.mulVec_pos_of_allPos hB (fun i => by rw [hw_eq_abs]; exact abs_nonneg _) hw_pos_some
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
    have h_B_z_pos := Matrix.mulVec_pos_of_allPos hB hz_nn hz_pos_some
    intro i
    have := h_B_z_pos i
    rw [hz_eig] at this
    have hz_i_pos := pos_of_mul_pos_right this (le_of_lt hμ)
    have : |w i| - w i > 0 := hz_i_pos
    by_cases hwi : 0 ≤ w i
    · rw [abs_of_nonneg hwi] at this
      linarith
    · exact not_le.mp hwi


lemma abs_eigenvector_of_symmetric {B : Matrix n n ℝ} (hB_symm : ∀ i j, B i j = B j i)
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


lemma pf_eigenvalue_is_max {B : Matrix n n ℝ} (hB_symm : ∀ i j, B i j = B j i)
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


lemma eigenvector_zero_of_walk {A : Matrix n n ℝ}
    (hA_symm : ∀ i j, A i j = A j i) (hA_nn : ∀ i j, 0 ≤ A i j)
    (u : n → ℝ) (hu_nn : ∀ i, 0 ≤ u i)
    (lam : ℝ) (hu_eig : A.mulVec u = lam • u)
    {i j : n}
    (w : SimpleGraph.Walk (SchreierSpectral.supportGraph A hA_symm) i j) :
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

lemma connected_eigenvector_unique {A : Matrix n n ℝ}
    (hA_symm : ∀ i j, A i j = A j i) (hA_nn : ∀ i j, 0 ≤ A i j)
    (hA_conn : SimpleGraph.Connected (SchreierSpectral.supportGraph A hA_symm))
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
      have h_reach : SimpleGraph.Reachable (SchreierSpectral.supportGraph A hA_symm) i₀ k := hA_conn.preconnected i₀ k
      obtain ⟨w_walk⟩ := h_reach
      exact eigenvector_zero_of_walk hA_symm hA_nn (w - t • v) h_diff_nn μ h_diff_eig w_walk h_min_achieved
    have h_diff_zero_again : w - t • v = 0 := by ext k; exact h_all_zero k
    exact h_diff_zero h_diff_zero_again

end SchreierSpectral





-- For ℝ, IsHermitian means Aᵀ = A
private lemma hermitian_real_transpose_eq' {n : Type*} [Fintype n] [DecidableEq n]
    (A : Matrix n n ℝ) (h : A.IsHermitian) : Aᵀ = A := by
  have hH : Aᴴ = A := h
  simp only [Matrix.conjTranspose, Matrix.transpose_map, star_trivial] at hH
  exact hH

-- Symmetric swap: u ⬝ᵥ (A *ᵥ v) = (A *ᵥ u) ⬝ᵥ v for symmetric A
private lemma dotProduct_symm_of_hermitian' {n : Type*} [Fintype n] [DecidableEq n]
    (A : Matrix n n ℝ) (h : A.IsHermitian) (u v : n → ℝ) :
    dotProduct u (A.mulVec v) = dotProduct (A.mulVec u) v := by
  rw [dotProduct_mulVec]
  have hAt : Aᵀ = A := hermitian_real_transpose_eq' A h
  suffices u ᵥ* A = A *ᵥ u by rw [this]
  conv_lhs => rw [← transpose_transpose A]
  rw [vecMul_transpose, hAt]

-- EuclideanSpace ℝ n inner = dotProduct on underlying n → ℝ
private lemma euclidean_inner_eq_dotProduct'' {n : Type*} [Fintype n] [DecidableEq n]
    (u : EuclideanSpace ℝ n) (w : n → ℝ) :
    ⟪u, (EuclideanSpace.equiv n ℝ).symm w⟫_ℝ = dotProduct (u : n → ℝ) w := by
  simp only [EuclideanSpace.inner_eq_star_dotProduct, dotProduct]
  apply Finset.sum_congr rfl
  intro i _
  simp only [star_trivial, EuclideanSpace.equiv]
  congr 1

-- If μ_B - 1 is an eigenvalue of A (via eigenvector v_B), then μ_B ≤ max_eig + 1
private lemma mu_B_le_max_eig' {n : Type*} [Fintype n] [DecidableEq n] [Nonempty n]
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
    fun k => euclidean_inner_eq_dotProduct'' (evec k) v_B
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
      rw [dotProduct_symm_of_hermitian' A hA_herm]
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


namespace SchreierSpectral

variable {d : ℕ} (hd : d ≥ 3)

lemma isPerronFrobeniusMax_realWeightedMatrix :
    IsPerronFrobeniusMax (realWeightedMatrix hd) (realWeightedMatrix_isHermitian hd) := by
  let A := realWeightedMatrix hd
  let B := A + 1
  have hB_irr := B_matrix_isIrreducible hd
  have h_pf := perron_frobenius hB_irr
  obtain ⟨μ_B, v_B, hμ_pos, hv_pos, hv_eig⟩ := h_pf
  have hB_symm : ∀ i j, B i j = B j i := by
    intro i j
    simp only [B, add_apply, one_apply]
    change realWeightedMatrix hd i j + _ = realWeightedMatrix hd j i + _
    rw [realWeightedMatrix_symm hd i j]
    by_cases h : i = j <;> simp [h, eq_comm]
  have hB_nn : ∀ i j, 0 ≤ B i j := fun i j =>
    add_nonneg (weightedMatrix_nonneg hd i j) (by by_cases h : i = j <;> simp [h])
  have h_add_eig : ∀ {lam : ℝ} {w : ZMod (2^(d-2)) → ℝ},
      A.mulVec w = lam • w → B.mulVec w = (lam + 1) • w := by
    intro lam w h; ext k; dsimp [B, mulVec, dotProduct]
    have h1 : ∑ l, (A k l + (1:Matrix _ _ ℝ) k l) * w l =
                ∑ l, A k l * w l + ∑ l, (1:Matrix _ _ ℝ) k l * w l := by
      rw [←Finset.sum_add_distrib]; apply Finset.sum_congr rfl; intro _ _; ring
    rw [h1]
    have h2 : ∑ l, A k l * w l = lam * w k := by
      have : (A.mulVec w) k = lam * w k := by rw [h, Pi.smul_apply, smul_eq_mul]
      exact this
    rw [h2]
    have h3 : ∑ l, (1:Matrix _ _ ℝ) k l * w l = w k := by
      have : ((1:Matrix _ _ ℝ).mulVec w) k = w k := by rw [Matrix.one_mulVec]
      exact this
    rw [h3, add_mul, one_mul]
  let eig := (realWeightedMatrix_isHermitian hd).eigenvalues
  let evec := (realWeightedMatrix_isHermitian hd).eigenvectorBasis
  let s := Finset.univ.image eig
  have hs_nonempty : s.Nonempty := ⟨eig 0, Finset.mem_image_of_mem eig (Finset.mem_univ 0)⟩
  let max_eig := Finset.max' s hs_nonempty
  obtain ⟨i_max, _, hi_max⟩ : ∃ i ∈ Finset.univ, eig i = max_eig :=
    Finset.mem_image.mp (Finset.max'_mem s hs_nonempty)
  use i_max; intro j; refine ⟨?_, ?_, ?_⟩
  · have h_le : (realWeightedMatrix_isHermitian hd).eigenvalues j ≤ max_eig :=
      Finset.le_max' s (eig j) (Finset.mem_image_of_mem eig (Finset.mem_univ j))
    have h_eq : (realWeightedMatrix_isHermitian hd).eigenvalues i_max = max_eig := hi_max
    rw [h_eq]
    exact h_le
  · intro hj_eq
    have heq : (realWeightedMatrix_isHermitian hd).eigenvalues j = max_eig := by 
      have h2 : (realWeightedMatrix_isHermitian hd).eigenvalues i_max = max_eig := hi_max
      rw [hj_eq]
      exact h2
    let w_i := evec i_max
    let w_j := evec j
    have hA_wi : A.mulVec w_i = max_eig • w_i := by
      have h := (realWeightedMatrix_isHermitian hd).mulVec_eigenvectorBasis i_max
      have h_eig : (realWeightedMatrix_isHermitian hd).eigenvalues i_max = max_eig := hi_max
      rw [h_eig] at h
      exact h
    have hA_wj : A.mulVec w_j = max_eig • w_j := by
      have h := (realWeightedMatrix_isHermitian hd).mulVec_eigenvectorBasis j
      have h_eig : (realWeightedMatrix_isHermitian hd).eigenvalues j = max_eig := heq
      rw [h_eig] at h
      exact h
    have hB_wi : B.mulVec w_i = (max_eig + 1) • w_i := h_add_eig hA_wi
    have hB_wj : B.mulVec w_j = (max_eig + 1) • w_j := h_add_eig hA_wj
    have hw_i_neq : w_i ≠ 0 := by
      intro h
      have h1 : ‖w_i‖ = 0 := by rw [h, norm_zero]
      have h2 : ‖w_i‖ = 1 := (OrthonormalBasis.orthonormal evec).1 i_max
      rw [h2] at h1; norm_num at h1
    have hw_j_neq : w_j ≠ 0 := by
      intro h
      have h1 : ‖w_j‖ = 0 := by rw [h, norm_zero]
      have h2 : ‖w_j‖ = 1 := (OrthonormalBasis.orthonormal evec).1 j
      rw [h2] at h1; norm_num at h1
    have h_le := pf_eigenvalue_is_max hB_symm hB_nn μ_B v_B hv_pos hv_eig
                   (max_eig + 1) w_i hw_i_neq hB_wi
    -- Derive A *ᵥ v_B = (μ_B - 1) • v_B
    have hA_vB : A.mulVec v_B = (μ_B - 1) • v_B := by
      ext k
      have hk := congr_fun hv_eig k
      dsimp [B, mulVec, dotProduct] at hk ⊢
      have h1 : ∑ l, (A k l + (1:Matrix _ _ ℝ) k l) * v_B l =
                  ∑ l, A k l * v_B l + ∑ l, (1:Matrix _ _ ℝ) k l * v_B l := by
        rw [←Finset.sum_add_distrib]; apply Finset.sum_congr rfl; intro _ _; ring
      rw [h1] at hk
      have h2 : ∑ l, (1:Matrix _ _ ℝ) k l * v_B l = v_B k := congr_fun (Matrix.one_mulVec v_B) k
      rw [h2] at hk
      try simp only [Pi.smul_apply, smul_eq_mul] at hk ⊢
      linarith
    have h_vB_neq : v_B ≠ 0 := by
      intro h; have := hv_pos 0; rw [h] at this; exact lt_irrefl 0 this
    have h_max_bound : ∀ k, eig k ≤ max_eig := fun k =>
      Finset.le_max' s (eig k) (Finset.mem_image_of_mem eig (Finset.mem_univ k))
    have h_mu_le : μ_B ≤ max_eig + 1 :=
      mu_B_le_max_eig' (realWeightedMatrix_isHermitian hd) hA_vB h_vB_neq max_eig h_max_bound
    have h_eq : μ_B = max_eig + 1 := le_antisymm h_mu_le h_le
    rw [h_eq] at hv_eig
    have hA_symm := realWeightedMatrix_symm hd
    have hA_nn := weightedMatrix_nonneg hd
    have hA_conn := weighted_support_connected hd
    have hA_vB_max : A.mulVec v_B = max_eig • v_B := by
      have : μ_B - 1 = max_eig := by linarith
      rw [this] at hA_vB
      exact hA_vB
    have hc_i := connected_eigenvector_unique hA_symm hA_nn hA_conn max_eig v_B w_i hv_pos hA_vB_max hA_wi
    have hc_j := connected_eigenvector_unique hA_symm hA_nn hA_conn max_eig v_B w_j hv_pos hA_vB_max hA_wj
    obtain ⟨ci, hi⟩ := hc_i
    obtain ⟨cj, hj⟩ := hc_j
    by_contra h_neq
    have hcj_neq : cj ≠ 0 := by
      intro h
      rw [h, zero_smul] at hj
      exact hw_j_neq hj
    have h_eq_vec : (evec i_max : EuclideanSpace ℝ _) = (ci / cj) • (evec j : EuclideanSpace ℝ _) := by
      ext k
      have hik := congr_fun hi k
      have hjk := congr_fun hj k
      change w_i k = (ci / cj) * w_j k
      
      calc
      w_i k = ci * v_B k := by rw [hik, Pi.smul_apply, smul_eq_mul]
        _ = ci * (w_j k / cj) := by
          have h_comm : cj * v_B k = v_B k * cj := mul_comm cj (v_B k)
          rw [hjk, Pi.smul_apply, smul_eq_mul, h_comm, mul_div_cancel_right₀ (v_B k) hcj_neq]
        _ = (ci / cj) * w_j k := by ring
    let b := evec.toBasis
    have h_eq_b : b i_max = (ci / cj) • b j := h_eq_vec
    have h1 : b.repr (b i_max) i_max = 1 := by rw [Basis.repr_self]; exact Finsupp.single_eq_same
    have h2 : b.repr (b j) i_max = 0 := by rw [Basis.repr_self]; exact Finsupp.single_eq_of_ne h_neq
    have h3 : b.repr ((ci / cj) • b j) i_max = 0 := by rw [LinearEquiv.map_smul, Finsupp.smul_apply, smul_eq_mul, h2, mul_zero]
    rw [h_eq_b] at h1
    rw [h3] at h1
    norm_num at h1
  · let w_i := evec i_max
    have hA_wi : A.mulVec w_i = max_eig • w_i := by
      have h := (realWeightedMatrix_isHermitian hd).mulVec_eigenvectorBasis i_max
      have h_eig : (realWeightedMatrix_isHermitian hd).eigenvalues i_max = max_eig := hi_max
      rw [h_eig] at h
      exact h
    have hB_wi : B.mulVec w_i = (max_eig + 1) • w_i := h_add_eig hA_wi
    have hw_i_neq : w_i ≠ 0 := by
      intro h
      have h1 : ‖w_i‖ = 0 := by rw [h, norm_zero]
      have h2 : ‖(evec i_max : EuclideanSpace ℝ _)‖ = 1 := (OrthonormalBasis.orthonormal evec).1 i_max
      have h3 : ‖w_i‖ = ‖(evec i_max : EuclideanSpace ℝ _)‖ := rfl
      rw [h3] at h1
      rw [h2] at h1
      norm_num at h1
    have hA_symm := realWeightedMatrix_symm (hd := hd)
    have hA_nn := weightedMatrix_nonneg (hd := hd)
    have hA_conn := weighted_support_connected hd
    have hA_vB : A.mulVec v_B = (μ_B - 1) • v_B := by
      ext k
      have hk := congr_fun hv_eig k
      dsimp [B, mulVec, dotProduct] at hk ⊢
      have h1 : ∑ l, (A k l + (1:Matrix _ _ ℝ) k l) * v_B l =
                  ∑ l, A k l * v_B l + ∑ l, (1:Matrix _ _ ℝ) k l * v_B l := by
        rw [←Finset.sum_add_distrib]; apply Finset.sum_congr rfl; intro _ _; ring
      rw [h1] at hk
      have h2 : ∑ l, (1:Matrix _ _ ℝ) k l * v_B l = v_B k := congr_fun (Matrix.one_mulVec v_B) k
      rw [h2] at hk
      try simp only [Pi.smul_apply, smul_eq_mul] at hk ⊢
      linarith
    have h_vB_neq : v_B ≠ 0 := by
      intro h; have := hv_pos 0; rw [h] at this; exact lt_irrefl 0 this
    have h_max_bound : ∀ k, (realWeightedMatrix_isHermitian hd).eigenvalues k ≤ max_eig := fun k =>
      Finset.le_max' s (eig k) (Finset.mem_image_of_mem eig (Finset.mem_univ k))
    have h_le_2 := pf_eigenvalue_is_max hB_symm hB_nn μ_B v_B hv_pos hv_eig (max_eig + 1) w_i hw_i_neq hB_wi
    have h_mu_le : μ_B ≤ max_eig + 1 :=
      mu_B_le_max_eig' (realWeightedMatrix_isHermitian hd) hA_vB h_vB_neq max_eig h_max_bound
    have h_eq : μ_B = max_eig + 1 := le_antisymm h_mu_le h_le_2
    have hA_vB_max : A.mulVec v_B = max_eig • v_B := by
      have : μ_B - 1 = max_eig := by linarith
      rw [this] at hA_vB
      exact hA_vB
    have hc_i := connected_eigenvector_unique hA_symm hA_nn hA_conn max_eig v_B w_i hv_pos hA_vB_max hA_wi
    obtain ⟨ci, hi⟩ := hc_i
    have hci_neq : ci ≠ 0 := by
      intro h
      rw [h, zero_smul] at hi
      exact hw_i_neq hi
    rcases lt_trichotomy ci 0 with h_neg | h_zero | h_pos
    · right
      intro x
      have h_val := congr_fun hi x
      dsimp [w_i] at h_val
      rw [h_val]
      exact mul_neg_of_neg_of_pos h_neg (hv_pos x)
    · exact False.elim (hci_neq h_zero)
    · left
      intro x
      have h_val := congr_fun hi x
      dsimp [w_i] at h_val
      rw [h_val]
      exact mul_pos h_pos (hv_pos x)

lemma B_matrix_adj_isIrreducible : Matrix.IsIrreducible (@realAdjacencyMatrix d + 1) := by
  have h_nn : ∀ i j, 0 ≤ (@realAdjacencyMatrix d) i j := adjacencyMatrix_nonneg
  have h_symm : ∀ i j, (@realAdjacencyMatrix d) i j = (@realAdjacencyMatrix d) j i := realAdjacencyMatrix_symm
  refine ⟨fun i j => add_nonneg (h_nn i j) (by by_cases h : i = j <;> simp [h]), ?_, ?_⟩
  · intro i j
    have hd2 : d ≥ 2 := by omega
    have h_conn := adjacency_support_connected hd2
    have h_reach := h_conn.preconnected i j
    obtain ⟨w⟩ := h_reach
    by_cases hij : i = j
    · use 1
      refine ⟨by norm_num, ?_⟩
      rw [hij, pow_one, add_apply, one_apply_eq]
      exact add_pos_of_nonneg_of_pos (h_nn j j) zero_lt_one
    · use w.length
      refine ⟨?_, ?_⟩
      · have : 0 ≠ w.length := by
          intro h_len
          have : w.length = 0 := h_len.symm
          have heq := SimpleGraph.Walk.eq_of_length_eq_zero this
          exact hij heq
        exact Nat.pos_of_ne_zero this.symm
      · have h1 : 0 < (@realAdjacencyMatrix d ^ w.length) i j := matrix_pow_pos_of_walk h_symm h_nn w
        have h2 : (@realAdjacencyMatrix d ^ w.length) i j ≤ ((@realAdjacencyMatrix d + 1) ^ w.length) i j :=
          B_matrix_pow_ge_A_pow h_nn w.length i j
        exact lt_of_lt_of_le h1 h2
  · use 0
    have : ((@realAdjacencyMatrix d + 1) : Matrix _ _ ℝ) 0 0 = @realAdjacencyMatrix d 0 0 + 1 := by
      rw [add_apply, one_apply_eq]
    rw [this]
    exact add_pos_of_nonneg_of_pos (h_nn 0 0) zero_lt_one

lemma isPerronFrobeniusMax_realAdjacencyMatrix :
    IsPerronFrobeniusMax (@realAdjacencyMatrix d) (@realAdjacencyMatrix_isHermitian d) := by
  have hd2 : d ≥ 2 := by omega
  let A := @realAdjacencyMatrix d
  let B := A + 1
  have hB_irr := B_matrix_adj_isIrreducible hd
  have h_pf := perron_frobenius hB_irr
  obtain ⟨μ_B, v_B, hμ_pos, hv_pos, hv_eig⟩ := h_pf
  have hB_symm : ∀ i j, B i j = B j i := by
    intro i j
    simp only [B, add_apply, one_apply]
    change (@realAdjacencyMatrix d) i j + _ = (@realAdjacencyMatrix d) j i + _
    rw [realAdjacencyMatrix_symm i j]
    by_cases h : i = j <;> simp [h, eq_comm]
  have hB_nn : ∀ i j, 0 ≤ B i j := fun i j =>
    add_nonneg (adjacencyMatrix_nonneg i j) (by by_cases h : i = j <;> simp [h])
  have h_add_eig : ∀ {lam : ℝ} {w : ZMod (2^(d-1)) → ℝ},
      A.mulVec w = lam • w → B.mulVec w = (lam + 1) • w := by
    intro lam w h; ext k; dsimp [B, mulVec, dotProduct]
    have h1 : ∑ l, (A k l + (1:Matrix _ _ ℝ) k l) * w l =
                ∑ l, A k l * w l + ∑ l, (1:Matrix _ _ ℝ) k l * w l := by
      rw [←Finset.sum_add_distrib]; apply Finset.sum_congr rfl; intro _ _; ring
    rw [h1]
    have h2 : ∑ l, A k l * w l = lam * w k := by
      have : (A.mulVec w) k = lam * w k := by rw [h, Pi.smul_apply, smul_eq_mul]
      exact this
    rw [h2]
    have h3 : ∑ l, (1:Matrix _ _ ℝ) k l * w l = w k := by
      have : ((1:Matrix _ _ ℝ).mulVec w) k = w k := by rw [Matrix.one_mulVec]
      exact this
    rw [h3, add_mul, one_mul]
  let eig := (@realAdjacencyMatrix_isHermitian d).eigenvalues
  let evec := (@realAdjacencyMatrix_isHermitian d).eigenvectorBasis
  let s := Finset.univ.image eig
  have hs_nonempty : s.Nonempty := ⟨eig 0, Finset.mem_image_of_mem eig (Finset.mem_univ 0)⟩
  let max_eig := Finset.max' s hs_nonempty
  obtain ⟨i_max, _, hi_max⟩ : ∃ i ∈ Finset.univ, eig i = max_eig :=
    Finset.mem_image.mp (Finset.max'_mem s hs_nonempty)
  use i_max; intro j; refine ⟨?_, ?_, ?_⟩
  · have h_le : (@realAdjacencyMatrix_isHermitian d).eigenvalues j ≤ max_eig :=
      Finset.le_max' s (eig j) (Finset.mem_image_of_mem eig (Finset.mem_univ j))
    have h_eq : (@realAdjacencyMatrix_isHermitian d).eigenvalues i_max = max_eig := hi_max
    rw [h_eq]
    exact h_le
  · intro hj_eq
    have heq : (@realAdjacencyMatrix_isHermitian d).eigenvalues j = max_eig := by 
      have h2 : (@realAdjacencyMatrix_isHermitian d).eigenvalues i_max = max_eig := hi_max
      rw [hj_eq]
      exact h2
    let w_i := evec i_max
    let w_j := evec j
    have hA_wi : A.mulVec w_i = max_eig • w_i := by
      have h := (@realAdjacencyMatrix_isHermitian d).mulVec_eigenvectorBasis i_max
      have h_eig : (@realAdjacencyMatrix_isHermitian d).eigenvalues i_max = max_eig := hi_max
      rw [h_eig] at h
      exact h
    have hA_wj : A.mulVec w_j = max_eig • w_j := by
      have h := (@realAdjacencyMatrix_isHermitian d).mulVec_eigenvectorBasis j
      have h_eig : (@realAdjacencyMatrix_isHermitian d).eigenvalues j = max_eig := heq
      rw [h_eig] at h
      exact h
    have hB_wi : B.mulVec w_i = (max_eig + 1) • w_i := h_add_eig hA_wi
    have hB_wj : B.mulVec w_j = (max_eig + 1) • w_j := h_add_eig hA_wj
    have hw_i_neq : w_i ≠ 0 := by
      intro h
      have h1 : ‖w_i‖ = 0 := by rw [h, norm_zero]
      have h2 : ‖(evec i_max : EuclideanSpace ℝ _)‖ = 1 := (OrthonormalBasis.orthonormal evec).1 i_max
      have h3 : ‖w_i‖ = ‖(evec i_max : EuclideanSpace ℝ _)‖ := rfl
      rw [h3] at h1
      rw [h2] at h1
      norm_num at h1
    have hw_j_neq : w_j ≠ 0 := by
      intro h
      have h1 : ‖w_j‖ = 0 := by rw [h, norm_zero]
      have h2 : ‖(evec j : EuclideanSpace ℝ _)‖ = 1 := (OrthonormalBasis.orthonormal evec).1 j
      have h3 : ‖w_j‖ = ‖(evec j : EuclideanSpace ℝ _)‖ := rfl
      rw [h3] at h1
      rw [h2] at h1
      norm_num at h1
    have h_le := pf_eigenvalue_is_max hB_symm hB_nn μ_B v_B hv_pos hv_eig
                   (max_eig + 1) w_i hw_i_neq hB_wi
    have hA_vB : A.mulVec v_B = (μ_B - 1) • v_B := by
      ext k
      have hk := congr_fun hv_eig k
      dsimp [B, mulVec, dotProduct] at hk ⊢
      have h1 : ∑ l, (A k l + (1:Matrix _ _ ℝ) k l) * v_B l =
                  ∑ l, A k l * v_B l + ∑ l, (1:Matrix _ _ ℝ) k l * v_B l := by
        rw [←Finset.sum_add_distrib]; apply Finset.sum_congr rfl; intro _ _; ring
      rw [h1] at hk
      have h2 : ∑ l, (1:Matrix _ _ ℝ) k l * v_B l = v_B k := congr_fun (Matrix.one_mulVec v_B) k
      rw [h2] at hk
      try simp only [Pi.smul_apply, smul_eq_mul] at hk ⊢
      linarith
    have h_vB_neq : v_B ≠ 0 := by
      intro h; have := hv_pos 0; rw [h] at this; exact lt_irrefl 0 this
    have h_max_bound : ∀ k, (@realAdjacencyMatrix_isHermitian d).eigenvalues k ≤ max_eig := fun k =>
      Finset.le_max' s (eig k) (Finset.mem_image_of_mem eig (Finset.mem_univ k))
    have h_mu_le : μ_B ≤ max_eig + 1 :=
      mu_B_le_max_eig' (@realAdjacencyMatrix_isHermitian d) hA_vB h_vB_neq max_eig h_max_bound
    have h_eq : μ_B = max_eig + 1 := le_antisymm h_mu_le h_le
    rw [h_eq] at hv_eig
    have hA_symm := realAdjacencyMatrix_symm (d := d)
    have hA_nn := adjacencyMatrix_nonneg (d := d)
    have hA_conn := adjacency_support_connected hd2
    have hA_vB_max : A.mulVec v_B = max_eig • v_B := by
      have : μ_B - 1 = max_eig := by linarith
      rw [this] at hA_vB
      exact hA_vB
    have hc_i := connected_eigenvector_unique hA_symm hA_nn hA_conn max_eig v_B w_i hv_pos hA_vB_max hA_wi
    have hc_j := connected_eigenvector_unique hA_symm hA_nn hA_conn max_eig v_B w_j hv_pos hA_vB_max hA_wj
    obtain ⟨ci, hi⟩ := hc_i
    obtain ⟨cj, hj⟩ := hc_j
    by_contra h_neq
    have hcj_neq : cj ≠ 0 := by
      intro h
      rw [h, zero_smul] at hj
      exact hw_j_neq hj
    have h_eq_vec : (evec i_max : EuclideanSpace ℝ _) = (ci / cj) • (evec j : EuclideanSpace ℝ _) := by
      ext k
      have hik := congr_fun hi k
      have hjk := congr_fun hj k
      change w_i k = (ci / cj) * w_j k
      
      calc
      w_i k = ci * v_B k := by rw [hik, Pi.smul_apply, smul_eq_mul]
        _ = ci * (w_j k / cj) := by
          have h_comm : cj * v_B k = v_B k * cj := mul_comm cj (v_B k)
          rw [hjk, Pi.smul_apply, smul_eq_mul, h_comm, mul_div_cancel_right₀ (v_B k) hcj_neq]
        _ = (ci / cj) * w_j k := by ring
    let b := evec.toBasis
    have h_eq_b : b i_max = (ci / cj) • b j := h_eq_vec
    have h1 : b.repr (b i_max) i_max = 1 := by rw [Basis.repr_self]; exact Finsupp.single_eq_same
    have h2 : b.repr (b j) i_max = 0 := by rw [Basis.repr_self]; exact Finsupp.single_eq_of_ne h_neq
    have h3 : b.repr ((ci / cj) • b j) i_max = 0 := by 
      rw [LinearEquiv.map_smul, Finsupp.smul_apply, smul_eq_mul, h2, mul_zero]
    rw [h_eq_b] at h1
    rw [h3] at h1
    norm_num at h1
  · let w_i := evec i_max
    have hA_wi : A.mulVec w_i = max_eig • w_i := by
      have h := (@realAdjacencyMatrix_isHermitian d).mulVec_eigenvectorBasis i_max
      have h_eig : (@realAdjacencyMatrix_isHermitian d).eigenvalues i_max = max_eig := hi_max
      rw [h_eig] at h
      exact h
    have hB_wi : B.mulVec w_i = (max_eig + 1) • w_i := h_add_eig hA_wi
    have hw_i_neq : w_i ≠ 0 := by
      intro h
      have h1 : ‖w_i‖ = 0 := by rw [h, norm_zero]
      have h2 : ‖(evec i_max : EuclideanSpace ℝ _)‖ = 1 := (OrthonormalBasis.orthonormal evec).1 i_max
      have h3 : ‖w_i‖ = ‖(evec i_max : EuclideanSpace ℝ _)‖ := rfl
      rw [h3] at h1
      rw [h2] at h1
      norm_num at h1
    have hA_symm := realAdjacencyMatrix_symm (d := d)
    have hA_nn := adjacencyMatrix_nonneg (d := d)
    have hA_conn := adjacency_support_connected hd2
    have hA_vB : A.mulVec v_B = (μ_B - 1) • v_B := by
      ext k
      have hk := congr_fun hv_eig k
      dsimp [B, mulVec, dotProduct] at hk ⊢
      have h1 : ∑ l, (A k l + (1:Matrix _ _ ℝ) k l) * v_B l =
                  ∑ l, A k l * v_B l + ∑ l, (1:Matrix _ _ ℝ) k l * v_B l := by
        rw [←Finset.sum_add_distrib]; apply Finset.sum_congr rfl; intro _ _; ring
      rw [h1] at hk
      have h2 : ∑ l, (1:Matrix _ _ ℝ) k l * v_B l = v_B k := congr_fun (Matrix.one_mulVec v_B) k
      rw [h2] at hk
      try simp only [Pi.smul_apply, smul_eq_mul] at hk ⊢
      linarith
    have h_vB_neq : v_B ≠ 0 := by
      intro h; have := hv_pos 0; rw [h] at this; exact lt_irrefl 0 this
    have h_max_bound : ∀ k, (@realAdjacencyMatrix_isHermitian d).eigenvalues k ≤ max_eig := fun k =>
      Finset.le_max' s (eig k) (Finset.mem_image_of_mem eig (Finset.mem_univ k))
    have h_le_2 := pf_eigenvalue_is_max hB_symm hB_nn μ_B v_B hv_pos hv_eig (max_eig + 1) w_i hw_i_neq hB_wi
    have h_mu_le : μ_B ≤ max_eig + 1 :=
      mu_B_le_max_eig' (@realAdjacencyMatrix_isHermitian d) hA_vB h_vB_neq max_eig h_max_bound
    have h_eq : μ_B = max_eig + 1 := le_antisymm h_mu_le h_le_2
    have hA_vB_max : A.mulVec v_B = max_eig • v_B := by
      have : μ_B - 1 = max_eig := by linarith
      rw [this] at hA_vB
      exact hA_vB
    have hc_i := connected_eigenvector_unique hA_symm hA_nn hA_conn max_eig v_B w_i hv_pos hA_vB_max hA_wi
    obtain ⟨ci, hi⟩ := hc_i
    have hci_neq : ci ≠ 0 := by
      intro h
      rw [h, zero_smul] at hi
      exact hw_i_neq hi
    rcases lt_trichotomy ci 0 with h_neg | h_zero | h_pos
    · right
      intro x
      have h_val := congr_fun hi x
      dsimp [w_i] at h_val
      rw [h_val]
      exact mul_neg_of_neg_of_pos h_neg (hv_pos x)
    · exact False.elim (hci_neq h_zero)
    · left
      intro x
      have h_val := congr_fun hi x
      dsimp [w_i] at h_val
      rw [h_val]
      exact mul_pos h_pos (hv_pos x)

end SchreierSpectral

theorem weightedMatrix_spectral_gap_positive {d : ℕ} (hd : d ≥ 3) :
    ∃ (i : ZMod (2^(d-2))), ∀ (j : ZMod (2^(d-2))),
      (SchreierSpectral.realWeightedMatrix_isHermitian hd).eigenvalues j ≤ (SchreierSpectral.realWeightedMatrix_isHermitian hd).eigenvalues i
      ∧ ((SchreierSpectral.realWeightedMatrix_isHermitian hd).eigenvalues j = (SchreierSpectral.realWeightedMatrix_isHermitian hd).eigenvalues i → j = i)
      ∧ ((∀ x, 0 < (SchreierSpectral.realWeightedMatrix_isHermitian hd).eigenvectorBasis i x) ∨ (∀ x, (SchreierSpectral.realWeightedMatrix_isHermitian hd).eigenvectorBasis i x < 0)) := by
  exact SchreierSpectral.isPerronFrobeniusMax_realWeightedMatrix hd

theorem adjacencyMatrix_spectral_gap_positive {d : ℕ} (hd : d ≥ 3) :
    ∃ (i : ZMod (2^(d-1))), ∀ (j : ZMod (2^(d-1))),
      (SchreierSpectral.realAdjacencyMatrix_isHermitian (d := d)).eigenvalues j ≤ (SchreierSpectral.realAdjacencyMatrix_isHermitian (d := d)).eigenvalues i
      ∧ ((SchreierSpectral.realAdjacencyMatrix_isHermitian (d := d)).eigenvalues j = (SchreierSpectral.realAdjacencyMatrix_isHermitian (d := d)).eigenvalues i → j = i)
      ∧ ((∀ x, 0 < (SchreierSpectral.realAdjacencyMatrix_isHermitian (d := d)).eigenvectorBasis i x) ∨ (∀ x, (SchreierSpectral.realAdjacencyMatrix_isHermitian (d := d)).eigenvectorBasis i x < 0)) := by
  exact SchreierSpectral.isPerronFrobeniusMax_realAdjacencyMatrix hd
