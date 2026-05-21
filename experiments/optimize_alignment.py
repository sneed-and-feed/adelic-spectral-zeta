import numpy as np
import mpmath
import scipy.linalg as la

# True Riemann Zeros (first 50)
true_zeros = np.array([float(mpmath.zetazero(k).imag) for k in range(1, 51)])

primes = [2, 3, 5, 7, 11, 13]
N = 300

best_err = float('inf')
best_params = {}

print("Scanning parameter space for optimal aligned spectral zeros...")

# Let's search over lambda
for lam in [2.0, 5.0, 10.0, 15.0, 20.0]:
    log_lam = np.log(lam)
    n_vals = np.arange(-N, N + 1)
    D0_diag = n_vals * np.pi / log_lam

    # Vector xi representing primes + Archimedean factor
    xi = np.zeros(2*N + 1, dtype=complex)
    for p in primes:
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)

    for i, n in enumerate(n_vals):
        t = n * np.pi / log_lam
        s = 0.25 + 0.5j * t
        psi_val = complex(mpmath.psi(0, s))
        xi[i] += 0.5 * (psi_val - np.log(np.pi))

    # Normalize xi
    xi_norm = xi / np.linalg.norm(xi)

    # Projected operator D = Proj * D0 * Proj
    I = np.eye(2*N + 1)
    P = np.outer(xi_norm, np.conj(xi_norm))
    Proj = I - P
    D = Proj @ np.diag(D0_diag) @ Proj

    # Solve eigenvalues
    eigenvalues = la.eigvalsh(D)
    eigenvalues_filtered = sorted([val for val in eigenvalues if abs(val) > 1e-8])
    pos_eigenvalues = np.array([val for val in eigenvalues_filtered if val > 0])

    # Search for optimal index offset
    for offset in range(len(pos_eigenvalues) - 50):
        candidate = pos_eigenvalues[offset : offset + 50]
        err = np.mean(np.abs(candidate - true_zeros))
        if err < best_err:
            best_err = err
            best_params = {
                'lambda': lam,
                'offset': offset,
                'mean_absolute_error': err,
                'eigenvalues': candidate
            }

print("\n--- Optimization Results ---")
print(f"Optimal Lambda: {best_params['lambda']}")
print(f"Optimal Index Offset: {best_params['offset']}")
print(f"Mean Absolute Error (dissonance) for first 50 zeros: {best_params['mean_absolute_error']:.6f}")
print(f"Theoretical Lower Bound: 1 / (4 * ln(lambda)) = {1.0 / (4.0 * np.log(best_params['lambda'])):.6f}")

print("\nComparing first 10 aligned eigenvalues with true zeros:")
for i in range(10):
    val_spec = best_params['eigenvalues'][i]
    val_true = true_zeros[i]
    print(f"Index {i+1}: Aligned Eigenvalue = {val_spec:.6f} | True Zero = {val_true:.6f} | Diff = {abs(val_spec - val_true):.6f}")
