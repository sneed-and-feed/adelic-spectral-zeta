"""Universality test for GL(n) spectral triples: rank-1 vs rank-N projection comparison."""

import numpy as np
import scipy.linalg as la
import mpmath
from typing import Tuple, List, Optional
from .core import get_tau

def _build_spectral_triple(degree: int, lambda_val: float, N_dim: int, OP_P_MAX: int) -> Tuple[np.ndarray, np.ndarray, np.ndarray, float, np.ndarray]:
    """Helper to construct the shared spectral triple components for GL(n).
    
    Args:
        degree: 4 = Sym³, 5 = Sym⁴.
        lambda_val: Scaling parameter.
        N_dim: Truncation dimension.
        OP_P_MAX: Maximum prime for the coupling vector.
        
    Returns:
        (D0_diag, xi_r1, gamma_shift, log_lam, op_primes)
    """
    dim = 2 * N_dim + 1
    n_vals = np.arange(-N_dim, N_dim + 1)
    log_lam = np.log(lambda_val)
    D0_diag = n_vals * np.pi / log_lam
    
    # Archimedean shift
    gamma_shift = np.zeros(dim, dtype=complex)
    for i, n in enumerate(n_vals):
        t = n * np.pi / log_lam
        s_val = 0.5 + 1j * t
        if degree == 4:
            psi1 = complex(mpmath.psi(0, s_val + 16.5)) - np.log(2*np.pi)
            psi2 = complex(mpmath.psi(0, s_val + 5.5)) - np.log(2*np.pi)
            gamma_shift[i] = 0.5 * (psi1 + psi2)
        else:
            # GL(5) Satake parameters for Sym^4
            psi_R = complex(mpmath.psi(0, (s_val + 22.0)/2.0)) - np.log(np.pi)
            psi_C1 = complex(mpmath.psi(0, s_val + 11.0)) - np.log(2*np.pi)
            psi_C2 = complex(mpmath.psi(0, s_val + 22.0)) - np.log(2*np.pi)
            gamma_shift[i] = 0.5 * (psi_R + psi_C1 + psi_C2)

    # Primes setup
    tau = get_tau(OP_P_MAX)
    is_prime = np.ones(OP_P_MAX + 1, dtype=bool)
    is_prime[:2] = False
    for i in range(2, int(OP_P_MAX**0.5) + 1):
        if is_prime[i]:
            is_prime[i*i::i] = False
    op_primes = np.where(is_prime)[0]

    # Rank-1 Construction
    xi_r1 = np.zeros(dim, dtype=complex)
    for p in op_primes:
        tp = float(tau[p] * (p ** -5.5))
        # A_prime represents the symmetric power Hecke eigenvalue relations
        if degree == 4:
            A_prime = tp**3 - 2.0 * tp
        else:
            A_prime = tp**4 - 3.0 * tp**2 + 1.0
            
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        xi_r1 += A_prime * (np.log(p) / np.sqrt(p)) * np.exp(phases)
    xi_r1 += gamma_shift
    
    return D0_diag, xi_r1, gamma_shift, log_lam, op_primes

def simulate_universality(degree: int, ref_zeros: np.ndarray, get_phase: callable, lambda_val: float, N_dim: int = 600, OP_P_MAX: int = 200) -> Tuple[float, float, float]:
    dim = 2 * N_dim + 1
    D0_diag, xi_r1, gamma_shift, log_lam, op_primes = _build_spectral_triple(degree, lambda_val, N_dim, OP_P_MAX)
    
    n_vals = np.arange(-N_dim, N_dim + 1)
    
    # Primes setup (we only need tau for the xi_rn part below)
    tau = get_tau(OP_P_MAX)
    xi_r1_norm = xi_r1 / np.linalg.norm(xi_r1)
    
    P1 = np.outer(xi_r1_norm, np.conj(xi_r1_norm))
    D_rank1 = (np.eye(dim) - P1) @ np.diag(D0_diag) @ (np.eye(dim) - P1)
    
    # Rank-N Construction
    xi_rn = []
    for j in range(degree):
        xi_j = np.zeros(dim, dtype=complex)
        for p in op_primes:
            tp = float(tau[p] * (p ** -5.5))
            if abs(tp) > 2.0:
                theta = 0.0
            else:
                theta = np.arccos(tp / 2.0)
            
            if degree == 4:
                alpha = np.exp(1j * (3 - 2*j) * theta)
            else:
                alpha = np.exp(1j * (4 - 2*j) * theta)
                
            phases = -1j * n_vals * np.pi * np.log(p) / log_lam
            xi_j += alpha * (np.log(p) / np.sqrt(p)) * np.exp(phases)
        xi_j += gamma_shift / degree
        xi_rn.append(xi_j)
        
    V = np.column_stack(xi_rn)
    Q, _ = np.linalg.qr(V)
    P_N = Q @ Q.T.conj()
    D_rankN = (np.eye(dim) - P_N) @ np.diag(D0_diag) @ (np.eye(dim) - P_N)
    
    # Solve eigenvalues
    evs_r1 = np.sort(np.abs(la.eigvalsh(D_rank1)))
    evs_r1 = evs_r1[evs_r1 > 1e-6][::2]
    
    evs_rN = np.sort(np.abs(la.eigvalsh(D_rankN)))
    evs_rN = evs_rN[evs_rN > 1e-6][::2]
    
    # Compute MAE
    k = len(ref_zeros)
    mae1 = np.mean(np.abs(evs_r1[:k] - ref_zeros)) if len(evs_r1) >= k else np.inf
    maeN = np.mean(np.abs(evs_rN[:k] - ref_zeros)) if len(evs_rN) >= k else np.inf
    
    # Dominance overlap: |P_N xi_1|^2 — measures the dominance of rank-1 in the rank-N subspace.
    overlap = np.linalg.norm(P_N @ xi_r1_norm)**2
    
    return float(mae1), float(maeN), float(overlap)

def compute_resolvent_trace_diff(z: complex, dim: int = 1000, lambda_val: float = 800.0, degree: int = 4, OP_P_MAX: int = 200) -> complex:
    """Compute the trace of (D_glob - z)^-1 - (D_0 - z)^-1 for a finite matrix truncation."""
    # dim is total dimension, let N_dim = dim // 2
    N_dim = dim // 2
    dim_actual = 2 * N_dim + 1
    
    D0_diag, xi_r1, _, _, _ = _build_spectral_triple(degree, lambda_val, N_dim, OP_P_MAX)
    
    if np.linalg.norm(xi_r1) > 0:
        xi_r1_norm = xi_r1 / np.linalg.norm(xi_r1)
    else:
        xi_r1_norm = xi_r1
        
    P1 = np.outer(xi_r1_norm, np.conj(xi_r1_norm))
    D_glob = (np.eye(dim_actual) - P1) @ np.diag(D0_diag) @ (np.eye(dim_actual) - P1)
    D_0 = np.diag(D0_diag)
    
    # Compute trace difference: Tr((D_glob - z I)^-1 - (D_0 - z I)^-1)
    I = np.eye(dim_actual)
    try:
        inv_glob = la.inv(D_glob - z * I)
        inv_0 = la.inv(D_0 - z * I)
        trace_diff = np.trace(inv_glob - inv_0)
    except Exception:
        trace_diff = 0.0 + 0.0j
        
    return trace_diff

def compute_perturbation_bound(xi_r1: np.ndarray, xi_components: list, D0_diag: np.ndarray) -> float:
    """Compute the Hoffman-Wielandt bound on eigenvalue difference
    between rank-1 and rank-N compressed operators: ||P_N - P_1||_F * ||D_0||_F.
    """
    xi_r1_norm = xi_r1 / np.linalg.norm(xi_r1)
    P1 = np.outer(xi_r1_norm, np.conj(xi_r1_norm))
    
    V = np.column_stack(xi_components)
    Q, _ = np.linalg.qr(V)
    P_N = Q @ Q.T.conj()
    
    frob_norm_diff = np.linalg.norm(P_N - P1, 'fro')
    D0_frob = np.linalg.norm(D0_diag) # norm of vector is Frobenius norm of diagonal matrix
    
    return frob_norm_diff * D0_frob

def compute_frobenius_gap(P1: np.ndarray, PN: np.ndarray) -> float:
    """Compute ||P_N - P_1||_F, the Frobenius norm of projection difference."""
    return np.linalg.norm(PN - P1, 'fro')
