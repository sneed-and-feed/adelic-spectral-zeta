"""
Test suite: test_D.py
Tests mathematical properties and correctness invariants.
"""
import numpy as np
import mpmath
import scipy.linalg as la

N = 250
lam = 26.0
log_lam = np.log(lam)
n_vals = np.arange(-N, N + 1)
D0_diag = n_vals * np.pi / log_lam

primes_43 = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43]

# Ramanujan tau values
tau = {
    2: -24, 3: 252, 5: 4830, 7: -16744, 11: 534612, 13: -577738,
    17: -6905934, 19: 10661420, 23: 18643272, 29: 128406630,
    31: -52843168, 37: -182213314, 41: 308120442, 43: -17125708
}

def tau_tilde(p):
    return float(tau[p] * (p**(-5.5)))

xi = np.zeros(2*N + 1, dtype=complex)
for p in primes_43:
    t_val = tau_tilde(p)
    phases = -1j * n_vals * np.pi * np.log(p) / log_lam
    xi += (t_val * np.log(p) / np.sqrt(p)) * np.exp(phases)

for i, n in enumerate(n_vals):
    t = n * np.pi / log_lam
    s_val = 0.5 + 1j * t
    psi_val = complex(mpmath.psi(0, s_val + 5.5))
    xi[i] += 1.0 * (psi_val - np.log(2 * np.pi))

# Check for NaN/Inf in xi
print("Is NaN in xi:", np.isnan(xi).any())
print("Is Inf in xi:", np.isinf(xi).any())
print("Norm of xi:", np.linalg.norm(xi))

xi_norm = xi / np.linalg.norm(xi)
I = np.eye(2*N + 1)
P = np.outer(xi_norm, np.conj(xi_norm))
Proj = I - P

D = Proj @ np.diag(D0_diag) @ Proj
eigenvalues = la.eigvalsh(D)
print("First 10 eigenvalues of D:")
print(eigenvalues[:10])
print("Last 10 eigenvalues of D:")
print(eigenvalues[-10:])
