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
