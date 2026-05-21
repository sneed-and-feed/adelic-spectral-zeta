import numpy as np
import scipy.linalg as la
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import time
from itertools import combinations
import mpmath

print("=" * 70)
print("TASK 8.2: INTERACTING FERMIONS & ENTANGLEMENT SCAN")
print("=" * 70)

# 1. System parameters
L = 12       # Number of single-particle modes (must be even)
N_f = L // 2 # Half-filling (6 fermions)
N = L // 2   # Mode range is [-N, N-1], i.e. 12 modes

# Generate Fock basis states (represented as tuples of indices of filled modes)
basis = list(combinations(range(L), N_f))
dim_fock = len(basis)
print(f"Fock space dimension for L={L}, N_f={N_f}: {dim_fock}")

# Map each basis state to its index
state_to_idx = {state: i for i, state in enumerate(basis)}

# Precompute signs for fermion hopping: c_i^\dagger c_j
# Let's write a function to apply c_i^\dagger c_j to a state
def hop(state, i, j):
    # state is a tuple of filled indices
    if j not in state or i in state:
        return None, 0
    # Create new state
    new_state = list(state)
    new_state.remove(j)
    new_state.append(i)
    new_state.sort()
    new_state = tuple(new_state)
    
    # Calculate sign due to anti-commutation
    # Sign is (-1)**(number of particles between i and j)
    low, high = min(i, j), max(i, j)
    between = sum(1 for p in state if low < p < high)
    sign = (-1)**between
    return new_state, sign

# 2. Setup the single-particle Dirac operator
# We will use the Riemann Zeta coupling vector for simplicity
P_MAX = 50
is_prime = np.ones(P_MAX + 1, dtype=bool)
is_prime[:2] = False
for i in range(2, int(P_MAX**0.5) + 1):
    if is_prime[i]:
        is_prime[i*i::i] = False
primes = np.where(is_prime)[0]

n_vals = np.arange(-N, N) # 12 modes

def get_D_matrix(t_lam):
    log_lam = np.log(t_lam)
    D0_diag = n_vals * np.pi / log_lam
    
    gamma_shift = np.zeros(L, dtype=complex)
    for i, n in enumerate(n_vals):
        t = n * np.pi / log_lam
        s_val = 0.5 + 1j * t
        try:
            gamma_shift[i] = 0.5 * complex(mpmath.psi(0, s_val / 2.0))
        except:
            gamma_shift[i] = 0.0
            
    xi = np.zeros(L, dtype=complex)
    for p in primes:
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)
    xi += gamma_shift
    
    if np.linalg.norm(xi) > 0:
        xi_norm = xi / np.linalg.norm(xi)
    else:
        xi_norm = xi
        
    P = np.outer(xi_norm, np.conj(xi_norm))
    D = (np.eye(L) - P) @ np.diag(D0_diag) @ (np.eye(L) - P)
    return D

# 3. Many-body Hamiltonian builder
def build_many_body_H(D, U):
    H = np.zeros((dim_fock, dim_fock), dtype=complex)
    
    # Hop terms (off-diagonal and diagonal of D)
    for idx, state in enumerate(basis):
        # Diagonal single-particle energy
        diag_val = sum(D[i, i] for i in state)
        H[idx, idx] += diag_val
        
        # Off-diagonal hopping
        for i in range(L):
            for j in range(L):
                if i == j: continue
                val = D[i, j]
                if abs(val) < 1e-12: continue
                new_state, sign = hop(state, i, j)
                if new_state is not None:
                    target_idx = state_to_idx[new_state]
                    H[target_idx, idx] += val * sign
                    
        # Interacting Coulomb repulsion: U * sum_{i < j} n_i n_j / |i - j|
        # Note: indices in state are sorted, so we can just do pairwise distances
        int_val = 0.0
        for i_idx in range(len(state)):
            for j_idx in range(i_idx + 1, len(state)):
                pos_i = state[i_idx]
                pos_j = state[j_idx]
                int_val += 1.0 / abs(pos_i - pos_j)
        H[idx, idx] += U * int_val
        
    return H

# 4. Partial trace and von Neumann entropy
# Subsystem A consists of the first L//2 modes (indices 0 to L//2 - 1)
# Subsystem B consists of the rest
subspace_A_size = L // 2

def get_entanglement_entropy(psi):
    # We construct the reduced density matrix of subsystem A
    # The basis states of A are combinations of particles in subsystem A
    # The basis states of B are combinations of particles in subsystem B
    # Since total particle number is conserved, if A has n_A particles, B must have N_f - n_A particles.
    # Let's build a matrix rho_A directly:
    # rho_A[config_A_1, config_A_2] = sum_{config_B} psi[config_A_1 + config_B] * conj(psi[config_A_2 + config_B])
    
    # Let's represent configurations as integer bitmasks
    # Subsystem A: bits 0 to L//2 - 1
    # Subsystem B: bits L//2 to L-1
    # Let's map each Fock basis state to its A and B components
    # We can write rho_A as a dictionary of blocks indexed by particle number in A
    blocks = {} # n_A -> matrix
    
    for idx_state, state in enumerate(basis):
        # Split state into A and B indices
        state_A = tuple(p for p in state if p < L//2)
        state_B = tuple(p for p in state if p >= L//2)
        n_A = len(state_A)
        
        if n_A not in blocks:
            blocks[n_A] = {}
        if state_A not in blocks[n_A]:
            blocks[n_A][state_A] = {}
        blocks[n_A][state_A][state_B] = idx_state
        
    # Now build the density matrix for each particle number sector n_A
    S = 0.0
    for n_A, block in blocks.items():
        configs_A = list(block.keys())
        dim_A = len(configs_A)
        if dim_A == 0: continue
        
        # We need to find all configs_B that can appear for this n_A
        # All configs_B must have size N_f - n_A
        configs_B = list(set(b for a in block.values() for b in a.keys()))
        dim_B = len(configs_B)
        
        # Build representation matrix of size (dim_A, dim_B)
        # psi_matrix[a_idx, b_idx] = psi[a + b]
        psi_mat = np.zeros((dim_A, dim_B), dtype=complex)
        for a_idx, config_A in enumerate(configs_A):
            for b_idx, config_B in enumerate(configs_B):
                if config_B in block[config_A]:
                    global_idx = block[config_A][config_B]
                    psi_mat[a_idx, b_idx] = psi[global_idx]
                    
        # The density matrix is rho_A = psi_mat @ psi_mat.conj().T
        # Its eigenvalues are the squares of the singular values of psi_mat!
        s_vals = la.svdvals(psi_mat)
        eigenvalues = s_vals**2
        
        # Add to entropy
        for ev in eigenvalues:
            if ev > 1e-12:
                S -= ev * np.log(ev)
                
    return S

# 5. Run sweep
t_vals = np.linspace(13.0, 26.0, 100)
U_vals = [0.0, 1.0, 3.0]

results = {U: [] for U in U_vals}

print("\nStarting sweeps over lambda for different interaction strengths U...")
for U in U_vals:
    print(f"  Running sweep for U = {U}...")
    start_u = time.time()
    for idx, t in enumerate(t_vals):
        D = get_D_matrix(t)
        H_MB = build_many_body_H(D, U)
        # Find the ground state
        evals, evecs = la.eigh(H_MB)
        psi_gs = evecs[:, 0]
        # Compute entanglement entropy
        S = get_entanglement_entropy(psi_gs)
        results[U].append(S)
    print(f"  U = {U} completed in {time.time() - start_u:.2f}s")

# 6. Plotting
fig, ax = plt.subplots(figsize=(12, 6))
fig.patch.set_facecolor('#0f0f1a')
ax.set_facecolor('#0f0f1a')
ax.tick_params(colors='white')
ax.xaxis.label.set_color('white')
ax.yaxis.label.set_color('white')
ax.title.set_color('white')
for spine in ax.spines.values(): spine.set_edgecolor('#444')
ax.grid(True, linestyle='--', alpha=0.2, color='#555')

colors = ['#4cc9f0', '#f72585', '#7209b7']
for idx, U in enumerate(U_vals):
    ax.plot(t_vals, results[U], color=colors[idx], linewidth=2.5, label=f'Interaction $U = {U}$')

known_zeros = [14.1347, 21.0220, 25.0108]
for kz in known_zeros:
    ax.axvline(kz, color='white', linestyle='--', linewidth=1.5, alpha=0.5)

ax.set_title("Interacting Fermions: Entanglement Entropy Sweeps under Coulomb Repulsion", color='white', fontsize=14)
ax.set_xlabel("Scaling Parameter $\lambda$ (Height $t$)", color='white', fontsize=12)
ax.set_ylabel("von Neumann Entropy $S$", color='white', fontsize=12)
ax.legend(facecolor='#1a1a2e', labelcolor='white')

plt.tight_layout()
import os
script_dir = os.path.dirname(os.path.abspath(__file__))
out = os.path.join(script_dir, "..", "figures", "interacting_entanglement_sweep.png")
plt.savefig(out, dpi=300, facecolor=fig.get_facecolor())
plt.close()
print(f"\nPlot saved to {out}")
print("=" * 70)
print("TASK 8.2 COMPLETE")
print("=" * 70)
