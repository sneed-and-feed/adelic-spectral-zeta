import numpy as np
from adelic_spectral_zeta.determinant import compute_eigenvalues

D0_eigs, Dglob_eigs = compute_eigenvalues(N_dim=150, lambda_val=2.2, p_max=151)
print("D0 eigenvalues (first 10 positive):")
print(D0_eigs[D0_eigs > 0][:10])
print("\nDglob eigenvalues (first 10 positive):")
print(Dglob_eigs[Dglob_eigs > 1e-5][:10])
