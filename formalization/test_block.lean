import Formalization.CollatzSpectral
import Mathlib.Data.Matrix.Kronecker

open Matrix CollatzSpectral Classical

lemma A'_tau_sym_01_10 {d : ℕ} (hd : d ≥ 3) (s1 r1 : ZMod (2^(d-2))) :
    A'_matrix hd (s1, 1) (r1, 0) = A'_matrix hd (s1, 0) (r1, 1) := by
  simp only [A'_matrix, Matrix.reindex_apply, Equiv.symm_symm]
  change adjacencyMatrix ((sheetSplit hd).symm (s1, 1)) ((sheetSplit hd).symm (r1, 0)) = 
         adjacencyMatrix ((sheetSplit hd).symm (s1, 0)) ((sheetSplit hd).symm (r1, 1))
  rw [sheetSplitInv_one hd s1, sheetSplitInv_zero hd r1]
  rw [sheetSplitInv_zero hd s1, sheetSplitInv_one hd r1]
  simp only [adjacencyMatrix]
  congr 1
  exact propext (tau_adj_bicond hd (canonicalLift s1) (canonicalLift r1))

lemma A'_tau_sym_11_00 {d : ℕ} (hd : d ≥ 3) (s1 r1 : ZMod (2^(d-2))) :
    A'_matrix hd (s1, 1) (r1, 1) = A'_matrix hd (s1, 0) (r1, 0) := by
  simp only [A'_matrix, Matrix.reindex_apply, Equiv.symm_symm]
  change adjacencyMatrix ((sheetSplit hd).symm (s1, 1)) ((sheetSplit hd).symm (r1, 1)) = 
         adjacencyMatrix ((sheetSplit hd).symm (s1, 0)) ((sheetSplit hd).symm (r1, 0))
  rw [sheetSplitInv_one hd s1, sheetSplitInv_one hd r1]
  rw [sheetSplitInv_zero hd s1, sheetSplitInv_zero hd r1]
  simp only [adjacencyMatrix]
  congr 1
  apply propext
  constructor
  · intro h; rw [← tau_tau hd (canonicalLift r1)]; exact (tau_adj_bicond hd _ _).mp h
  · intro h; exact (tau_adj_bicond hd _ _).mpr (by rw [tau_tau hd]; exact h)

lemma conjBlockInv_eq_kron {d : ℕ} :
    @conjBlockInv d = kroneckerMap (· * ·)
      (1 : Matrix (ZMod (2^(d-2))) (ZMod (2^(d-2))) ℚ) hadamardInv := by
  ext ⟨i1, i2⟩ ⟨j1, j2⟩
  simp only [conjBlockInv, kroneckerMap, Matrix.one_apply]
  by_cases h : i1 = j1 <;> simp [h]

lemma conjBlock_eq_kron {d : ℕ} :
    @conjBlock d = kroneckerMap (· * ·)
      (1 : Matrix (ZMod (2^(d-2))) (ZMod (2^(d-2))) ℚ) hadamardBlock := by
  ext ⟨i1, i2⟩ ⟨j1, j2⟩
  simp only [conjBlock, kroneckerMap, Matrix.one_apply]
  by_cases h : i1 = j1 <;> simp [h]

lemma sum_sum_ite_eq {d : ℕ} (s1 r1 : ZMod (2^(d-2)))
    (f : ZMod (2^(d-2)) → ZMod (2^(d-2)) → ℚ) :
    ∑ k1 : ZMod (2^(d-2)), ∑ l1 : ZMod (2^(d-2)),
      (if s1 = k1 then if l1 = r1 then f k1 l1 else 0 else 0) =
    f s1 r1 := by
  rw [Finset.sum_eq_single s1]
  · rw [Finset.sum_eq_single r1]
    · simp
    · intro l1 _ hl1; simp [hl1]
    · intro h; exact absurd (Finset.mem_univ r1) h
  · intro k1 _ hk1; apply Finset.sum_eq_zero; intro l1 _; simp [Ne.symm hk1]
  · intro h; exact absurd (Finset.mem_univ s1) h

lemma A'_block_diag_proof {d : ℕ} (hd : d ≥ 3) :
    conjBlockInv * (A'_matrix hd) * conjBlock = A'_block_diag_target hd := by
  ext ⟨s1, s2⟩ ⟨r1, r2⟩
  simp only [Matrix.mul_apply, Fintype.sum_prod_type]
  simp only [conjBlockInv, conjBlock, A'_matrix, A'_block_diag_target,
             Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
  simp only [Finset.sum_mul, mul_ite, ite_mul, mul_zero, zero_mul]
  
  -- The LHS is now ∑ l1 l2 (if l1=r1 then ∑ k1 k2 (if s1=k1 then H⁻¹ * A' * H else 0) else 0)
  simp_rw [Finset.sum_comm (s := Finset.univ (α := ZMod (2^(d-2))))
                           (t := Finset.univ (α := ZMod 2))]
  -- We can evaluate these sums using sum_ite_eq
  simp only [Finset.sum_ite_eq, Finset.sum_ite_eq', Finset.mem_univ, if_true]
  
  -- Abbreviate entries for readability
  have hA10 : A'_matrix hd (s1, 1) (r1, 0) = A'_matrix hd (s1, 0) (r1, 1) := A'_tau_sym_01_10 hd s1 r1
  have hA11 : A'_matrix hd (s1, 1) (r1, 1) = A'_matrix hd (s1, 0) (r1, 0) := A'_tau_sym_11_00 hd s1 r1
  
  -- Unfold A'_matrix everywhere so terms exactly match the sum output
  simp only [A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply] at hA10 hA11 ⊢
  
  -- Now fin_cases on s2 and r2
  fin_cases s2 <;> fin_cases r2
  · -- s2=0, r2=0: should equal weightedMatrix s1 r1 = P + Q
    dsimp [A'_block_diag_target, weightedMatrix, antisymMatrix]
    simp only [sum_zmod_two]
    rw [hA10, hA11]
    simp only [hadamardInv, hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
    norm_num
    ring
  · -- s2=0, r2=1: should equal 0 (off-diagonal block)
    dsimp [A'_block_diag_target, weightedMatrix, antisymMatrix]
    simp only [sum_zmod_two]
    rw [hA10, hA11]
    simp only [hadamardInv, hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
    norm_num
    ring
  · -- s2=1, r2=0: should equal 0 (off-diagonal block)  
    dsimp [A'_block_diag_target, weightedMatrix, antisymMatrix]
    simp only [sum_zmod_two]
    rw [hA10, hA11]
    simp only [hadamardInv, hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
    norm_num
    ring
  · -- s2=1, r2=1: should equal antisymMatrix s1 r1 = P - Q
    dsimp [A'_block_diag_target, weightedMatrix, antisymMatrix]
    simp only [sum_zmod_two]
    rw [hA10, hA11]
    simp only [hadamardInv, hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
    norm_num
    ring
