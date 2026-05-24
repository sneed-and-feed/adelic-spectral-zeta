import numpy as np
import sys
sys.path.append(".")
from tests.test_eigenvector_alignment import build_adjacency, get_lift, get_modulation_isometry

d = 5
A_d = build_adjacency(d)
U_d = get_modulation_isometry(d - 1)
H_d_1 = U_d.T @ A_d @ U_d
L = get_lift(d - 2, d - 1)
U = get_modulation_isometry(d - 2)
W = np.hstack([L, U])
H_split = W.T @ H_d_1 @ W
print("H_4 split:")
print(np.round(H_split, 6))
