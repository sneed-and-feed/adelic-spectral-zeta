"""
Adelic Spectral Zeta: eval_chain_rayleigh.py
"""

import numpy as np

def run_chain_rayleigh(d):
    M = 1 << (d - 3)
    N = 1 << (d - 1)
    
    # Hop amplitudes
    j_arr = np.arange(M)
    W = 2 * np.cos(np.pi * (3**j_arr) / N)
    
    # 1D Chain Tridiagonal Matrix
    T = np.zeros((M, M))
    for i in range(M - 1):
        T[i, i+1] = W[i]
        T[i+1, i] = W[i]
        
    # Test vector 1: sin(pi * j / M)
    u1 = np.sin(np.pi * j_arr / M)
    if np.sum(u1**2) > 0:
        rq1 = (u1 @ T @ u1) / (u1 @ u1)
    else:
        rq1 = 0
        
    # Test vector 2: sin(pi * (j+1) / (M+1))
    u2 = np.sin(np.pi * (j_arr + 1) / (M + 1))
    rq2 = (u2 @ T @ u2) / (u2 @ u2)
    
    print(f"d={d}, M={M}")
    print(f"  RQ (pi*j/M)       : {rq1:.6f}")
    print(f"  RQ (pi*(j+1)/(M+1)): {rq2:.6f}")

    # Maximum eigenvalue
    vals = np.linalg.eigvalsh(T)
    print(f"  Max Eigenvalue    : {vals.max():.6f}")
    print("-" * 40)

def main():
    for d in range(4, 10):
        run_chain_rayleigh(d)

if __name__ == '__main__':
    main()
