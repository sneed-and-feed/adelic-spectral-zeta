import numpy as np
import scipy.linalg as la
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

def solve_ground_state_entanglement(t_zero, n_fermions, n_sites, repulsion_strength=0.1):
    """Solve the ground state many-body entanglement for the given parameters."""
    # Set up single-particle modes
    L = n_sites
    N_f = n_fermions
    n_vals = np.arange(-L//2, L//2) if L % 2 == 0 else np.arange(-L//2, L//2 + 1)
    n_vals = n_vals[:L]
    
    # Build single-particle operator D
    log_lam = np.log(max(1.1, t_zero))
    D0_diag = n_vals * np.pi / log_lam
    
    # Build coupling vector xi
    xi = np.zeros(L, dtype=complex)
    primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31][:L]
    for p in primes:
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)
        
    if np.linalg.norm(xi) > 0:
        xi_norm = xi / np.linalg.norm(xi)
    else:
        xi_norm = xi
        
    P = np.outer(xi_norm, np.conj(xi_norm))
    D = (np.eye(L) - P) @ np.diag(D0_diag) @ (np.eye(L) - P)
    
    # Build Fock basis
    basis = list(combinations(range(L), N_f))
    state_to_idx = {state: i for i, state in enumerate(basis)}
    
    H = build_many_body_H(D, repulsion_strength, L, basis, state_to_idx)
    
    # Diagonalize to get ground state
    evals, evecs = la.eigh(H)
    psi = evecs[:, 0]
    
    # Bipartite cut A: first L//2 modes
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
        
    from itertools import chain
    subsets_A = list(chain.from_iterable(combinations(range(L//2), r) for r in range(L//2 + 1)))
    subsets_A_to_idx = {sub: i for i, sub in enumerate(subsets_A)}
    dim_A_tot = len(subsets_A)
    rho_A = np.zeros((dim_A_tot, dim_A_tot), dtype=complex)
    
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
                    
        rho_block = psi_mat @ psi_mat.conj().T
        for a_i, config_A_i in enumerate(configs_A):
            for a_j, config_A_j in enumerate(configs_A):
                idx_i = subsets_A_to_idx[config_A_i]
                idx_j = subsets_A_to_idx[config_A_j]
                rho_A[idx_i, idx_j] = rho_block[a_i, a_j]
                
        s_vals = la.svdvals(psi_mat)
        eigenvalues = s_vals**2
        for ev in eigenvalues:
            if ev > 1e-12:
                S -= ev * np.log(ev)
                
    return S, rho_A

