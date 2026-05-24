import numpy as np
import os
import sys

# Add src to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))

from adelic_spectral_zeta.adelic_dirac import construct_D0, construct_D_artin

def compute_sobolev_energy(N_inf, d, sigma, lam=2.0):
    """
    Constructs the operator, finds the near-zero mode, and computes its Sobolev energy.
    """
    # 1. Build the global operator D_artin
    D_art = construct_D_artin(N_inf, d, sigma, case="unramified", lam=lam)
    
    # 2. Find the zero-mode (eigenvector with minimum absolute eigenvalue)
    # Since the matrix isn't huge, we can do full diagonalization
    eigenvalues, eigenvectors = np.linalg.eig(D_art)
    idx = np.argsort(np.abs(eigenvalues))
    min_eigval = eigenvalues[idx[0]]
    zero_mode = eigenvectors[:, idx[0]]
    
    # 3. Construct the Sobolev Metric Operator S = D_cov^2 + I
    # For simplicity, we just use the Archimedean drift D0 to measure kinetic energy
    D0 = construct_D0(N_inf, sigma, lam)
    I_2d = np.eye(1 << d, dtype=complex)
    D0_glob = np.kron(D0, I_2d)
    
    # S = D0_glob^2 + I
    S = D0_glob @ D0_glob + np.eye(N_inf * (1 << d), dtype=complex)
    
    # 4. Compute Energy E = <psi | S | psi>
    energy = np.real(np.vdot(zero_mode, S @ zero_mode))
    
    return min_eigval, energy

def run_audit():
    N_infs = [10, 50, 100, 200, 400, 800]
    d = 1  # small depth for fast iteration
    
    sigma_on = 0.5
    sigma_off = 0.7
    
    print("==================================================")
    print(" ADÈLIC SOBOLEV ENERGY AUDIT (Dirichlet Explosion)")
    print("==================================================")
    print(f"{'N_inf':<10} | {'E (sigma=0.5)':<20} | {'E (sigma=0.7)':<20}")
    print("-" * 50)
    
    for N_inf in N_infs:
        _, energy_on = compute_sobolev_energy(N_inf, d, sigma_on)
        _, energy_off = compute_sobolev_energy(N_inf, d, sigma_off)
        
        print(f"{N_inf:<10} | {energy_on:<20.4f} | {energy_off:<20.4f}")
        
    print("==================================================")
    print("Observation: If the energy for sigma=0.7 diverges significantly")
    print("compared to sigma=0.5, the 'Rogue Wave' vulnerability is closed.")
    print("==================================================")

if __name__ == "__main__":
    run_audit()
