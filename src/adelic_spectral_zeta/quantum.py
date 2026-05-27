import numpy as np
import scipy.linalg as la
import scipy.sparse as sp
from scipy.sparse.linalg import eigsh
from itertools import combinations

def hop(state, i, j):
    """Apply standard fermonic hop c_i^dagger c_j with anti-commutation sign."""
    if j not in state or i in state:
        return None, 0
    new_state = list(state)
    new_state.remove(j)
    new_state.append(i)
    new_state.sort()
    new_state = tuple(new_state)
    
    low, high = min(i, j), max(i, j)
    between = sum(1 for p in state if low < p < high)
    sign = (-1)**between
    return new_state, sign

def build_many_body_H(D, U, L, basis, state_to_idx):
    dim_fock = len(basis)
    H = np.zeros((dim_fock, dim_fock), dtype=complex)
    
    for idx, state in enumerate(basis):
        diag_val = sum(D[i, i] for i in state)
        H[idx, idx] += diag_val
        
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
        int_val = 0.0
        for i_idx in range(len(state)):
            for j_idx in range(i_idx + 1, len(state)):
                pos_i = state[i_idx]
                pos_j = state[j_idx]
                int_val += 1.0 / abs(pos_i - pos_j)
        H[idx, idx] += U * int_val
        
    return H

def build_many_body_H_sparse(D, U, L, basis, state_to_idx):
    """Builds the interacting Hamiltonian as a scipy.sparse.coo_matrix."""
    dim_fock = len(basis)
    rows = []
    cols = []
    data = []
    
    for idx, state in enumerate(basis):
        diag_val = sum(D[i, i] for i in state)
        
        # Interacting Coulomb repulsion: U * sum_{i < j} n_i n_j / |i - j|
        int_val = 0.0
        for i_idx in range(len(state)):
            for j_idx in range(i_idx + 1, len(state)):
                pos_i = state[i_idx]
                pos_j = state[j_idx]
                int_val += 1.0 / abs(pos_i - pos_j)
                
        total_diag = diag_val + U * int_val
        if abs(total_diag) > 1e-12:
            rows.append(idx)
            cols.append(idx)
            data.append(total_diag)
            
        for i in range(L):
            for j in range(L):
                if i == j: continue
                val = D[i, j]
                if abs(val) < 1e-12: continue
                new_state, sign = hop(state, i, j)
                if new_state is not None:
                    target_idx = state_to_idx[new_state]
                    rows.append(target_idx)
                    cols.append(idx)
                    data.append(val * sign)
                    
    H_sparse = sp.coo_matrix((data, (rows, cols)), shape=(dim_fock, dim_fock), dtype=complex)
    return H_sparse.tocsr()

def get_entanglement_entropy(psi, L, N_f, basis):
    # Split state into A (first L//2 modes) and B (rest)
    blocks = {}
    
    for idx_state, state in enumerate(basis):
        state_A = tuple(p for p in state if p < L//2)
        state_B = tuple(p for p in state if p >= L//2)
        n_A = len(state_A)
        
        if n_A not in blocks:
            blocks[n_A] = {}
        if state_A not in blocks[n_A]:
            blocks[n_A][state_A] = {}
        blocks[n_A][state_A][state_B] = idx_state
        
    S = 0.0
    for n_A, block in blocks.items():
        configs_A = list(block.keys())
        dim_A = len(configs_A)
        if dim_A == 0: continue
        
        configs_B = list(set(b for a in block.values() for b in a.keys()))
        dim_B = len(configs_B)
        
        psi_mat = np.zeros((dim_A, dim_B), dtype=complex)
        for a_idx, config_A in enumerate(configs_A):
            for b_idx, config_B in enumerate(configs_B):
                if config_B in block[config_A]:
                    global_idx = block[config_A][config_B]
                    psi_mat[a_idx, b_idx] = psi[global_idx]
                    
        s_vals = la.svdvals(psi_mat)
        eigenvalues = s_vals**2
        
        for ev in eigenvalues:
            if ev > 1e-12:
                S -= ev * np.log(ev)
                
    return S

def solve_ground_state_entanglement_sparse(t_zero, n_fermions, n_sites, repulsion_strength=0.1):
    """Solve the ground state many-body entanglement using sparse matrices."""
    L = n_sites
    N_f = n_fermions
    n_vals = np.arange(-L//2, L//2) if L % 2 == 0 else np.arange(-L//2, L//2 + 1)
    n_vals = n_vals[:L]
    
    log_lam = np.log(max(1.1, t_zero))
    D0_diag = n_vals * np.pi / log_lam
    
    xi = np.zeros(L, dtype=complex)
    primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71][:L]
    for p in primes:
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)
        
    if np.linalg.norm(xi) > 0:
        xi_norm = xi / np.linalg.norm(xi)
    else:
        xi_norm = xi
        
    P = np.outer(xi_norm, np.conj(xi_norm))
    D = (np.eye(L) - P) @ np.diag(D0_diag) @ (np.eye(L) - P)
    
    basis = list(combinations(range(L), N_f))
    state_to_idx = {state: i for i, state in enumerate(basis)}
    
    H_sparse = build_many_body_H_sparse(D, repulsion_strength, L, basis, state_to_idx)
    
    # Solve for the smallest algebraic eigenvalue (ground state)
    try:
        evals, evecs = eigsh(H_sparse, k=1, which='SA')
        psi = evecs[:, 0]
    except:
        # Fallback if ARPACK fails on small L
        H_dense = H_sparse.toarray()
        evals, evecs = la.eigh(H_dense)
        psi = evecs[:, 0]
        
    S = get_entanglement_entropy(psi, L, N_f, basis)
    return S

def solve_ground_state_entanglement(t_zero, n_fermions, n_sites, repulsion_strength=0.1):
    # Backward compatible wrapper mapping to sparse
    return solve_ground_state_entanglement_sparse(t_zero, n_fermions, n_sites, repulsion_strength)

def compute_partition_oeis(n):
    if n < 0: return 0
    if n == 0: return 1
    p = [0]*(n+1)
    p[0] = 1
    for i in range(1, n+1):
        for j in range(i, n+1):
            p[j] += p[j - i]
    return p[n]

def build_ramanujan_superconductor_H_sparse(D, U, Delta, L):
    """Builds the full Fock space BdG interacting Hamiltonian."""
    # Generate full Fock space basis
    basis = []
    for nf in range(L + 1):
        for state in combinations(range(L), nf):
            basis.append(state)
    state_to_idx = {state: i for i, state in enumerate(basis)}
    
    dim_fock = len(basis)
    rows = []
    cols = []
    data = []
    
    # Precompute Ramanujan pairings
    V_pair = {}
    for i in range(L):
        for j in range(L):
            if i != j:
                p_val = compute_partition_oeis(abs(i - j))
                V_pair[(i, j)] = Delta * p_val
                
    for idx, state in enumerate(basis):
        # 1. Diagonal elements
        diag_val = sum(D[i, i] for i in state)
        
        # Coulomb repulsion
        int_val = 0.0
        for i_idx in range(len(state)):
            for j_idx in range(i_idx + 1, len(state)):
                pos_i = state[i_idx]
                pos_j = state[j_idx]
                int_val += 1.0 / abs(pos_i - pos_j)
                
        total_diag = diag_val + U * int_val
        if abs(total_diag) > 1e-12:
            rows.append(idx)
            cols.append(idx)
            data.append(total_diag)
            
        # 2. Single-particle hopping
        for i in range(L):
            for j in range(L):
                if i == j: continue
                val = D[i, j]
                if abs(val) < 1e-12: continue
                new_state, sign = hop(state, i, j)
                if new_state is not None:
                    target_idx = state_to_idx[new_state]
                    rows.append(target_idx)
                    cols.append(idx)
                    data.append(val * sign)
                    
        # 3. Superconducting pairing: \sum_{i < j} V_{ij} c_i^\dagger c_j^\dagger + h.c.
        for i in range(L):
            for j in range(i + 1, L):
                if i not in state and j not in state:
                    # Apply c_i^dagger c_j^dagger
                    pos_i = sum(1 for p in state if p < i)
                    pos_j = sum(1 for p in state if p < j)
                    sign = (-1)**(pos_i + pos_j)
                    
                    new_state = list(state)
                    new_state.append(i)
                    new_state.append(j)
                    new_state.sort()
                    new_state = tuple(new_state)
                    
                    target_idx = state_to_idx[new_state]
                    v_ij = V_pair[(i, j)]
                    
                    # <new_state | H | state> = V_{ij} * sign
                    rows.append(target_idx)
                    cols.append(idx)
                    data.append(v_ij * sign)
                    
                    # <state | H | new_state> = conj(V_{ij} * sign)
                    rows.append(idx)
                    cols.append(target_idx)
                    data.append(np.conj(v_ij * sign))
                    
    H_sparse = sp.coo_matrix((data, (rows, cols)), shape=(dim_fock, dim_fock), dtype=complex)
    return H_sparse.tocsr(), basis, state_to_idx
