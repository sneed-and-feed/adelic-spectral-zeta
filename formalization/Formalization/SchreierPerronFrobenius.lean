import Formalization.MathlibSpectral
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

lemma isIrreducible_of_connected {n : Type _} [Fintype n] [DecidableEq n] [Nonempty n]
    (A : Matrix n n ℝ) (hA_symm : ∀ i j, A i j = A j i)
    (hA_nn : ∀ i j, 0 ≤ A i j)
    (h_conn : (supportGraph A hA_symm).Connected) :
    Matrix.IsIrreducible (A + 1) := by
  refine ⟨fun i j => add_nonneg (hA_nn i j) (by by_cases h : i = j <;> simp [h]), ?_, ?_⟩
  · intro i j
    obtain ⟨w⟩ := h_conn.preconnected i j
    by_cases hij : i = j
    · use 1
      refine ⟨by norm_num, ?_⟩
      rw [hij, pow_one, add_apply, one_apply_eq]
      exact add_pos_of_nonneg_of_pos (hA_nn j j) zero_lt_one
    · use w.length
      refine ⟨?_, ?_⟩
      · have h_len_ne : 0 ≠ w.length := fun h_len => hij (SimpleGraph.Walk.eq_of_length_eq_zero h_len.symm)
        exact Nat.pos_of_ne_zero h_len_ne.symm
      · exact (pow_pos_of_walk hA_symm hA_nn w).trans_le (pow_le_add_one_pow hA_nn w.length i j)
  · let i := Classical.arbitrary n
    use i
    have : ((A + 1) : Matrix _ _ ℝ) i i = A i i + 1 := by rw [add_apply, one_apply_eq]
    rw [this]
    exact add_pos_of_nonneg_of_pos (hA_nn i i) zero_lt_one

lemma isPerronFrobeniusMax_of_connected {n : Type _} [Fintype n] [DecidableEq n] [Nonempty n]
    (A : Matrix n n ℝ) (hA_herm : A.IsHermitian)
    (hB_irr : Matrix.IsIrreducible (A + 1))
    (hA_nn : ∀ i j, 0 ≤ A i j)
    (hA_conn : (supportGraph A (symm_of_herm hA_herm)).Connected) :
    IsPerronFrobeniusMax A hA_herm := by
  let B := A + 1
  obtain ⟨μ_B, v_B, _, hv_pos, hv_eig⟩ := perron_frobenius hB_irr
  have hB_symm : ∀ i j, B i j = B j i := by
    intro i j; dsimp [B, add_apply, one_apply]; rw [symm_of_herm hA_herm i j]; by_cases h : i = j <;> simp [h, eq_comm]
  have hB_nn : ∀ i j, 0 ≤ B i j := fun i j => add_nonneg (hA_nn i j) (by by_cases h : i = j <;> simp [h])
  have h_add_eig : ∀ {lam : ℝ} {w : n → ℝ}, A.mulVec w = lam • w → B.mulVec w = (lam + 1) • w := by
    intro lam w h; ext k; dsimp [B, mulVec, dotProduct]
    have h1 : ∑ l, (A k l + (1:Matrix _ _ ℝ) k l) * w l = ∑ l, A k l * w l + ∑ l, (1:Matrix _ _ ℝ) k l * w l := by rw [←Finset.sum_add_distrib]; apply Finset.sum_congr rfl; intro _ _; ring
    rw [h1]
    have h2 : ∑ l, A k l * w l = lam * w k := by
      have : (A.mulVec w) k = lam * w k := by rw [h, Pi.smul_apply, smul_eq_mul]
      exact this
    rw [h2]
    have h3 : ∑ l, (1:Matrix _ _ ℝ) k l * w l = w k := congr_fun (Matrix.one_mulVec w) k
    rw [h3]
    ring
  let eig := hA_herm.eigenvalues
  let evec := hA_herm.eigenvectorBasis
  let s := Finset.univ.image eig
  have hs_nonempty : s.Nonempty := ⟨eig (Classical.arbitrary n), Finset.mem_image_of_mem _ (Finset.mem_univ _)⟩
  let max_eig := Finset.max' s hs_nonempty
  obtain ⟨i_max, _, hi_max⟩ : ∃ i ∈ Finset.univ, eig i = max_eig := Finset.mem_image.mp (Finset.max'_mem s hs_nonempty)
  use i_max; intro j; refine ⟨?_, ?_, ?_⟩
  · have heq : hA_herm.eigenvalues i_max = max_eig := hi_max
    rw [heq]
    exact Finset.le_max' s _ (Finset.mem_image_of_mem _ (Finset.mem_univ j))
  · intro hj_eq
    have heq : hA_herm.eigenvalues j = max_eig := hj_eq.trans hi_max
    let w_i := evec i_max; let w_j := evec j
    have heq_eig_i : hA_herm.eigenvalues i_max = max_eig := hi_max
    have hA_wi : A.mulVec w_i = max_eig • w_i := by have h := hA_herm.mulVec_eigenvectorBasis i_max; rw [heq_eig_i] at h; exact h
    have hA_wj : A.mulVec w_j = max_eig • w_j := by have h := hA_herm.mulVec_eigenvectorBasis j; rw [heq] at h; exact h
    have hB_wi : B.mulVec w_i = (max_eig + 1) • w_i := h_add_eig hA_wi
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
    have h_le := eigenvalue_le_of_symm_of_nonneg hB_symm hB_nn μ_B v_B hv_pos hv_eig (max_eig + 1) w_i hw_i_neq hB_wi
    have hA_vB : A.mulVec v_B = (μ_B - 1) • v_B := by
      ext k; have hk := congr_fun hv_eig k; dsimp [B, mulVec, dotProduct] at hk ⊢
      have h1 : ∑ l, (A k l + (1:Matrix _ _ ℝ) k l) * v_B l = ∑ l, A k l * v_B l + ∑ l, (1:Matrix _ _ ℝ) k l * v_B l := by rw [←Finset.sum_add_distrib]; apply Finset.sum_congr rfl; intro _ _; ring
      rw [h1] at hk; have h2 : ∑ l, (1:Matrix _ _ ℝ) k l * v_B l = v_B k := congr_fun (Matrix.one_mulVec v_B) k
      rw [h2] at hk; try simp only [Pi.smul_apply, smul_eq_mul] at hk ⊢
      change ∑ l, A k l * v_B l = (μ_B - 1) * v_B k
      linarith
    have h_vB_neq : v_B ≠ 0 := by intro h; have := hv_pos (Classical.arbitrary n); rw [h] at this; exact lt_irrefl 0 this
    have h_max_bound : ∀ k, eig k ≤ max_eig := fun k => Finset.le_max' s (eig k) (Finset.mem_image_of_mem eig (Finset.mem_univ k))
    have h_mu_le : μ_B ≤ max_eig + 1 := eigenvalue_le_maxEig_add_one hA_herm hA_vB h_vB_neq max_eig h_max_bound
    have h_eq : μ_B = max_eig + 1 := le_antisymm h_mu_le h_le
    rw [h_eq] at hv_eig
    have hA_vB_max : A.mulVec v_B = max_eig • v_B := by
      have hsub : μ_B - 1 = max_eig := by linarith
      rw [hsub] at hA_vB
      exact hA_vB
    obtain ⟨ci, hi⟩ := eigenvector_unique_of_connected (symm_of_herm hA_herm) hA_nn hA_conn max_eig v_B w_i hv_pos hA_vB_max hA_wi
    obtain ⟨cj, hj⟩ := eigenvector_unique_of_connected (symm_of_herm hA_herm) hA_nn hA_conn max_eig v_B w_j hv_pos hA_vB_max hA_wj
    by_contra h_neq
    have hcj_neq : cj ≠ 0 := by intro h; rw [h, zero_smul] at hj; exact hw_j_neq hj
    have h_eq_vec : (evec i_max : EuclideanSpace ℝ _) = (ci / cj) • (evec j : EuclideanSpace ℝ _) := by
      ext k; have hik := congr_fun hi k; have hjk := congr_fun hj k; change w_i k = (ci / cj) * w_j k
      calc w_i k = ci * v_B k := by rw [hik, Pi.smul_apply, smul_eq_mul]
        _ = ci * (w_j k / cj) := by have h_comm : cj * v_B k = v_B k * cj := mul_comm cj (v_B k); rw [hjk, Pi.smul_apply, smul_eq_mul, h_comm, mul_div_cancel_right₀ (v_B k) hcj_neq]
        _ = (ci / cj) * w_j k := by ring
    let b := evec.toBasis
    have h1 : b.repr (b i_max) i_max = 1 := by rw [Basis.repr_self]; exact Finsupp.single_eq_same
    have h2 : b.repr (b j) i_max = 0 := by rw [Basis.repr_self]; exact Finsupp.single_eq_of_ne h_neq
    have h3 : b.repr ((ci / cj) • b j) i_max = 0 := by rw [LinearEquiv.map_smul, Finsupp.smul_apply, smul_eq_mul, h2, mul_zero]
    have h_eq_b : b i_max = (ci / cj) • b j := h_eq_vec
    rw [h_eq_b] at h1; rw [h3] at h1; norm_num at h1
  · let w_i := evec i_max
    have heq_eig_i : hA_herm.eigenvalues i_max = max_eig := hi_max
    have hA_wi : A.mulVec w_i = max_eig • w_i := by have h := hA_herm.mulVec_eigenvectorBasis i_max; rw [heq_eig_i] at h; exact h
    have hB_wi : B.mulVec w_i = (max_eig + 1) • w_i := h_add_eig hA_wi
    have hw_i_neq : w_i ≠ 0 := by
      intro h
      have h1 : ‖w_i‖ = 0 := by rw [h, norm_zero]
      have h2 : ‖(evec i_max : EuclideanSpace ℝ _)‖ = 1 := (OrthonormalBasis.orthonormal evec).1 i_max
      have h3 : ‖w_i‖ = ‖(evec i_max : EuclideanSpace ℝ _)‖ := rfl
      rw [h3] at h1
      rw [h2] at h1
      norm_num at h1
    have h_le_2 := eigenvalue_le_of_symm_of_nonneg hB_symm hB_nn μ_B v_B hv_pos hv_eig (max_eig + 1) w_i hw_i_neq hB_wi
    have hA_vB : A.mulVec v_B = (μ_B - 1) • v_B := by
      ext k; have hk := congr_fun hv_eig k; dsimp [B, mulVec, dotProduct] at hk ⊢
      have h1 : ∑ l, (A k l + (1:Matrix _ _ ℝ) k l) * v_B l = ∑ l, A k l * v_B l + ∑ l, (1:Matrix _ _ ℝ) k l * v_B l := by rw [←Finset.sum_add_distrib]; apply Finset.sum_congr rfl; intro _ _; ring
      rw [h1] at hk; have h2 : ∑ l, (1:Matrix _ _ ℝ) k l * v_B l = v_B k := congr_fun (Matrix.one_mulVec v_B) k
      rw [h2] at hk; try simp only [Pi.smul_apply, smul_eq_mul] at hk ⊢
      change ∑ l, A k l * v_B l = (μ_B - 1) * v_B k
      linarith
    have h_vB_neq : v_B ≠ 0 := by intro h; have := hv_pos (Classical.arbitrary n); rw [h] at this; exact lt_irrefl 0 this
    have h_max_bound : ∀ k, eig k ≤ max_eig := fun k => Finset.le_max' s (eig k) (Finset.mem_image_of_mem eig (Finset.mem_univ k))
    have h_mu_le : μ_B ≤ max_eig + 1 := eigenvalue_le_maxEig_add_one hA_herm hA_vB h_vB_neq max_eig h_max_bound
    have h_eq : μ_B = max_eig + 1 := le_antisymm h_mu_le h_le_2
    have hA_vB_max : A.mulVec v_B = max_eig • v_B := by
      have hsub : μ_B - 1 = max_eig := by linarith
      rw [hsub] at hA_vB
      exact hA_vB
    obtain ⟨ci, hi⟩ := eigenvector_unique_of_connected (symm_of_herm hA_herm) hA_nn hA_conn max_eig v_B w_i hv_pos hA_vB_max hA_wi
    have hci_neq : ci ≠ 0 := by intro h; rw [h, zero_smul] at hi; exact hw_i_neq hi
    rcases lt_trichotomy ci 0 with h_neg | h_zero | h_pos
    · right; intro x; have h_val := congr_fun hi x; dsimp [w_i] at h_val; rw [h_val]; exact mul_neg_of_neg_of_pos h_neg (hv_pos x)
    · exact False.elim (hci_neq h_zero)
    · left; intro x; have h_val := congr_fun hi x; dsimp [w_i] at h_val; rw [h_val]; exact mul_pos h_pos (hv_pos x)

variable {d : ℕ} (hd : d ≥ 3)

lemma isPerronFrobeniusMax_realWeightedMatrix :
    IsPerronFrobeniusMax (realWeightedMatrix hd) (realWeightedMatrix_isHermitian hd) := 
  isPerronFrobeniusMax_of_connected _ _ (isIrreducible_of_connected _ _ (weightedMatrix_nonneg hd) (weighted_support_connected hd)) (weightedMatrix_nonneg hd) (weighted_support_connected hd)

lemma isPerronFrobeniusMax_realAdjacencyMatrix :
    IsPerronFrobeniusMax (@realAdjacencyMatrix d) (@realAdjacencyMatrix_isHermitian d) := by
  have hd2 : d ≥ 2 := by omega
  exact isPerronFrobeniusMax_of_connected _ _ (isIrreducible_of_connected _ _ adjacencyMatrix_nonneg (adjacency_support_connected hd2)) adjacencyMatrix_nonneg (adjacency_support_connected hd2)

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
