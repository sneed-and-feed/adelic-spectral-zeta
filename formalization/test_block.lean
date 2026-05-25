import Formalization.CollatzSpectral

open Matrix CollatzSpectral

lemma test_A'_block_diag {d : ℕ} (hd : d ≥ 3) :
    conjBlockInv * (A'_matrix hd) * conjBlock = A'_block_diag_target hd := by
  ext ⟨s1, s2⟩ ⟨r1, r2⟩
  simp only [Matrix.mul_apply, conjBlockInv, A'_matrix, conjBlock, A'_block_diag_target]
  simp only [Fintype.sum_prod_type]
  simp only [ite_mul, zero_mul, mul_ite, mul_zero, Finset.sum_ite_eq', Finset.sum_ite_eq, Finset.mem_univ, if_true]
  fin_cases s2 <;> fin_cases r2
  · -- s2 = 0, r2 = 0
    dsimp [hadamardBlock, hadamardInv, weightedMatrix, antisymMatrix]
    -- sum over x_3 is sum over 0 and 1!
    rw [Finset.sum_univ_two, Finset.sum_univ_two]
    dsimp
    ring
  · -- s2 = 0, r2 = 1
    dsimp [hadamardBlock, hadamardInv, weightedMatrix, antisymMatrix]
    rw [Finset.sum_univ_two, Finset.sum_univ_two]
    dsimp
    ring
  · -- s2 = 1, r2 = 0
    dsimp [hadamardBlock, hadamardInv, weightedMatrix, antisymMatrix]
    rw [Finset.sum_univ_two, Finset.sum_univ_two]
    dsimp
    ring
  · -- s2 = 1, r2 = 1
    dsimp [hadamardBlock, hadamardInv, weightedMatrix, antisymMatrix]
    rw [Finset.sum_univ_two, Finset.sum_univ_two]
    dsimp
    ring
