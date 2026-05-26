import Formalization.CollatzSpectral

open Classical
open Matrix

lemma hadamardInv_right_inv {d : ℕ} (hd : d ≥ 3) :
    hadamardBlock * hadamardInv = 1 := by
  simp [hadamardInv]
  rw [Matrix.mul_smul, hadamard_sq hd]
  ext i j
  simp [Matrix.smul_apply, Matrix.one_apply]
  split_ifs <;> norm_num

lemma conjBlockInv_mul_conjBlock {d : ℕ} (hd : d ≥ 3) :
    conjBlockInv * conjBlock = 1 := by
  ext ⟨i1, j1⟩ ⟨i2, j2⟩
  simp only [conjBlockInv, conjBlock, Matrix.mul_apply, Matrix.one_apply, Fintype.sum_prod_type]
  by_cases h : i1 = i2
  · subst h
    have : ∀ k1, (∑ k2, (if i1 = k1 then hadamardInv j1 k2 else 0) * (if k1 = i1 then hadamardBlock k2 j2 else 0))
        = if i1 = k1 then ∑ k2, hadamardInv j1 k2 * hadamardBlock k2 j2 else 0 := by
      intro k1
      by_cases hk : i1 = k1 <;> simp [hk]
    simp_rw [this]
    rw [Finset.sum_eq_single i1]
    · simp [hadamardInv_left_inv hd]
    · intro k1 _ hk1; simp [hk1]
    · intro h_mem; exact (h_mem (Finset.mem_univ i1)).elim
  · -- i1 ≠ i2
    have : ∀ k1 k2, (if i1 = k1 then hadamardInv j1 k2 else 0) * (if k1 = i2 then hadamardBlock k2 j2 else 0) = 0 := by
      intro k1 k2
      by_cases hk1 : i1 = k1 <;> simp [hk1, h]
    simp_rw [this]
    simp [h]

lemma conjBlock_mul_conjBlockInv {d : ℕ} (hd : d ≥ 3) :
    conjBlock * conjBlockInv = 1 := by
  ext ⟨i1, j1⟩ ⟨i2, j2⟩
  simp only [conjBlock, conjBlockInv, Matrix.mul_apply, Matrix.one_apply, Fintype.sum_prod_type]
  by_cases h : i1 = i2
  · subst h
    have : ∀ k1, (∑ k2, (if i1 = k1 then hadamardBlock j1 k2 else 0) * (if k1 = i1 then hadamardInv k2 j2 else 0))
        = if i1 = k1 then ∑ k2, hadamardBlock j1 k2 * hadamardInv k2 j2 else 0 := by
      intro k1
      by_cases hk : i1 = k1 <;> simp [hk]
    simp_rw [this]
    rw [Finset.sum_eq_single i1]
    · simp [hadamardInv_right_inv hd]
    · intro k1 _ hk1; simp [hk1]
    · intro h_mem; exact (h_mem (Finset.mem_univ i1)).elim
  · -- i1 ≠ i2
    have : ∀ k1 k2, (if i1 = k1 then hadamardBlock j1 k2 else 0) * (if k1 = i2 then hadamardInv k2 j2 else 0) = 0 := by
      intro k1 k2
      by_cases hk1 : i1 = k1 <;> simp [hk1, h]
    simp_rw [this]
    simp [h]

lemma reindex_mul [Fintype n] {m' n' o' : Type*}
    (eₘ : m ≃ m') (eₙ : n ≃ n') (eₒ : o ≃ o')
    (M : Matrix m n α) (N : Matrix n o α) :
    Matrix.reindex eₘ eₙ M * Matrix.reindex eₙ eₒ N = Matrix.reindex eₘ eₒ (M * N) := by
  simp [Matrix.reindex, Matrix.submatrix_mul _ _ _ _ _ _ eₙ.symm.bijective]

theorem collatz_spectral_decomposition_new {d : ℕ} (hd : d ≥ 3) :
    ∃ (S : Matrix (ZMod (2^(d-1))) (ZMod (2^(d-1))) ℚ) (S_inv : Matrix (ZMod (2^(d-1))) (ZMod (2^(d-1))) ℚ),
      S_inv * S = 1 ∧ S * S_inv = 1 ∧
      S_inv * (@adjacencyMatrix d) * S = 
        Matrix.reindex (sheetSplit hd).symm (sheetSplit hd).symm (A'_block_diag_target hd) := by
  let e := sheetSplit hd
  use Matrix.reindex e.symm e.symm conjBlock
  use Matrix.reindex e.symm e.symm conjBlockInv
  constructor
  · -- S_inv * S = 1
    rw [reindex_mul]
    rw [conjBlockInv_mul_conjBlock hd]
    rw [Matrix.reindex_one]
  · constructor
    · -- S * S_inv = 1
      rw [reindex_mul]
      rw [conjBlock_mul_conjBlockInv hd]
      rw [Matrix.reindex_one]
    · -- S_inv * A * S = block diag
      have hA : @adjacencyMatrix d = Matrix.reindex e.symm e.symm (A'_matrix hd) := by
        rw [A'_matrix]
        -- Matrix.reindex_reindex doesn't exist explicitly sometimes, let's use submatrix
        ext i j
        simp [Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_symm]
      rw [hA]
      rw [reindex_mul, reindex_mul]
      rw [A'_block_diag hd]
