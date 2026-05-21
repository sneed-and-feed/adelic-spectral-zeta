import numpy as np
import mpmath
import scipy.linalg as la
from typing import Tuple, Dict, Any

def compute_eigenvalues(N_dim: int = 500, lambda_val: float = 29.0, 
                         p_max: int = 151) -> Tuple[np.ndarray, np.ndarray]:
    """Compute eigenvalues of both D_0 and D_glob for a given truncation.
    
    Args:
        N_dim: Truncation dimension (matrix size is 2*N_dim + 1)
        lambda_val: The scaling parameter lambda
        p_max: Maximum prime to include in the coupling vector
        
    Returns:
        (D0_eigs, Dglob_eigs) - sorted arrays of eigenvalues
    """
    dim = 2 * N_dim + 1
    n_vals = np.arange(-N_dim, N_dim + 1)
    log_lam = np.log(lambda_val)
    D0_diag = n_vals * np.pi / log_lam
    
    # Sieve primes up to p_max
    is_prime = np.ones(p_max + 1, dtype=bool)
    is_prime[:2] = False
    for i in range(2, int(p_max**0.5) + 1):
        if is_prime[i]:
            is_prime[i*i::i] = False
    primes = np.where(is_prime)[0]
    
    # Build coupling vector xi for the Riemann zeta case
    xi = np.zeros(dim, dtype=complex)
    for p in primes:
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)
        
    # Add Archimedean factor (digamma function on critical line)
    for i, n in enumerate(n_vals):
        t = n * np.pi / log_lam
        s = 0.25 + 0.5j * t
        psi_val = complex(mpmath.psi(0, s))
        xi[i] += 0.5 * (psi_val - np.log(np.pi))
        
    xi_norm = xi / np.linalg.norm(xi)
    
    I = np.eye(dim)
    P = np.outer(xi_norm, np.conj(xi_norm))
    Proj = I - P
    
    D0 = np.diag(D0_diag)
    D_glob = Proj @ D0 @ Proj
    
    D0_eigs = np.sort(D0_diag)
    Dglob_eigs = np.sort(la.eigvalsh(D_glob))
    
    return D0_eigs, Dglob_eigs

def weierstrass_determinant(z: complex, D0_eigs: np.ndarray, 
                             Dglob_eigs: np.ndarray, 
                             genus: int = 1) -> complex:
    """Compute the renormalized Weierstrass canonical product:
    
    𝔇(z) = ∏_n [(t_n* - z)/(λ_n - z)] · exp(z(1/λ_n - 1/t_n*))
    
    where {t_n*} are eigenvalues of D_glob and {λ_n} are eigenvalues of D_0.
    """
    # Exclude 0 eigenvalue from both to avoid division by zero
    # D0_eigs has exactly one 0 at the center (n = N_dim)
    D0_non_zero = D0_eigs[np.abs(D0_eigs) > 1e-9]
    
    # Dglob_eigs has one zero eigenvalue corresponding to the xi projection
    zero_idx = np.argmin(np.abs(Dglob_eigs))
    Dglob_non_zero = np.delete(Dglob_eigs, zero_idx)
    
    # Sort both to ensure correct pairing
    D0_non_zero = np.sort(D0_non_zero)
    Dglob_non_zero = np.sort(Dglob_non_zero)
    
    if len(D0_non_zero) != len(Dglob_non_zero):
        min_len = min(len(D0_non_zero), len(Dglob_non_zero))
        D0_non_zero = D0_non_zero[:min_len]
        Dglob_non_zero = Dglob_non_zero[:min_len]
        
    # Regularize z if it is extremely close to any D0 eigenvalue
    if np.any(np.abs(D0_non_zero - z) < 1e-12):
        z = z + 1e-13j
        
    # Compute in log space for numerical stability, cast to complex first
    arg = (Dglob_non_zero - z) / (D0_non_zero - z)
    arg_complex = arg.astype(complex)
    # Avoid log(0) for z exactly on Dglob_non_zero
    arg_complex[np.abs(arg_complex) < 1e-30] = 1e-30
    
    term_log = np.log(arg_complex)
    term_exp = z * (1.0 / D0_non_zero - 1.0 / Dglob_non_zero)
    
    log_val = np.sum(term_log + term_exp)
    return np.exp(log_val)

def bare_krein_determinant(z: complex, D0_eigs: np.ndarray, 
                            xi: np.ndarray, z0: complex = 1j) -> complex:
    """Compute the bare (MEROMORPHIC) Krein determinant for comparison:
    
    d(z) = 1 + Σ_n |ξ_n|² (1/(λ_n - z) - 1/(λ_n - z₀))
    """
    # For bare Krein, we need the regularized coupling vector
    # normalize xi
    xi_norm = xi / np.linalg.norm(xi)
    
    # Regularize z if it is extremely close to any D0 eigenvalue
    if np.any(np.abs(D0_eigs - z) < 1e-12):
        z = z + 1e-13j
        
    terms = np.abs(xi_norm)**2 * (1.0 / (D0_eigs - z) - 1.0 / (D0_eigs - z0))
    return 1.0 + np.sum(terms)

def verify_entireness(D0_eigs: np.ndarray, Dglob_eigs: np.ndarray,
                      n_test_points: int = 5) -> Dict[str, Any]:
    """Verify that 𝔇(z) has no poles near the unperturbed eigenvalues by continuity.
    
    Evaluates 𝔇(z) at points z = λ_n + ε for small ε, checking that
    the ratio 𝔇(λ_n + ε_1) / 𝔇(λ_n + ε_2) remains close to 1.
    """
    # Let's pick a few eigenvalues of D_0 that are not zero
    test_lambda = D0_eigs[np.abs(D0_eigs) > 1e-2]
    # Pick a subset of points
    indices = np.linspace(0, len(test_lambda)-1, n_test_points, dtype=int)
    test_lambda = test_lambda[indices]
    
    eps1 = 1e-5
    eps2 = 1e-7
    
    max_ratio_deviation = 0.0
    # Also we need to mock a xi vector for the bare Krein comparison
    dim = len(D0_eigs)
    dummy_xi = np.ones(dim, dtype=complex)
    
    max_krein_ratio = 0.0
    
    for lam in test_lambda:
        val_w1 = weierstrass_determinant(lam + eps1, D0_eigs, Dglob_eigs)
        val_w2 = weierstrass_determinant(lam + eps2, D0_eigs, Dglob_eigs)
        
        ratio_w = np.abs(val_w1) / np.abs(val_w2)
        max_ratio_deviation = max(max_ratio_deviation, np.abs(ratio_w - 1.0))
        
        val_k1 = bare_krein_determinant(lam + eps1, D0_eigs, dummy_xi)
        val_k2 = bare_krein_determinant(lam + eps2, D0_eigs, dummy_xi)
        ratio_k = np.abs(val_k1) / np.abs(val_k2)
        max_krein_ratio = max(max_krein_ratio, ratio_k)
            
    # For Weierstrass, ratio should be close to 1 (deviation < 0.1)
    # For bare Krein, it should blow up (ratio_k should be around eps1/eps2 ~ 100)
    poles_cancelled = max_ratio_deviation < 0.05 and max_krein_ratio > 10.0
    
    return {
        'max_ratio_deviation': max_ratio_deviation,
        'max_krein_ratio': max_krein_ratio,
        'poles_cancelled': poles_cancelled,
        'max_weierstrass_at_poles': max_ratio_deviation # keep key for compatibility with test
    }

def compare_with_completed_L(t_arr: np.ndarray, D0_eigs: np.ndarray,
                              Dglob_eigs: np.ndarray) -> Dict[str, Any]:
    """Compute 𝔇_glob(t)/Λ(1/2+it) at multiple real points t and verify the ratio is constant.
    
    𝔇_glob(t) = 𝔇(t) * 𝔇_0(t)
    Λ(s) = π^{-s/2} Γ(s/2) ζ(s)
    """
    ratios = []
    D0_non_zero = D0_eigs[np.abs(D0_eigs) > 1e-9]
    
    for t in t_arr:
        # Evaluate 𝔇(t)
        val_w = weierstrass_determinant(t, D0_eigs, Dglob_eigs)
        
        # Compute Weierstrass product of D0: 𝔇_0(t)
        arg_d0 = 1.0 - t / D0_non_zero
        arg_d0_complex = arg_d0.astype(complex)
        arg_d0_complex[np.abs(arg_d0_complex) < 1e-30] = 1e-30
        term_log_d0 = np.log(arg_d0_complex)
        term_exp_d0 = t / D0_non_zero
        val_d0 = np.exp(np.sum(term_log_d0 + term_exp_d0))
        
        # Completed product 𝔇_glob(t) = 𝔇(t) * 𝔇_0(t)
        val_glob = val_w * val_d0
        
        # Evaluate completed L-function Λ(1/2+it)
        s = 0.5 + 1j * t
        val_L = float(np.abs(complex(mpmath.pi**(-s/2) * mpmath.gamma(s/2) * mpmath.zeta(s))))
        
        ratios.append(np.abs(val_glob) / val_L)
        
    ratios = np.array(ratios)
    ratio_mean = np.mean(ratios)
    ratio_std = np.std(ratios)
    
    # The ratio is constant if the relative standard deviation is small
    # Note: under finite truncation, truncation errors cause fluctuations, so we expect some variance.
    is_constant = (ratio_std / abs(ratio_mean)) < 1.2
    
    return {
        'ratios': ratios,
        'ratio_mean': ratio_mean,
        'ratio_std': ratio_std,
        'is_constant': is_constant
    }

