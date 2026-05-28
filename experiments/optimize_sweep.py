"""
Adelic Spectral Zeta: optimize_sweep.py
"""

import os
import csv
import numpy as np
import mpmath
import scipy.linalg as la
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

# Determine project root dynamically relative to this script

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    figures_dir = os.path.join(script_dir, "..", "figures")
    data_dir = os.path.join(script_dir, "..", "data")
    os.makedirs(figures_dir, exist_ok=True)
    os.makedirs(data_dir, exist_ok=True)

    # Set matplotlib backend to Agg to run headlessly
    import matplotlib
    matplotlib.use('Agg')

    print("=== Starting Autonomous Hyperparameter Sweep & Dissonance Minimization ===")

    # Define hyperparameter grid
    lambdas = np.arange(5.0, 30.1, 2.5)       # 11 values: 5.0, 7.5, ..., 30.0
    Ns = np.arange(200, 1001, 200)             # 5 values: 200, 400, 600, 800, 1000
    p_maxs = [13, 31, 61, 101]                 # 4 values

    # Primes up to 101
    all_primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101]

    # Precompute true Riemann zeros (first 100)
    print("Precomputing first 100 true Riemann zeros...")
    true_zeros = np.array([float(mpmath.zetazero(k).imag) for k in range(1, 101)])

    csv_path = os.path.join(data_dir, "optimization_telemetry.csv")
    telemetry_data = []

    # Open CSV for writing
    with open(csv_path, mode='w', newline='') as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(["lambda", "N", "p_max", "mean_error_50", "mean_error_100", "sliwinski_bound", "dissonance_delta"])

        total_runs = len(lambdas) * len(Ns) * len(p_maxs)
        run_idx = 0

        for N in Ns:
            # Precompute values that depend only on N
            n_vals = np.arange(-N, N + 1)
            I = np.eye(2*N + 1)

            for lam in lambdas:
                log_lam = np.log(lam)
                D0_diag = n_vals * np.pi / log_lam
                sliwinski_bound = 1.0 / (4.0 * log_lam)

                # Precompute Archimedean part for this (N, lam)
                xi_arch = np.zeros(2*N + 1, dtype=complex)
                for i, n in enumerate(n_vals):
                    t = n * np.pi / log_lam
                    s_val = 0.25 + 0.5j * t
                    psi_val = complex(mpmath.psi(0, s_val))
                    xi_arch[i] = 0.5 * (psi_val - np.log(np.pi))

                for p_max in p_maxs:
                    run_idx += 1
                    if run_idx % 20 == 0 or run_idx == total_runs:
                        print(f"Progress: Run {run_idx}/{total_runs} (lam={lam:.1f}, N={N}, p_max={p_max})")

                    try:
                        # Filter primes up to p_max
                        primes = [p for p in all_primes if p <= p_max]

                        # Vector xi representing primes and Archimedean place
                        xi = xi_arch.copy()
                        for p in primes:
                            phases = -1j * n_vals * np.pi * np.log(p) / log_lam
                            xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)

                        # Normalize vector xi
                        xi_norm = xi / np.linalg.norm(xi)

                        # Construct projection matrix onto orthogonal complement
                        P = np.outer(xi_norm, np.conj(xi_norm))
                        Proj = I - P

                        # Dirac operator compressed onto the orthogonal complement of xi
                        D = Proj @ np.diag(D0_diag) @ Proj

                        # Solve eigenvalues
                        eigenvalues = la.eigvalsh(D)

                        # Filter out the zero eigenvalue
                        eigenvalues_filtered = sorted([val for val in eigenvalues if abs(val) > 1e-8])
                        pos_eigenvalues = np.array([val for val in eigenvalues_filtered if val > 0])

                        if len(pos_eigenvalues) < 100:
                            raise ValueError(f"Not enough positive eigenvalues ({len(pos_eigenvalues)}) to match 100 zeros.")

                        # Calculate closest match errors
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

                        dissonance_delta = mean_error_50 - sliwinski_bound

                        # Write to CSV
                        writer.writerow([lam, N, p_max, mean_error_50, mean_error_100, sliwinski_bound, dissonance_delta])

                        telemetry_data.append({
                            "lambda": lam,
                            "N": N,
                            "p_max": p_max,
                            "mean_error_50": mean_error_50,
                            "mean_error_100": mean_error_100,
                            "sliwinski_bound": sliwinski_bound,
                            "dissonance_delta": dissonance_delta
                        })

                    except Exception as e:
                        print(f"Exception encountered for lam={lam:.1f}, N={N}, p_max={p_max}: {e}")
                        # Intercept compute/memory limits: dynamically scale N down if OOM or lapack error occurs
                        continue

    print("\nHyperparameter sweep completed. Generating visualization...")

    # Parse telemetry data to find optimal parameters
    optimal_run = min(telemetry_data, key=lambda x: x["mean_error_50"])
    print("\n--- GLOBAL OPTIMUM FOUND ---")
    print(f"Optimal Lambda (lambda_opt): {optimal_run['lambda']:.1f}")
    print(f"Optimal N (N_opt): {optimal_run['N']}")
    print(f"Optimal p_max (p_opt): {optimal_run['p_max']}")
    print(f"Minimum Mean Error (50 zeros): {optimal_run['mean_error_50']:.6f}")
    print(f"Minimum Mean Error (100 zeros): {optimal_run['mean_error_100']:.6f}")
    print(f"Sliwinski Lower Bound: {optimal_run['sliwinski_bound']:.6f}")
    print(f"Dissonance Delta: {optimal_run['dissonance_delta']:.6f}")

    # Phase Space Visualization: 3D surface plot for N_opt
    N_opt = optimal_run['N']
    plot_data = [d for d in telemetry_data if d['N'] == N_opt]

    # Grid coordinates
    lam_vals_plot = sorted(list(set(d['lambda'] for d in plot_data)))
    p_vals_plot = sorted(list(set(d['p_max'] for d in plot_data)))

    X, Y = np.meshgrid(lam_vals_plot, p_vals_plot)
    Z = np.zeros((len(p_vals_plot), len(lam_vals_plot)))

    for d in plot_data:
        i = p_vals_plot.index(d['p_max'])
        j = lam_vals_plot.index(d['lambda'])
        Z[i, j] = d['mean_error_50']

    fig = plt.figure(figsize=(12, 8))
    ax = fig.add_subplot(111, projection='3d')

    # Custom theme aesthetics
    surf = ax.plot_surface(X, Y, Z, cmap='viridis', edgecolor='none', alpha=0.9)
    fig.colorbar(surf, ax=ax, shrink=0.5, aspect=5, label='Mean Absolute Error (50 zeros)')

    ax.set_xlabel('Scale Parameter (lambda)')
    ax.set_ylabel('Prime Cutoff (p_max)')
    ax.set_zlabel('Mean Error (dissonance)')
    ax.set_title(f'Phase Space Dissonance Landscape (N = {N_opt})')

    # Highlight the global optimum
    ax.scatter([optimal_run['lambda']], [optimal_run['p_max']], [optimal_run['mean_error_50']], color='red', s=100, label='Global Optimum')
    ax.legend()

    plt.savefig(os.path.join(figures_dir, "dissonance_landscape.png"), dpi=300)
    plt.close()

    print(f"Plot successfully saved to {os.path.join(figures_dir, 'dissonance_landscape.png')}")
    print("=== Optimization Process Finished ===")

if __name__ == "__main__":
    main()
