import numpy as np
import mpmath
import scipy.linalg as la

# Set up parameters
lam = 15.0  # scale parameter
log_lam = np.log(lam)
primes = [2, 3, 5, 7, 11, 13]
N = 250  # size is 2N+1

# Diagonal entries for D_0 (scaling operator)
n_vals = np.arange(-N, N + 1)
D0_diag = n_vals * np.pi / log_lam

# Vector xi representing primes + Archimedean factor
xi = np.zeros(2*N + 1, dtype=complex)
for p in primes:
    # Phase factors for prime p
    phases = -1j * n_vals * np.pi * np.log(p) / log_lam
    xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)

# Add Archimedean factor (logarithmic derivative of completed Gamma factor)
# for each eigenvalue lambda_n = n * pi / log_lam
for i, n in enumerate(n_vals):
    t = n * np.pi / log_lam
    # Digamma function psi(1/4 + i * t/2)
    s = 0.25 + 0.5j * t
    # Using mpmath for high-precision digamma
    psi_val = complex(mpmath.psi(0, s))
    xi[i] += 0.5 * (psi_val - np.log(np.pi))

# Normalize xi
xi_norm = xi / np.linalg.norm(xi)

# Projector onto orthogonal complement of xi
I = np.eye(2*N + 1)
P = np.outer(xi_norm, np.conj(xi_norm))
Proj = I - P

# Projected operator D = Proj * D0 * Proj
D = Proj @ np.diag(D0_diag) @ Proj

# Solve eigenvalues
eigenvalues = la.eigvalsh(D)

# Filter out the zero eigenvalue corresponding to xi
# The zero eigenvalue should be very close to 0
eigenvalues_filtered = sorted([val for val in eigenvalues if abs(val) > 1e-8])

# Get positive eigenvalues
pos_eigenvalues = sorted([val for val in eigenvalues_filtered if val > 0])

# Get true Riemann zeros
true_zeros = [float(mpmath.zetazero(k).imag) for k in range(1, 15)]

print("First 10 positive eigenvalues of compressed operator:")
print(pos_eigenvalues[:10])
print("\nTrue Riemann zeros:")
print(true_zeros[:10])
