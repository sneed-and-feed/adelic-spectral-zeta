import sys

path = 'formalization/Formalization/SchreierPerronFrobenius.lean'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

reps = {
    'matrix_pow_pos_of_walk': 'pow_pos_of_walk',
    'connected_eigenvector_unique': 'eigenvector_unique_of_connected',
    'eigenvector_constant_sign_matrix': 'eigenvector_constant_sign_of_pos',
    'abs_eigenvector_of_symmetric': 'abs_eigenvector_of_symm',
    'pf_eigenvalue_is_max': 'eigenvalue_le_of_symm_of_nonneg',
    "mu_B_le_max_eig'": 'eigenvalue_le_maxEig_add_one',
    'B_matrix_pow_ge_A_pow': 'pow_le_add_one_pow',
    'eigenvector_zero_of_walk': 'eq_zero_of_walk_of_eigenvector'
}

for k, v in reps.items():
    c = c.replace(k, v)

with open(path, 'w', encoding='utf-8', newline='') as f:
    f.write(c)

print("Replaced.")
