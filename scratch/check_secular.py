import numpy as np
import scipy.linalg as la
from adelic_spectral_zeta.determinant import compute_eigenvalues

# Let's compute eigenvalues using compute_eigenvalues
D0_eigs, Dglob_eigs = compute_eigenvalues(N_dim=150, lambda_val=2.2, p_max=151)
non_zero_eigs = Dglob_eigs[np.abs(Dglob_eigs) > 1e-5]

# Let's compute the secular function at these eigenvalues
dim = len(D0_eigs)
n_vals = np.arange(-150, 151)
log_lam = np.log(2.2)
D0_diag = n_vals * np.pi / log_lam

# Reconstruct normalized xi from compute_eigenvalues logic
is_prime = np.ones(151 + 1, dtype=bool)
is_prime[:2] = False
for i in range(2, int(151**0.5) + 1):
    if is_prime[i]:
        is_prime[i*i::i] = False
primes = np.where(is_prime)[0]

import mpmath
xi = np.zeros(dim, dtype=complex)
for p in primes:
    phases = -1j * n_vals * np.pi * np.log(p) / log_lam
    xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)
for i, n in enumerate(n_vals):
    t = n * np.pi / log_lam
    s = 0.25 + 0.5j * t
    psi_val = complex(mpmath.psi(0, s))
    xi[i] += 0.5 * (psi_val - np.log(np.pi))
xi_norm = xi / np.linalg.norm(xi)
weights = np.abs(xi_norm)**2

def S(z):
    return np.sum(weights / (z - D0_diag))

print("Checking S(z) at the first 5 positive eigenvalues of Dglob:")
for val in non_zero_eigs[non_zero_eigs > 0][:5]:
    print(f"val = {val:.6f} | S(val) = {S(val):.6e}")
