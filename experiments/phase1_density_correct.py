"""
Adelic Spectral Zeta: phase1_density_correct.py
"""

import numpy as np
from scipy.special import digamma, lambertw
from scipy.optimize import least_squares, brentq
import matplotlib.pyplot as plt
import os
import mpmath

os.makedirs('figures', exist_ok=True)

# =============================================================================
# 1. DENSITY-CORRECT UNPERTURBED OPERATOR (FAST)
# =============================================================================

def riemann_von_mangoldt_inverse(n):
    """Solve N(T) = n for T using Lambert W + Newton refinement."""
    if n <= 0:
        return 0.0
    w = lambertw(n / np.e).real
    T = 2 * np.pi * n / w
    for _ in range(5):
        N_val = (T / (2*np.pi)) * np.log(T / (2*np.pi)) - T / (2*np.pi)
        dN = np.log(T / (2*np.pi)) / (2*np.pi)
        T = T - (N_val - n) / dN
    return T

def build_D0_density_correct(N):
    """Build diagonal operator D0 with Riemann-von Mangoldt density."""
    n_pos = np.arange(1, N+1)
    t_pos = np.array([riemann_von_mangoldt_inverse(n) for n in n_pos])
    t_neg = -t_pos[::-1]
    return np.concatenate([t_neg, t_pos])

# =============================================================================
# 2. KREIN SECULAR EQUATION
# =============================================================================

def krein_solver(t_n, xi):
    """Solve f(z) = 1 + sum |xi_n|^2 / (t_n - z) = 0 via brentq."""
    xi_sq = np.abs(xi)**2
    t_sorted = np.sort(t_n)
    perturbed = []
    spacing = np.min(np.diff(t_sorted))
    eps = spacing * 1e-6
    
    def secular(z):
        return 1.0 + np.sum(xi_sq / (t_n - z))
    
    for i in range(len(t_sorted) - 1):
        a, b = t_sorted[i], t_sorted[i+1]
        if a < 0 < b:
            continue
        
        fa, fb = secular(a + eps), secular(b - eps)
        if fa * fb > 0:
            continue
            
        try:
            root = brentq(secular, a + eps, b - eps, xtol=1e-12, maxiter=50)
            perturbed.append(root)
        except ValueError:
            pass
    
    return np.array(perturbed)

# =============================================================================
# 3. VECTORIZED PERTURBATION VECTOR (NO mpmath)
# =============================================================================

def build_xi(params, t_n, primes):
    """Fully vectorized xi construction using scipy.special.digamma."""
    lam = params[0]
    k = len(primes)
    prime_weights = params[1:1+k]
    arch_coeff = params[1+k]
    arch_offset = params[2+k]
    
    log_lam = np.log(lam)
    xi = np.zeros(len(t_n), dtype=complex)
    
    # Prime contributions (vectorized)
    for j, p in enumerate(primes):
        phases = -1j * t_n * np.log(p) / log_lam
        xi += prime_weights[j] * np.exp(phases)
    
    # Archimedean contribution (fully vectorized, no loops)
    s_val = np.where(np.abs(t_n) < 1e-10, 0.25, 0.25 + 0.5j * t_n)
    psi_val = digamma(s_val)
    xi += arch_coeff * (psi_val - arch_offset)
    
    return xi

# =============================================================================
# 4. RESIDUAL + OPTIMIZATION
# =============================================================================

def residual(params, t_n, primes, true_zeros, K_start=0):
    """Compute (predicted - true) for K positive perturbed eigenvalues starting at K_start."""
    xi = build_xi(params, t_n, primes)
    perturbed = krein_solver(t_n, xi)
    pos = np.sort(perturbed[perturbed > 0])
    K = len(true_zeros)
    
    # We want pos[K_start : K_start+K]
    target_pos = pos[K_start : K_start+K]
    
    if len(target_pos) < K:
        pad = np.full(K, 1e6)
        pad[:len(target_pos)] = target_pos - true_zeros[:len(target_pos)]
        return pad
    
    return target_pos[:K] - true_zeros

def run_optimization(N, primes, K=50, K_start=0):
    """Full density-correct + Krein + least-squares pipeline."""
    print(f"\\n{'='*60}")
    print(f"OPTIMIZATION: N={N}, Matrix={2*N+1}, Targets={K} (starting at index {K_start})")
    print(f"{'='*60}")
    
    # True Riemann zeros (FAST: precompute once)
    true_zeros = np.array([float(mpmath.zetazero(k).imag) for k in range(K_start+1, K_start+K+1)])
    
    t_n = build_D0_density_correct(N)
    print(f"D0 range: [{t_n.min():.2f}, {t_n.max():.2f}]")
    print(f"Target D0: {np.sort(t_n[t_n > 0])[K_start:K_start+5]}")
    print(f"Target true: {true_zeros[:5]}")
    
    # Initial guess
    x0 = np.concatenate([
        [15.0],
        [np.log(p)/np.sqrt(p) for p in primes],
        [0.5, np.log(np.pi)]
    ])
    
    lower = np.concatenate([[1.0], [-5.0]*len(primes), [0.0, 0.0]])
    upper = np.concatenate([[100.0], [5.0]*len(primes), [5.0, 5.0]])
    
    print(f"Params: {len(x0)} | Targets: {K}")
    print(f"Initial MAE: {np.mean(np.abs(residual(x0, t_n, primes, true_zeros, K_start))):.4f}")
    
    result = least_squares(
        residual, x0,
        args=(t_n, primes, true_zeros, K_start),
        bounds=(lower, upper),
        method='trf',
        max_nfev=2000,
        ftol=1e-10, xtol=1e-10,
        verbose=0
    )
    
    xi_opt = build_xi(result.x, t_n, primes)
    perturbed_opt = krein_solver(t_n, xi_opt)
    pos_opt = np.sort(perturbed_opt[perturbed_opt > 0])
    predicted = pos_opt[K_start : K_start+K]
    actual_K = len(predicted)
    diffs = np.abs(predicted - true_zeros[:actual_K])
    mae = np.mean(diffs)
    
    print(f"\\nSuccess: {result.success} | Cost: {result.cost:.6f}")
    print(f"MAE: {mae:.6f} | MaxErr: {np.max(diffs):.6f}")
    print(f"Lambda: {result.x[0]:.4f}")
    print(f"Prime weights: {np.round(result.x[1:1+len(primes)], 4)}")
    print(f"Arch coeff: {result.x[1+len(primes)]:.4f}")
    print(f"Arch offset: {result.x[2+len(primes)]:.4f}")
    print(f"Predicted[0:5]: {np.round(predicted[:5], 4)}")
    print(f"True[0:5]:      {np.round(true_zeros[:5], 4)}")
    
    return result

# =============================================================================
# 5. RUN IT
# =============================================================================
if __name__ == "__main__":
    primes = [2, 3, 5, 7, 11, 13]
    # Skip the first 10 zeros, target the next 15
    res = run_optimization(N=50, primes=primes, K=15, K_start=10)
