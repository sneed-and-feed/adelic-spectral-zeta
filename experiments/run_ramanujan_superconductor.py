"""
Adelic Spectral Zeta: run_ramanujan_superconductor.py
"""

import sys
import os

import numpy as np
from scipy.sparse.linalg import eigsh
from adelic_spectral_zeta.quantum import build_ramanujan_superconductor_H_sparse

def run_experiment(L, U, Delta):
    # Free particle spectrum D_ij (simple nearest neighbor hopping)
    D = np.zeros((L, L), dtype=complex)
    t = 1.0
    for i in range(L - 1):
        D[i, i+1] = -t
        D[i+1, i] = -t
        
    print(f"Building Ramanujan Hamiltonian for L={L}, U={U}, Delta={Delta:.2f}...")
    H_sparse, basis, state_to_idx = build_ramanujan_superconductor_H_sparse(D, U, Delta, L)
    
    # Calculate lowest 2 eigenvalues to find the spectral gap
    try:
        evals, evecs = eigsh(H_sparse, k=2, which='SA')
        E0 = evals[0]
        E1 = evals[1]
        gap = E1 - E0
    except Exception as e:
        print(f"eigsh failed: {e}. Using dense fallback.")
        H_dense = H_sparse.toarray()
        evals = np.linalg.eigvalsh(H_dense)
        E0 = evals[0]
        E1 = evals[1]
        gap = E1 - E0

    print(f"E0: {E0:.6f}, E1: {E1:.6f}, Gap: {gap:.6f}")
    return gap

if __name__ == "__main__":
    L = 10
    U = 0.5
    
    print("Sweeping pairing strength Delta (attractive, negative):")
    deltas = np.linspace(0.0, -0.5, 11)
    gaps = []
    
    for Delta in deltas:
        gap = run_experiment(L, U, Delta)
        gaps.append(gap)
        
    print("\nResults:")
    for d, g in zip(deltas, gaps):
        print(f"Delta: {d:.2f} -> Gap: {g:.6f}")
