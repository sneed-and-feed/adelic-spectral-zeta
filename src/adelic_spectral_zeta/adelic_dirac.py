import numpy as np

def construct_D0(N_inf, sigma, lam=2.0):
    """
    Constructs the Archimedean drift operator D_0(sigma) of size N_inf x N_inf.
    D_0(sigma) = diag(n * pi / log(lam)) + sigma * I
    where n goes from -N_inf // 2 to (N_inf - 1) // 2.
    """
    n = np.arange(-N_inf // 2, (N_inf + 1) // 2)
    n = n[:N_inf]
    diag_vals = n * np.pi / np.log(lam) + sigma
    return np.diag(diag_vals).astype(complex)

def construct_omega2(d):
    """
    Constructs the 2-adic connection matrix omega_2 of size 2^d x 2^d.
    omega_2 = 0.5 * (|1_0><1_1| + |1_1><1_0|)
    """
    N = 1 << d
    omega = np.zeros((N, N), dtype=complex)
    x_coords = np.arange(N)
    parity = x_coords % 2
    omega[parity[:, None] != parity[None, :]] = 1.0 / N
    return omega

def construct_D_cov(N_inf, d, sigma, lam=2.0):
    r"""
    Constructs the gauge-covariant global Dirac operator:
    D_cov(sigma) = D_0(sigma) \otimes I_(2^d) + I_inf \otimes \omega_2
    """
    D0 = construct_D0(N_inf, sigma, lam)
    omega2 = construct_omega2(d)
    
    I_2d = np.eye(1 << d, dtype=complex)
    I_inf = np.eye(N_inf, dtype=complex)
    
    D_cov = np.kron(D0, I_2d) + np.kron(I_inf, omega2)
    return D_cov

def construct_xi_and_P(N_inf, d, case="unramified"):
    """
    Constructs the normalized coupling vector xi_rho and projection matrix P_rho.
    case can be "unramified" or "ramified".
    """
    # Archimedean sector: constant normalized vector
    xi_inf = np.ones(N_inf, dtype=complex) / np.sqrt(N_inf)
    
    N2 = 1 << d
    if case == "unramified":
        # xi_2 = |1>
        xi_2 = np.ones(N2, dtype=complex) / np.sqrt(N2)
    elif case == "ramified":
        # xi_2 = |1_0> (orthogonal to omega_2, i.e., <1_0|omega_2|1_0> = 0)
        xi_2 = np.zeros(N2, dtype=complex)
        xi_2[0::2] = 1.0 / np.sqrt(N2 / 2.0)
    else:
        raise ValueError("case must be 'unramified' or 'ramified'")
        
    xi_rho = np.kron(xi_inf, xi_2)
    
    # Projection matrix P_rho = |xi_rho><xi_rho|
    P_rho = np.outer(xi_rho, xi_rho.conj())
    
    return xi_rho, P_rho

def construct_D_artin(N_inf, d, sigma, case="unramified", lam=2.0):
    """
    Constructs the physical Artin Dirac operator D_artin(sigma) of size (N_inf * 2^d) x (N_inf * 2^d).
    D_artin = (I - P_rho) * D_cov * (I - P_rho)
    """
    D_cov = construct_D_cov(N_inf, d, sigma, lam)
    _, P_rho = construct_xi_and_P(N_inf, d, case)
    
    dim = N_inf * (1 << d)
    I_glob = np.eye(dim, dtype=complex)
    
    Proj = I_glob - P_rho
    D_artin = Proj @ D_cov @ Proj
    return D_artin

def sweep_eigenvalues(N_inf, d, sigmas, case="unramified", lam=2.0):
    """
    Computes the eigenvalues of D_artin(sigma) over a range of sigma values.
    Returns a dictionary mapping each sigma to its sorted eigenvalues (by absolute value).
    """
    results = {}
    for sigma in sigmas:
        D_art = construct_D_artin(N_inf, d, sigma, case, lam)
        eigenvalues = np.linalg.eigvals(D_art)
        # Sort by absolute value
        idx = np.argsort(np.abs(eigenvalues))
        results[sigma] = eigenvalues[idx]
    return results
