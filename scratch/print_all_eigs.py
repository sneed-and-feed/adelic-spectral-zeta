import numpy as np
import scipy.linalg as la
from adelic_spectral_zeta.determinant import compute_eigenvalues

D0_eigs, Dglob_eigs = compute_eigenvalues(N_dim=150, lambda_val=2.2, p_max=151)
print("Sorted Dglob eigenvalues:")
print(Dglob_eigs[140:160])
