import os

file_path = 'formalization/Formalization/MathlibSpectral.lean'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_pow_le = """    have h1 : A i l ≤ (A + 1) i l := by
      by_cases h : i = l
      · simp [h, add_apply, one_apply_eq]
        exact le_add_of_nonneg_right zero_le_one
      · simp [h, add_apply, one_apply_ne]
    exact mul_le_mul h1 (ih l j) (pow_nonneg hA_nn k l j) hA1_nn"""

new_pow_le = """    have h1 : A i l ≤ (A + 1) i l := by
      by_cases h : i = l
      · simp [h, add_apply, one_apply_eq]
      · simp [h, add_apply, one_apply_ne]
    exact mul_le_mul h1 (ih l j) (pow_nonneg hA_nn k l j) hA1_nn"""

content = content.replace(old_pow_le, new_pow_le)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("MathlibSpectral.lean successfully golfed!")
