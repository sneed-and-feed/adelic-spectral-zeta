"""Construction of adèlic Dirac operators D₀, D_cov, and D_Artin for 2-adic spectral triples."""

import numpy as np
from typing import Tuple, Dict, List

def construct_D0(N_inf: int, sigma: float, lam: float = 2.0) -> np.ndarray:
    """Constructs the archimedean Dirac operator D₀ on the real line.
    
    Args:
        N_inf: The truncation dimension for the infinite place.
        sigma: The Archimedean shift parameter.
        lam: The scaling parameter λ (default 2.0).
    """
    n = np.arange(-N_inf // 2, (N_inf + 1) // 2)[:N_inf]
    diag_vals = n * np.pi / np.log(lam) + sigma
    return np.diag(diag_vals).astype(complex)

def construct_omega2(d: int) -> np.ndarray:
    """Constructs the 2-adic parity operator ω₂ on ℂ^(2^d).
    
    This is an off-diagonal block matrix mixing even/odd 2-adic residues.
    """
    N = 1 << d
    omega = np.zeros((N, N), dtype=complex)
    x_coords = np.arange(N)
    parity = x_coords % 2
    omega[parity[:, None] != parity[None, :]] = 1.0 / N
    return omega

def construct_D_cov(N_inf: int, d: int, sigma: float, lam: float = 2.0) -> np.ndarray:
    """Constructs the unprojected covariant Dirac operator D_cov = D₀ ⊗ I + I ⊗ ω₂."""
    D0 = construct_D0(N_inf, sigma, lam)
    omega2 = construct_omega2(d)
    
    I_2d = np.eye(1 << d, dtype=complex)
    I_inf = np.eye(N_inf, dtype=complex)
    
    D_cov = np.kron(D0, I_2d) + np.kron(I_inf, omega2)
    return D_cov

def construct_xi_and_P(N_inf: int, d: int, case: str = "unramified") -> Tuple[np.ndarray, np.ndarray]:
    """Constructs the rank-1 test vector ξ_ρ and its projection P_ρ for an Artin representation.
    
    'unramified' = uniform on 2-adic part.
    'ramified' = supported on even residues.
    """
    xi_inf = np.ones(N_inf, dtype=complex) / np.sqrt(N_inf)
    
    N2 = 1 << d
    if case == "unramified":
        xi_2 = np.ones(N2, dtype=complex) / np.sqrt(N2)
    elif case == "ramified":
        xi_2 = np.zeros(N2, dtype=complex)
        xi_2[0::2] = 1.0 / np.sqrt(N2 / 2.0)
    else:
        raise ValueError("case must be 'unramified' or 'ramified'")
        
    xi_rho = np.kron(xi_inf, xi_2)
    P_rho = np.outer(xi_rho, xi_rho.conj())
    
    return xi_rho, P_rho

def construct_D_artin(N_inf: int, d: int, sigma: float, case: str = "unramified", lam: float = 2.0) -> np.ndarray:
    """Constructs the projected Artin Dirac operator D_Artin = (I - P_ρ) D_cov (I - P_ρ)."""
    D_cov = construct_D_cov(N_inf, d, sigma, lam)
    _, P_rho = construct_xi_and_P(N_inf, d, case)
    
    dim = N_inf * (1 << d)
    I_glob = np.eye(dim, dtype=complex)
    
    Proj = I_glob - P_rho
    D_artin = Proj @ D_cov @ Proj
    return D_artin

def sweep_eigenvalues(N_inf: int, d: int, sigmas: List[float], case: str = "unramified", lam: float = 2.0, k: int = 6) -> Dict[float, np.ndarray]:
    """Sweeps over multiple sigma values and returns the sorted eigenvalues of D_Artin."""
    results = {}
    for sigma in sigmas:
        D_art = construct_D_artin(N_inf, d, sigma, case, lam)
        # Fast Hermitian solver
        eigenvalues = np.linalg.eigvalsh(D_art)
        idx = np.argsort(np.abs(eigenvalues))
        results[sigma] = eigenvalues[idx]
    return results
