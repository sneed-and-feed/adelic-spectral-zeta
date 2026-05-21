import numpy as np
import mpmath
import scipy.linalg as la

# Set N = 250, lam = 15.0
N = 250
lam = 15.0
log_lam = np.log(lam)
n_vals = np.arange(-N, N + 1)
D0_diag = n_vals * np.pi / log_lam

primes_43 = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43]

# Compute Ramanujan tau values
M = 100
poly = np.zeros(M + 1)
poly[0] = 1.0
for n in range(1, M + 1):
    next_poly = poly.copy()
    for i in range(M + 1 - n):
        next_poly[i + n] -= poly[i]
    poly = next_poly

delta_poly = np.zeros(M + 1)
delta_poly[0] = 1.0
for power in range(24):
    next_delta = np.zeros(M + 1)
    for i in range(M + 1):
        for j in range(M + 1 - i):
            next_delta[i + j] += delta_poly[i] * poly[j]
    delta_poly = next_delta

tau = np.zeros(M + 1)
for i in range(M):
    tau[i + 1] = delta_poly[i]

def tau_tilde(p):
    return float(tau[p] * (p**(-5.5)))

# Compute first 25 zeros of Ramanujan L-function
print("Computing first 25 zeros of L(s, Delta)...")
def Xi_delta(t):
    s = mpmath.mpc(0.5, t)
    total = mpmath.mpc(0.0)
    for n in range(1, 60):
        coeff = float(tau[n] * (n**(-5.5)))
        val = coeff / (n**s) * mpmath.gammainc(s + 5.5, 2 * mpmath.pi * n)
        total += val
    xi_val = 2 * ( (2 * mpmath.pi)**(-s) * total ).real
    return float(xi_val)

t_grid = np.linspace(0, 80, 1500)
y_vals = [Xi_delta(t) for t in t_grid]

true_zeros = []
for i in range(len(t_grid) - 1):
    if y_vals[i] * y_vals[i+1] < 0:
        root = mpmath.findroot(Xi_delta, (t_grid[i], t_grid[i+1]))
        true_zeros.append(float(root))
        if len(true_zeros) == 25:
            break

true_zeros = np.array(true_zeros)
print("True Zeros:", true_zeros)

# Construct vector xi
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

xi_norm = xi / np.linalg.norm(xi)
I = np.eye(2*N + 1)
P = np.outer(xi_norm, np.conj(xi_norm))
Proj = I - P
D = Proj @ np.diag(D0_diag) @ Proj

eigenvalues = la.eigvalsh(D)
eigenvalues_filtered = sorted([val for val in eigenvalues if abs(val) > 1e-8])
pos_eigenvalues = np.array([val for val in eigenvalues_filtered if val > 0])
print("Pos Eigenvalues (first 10):", pos_eigenvalues[:10])

diffs = []
for z_val in true_zeros:
    closest_ev = pos_eigenvalues[np.argmin(np.abs(pos_eigenvalues - z_val))]
    diffs.append(abs(closest_ev - z_val))
mean_err = np.mean(diffs)
print("Computed Mean Absolute Error:", mean_err)
