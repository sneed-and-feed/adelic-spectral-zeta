import numpy as np
from adelic_spectral_zeta.determinant import compute_eigenvalues

D0_eigs, Dglob_eigs = compute_eigenvalues(N_dim=500, lambda_val=2.2, p_max=151)
print("Dglob eigenvalues (first 10 positive):")
print(Dglob_eigs[Dglob_eigs > 1e-5][:10])
