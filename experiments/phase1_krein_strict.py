"""
Adelic Spectral Zeta: phase1_krein_strict.py
"""

import numpy as np
import scipy.optimize as opt
import mpmath

def compute_perturbed_eigenvalues(lam, N, primes):
    """
    Solve the Krein secular equation for a rank-1 perturbation.
    Returns perturbed eigenvalues via index-to-index comparison.
    """
    log_lam = np.log(lam)
    n_vals = np.arange(-N, N + 1)
    lambda_n = n_vals * np.pi / log_lam  # unperturbed eigenvalues
    
    # Construct xi vector (same physical model as original)
    xi = np.zeros(2*N + 1, dtype=complex)
    for p in primes:
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)
    
    # Archimedean contribution (digamma)
    for i, n in enumerate(n_vals):
        t = n * np.pi / log_lam
        s_val = 0.25 + 0.5j * t
        psi_val = complex(mpmath.psi(0, s_val))
        xi[i] += 0.5 * (psi_val - np.log(np.pi))
    
    xi_sq = np.abs(xi)**2
    
    # Krein secular equation: f(z) = 1 + sum |xi_n|^2 / (lambda_n - z)
    def secular(z):
        return 1.0 + np.sum(xi_sq / (lambda_n - z))
    
    # Find one root in each interval between consecutive unperturbed eigenvalues
    lambda_sorted = np.sort(lambda_n)
    perturbed = []
    spacing = np.pi / log_lam
    eps = spacing * 1e-6
    
    for i in range(len(lambda_sorted) - 1):
        a, b = lambda_sorted[i], lambda_sorted[i+1]
        try:
            root = opt.brentq(secular, a + eps, b - eps, xtol=1e-14, maxiter=100)
            perturbed.append(root)
        except ValueError:
            pass  # No sign change (rare if xi_n = 0)
    
    return np.array(perturbed), lambda_n, xi

def evaluate_convergence(lam, N_values, primes, max_zero_idx=50):
    """
    STRICT index-to-index comparison. No cherry-picking.
    """
    true_zeros = np.array([float(mpmath.zetazero(k).imag) 
                           for k in range(1, max_zero_idx + 1)])
    
    for N in N_values:
        perturbed, lambda_n, xi = compute_perturbed_eigenvalues(lam, N, primes)
        pos_perturbed = np.sort(perturbed[perturbed > 0])
        
        if len(pos_perturbed) < max_zero_idx:
            print(f"N={N}: Only {len(pos_perturbed)} positive eigenvalues")
            continue
        
        # STRICT: first 50 predicted vs first 50 true, index-to-index
        predicted = pos_perturbed[:max_zero_idx]
        diffs = np.abs(predicted - true_zeros)
        mae = np.mean(diffs)
        
        print(f"N={N}: MAE={mae:.4f}, max_err={np.max(diffs):.4f}")
        print(f"  Predicted first 5: {predicted[:5]}")
        print(f"  True first 5:      {true_zeros[:5]}")

if __name__ == "__main__":
    primes_13 = [2, 3, 5, 7, 11, 13]
    evaluate_convergence(lam=15.0, N_values=[100, 200, 400, 800], primes=primes_13)
