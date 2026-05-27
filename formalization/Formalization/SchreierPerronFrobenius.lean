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

variable {d : ℕ} (hd : d ≥ 3)

variable {n : Type _} [Fintype n] [DecidableEq n] [Nonempty n]



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





end SchreierSpectral





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
