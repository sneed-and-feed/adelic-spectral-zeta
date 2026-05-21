import numpy as np
import mpmath
import scipy.linalg as la

# True Riemann Zeros (first 50)
true_zeros = np.array([float(mpmath.zetazero(k).imag) for k in range(1, 51)])

primes = [2, 3, 5, 7, 11, 13]
N = 400  # large size to cover all 50 zeros up to 113.29

print("Evaluating closest eigenvalue mapping for different lambda values...")

for lam in [5.0, 10.0, 15.0, 20.0, 30.0]:
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

    # For each true zero, find the closest eigenvalue in pos_eigenvalues
    closest_vals = []
    diffs = []
    for z_val in true_zeros:
        closest_ev = pos_eigenvalues[np.argmin(np.abs(pos_eigenvalues - z_val))]
        closest_vals.append(closest_ev)
        diffs.append(abs(closest_ev - z_val))

    mean_err = np.mean(diffs)
    max_err = np.max(diffs)
    bound = 1.0 / (4.0 * np.log(lam))

    print(f"\nLambda = {lam:.1f}:")
    print(f"  Mean Absolute Error (dissonance) for 50 zeros: {mean_err:.6f}")
    print(f"  Maximum Error: {max_err:.6f}")
    print(f"  Theoretical Lower Bound (1/(4*ln(lambda))): {bound:.6f}")

    if lam == 15.0:
        print("  Sample matches for Lambda = 15.0:")
        for idx in range(10):
            print(f"    Zero {idx+1}: {true_zeros[idx]:.6f} | Match: {closest_vals[idx]:.6f} | Diff: {diffs[idx]:.6f}")
