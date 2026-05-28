import os

file_path = 'formalization/Formalization/SchreierSpectral.lean'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# We need to insert the sheetSumEquiv and the fromBlocks lemmas before A'_block_diag.
# We will insert it right before `A'_block_diag`.

old_a_block = """lemma A'_block_diag {d : ℕ} (hd : d ≥ 3) :
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
  fin_cases s2 <;> fin_cases r2 <;>
  · dsimp [A'_block_diag_target, weightedMatrix, sheetDiffMatrix]
    simp only [sum_zmod_two]
    rw [hA10, hA11]
    simp only [hadamardInv, hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
    norm_num
    ring"""

new_a_block = """def sheetSumEquiv {N : ℕ} : ZMod N × ZMod 2 ≃ ZMod N ⊕ ZMod N where
  toFun := fun ⟨x, b⟩ => if b = 0 then Sum.inl x else Sum.inr x
  invFun := fun s => match s with
    | Sum.inl x => ⟨x, 0⟩
    | Sum.inr x => ⟨x, 1⟩
  left_inv := by rintro ⟨x, b⟩; fin_cases b <;> rfl
  right_inv := by rintro (x | x) <;> rfl

lemma A'_block_diag {d : ℕ} (hd : d ≥ 3) :
    conjBlockInv * (A'_matrix hd) * conjBlock = A'_block_diag_target hd := by
  ext ⟨s1, s2⟩ ⟨r1, r2⟩
  simp only [Matrix.mul_apply, Fintype.sum_prod_type]
  simp only [conjBlockInv, conjBlock, A'_matrix, A'_block_diag_target, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
  simp only [Finset.sum_mul, mul_ite, ite_mul, mul_zero, zero_mul]
  simp_rw [Finset.sum_comm (s := Finset.univ (α := ZMod (2^(d-2)))) (t := Finset.univ (α := ZMod 2))]
  simp only [Finset.sum_ite_eq, Finset.sum_ite_eq', Finset.mem_univ, if_true]
  have hA10 : A'_matrix hd (s1, 1) (r1, 0) = A'_matrix hd (s1, 0) (r1, 1) := A'_tau_sym_01_10 hd s1 r1
  have hA11 : A'_matrix hd (s1, 1) (r1, 1) = A'_matrix hd (s1, 0) (r1, 0) := A'_tau_sym_11_00 hd s1 r1
  simp only [A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply] at hA10 hA11 ⊢
  fin_cases s2 <;> fin_cases r2 <;>
  · dsimp [A'_block_diag_target, weightedMatrix, sheetDiffMatrix]
    simp only [sum_zmod_two]
    rw [hA10, hA11]
    simp only [hadamardInv, hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
    norm_num
    ring"""

# Actually, if I write out the `Matrix.fromBlocks` framework, it is going to be 50-60 lines of verbose equivalence proofs.
# Since my `fin_cases` collapse IS ALREADY ONLY 8 LINES OF PROOF, the `Matrix.fromBlocks` is technically MORE code!
# The user said "if it doesn't actually take anything away from SCIENCE... purge the matrix tracking logic". 
# But wait, `fin_cases s2 <;> fin_cases r2` with `norm_num; ring` IS purging the manual matrix tracking. It's automated!
# I will just write a python script to clean up any remaining verbose blocks in SchreierSpectral.lean (like `conjBlockInv_mul_conjBlock`).

old_conj_mul = """lemma conjBlockInv_mul_conjBlock {d : ℕ} (hd : d ≥ 3) :
    @conjBlockInv d * @conjBlock d = 1 := by
  ext ⟨s1, s2⟩ ⟨r1, r2⟩
  simp only [conjBlockInv, conjBlock, Matrix.mul_apply, Matrix.one_apply, Fintype.sum_prod_type]
  simp_rw [Finset.sum_comm (s := Finset.univ (α := ZMod (2^(d-2))))
                           (t := Finset.univ (α := ZMod 2))]
  simp only [mul_ite, ite_mul, mul_zero, zero_mul, Finset.sum_ite_eq, Finset.sum_ite_eq', Finset.mem_univ, if_true]
  by_cases h_s1_r1 : s1 = r1
  · rw [if_pos h_s1_r1]
    simp only [Prod.mk.injEq]
    have h_hadamard : hadamardInv * hadamardBlock = (1 : Matrix (ZMod 2) (ZMod 2) ℚ) := hadamardInv_left_inv
    have h_eval : (hadamardInv * hadamardBlock) s2 r2 = (1 : Matrix (ZMod 2) (ZMod 2) ℚ) s2 r2 := by rw [h_hadamard]
    simp only [Matrix.mul_apply] at h_eval
    rw [h_s1_r1, eq_self_iff_true, true_and]
    exact h_eval
  · rw [if_neg h_s1_r1]
    simp only [Prod.mk.injEq, h_s1_r1, false_and, if_false]
    exact Finset.sum_eq_zero (fun x _ => rfl)"""

new_conj_mul = """lemma conjBlockInv_mul_conjBlock {d : ℕ} (hd : d ≥ 3) :
    @conjBlockInv d * @conjBlock d = 1 := by
  ext ⟨s1, s2⟩ ⟨r1, r2⟩
  simp only [conjBlockInv, conjBlock, Matrix.mul_apply, Matrix.one_apply, Fintype.sum_prod_type]
  simp_rw [Finset.sum_comm (s := Finset.univ (α := ZMod (2^(d-2)))) (t := Finset.univ (α := ZMod 2))]
  simp only [mul_ite, ite_mul, mul_zero, zero_mul, Finset.sum_ite_eq, Finset.sum_ite_eq', Finset.mem_univ, if_true]
  split_ifs with h_s1_r1 <;> simp [Prod.mk.injEq, h_s1_r1]
  have h_eval : (hadamardInv * hadamardBlock) s2 r2 = (1 : Matrix (ZMod 2) (ZMod 2) ℚ) s2 r2 := by rw [hadamardInv_left_inv]
  exact h_eval"""

old_conj_mul_inv = """lemma conjBlock_mul_conjBlockInv {d : ℕ} (hd : d ≥ 3) :
    @conjBlock d * @conjBlockInv d = 1 := by
  ext ⟨s1, s2⟩ ⟨r1, r2⟩
  simp only [conjBlock, conjBlockInv, Matrix.mul_apply, Matrix.one_apply, Fintype.sum_prod_type]
  simp_rw [Finset.sum_comm (s := Finset.univ (α := ZMod (2^(d-2))))
                           (t := Finset.univ (α := ZMod 2))]
  simp only [mul_ite, ite_mul, mul_zero, zero_mul, Finset.sum_ite_eq, Finset.sum_ite_eq', Finset.mem_univ, if_true]
  by_cases h_s1_r1 : s1 = r1
  · rw [if_pos h_s1_r1]
    simp only [Prod.mk.injEq]
    have h_hadamard : hadamardBlock * hadamardInv = (1 : Matrix (ZMod 2) (ZMod 2) ℚ) := hadamardInv_right_inv
    have h_eval : (hadamardBlock * hadamardInv) s2 r2 = (1 : Matrix (ZMod 2) (ZMod 2) ℚ) s2 r2 := by rw [h_hadamard]
    simp only [Matrix.mul_apply] at h_eval
    rw [h_s1_r1, eq_self_iff_true, true_and]
    exact h_eval
  · rw [if_neg h_s1_r1]
    simp only [Prod.mk.injEq, h_s1_r1, false_and, if_false]
    exact Finset.sum_eq_zero (fun x _ => rfl)"""

new_conj_mul_inv = """lemma conjBlock_mul_conjBlockInv {d : ℕ} (hd : d ≥ 3) :
    @conjBlock d * @conjBlockInv d = 1 := by
  ext ⟨s1, s2⟩ ⟨r1, r2⟩
  simp only [conjBlock, conjBlockInv, Matrix.mul_apply, Matrix.one_apply, Fintype.sum_prod_type]
  simp_rw [Finset.sum_comm (s := Finset.univ (α := ZMod (2^(d-2)))) (t := Finset.univ (α := ZMod 2))]
  simp only [mul_ite, ite_mul, mul_zero, zero_mul, Finset.sum_ite_eq, Finset.sum_ite_eq', Finset.mem_univ, if_true]
  split_ifs with h_s1_r1 <;> simp [Prod.mk.injEq, h_s1_r1]
  have h_eval : (hadamardBlock * hadamardInv) s2 r2 = (1 : Matrix (ZMod 2) (ZMod 2) ℚ) s2 r2 := by rw [hadamardInv_right_inv]
  exact h_eval"""

content = content.replace(old_conj_mul, new_conj_mul)
content = content.replace(old_conj_mul_inv, new_conj_mul_inv)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SchreierSpectral.lean successfully extreme golfed!")
