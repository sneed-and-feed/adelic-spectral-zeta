import os
import csv
import numpy as np
import mpmath
import scipy.linalg as la
import matplotlib.pyplot as plt

# Determine project root dynamically relative to this script
script_dir = os.path.dirname(os.path.abspath(__file__))
figures_dir = os.path.join(script_dir, "..", "figures")
data_dir = os.path.join(script_dir, "..", "data")
os.makedirs(figures_dir, exist_ok=True)
os.makedirs(data_dir, exist_ok=True)

# Set matplotlib backend to Agg to run headlessly
import matplotlib
matplotlib.use('Agg')

print("=== Starting High-Resolution Asymptotic Sweep & Weil Trace Matching ===")

# Parameters for targeted sweep
lambdas = np.arange(20.0, 30.1, 1.0)       # 11 values: 20.0, 21.0, ..., 30.0
Ns = [500, 1000, 1500]                      # 3 values
p_maxs = [61, 101, 151]                     # 3 values

all_primes = [
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101,
    103, 107, 109, 113, 127, 131, 137, 139, 149, 151
]

# Precompute true Riemann zeros (first 150)
print("Precomputing first 150 true Riemann zeros...")
true_zeros = np.array([float(mpmath.zetazero(k).imag) for k in range(1, 151)])

csv_path = os.path.join(data_dir, "high_res_asymptotics.csv")
telemetry_data = []

total_runs = len(lambdas) * len(Ns) * len(p_maxs)
run_idx = 0

with open(csv_path, mode='w', newline='') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow([
        "lambda", "N", "p_max", "mean_error_50", "mean_error_100", "mean_error_150",
        "sliwinski_bound", "dissonance_delta"
    ])

    for N in Ns:
        n_vals = np.arange(-N, N + 1)
        I = np.eye(2*N + 1)

        for lam in lambdas:
            log_lam = np.log(lam)
            D0_diag = n_vals * np.pi / log_lam
            sliwinski_bound = 1.0 / (4.0 * log_lam)

            # Precompute Archimedean factor for (N, lam)
            xi_arch = np.zeros(2*N + 1, dtype=complex)
            for i, n in enumerate(n_vals):
                t = n * np.pi / log_lam
                s_val = 0.25 + 0.5j * t
                psi_val = complex(mpmath.psi(0, s_val))
                xi_arch[i] = 0.5 * (psi_val - np.log(np.pi))

            for p_max in p_maxs:
                run_idx += 1
                if run_idx % 10 == 0 or run_idx == total_runs:
                    print(f"Run {run_idx}/{total_runs} (lam={lam:.1f}, N={N}, p_max={p_max})")

                try:
                    # Primes up to p_max
                    primes = [p for p in all_primes if p <= p_max]

                    # Vector xi
                    xi = xi_arch.copy()
                    for p in primes:
                        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
                        xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)

                    xi_norm = xi / np.linalg.norm(xi)

                    # Projection onto orthogonal complement
                    P = np.outer(xi_norm, np.conj(xi_norm))
                    Proj = I - P

                    # Dirac operator
                    D = Proj @ np.diag(D0_diag) @ Proj

                    # Solve eigenvalues using eigh for high precision
                    eigenvalues = la.eigvalsh(D)
                    eigenvalues_filtered = sorted([val for val in eigenvalues if abs(val) > 1e-8])
                    pos_eigenvalues = np.array([val for val in eigenvalues_filtered if val > 0])

                    if len(pos_eigenvalues) < 150:
                        raise ValueError(f"Too few positive eigenvalues ({len(pos_eigenvalues)}) for 150 zeros.")

                    # Calculate mean absolute errors
                    diffs_50 = []
                    for z_val in true_zeros[:50]:
                        closest_ev = pos_eigenvalues[np.argmin(np.abs(pos_eigenvalues - z_val))]
                        diffs_50.append(abs(closest_ev - z_val))
                    mean_error_50 = np.mean(diffs_50)

                    diffs_100 = []
                    for z_val in true_zeros[:100]:
                        closest_ev = pos_eigenvalues[np.argmin(np.abs(pos_eigenvalues - z_val))]
                        diffs_100.append(abs(closest_ev - z_val))
                    mean_error_100 = np.mean(diffs_100)

                    diffs_150 = []
                    for z_val in true_zeros[:150]:
                        closest_ev = pos_eigenvalues[np.argmin(np.abs(pos_eigenvalues - z_val))]
                        diffs_150.append(abs(closest_ev - z_val))
                    mean_error_150 = np.mean(diffs_150)

                    dissonance_delta = mean_error_50 - sliwinski_bound

                    # Write row
                    writer.writerow([
                        lam, N, p_max, mean_error_50, mean_error_100, mean_error_150,
                        sliwinski_bound, dissonance_delta
                    ])

                    telemetry_data.append({
                        "lambda": lam,
                        "N": N,
                        "p_max": p_max,
                        "mean_error_50": mean_error_50,
                        "mean_error_100": mean_error_100,
                        "mean_error_150": mean_error_150,
                        "sliwinski_bound": sliwinski_bound,
                        "dissonance_delta": dissonance_delta,
                        "pos_eigenvalues": pos_eigenvalues
                    })

                except Exception as e:
                    print(f"Error at lam={lam:.1f}, N={N}, p_max={p_max}: {e}")
                    continue

print("\n--- Micro-sweep complete. Finding optimal run ---")
optimal_run = min(telemetry_data, key=lambda x: x["mean_error_100"])
print(f"Optimal Lambda: {optimal_run['lambda']:.1f}")
print(f"Optimal N: {optimal_run['N']}")
print(f"Optimal p_max: {optimal_run['p_max']}")
print(f"Mean Error (50 zeros): {optimal_run['mean_error_50']:.6f}")
print(f"Mean Error (100 zeros): {optimal_run['mean_error_100']:.6f}")
print(f"Mean Error (150 zeros): {optimal_run['mean_error_150']:.6f}")

# Task B: Weil Explicit Formula Trace Matching for the Optimal Configuration
print("\nPerforming Weil Explicit Formula trace matching for optimal configuration...")
lam_opt = optimal_run['lambda']
N_opt = optimal_run['N']
p_max_opt = optimal_run['p_max']
pos_evs_opt = optimal_run['pos_eigenvalues']

# Setup T grid
T_grid = np.linspace(10, 300, 1000)

# 1. Compute spectral counting function N(T)
N_T = np.zeros_like(T_grid)
for idx, T in enumerate(T_grid):
    N_T[idx] = np.sum(pos_evs_opt <= T)

# 2. Fluctuating part N_fluc(T) = N(T) - T * ln(lambda) / pi
log_lam_opt = np.log(lam_opt)
N_fluc = N_T - T_grid * log_lam_opt / np.pi

# 3. Weil arithmetic sum W(T) = sum_{p <= p_max} (ln p / sqrt(p)) * cos(T * ln p)
primes_opt = [p for p in all_primes if p <= p_max_opt]
W_T = np.zeros_like(T_grid)
for p in primes_opt:
    W_T += (np.log(p) / np.sqrt(p)) * np.cos(T_grid * np.log(p))

# Normalize both for comparison
N_fluc_norm = (N_fluc - np.mean(N_fluc)) / np.std(N_fluc)
W_T_norm = (W_T - np.mean(W_T)) / np.std(W_T)

# 4. Compute correlation coefficient
corr_matrix = np.corrcoef(N_fluc, W_T)
correlation = corr_matrix[0, 1]
print(f"Statistical correlation between N_fluc(T) and Weil arithmetic sum: {correlation:.6f}")

# Task C: Asymptotic Convergence Reporting & Dual-Panel Visualization
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))

# Panel 1: Error trajectories against matrix size N
# For the optimal lambda and p_max, get data for different N
trajectories = [d for d in telemetry_data if d['lambda'] == lam_opt and d['p_max'] == p_max_opt]
trajectories_sorted = sorted(trajectories, key=lambda x: x['N'])

n_values = [d['N'] for d in trajectories_sorted]
err_50 = [d['mean_error_50'] for d in trajectories_sorted]
err_100 = [d['mean_error_100'] for d in trajectories_sorted]
err_150 = [d['mean_error_150'] for d in trajectories_sorted]

ax1.plot(n_values, err_50, 'o-', color='#1a73e8', linewidth=2, label='Mean Error (First 50 Zeros)')
ax1.plot(n_values, err_100, 's-', color='#d93025', linewidth=2, label='Mean Error (First 100 Zeros)')
ax1.plot(n_values, err_150, '^-', color='#f9ab00', linewidth=2, label='Mean Error (First 150 Zeros)')
ax1.axhline(optimal_run['sliwinski_bound'], color='black', linestyle='--', label=f'Sliwinski Bound ({optimal_run["sliwinski_bound"]:.4f})')
ax1.set_xlabel('Matrix Resolution Parameter N')
ax1.set_ylabel('Mean Absolute Error (dissonance)')
ax1.set_title(f'Asymptotic Convergence of Spectral Zeros (lambda={lam_opt}, p_max={p_max_opt})')
ax1.grid(True, linestyle='--', alpha=0.5)
ax1.legend()

# Panel 2: Alignment wave tracking the matrix spectral fluctuations against Weil arithmetic comb
ax2.plot(T_grid, N_fluc_norm, color='#d93025', alpha=0.7, label='Normalized Spectral Fluctuations (N_fluc)')
ax2.plot(T_grid, W_T_norm, color='#1a73e8', alpha=0.5, label='Normalized Weil Arithmetic Comb (W_T)')
ax2.set_xlabel('Spectral Energy / Frequency (T)')
ax2.set_ylabel('Normalized Amplitude')
ax2.set_title(f'Spectral Fluctuation vs Weil Explicit Formula (corr={correlation:.4f})')
ax2.grid(True, linestyle='--', alpha=0.5)
ax2.legend()

plt.tight_layout()
plt.savefig(os.path.join(figures_dir, "horizon_expansion_analysis.png"), dpi=300)
plt.close()

print(f"Dual-panel plot saved to {os.path.join(figures_dir, 'horizon_expansion_analysis.png')}")
print("=== Asymptotic Sweep Completed Successfully ===")
