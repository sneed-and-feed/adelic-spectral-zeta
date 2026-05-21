import os
import numpy as np
import scipy.linalg as la
import mpmath
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

def setup_coupling(N_dim: int = 100, lambda_val: float = 29.0, p_max: int = 151):
    dim = 2 * N_dim + 1
    n_vals = np.arange(-N_dim, N_dim + 1)
    log_lam = np.log(lambda_val)
    D0_diag = n_vals * np.pi / log_lam
    
    # Sieve primes
    is_prime = np.ones(p_max + 1, dtype=bool)
    is_prime[:2] = False
    for i in range(2, int(p_max**0.5) + 1):
        if is_prime[i]:
            is_prime[i*i::i] = False
    primes = np.where(is_prime)[0]
    
    # Build coupling vector xi
    xi = np.zeros(dim, dtype=complex)
    for p in primes:
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)
        
    for i, n in enumerate(n_vals):
        t = n * np.pi / log_lam
        s = 0.25 + 0.5j * t
        psi_val = complex(mpmath.psi(0, s))
        xi[i] += 0.5 * (psi_val - np.log(np.pi))
        
    xi_norm = xi / np.linalg.norm(xi)
    return D0_diag, xi_norm

def compute_symmetry_score(theta: float, sigma: float, D0_diag: np.ndarray, xi_norm: np.ndarray) -> float:
    dim = len(D0_diag)
    I = np.eye(dim)
    P_xi = np.outer(xi_norm, np.conj(xi_norm))
    
    # D0(sigma) = D0 - i*(sigma - 0.5)*I
    D0_sigma = np.diag(D0_diag - 1j * (sigma - 0.5))
    
    # Construct extension
    if abs(theta - np.pi) < 1e-5:
        # theta = pi corresponds to kappa = infinity (D_glob)
        Proj = I - P_xi
        D_op = Proj @ D0_sigma @ Proj
        eigs = la.eigvals(D_op)
        # Exclude the zero mode
        eigs_filtered = [e for e in eigs if abs(e) > 1e-7]
    else:
        kappa = np.tan(theta / 2.0)
        D_op = D0_sigma + kappa * P_xi
        eigs = la.eigvals(D_op)
        # Exclude the perturbed/shifted mode which is far away
        eigs_filtered = [e for e in eigs if abs(e - kappa) > 1e-1]
        
    eigs_filtered = np.array(eigs_filtered)
    
    # Compute symmetry score: average distance to nearest symmetric partner
    # symmetry requires that for each eigenvalue z_j, -z_j is also in the spectrum.
    diffs = []
    for e in eigs_filtered:
        diffs.append(np.min(np.abs(eigs_filtered + e)))
    return np.mean(diffs)

def main():
    print("==================================================================")
    print("        CRITICAL LINE RIGIDITY AND THETA_0 UNIQUENESS SCAN")
    print("==================================================================\n")
    
    N_dim = 100
    lambda_val = 29.0
    p_max = 151
    
    D0_diag, xi_norm = setup_coupling(N_dim, lambda_val, p_max)
    
    # Grid of theta values in (0, 2*pi), including exactly pi
    theta_vals = np.concatenate([
        np.linspace(0.1, np.pi - 0.1, 29),
        [np.pi],
        np.linspace(np.pi + 0.1, 2 * np.pi - 0.1, 30)
    ])
    
    print("Scanning theta for different values of sigma...")
    scores_05 = [compute_symmetry_score(t, 0.5, D0_diag, xi_norm) for t in theta_vals]
    scores_03 = [compute_symmetry_score(t, 0.3, D0_diag, xi_norm) for t in theta_vals]
    scores_07 = [compute_symmetry_score(t, 0.7, D0_diag, xi_norm) for t in theta_vals]
    
    # Find optimal theta for sigma = 0.5
    # Excluding region near theta = 0/2*pi to avoid unperturbed trivial zero
    valid_indices = np.where((theta_vals > 0.5) & (theta_vals < 2 * np.pi - 0.5))[0]
    opt_idx = valid_indices[np.argmin(np.array(scores_05)[valid_indices])]
    opt_theta = theta_vals[opt_idx]
    opt_score = scores_05[opt_idx]
    
    print(f"\nOptimal extension parameter theta_0 for sigma=0.5: {opt_theta:.6f} (approx pi = {np.pi:.6f})")
    print(f"Symmetry score at theta_0: {opt_score:.6e}")
    
    # Verify that off the critical line, the score is bounded away from zero
    min_score_03 = np.min(scores_03)
    min_score_07 = np.min(scores_07)
    print(f"Minimum symmetry score for sigma=0.3: {min_score_03:.6f}")
    print(f"Minimum symmetry score for sigma=0.7: {min_score_07:.6f}")
    
    # Save the plot
    os.makedirs("figures", exist_ok=True)
    plt.figure(figsize=(9, 6))
    plt.plot(theta_vals, scores_05, label=r'$\sigma = 0.5$ (Critical Line)', color='blue', lw=2)
    plt.plot(theta_vals, scores_03, label=r'$\sigma = 0.3$ (Off-critical)', color='red', linestyle='--', lw=2)
    plt.plot(theta_vals, scores_07, label=r'$\sigma = 0.7$ (Off-critical)', color='green', linestyle=':', lw=2)
    
    plt.axvline(np.pi, color='purple', linestyle='-.', label=r'$\theta_0 = \pi$ (Friedrichs/APS extension)')
    plt.yscale('log')
    plt.title(r'Rigidity: Spectral Symmetry Score vs $\theta$')
    plt.xlabel(r'Self-Adjoint Extension Parameter $\theta$')
    plt.ylabel('Symmetry Score (Log Scale)')
    plt.grid(True, which='both', linestyle=':', alpha=0.5)
    plt.legend()
    plt.tight_layout()
    plt.savefig('figures/theta_rigidity.png')
    plt.close()
    print("\nSaved rigidity plot to figures/theta_rigidity.png")

if __name__ == '__main__':
    main()
