import os
import numpy as np
import mpmath
import scipy.linalg as la
import matplotlib.pyplot as plt

# Ensure figures directory exists
script_dir = os.path.dirname(os.path.abspath(__file__))
figures_dir = os.path.join(script_dir, "..", "figures")
os.makedirs(figures_dir, exist_ok=True)

# Set matplotlib backend to Agg to run headlessly
import matplotlib
matplotlib.use('Agg')

print("=== Starting Dirichlet L-Function Adélic Spectral Triple Sandbox Modulo 3 ===")

# Define the primitive Dirichlet character modulo 3
# chi(1) = 1, chi(2) = -1, chi(3) = 0 (and periodic)
def chi_3(p):
    if p % 3 == 0:
        return 0.0
    elif p % 3 == 1:
        return 1.0
    else:
        return -1.0

# Primes up to 43
primes_43 = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43]

# 1. Compute true zeros of L(s, chi_3)
print("Computing first 30 non-trivial zeros of L(s, chi_3) on the critical line...")
def L_3(t):
    s = 0.5 + 1j * t
    return 3**(-s) * (mpmath.hurwitz(s, 1/3) - mpmath.hurwitz(s, 2/3))

def xi_3(t):
    s = 0.5 + 1j * t
    gamma_factor = mpmath.gamma((s + 1) / 2)
    conductor_factor = (3 / mpmath.pi)**((s + 1) / 2)
    return conductor_factor * gamma_factor * L_3(t)

# Find first 30 zeros by scanning t
t_grid = mpmath.linspace(0, 100, 3000)
y_vals = [float(xi_3(t).real) for t in t_grid]

true_zeros = []
for i in range(len(t_grid) - 1):
    if y_vals[i] * y_vals[i+1] < 0:
        root = mpmath.findroot(lambda t: xi_3(t).real, (t_grid[i], t_grid[i+1]))
        true_zeros.append(float(root))
        if len(true_zeros) == 30:
            break

true_zeros = np.array(true_zeros)
print("First 30 zeros computed successfully.")
print(f"Sample zeros: {true_zeros[:5]}")

# 2. Run scan for optimal lambda
print("\nScanning scale parameter lambda in [5.0, 30.0] for N = 300...")
N = 300
n_vals = np.arange(-N, N + 1)
I = np.eye(2*N + 1)

best_err = float('inf')
best_lam = 0.0
best_evs = None

# Character Mod 3 parameters
q = 3
a = 1  # odd character

for lam in np.arange(5.0, 30.1, 0.5):
    log_lam = np.log(lam)
    D0_diag = n_vals * np.pi / log_lam

    # Construct twisted vector xi
    xi = np.zeros(2*N + 1, dtype=complex)
    for p in primes_43:
        chi_val = chi_3(p)
        if chi_val == 0:
            continue
        # Twisting by character
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        xi += (chi_val * np.log(p) / np.sqrt(p)) * np.exp(phases)

    # Parity-shifted Archimedean factor
    for i, n in enumerate(n_vals):
        t = n * np.pi / log_lam
        s_val = 0.25 + 0.5j * t
        psi_val = complex(mpmath.psi(0, (s_val + a) / 2))
        xi[i] += 0.5 * (psi_val + np.log(q / np.pi))

    # Normalize
    xi_norm = xi / np.linalg.norm(xi)

    # Projection
    P = np.outer(xi_norm, np.conj(xi_norm))
    Proj = I - P

    # Dirac operator
    D = Proj @ np.diag(D0_diag) @ Proj

    # Solve eigenvalues
    eigenvalues = la.eigvalsh(D)
    eigenvalues_filtered = sorted([val for val in eigenvalues if abs(val) > 1e-8])
    pos_eigenvalues = np.array([val for val in eigenvalues_filtered if val > 0])

    # Find closest matches for the first 30 zeros
    diffs = []
    for z_val in true_zeros:
        closest_ev = pos_eigenvalues[np.argmin(np.abs(pos_eigenvalues - z_val))]
        diffs.append(abs(closest_ev - z_val))
    mean_err = np.mean(diffs)

    if mean_err < best_err:
        best_err = mean_err
        best_lam = lam
        best_evs = pos_eigenvalues

print(f"\n--- Dirichlet Optimization Results ---")
print(f"Optimal Lambda: {best_lam:.1f}")
print(f"Minimum Mean Absolute Error (30 zeros): {best_err:.6f}")
print(f"Theoretical Lower Bound: 1 / (4 * ln(lambda)) = {1.0 / (4.0 * np.log(best_lam)):.6f}")

# Find matches for plotting
closest_matches = []
for z_val in true_zeros:
    closest_ev = best_evs[np.argmin(np.abs(best_evs - z_val))]
    closest_matches.append(closest_ev)

# Weil explicit formula matching for characters
# W_chi(T) = sum_p (ln p / sqrt(p)) * chi(p) * cos(T * ln p)
T_grid = np.linspace(10, 100, 1000)

# Compute spectral fluctuations
N_T = np.zeros_like(T_grid)
for idx, T in enumerate(T_grid):
    N_T[idx] = np.sum(best_evs <= T)
N_fluc = N_T - T_grid * np.log(best_lam) / np.pi

# Compute Weil sum
W_T = np.zeros_like(T_grid)
for p in primes_43:
    W_T += (chi_3(p) * np.log(p) / np.sqrt(p)) * np.cos(T_grid * np.log(p))

N_fluc_norm = (N_fluc - np.mean(N_fluc)) / np.std(N_fluc)
W_T_norm = (W_T - np.mean(W_T)) / np.std(W_T)

corr = np.corrcoef(N_fluc, W_T)[0, 1]
print(f"Statistical correlation with Dirichlet Weil comb: {corr:.6f}")

# Plotting
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))

# Left Panel: Eigenvalue Alignment
ax1.plot(range(1, 31), true_zeros, 'o-', color='#1a73e8', linewidth=2, label='True Dirichlet Zeros')
ax1.plot(range(1, 31), closest_matches, 'x--', color='#d93025', linewidth=2, label='Twisted Spectral Eigenvalues')
ax1.set_xlabel('Zero Index')
ax1.set_ylabel('Imaginary Part / Eigenvalue')
ax1.set_title(f'Eigenvalue Alignment with L(s, chi_3) Zeros (lambda={best_lam:.1f})')
ax1.grid(True, linestyle='--', alpha=0.5)
ax1.legend()

# Right Panel: Weil Character Trace Matching
ax2.plot(T_grid, N_fluc_norm, color='#d93025', alpha=0.7, label='Normalized Spectral Fluctuations')
ax2.plot(T_grid, W_T_norm, color='#1a73e8', alpha=0.5, label='Normalized Dirichlet Weil Comb')
ax2.set_xlabel('Spectral Energy / Frequency (T)')
ax2.set_ylabel('Normalized Amplitude')
ax2.set_title(f'Twisted Fluctuation vs Dirichlet Weil Comb (corr={corr:.4f})')
ax2.grid(True, linestyle='--', alpha=0.5)
ax2.legend()

plt.savefig(os.path.join(figures_dir, "dirichlet_character_resonance.png"), dpi=300)
plt.close()

print(f"Plots successfully saved to {os.path.join(figures_dir, 'dirichlet_character_resonance.png')}")
print("=== Dirichlet Sandbox Modulo 3 Sweep Finished ===")
