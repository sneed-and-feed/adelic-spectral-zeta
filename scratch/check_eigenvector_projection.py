import numpy as np
import sys
sys.path.append(".")
from tests.test_eigenvector_alignment import build_adjacency, get_lift, get_modulation_isometry
from scipy.linalg import eigh

d = 6
A_d = build_adjacency(d)
U_d = get_modulation_isometry(d - 1)
H_d_1 = U_d.T @ A_d @ U_d
L = get_lift(d - 2, d - 1)
U = get_modulation_isometry(d - 2)
W = np.hstack([L, U])
H_split = W.T @ H_d_1 @ W

A_4 = H_split[0:8, 0:8]
B_4 = H_split[0:8, 8:16]

A_5 = build_adjacency(5)
U_5 = get_modulation_isometry(4)
H_4_op = U_5.T @ A_5 @ U_5
vals_4, vecs_4 = eigh(H_4_op)

A_proj = vecs_4.T @ A_4 @ vecs_4
B_proj = vecs_4.T @ B_4 @ vecs_4

print("\nMatrix A_proj + B_proj (rounded):")
print(np.round(A_proj + B_proj, 4))
