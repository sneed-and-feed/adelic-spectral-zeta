import numpy as np
import scipy.linalg as la
import mpmath
from .core import get_tau

def simulate_universality(degree, ref_zeros, get_phase, lambda_val, N_dim=600, OP_P_MAX=200):
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
        if degree == 4:
            A_prime = tp**3 - 2.0 * tp
        else:
            A_prime = tp**4 - 3.0 * tp**2 + 1.0
            
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        xi_r1 += A_prime * (np.log(p) / np.sqrt(p)) * np.exp(phases)
    xi_r1 += gamma_shift
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
    
    # Dominance overlap
    overlap = np.linalg.norm(P_N @ xi_r1_norm)**2
    
    return mae1, maeN, overlap

def compute_resolvent_trace_diff(z, dim=1000, lambda_val=800.0, degree=4, OP_P_MAX=200):
    """Compute the trace of (D_glob - z)^-1 - (D_0 - z)^-1 for a finite matrix truncation."""
    # dim is total dimension, let N_dim = dim // 2
    N_dim = dim // 2
    dim_actual = 2 * N_dim + 1
    
    n_vals = np.arange(-N_dim, N_dim + 1)
    log_lam = np.log(lambda_val)
    D0_diag = n_vals * np.pi / log_lam
    
    # Archimedean shift
    gamma_shift = np.zeros(dim_actual, dtype=complex)
    for i, n in enumerate(n_vals):
        t = n * np.pi / log_lam
        s_val = 0.5 + 1j * t
        if degree == 4:
            psi1 = complex(mpmath.psi(0, s_val + 16.5)) - np.log(2*np.pi)
            psi2 = complex(mpmath.psi(0, s_val + 5.5)) - np.log(2*np.pi)
            gamma_shift[i] = 0.5 * (psi1 + psi2)
        else:
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
    xi_r1 = np.zeros(dim_actual, dtype=complex)
    for p in op_primes:
        tp = float(tau[p] * (p ** -5.5))
        if degree == 4:
            A_prime = tp**3 - 2.0 * tp
        else:
            A_prime = tp**4 - 3.0 * tp**2 + 1.0
            
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        xi_r1 += A_prime * (np.log(p) / np.sqrt(p)) * np.exp(phases)
    xi_r1 += gamma_shift
    
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

