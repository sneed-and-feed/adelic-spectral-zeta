import os

file_path = 'formalization/Formalization/SchreierSpectral.lean'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_fin_cases = """  -- Now fin_cases on s2 and r2
  fin_cases s2 <;> fin_cases r2
  · -- s2=0, r2=0: should equal weightedMatrix s1 r1 = P + Q
    dsimp [A'_block_diag_target, weightedMatrix, sheetDiffMatrix]
    simp only [sum_zmod_two]
    rw [hA10, hA11]
    simp only [hadamardInv, hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
    norm_num
    ring
  · -- s2=0, r2=1: should equal 0 (off-diagonal block)
    dsimp [A'_block_diag_target, weightedMatrix, sheetDiffMatrix]
    simp only [sum_zmod_two]
    rw [hA10, hA11]
    simp only [hadamardInv, hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
    norm_num
    ring
  · -- s2=1, r2=0: should equal 0 (off-diagonal block)  
    dsimp [A'_block_diag_target, weightedMatrix, sheetDiffMatrix]
    simp only [sum_zmod_two]
    rw [hA10, hA11]
    simp only [hadamardInv, hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
    norm_num
    ring
  · -- s2=1, r2=1: should equal sheetDiffMatrix s1 r1 = P - Q
    dsimp [A'_block_diag_target, weightedMatrix, sheetDiffMatrix]
    simp only [sum_zmod_two]
    rw [hA10, hA11]
    simp only [hadamardInv, hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
    norm_num
    ring"""

new_fin_cases = """  -- Now fin_cases on s2 and r2
  fin_cases s2 <;> fin_cases r2 <;>
  · dsimp [A'_block_diag_target, weightedMatrix, sheetDiffMatrix]
    simp only [sum_zmod_two]
    rw [hA10, hA11]
    simp only [hadamardInv, hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
    norm_num
    ring"""

content = content.replace(old_fin_cases, new_fin_cases)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SchreierSpectral.lean fin_cases successfully golfed!")
