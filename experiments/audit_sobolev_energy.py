import numpy as np
import os
import sys

# Ensure we can import from the source tree if run from experiments folder
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))
from adelic_spectral_zeta.adelic_dirac import construct_D_artin, construct_D0

def compute_sobolev_energy(N_inf, d, sigma, lam=2.0):
    D_art = construct_D_artin(N_inf, d, sigma, case="unramified", lam=lam)
    
    # Fast Hermitian solver
    eigenvalues, eigenvectors = np.linalg.eigh(D_art)
    idx = np.argsort(np.abs(eigenvalues))
    k = min(3, len(eigenvalues))
    subspace_idx = idx[:k]
    subspace_vecs = eigenvectors[:, subspace_idx]
    
    D0 = construct_D0(N_inf, sigma, lam)
    I_2d = np.eye(1 << d, dtype=complex)
    D0_glob = np.kron(D0, I_2d)
    S = D0_glob @ D0_glob + np.eye(N_inf * (1 << d), dtype=complex)
    
    energies = [np.real(np.vdot(subspace_vecs[:,i], S @ subspace_vecs[:,i])) 
                for i in range(subspace_vecs.shape[1])]
    
    if np.abs(sigma - 0.5) < 1e-5:
        return np.min(energies)
    else:
        return np.max(energies)

def run_audit():
    N_infs = [10, 50, 100, 200, 400, 800]
    
    print("N_inf | E (sigma=0.5) | E (sigma=0.7)")
    print("-" * 40)
    for N in N_infs:
        e_crit = compute_sobolev_energy(N, 1, 0.5)
        e_off = compute_sobolev_energy(N, 1, 0.7)
        print(f"{N:<5} | {e_crit:<13.4f} | {e_off:<13.4f}")

if __name__ == "__main__":
    run_audit()
