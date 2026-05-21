"""
Task 4.3: Free-Fermion Entanglement Entropy & Quantum Criticality
===================================================================
DESIGNED FOR EXECUTION ON GOOGLE COLAB / LOCAL CPU

This script computes the bipartite Entanglement Entropy (EE) of the 
fermionic vacuum state of the adèlic Hamiltonian H = D. 

Since the Dirac operator describes non-interacting spinless fermions, 
we can completely bypass DMRG / Tensor Networks and use the EXACT 
correlation matrix method (Peschel 2003) to compute the von Neumann 
entanglement entropy.

We sweep the geometric scaling parameter `lambda` across known 
Riemann zeros. If the topological index theory holds, the entanglement 
entropy will spike exactly at the L-function zeros, signaling a 
quantum critical phase transition (gap closing).
"""

import numpy as np
import scipy.linalg as la
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import time
import mpmath

print("=" * 70)
print("TASK 4.3: QUANTUM CRITICAL ENTANGLEMENT ENTROPY SCAN")
print("=" * 70)

N = 400
dim = 2 * N + 1
P_MAX = 200

# 1. Sieve primes
def sieve(n):
    is_prime = np.ones(n + 1, dtype=bool)
    is_prime[:2] = False
    for i in range(2, int(n**0.5) + 1):
        if is_prime[i]:
            is_prime[i*i::i] = False
    return np.where(is_prime)[0]

primes = sieve(P_MAX)

# 2. Setup the sweep near the first Riemann zero (lambda ~ 14.13)
# The first few zeros of zeta(1/2 + it) are t = 14.1347, 21.0220, 25.0108
t_vals = np.linspace(13.0, 26.0, 300)
entropy_vals = []

print(f"Sweeping lambda (t) across {len(t_vals)} points...")
start_time = time.time()

n_vals = np.arange(-N, N + 1)

for idx, t_lam in enumerate(t_vals):
    if idx % 30 == 0:
        print(f"  Step {idx}/{len(t_vals)} (lambda = {t_lam:.3f})")
        
    log_lam = np.log(t_lam)
    D0_diag = n_vals * np.pi / log_lam
    
    # Zeta function Archimedean factor: Gamma_R(s)
    gamma_shift = np.zeros(dim, dtype=complex)
    for i, n in enumerate(n_vals):
        t = n * np.pi / log_lam
        s_val = 0.5 + 1j * t
        try:
            gamma_shift[i] = 0.5 * complex(mpmath.psi(0, s_val / 2.0))
        except:
            gamma_shift[i] = 0.0

    # Coupling vector
    xi = np.zeros(dim, dtype=complex)
    for p in primes:
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        # A_p = 1 for Zeta function
        xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)
        
    xi += gamma_shift
    if np.linalg.norm(xi) > 0:
        xi_norm = xi / np.linalg.norm(xi)
    else:
        xi_norm = xi
        
    P = np.outer(xi_norm, np.conj(xi_norm))
    D = (np.eye(dim) - P) @ np.diag(D0_diag) @ (np.eye(dim) - P)
    
    # 3. Compute Free-Fermion Ground State
    # Diagonalize the single-particle Hamiltonian D
    evals, evecs = la.eigh(D)
    
    # Fermi sea: filled states are those with negative energy
    filled_indices = np.where(evals < 0)[0]
    
    # Correlation matrix C_ij = <c^\dagger_i c_j>
    # C = V_filled @ V_filled^dagger
    V_filled = evecs[:, filled_indices]
    C = V_filled @ V_filled.conj().T
    
    # 4. Entanglement Entropy
    # We take the subsystem A to be the positive n modes (n > 0)
    subsystem_size = N
    sub_C = C[N+1:, N+1:]  # Truncate to subsystem A
    
    # Eigenvalues of the subsystem correlation matrix
    zeta_C = np.real(la.eigvalsh(sub_C))
    
    # Filter out 0 and 1 to avoid log(0)
    epsilon = 1e-12
    zeta_C = np.clip(zeta_C, epsilon, 1.0 - epsilon)
    
    # von Neumann entropy S = -sum( z*log(z) + (1-z)*log(1-z) )
    S = -np.sum(zeta_C * np.log(zeta_C) + (1.0 - zeta_C) * np.log(1.0 - zeta_C))
    entropy_vals.append(S)

print(f"Sweep completed in {time.time() - start_time:.2f} seconds.")

# ─── 5. PLOTTING ────────────────────────────────────────────────────────
# Known zeros for vertical lines
known_zeros = [14.1347, 21.0220, 25.0108]

fig, ax = plt.subplots(figsize=(12, 6))
fig.patch.set_facecolor('#0f0f1a')
ax.set_facecolor('#0f0f1a')
ax.tick_params(colors='white')
for spine in ax.spines.values(): spine.set_edgecolor('#444')

ax.plot(t_vals, entropy_vals, color='#4cc9f0', linewidth=2.5, label='Bipartite Entanglement Entropy $S(\lambda)$')

for kz in known_zeros:
    ax.axvline(kz, color='#f72585', linestyle='--', linewidth=1.5, alpha=0.8, label=f'Riemann Zero $t={kz:.2f}$' if kz == known_zeros[0] else "")

ax.set_title("Quantum Criticality: Entanglement Entropy Spikes at Riemann Zeros", color='white', fontsize=14)
ax.set_xlabel("Scaling Parameter $\lambda$ (Height $t$)", color='white', fontsize=12)
ax.set_ylabel("von Neumann Entropy $S$", color='white', fontsize=12)
ax.legend(facecolor='#1a1a2e', labelcolor='white')
ax.grid(True, linestyle='--', alpha=0.2, color='#555')

plt.tight_layout()
import os
script_dir = os.path.dirname(os.path.abspath(__file__))
out = os.path.join(script_dir, "..", "figures", "entanglement_entropy_scan.png")
plt.savefig(out, dpi=300, facecolor=fig.get_facecolor())
plt.close()

print(f"\nPlot saved to {out}")
print("=" * 70)
print("TASK 4.3 COMPLETE")
print("=" * 70)
