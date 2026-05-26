
lemma isPerronFrobeniusMax_realWeightedMatrix :
    IsPerronFrobeniusMax (realWeightedMatrix hd) (realWeightedMatrix_isHermitian hd) := by
  let A := realWeightedMatrix hd
  let B := A + 1
  have hB_irr := B_matrix_isIrreducible hd
  have h_pf := perron_frobenius hB_irr
  obtain ⟨μ_B, v_B, hμ_pos, hv_pos, hv_eig⟩ := h_pf
  have hB_symm : ∀ i j, B i j = B j i := by
    intro i j; dsimp [B]
    rw [add_apply, add_apply, realWeightedMatrix_symm hd i j, one_apply, one_apply, @eq_comm _ i j]
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
      have : (A.mulVec w) k = lam * w k := by rw [h, Pi.smul_apply, smul_eq_mul]; exact this
    rw [h2]
    have h3 : ∑ l, (1:Matrix _ _ ℝ) k l * w l = w k := by
      have : ((1:Matrix _ _ ℝ).mulVec w) k = w k := by rw [Matrix.one_mulVec]; exact this
    rw [h3, add_mul, one_mul]
  let eig := (realWeightedMatrix_isHermitian hd).eigenvalues
  let evec := (realWeightedMatrix_isHermitian hd).eigenvectorBasis
  let s := Finset.univ.image eig
  have hs_nonempty : s.Nonempty := ⟨eig 0, Finset.mem_image_of_mem eig (Finset.mem_univ 0)⟩
  let max_eig := Finset.max' s hs_nonempty
  obtain ⟨i_max, hi_max⟩ : ∃ i, eig i = max_eig :=
    Finset.mem_image.mp (Finset.max'_mem s hs_nonempty)
  use i_max; intro j; refine ⟨?_, ?_⟩
  · exact hi_max ▸ Finset.le_max' s (eig j) (Finset.mem_image_of_mem eig (Finset.mem_univ j))
  · intro hj_eq
    have heq : eig j = max_eig := by rw [hj_eq, hi_max]
    let w_i := evec i_max
    let w_j := evec j
    have hA_wi : A.mulVec w_i = max_eig • w_i :=
      (realWeightedMatrix_isHermitian hd).mulVec_eigenvectorBasis i_max ▸ by rw [hi_max]
    have hA_wj : A.mulVec w_j = max_eig • w_j :=
      (realWeightedMatrix_isHermitian hd).mulVec_eigenvectorBasis j ▸ by rw [heq]
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
      dsimp [B, mulVec, dotProduct] at hk
      have h1 : ∑ l, (A k l + (1:Matrix _ _ ℝ) k l) * v_B l =
                  ∑ l, A k l * v_B l + ∑ l, (1:Matrix _ _ ℝ) k l * v_B l := by
        rw [←Finset.sum_add_distrib]; apply Finset.sum_congr rfl; intro _ _; ring
      rw [h1] at hk
      have h2 : ∑ l, (1:Matrix _ _ ℝ) k l * v_B l = v_B k := by
        exact ((1:Matrix _ _ ℝ).mulVec v_B k).symm ▸ by rw [Matrix.one_mulVec]
      rw [h2] at hk
      simp only [Pi.smul_apply, smul_eq_mul]; linarith
    have h_vB_neq : v_B ≠ 0 := by
      intro h; have := hv_pos 0; rw [h] at this; exact lt_irrefl 0 this
    have h_max_bound : ∀ k, eig k ≤ max_eig := fun k =>
      Finset.le_max' s (eig k) (Finset.mem_image_of_mem eig (Finset.mem_univ k))
    have h_mu_le : μ_B ≤ max_eig + 1 :=
      mu_B_le_max_eig' (realWeightedMatrix_isHermitian hd) hA_vB h_vB_neq max_eig h_max_bound
    have h_eq : μ_B = max_eig + 1 := le_antisymm h_mu_le h_le
    rw [h_eq] at hv_eig
    exact pf_eigenvector_unique hB_symm hB_nn hv_pos hv_eig (max_eig + 1) w_i hw_i_neq hB_wi w_j hw_j_neq hB_wj

end SchreierSpectral

theorem weightedMatrix_spectral_gap_positive {d : ℕ} (hd : d ≥ 3) :
    ∃ (i : ZMod (2^(d-2))), ∀ (j : ZMod (2^(d-2))),
      (realWeightedMatrix_isHermitian hd).eigenvalues j ≤ (realWeightedMatrix_isHermitian hd).eigenvalues i
      ∧ ((realWeightedMatrix_isHermitian hd).eigenvalues j = (realWeightedMatrix_isHermitian hd).eigenvalues i → j = i) := by
  exact isPerronFrobeniusMax_realWeightedMatrix hd
