import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))

import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as sla
import matplotlib.pyplot as plt
import time

from adelic_spectral_zeta.cryptography import (
    build_factorization_hamiltonian,
    build_adelic_driver_hamiltonian,
    bipartite_entanglement_entropy_xy
)

def run_cryptographic_annealing():
    print("--- Adèlic Cryptographic Phase Transition ---")
    
    # Target Semiprime N = 437 (19 * 23)
    N = 437
    # Max factor is 23, which fits in 5 bits (0 to 31).
    n_bits = 5
    dim = 2 ** (2 * n_bits)
    print(f"Target N = {N}")
    print(f"Register Size: {n_bits} bits per factor (Total {2*n_bits} qubits)")
    print(f"Hilbert Space Dimension: {dim} x {dim}")
    
    print("\nBuilding H_cost...")
    t0 = time.time()
    H_cost = build_factorization_hamiltonian(N, n_bits)
    print(f"H_cost built in {time.time() - t0:.2f}s")
    
    print("Building H_driver (Adèlic Metric)...")
    t0 = time.time()
    H_driver = build_adelic_driver_hamiltonian(n_bits)
    print(f"H_driver built in {time.time() - t0:.2f}s")
    
    # Sweep annealing parameter tau from 0.0 to 1.0
    # tau = 0.0 -> Pure Driver (Quantum Superposition)
    # tau = 1.0 -> Pure Cost (Classical Factorization)
    n_steps = 100
    taus = np.linspace(0.0, 1.0, n_steps)
    
    entropies = []
    
    print("\nRunning Adèlic Annealing Sweep...")
    for idx, tau in enumerate(taus):
        # H(tau) = (1 - tau) * H_driver + tau * H_cost
        H_tau = (1.0 - tau) * H_driver + tau * H_cost
        
        # We find the ground state. Because H_tau is sparse and symmetric, we use eigsh
        # which='SA' finds the Smallest Algebraic eigenvalues
        try:
            evals, evecs = sla.eigsh(H_tau, k=1, which='SA')
            ground_state = evecs[:, 0]
            
            # Compute entanglement entropy between X and Y registers
            S = bipartite_entanglement_entropy_xy(ground_state, n_bits)
            entropies.append(S)
            
            # Find the most probable state (x, y)
            max_idx = np.argmax(np.abs(ground_state)**2)
            x = max_idx >> n_bits
            y = max_idx & ((1 << n_bits) - 1)
            
            if idx % 10 == 0 or tau == 1.0:
                print(f"tau={tau:.2f} | Entropy={S:.4f} nats | Most Probable State: |{x}, {y}> (Cost: {(x*y - N)**2})")
                
            # If the superposition collapsed exactly into the factors, we broke it!
            if (x * y == N) and S < 1e-2 and tau < 0.99:
                print(f"!!! MACROSCOPIC COLLAPSE DETECTED at tau={tau:.4f} !!!")
                print(f"Factors found: {x} * {y} = {N}")
                # We don't break, we want to see the rest of the curve
                
        except Exception as e:
            print(f"Error at tau={tau}: {e}")
            entropies.append(0.0)

    # Plotting
    plt.figure(figsize=(10, 6))
    plt.plot(taus, entropies, color="#C4A6D1", linewidth=2.5, label="Adèlic Entanglement Entropy")
    plt.fill_between(taus, entropies, color="#C4A6D1", alpha=0.2)
    
    # Dark modern theme
    plt.style.use('dark_background')
    ax = plt.gca()
    ax.set_facecolor('#121212')
    plt.gcf().patch.set_facecolor('#121212')
    ax.grid(color='#333333', linestyle='--', alpha=0.5)
    
    plt.title(f"Cryptographic Phase Transition (Factoring N={N})", color="white", fontsize=14)
    plt.xlabel(r"Annealing Parameter $\tau$", color="white", fontsize=12)
    plt.ylabel("Bipartite Entanglement Entropy (nats)", color="white", fontsize=12)
    plt.legend(facecolor='#121212', edgecolor='#333333')
    
    out_path = os.path.join(os.path.dirname(__file__), 'cryptographic_phase_transition.png')
    plt.savefig(out_path, dpi=300, bbox_inches='tight')
    print(f"\nPlot saved to {out_path}")

if __name__ == "__main__":
    run_cryptographic_annealing()
