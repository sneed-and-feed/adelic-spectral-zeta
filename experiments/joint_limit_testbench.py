"""
Adelic Spectral Zeta: joint_limit_testbench.py
"""

import os
import sys
import numpy as np
from time import time
from adelic_spectral_zeta.erdos_similarity import (
    construct_adelic_sequence,
    construct_adelic_set,
    solve_schrodinger_spectrum
)

def run_diagonal_sweep():
    print("======================================================================")
    print("Joint Limit (M, d) -> inf: Diagonal Curve and Homogenization Sweep")
    print("======================================================================")
    
    # Parameters
    N_inf = 32
    L = 1.0
    lmbda = 100.0
    primes = [2, 3]
    
    M_vals = [2, 3, 4, 5, 6, 7]
    d_vals = [1, 2, 3, 4] # Keep max depth at 4 to run smoothly on laptop
    
    # Pre-allocate results array
    E0_matrix = np.zeros((len(M_vals), len(d_vals)))
    
    # Optional Colab check
    print("Initializing sparse solvers (CPU mode)...")
    
    for i, M in enumerate(M_vals):
        for j, d in enumerate(d_vals):
            depths = [d, d]
            
            # Construct Sequence
            seq = construct_adelic_sequence("geometric", M, primes=primes, depths=depths, base=11)
            
            # Construct Porous Adelic Set
            set_B = construct_adelic_set("porous", N_inf, primes=primes, depths=depths, L=L)
            
            # To capture the shifting interval for Two-Scale Homogenization,
            # we scale the window based on M. The critical scales shift roughly by -M * log(11).
            # But the presence function in 'erdos_similarity.py' evaluates y_b = exp(u).
            # We want to scan the relevant interval. For M=2, u in [-2.0, 1.5] was used.
            # We'll just shift the interval relative to M=2.
            shift = (M - 2) * np.log(11)
            
            grid_params = {
                "N_u": 30,
                "u_min": -2.0 - shift,
                "u_max": 1.5 - shift,
                "V_list": depths,
                "primes": primes,
                "L": L
            }
            
            t0 = time()
            try:
                eigs, _, _ = solve_schrodinger_spectrum(set_B, seq, grid_params, lmbda=lmbda)
                E0 = eigs[0]
            except Exception as e:
                print(f"Error solving for M={M}, d={d}: {e}")
                E0 = float('nan')
            t1 = time()
            
            E0_matrix[i, j] = E0
            print(f"M = {M:2d}, d = {d:2d} | E_0 = {E0:7.4f} | Time: {t1-t0:.2f}s")
            
    print("\n======================================================================")
    print("Summary matrix E_0(M, d):")
    print("M \\ d | " + " | ".join([f"{d:6d}" for d in d_vals]))
    print("-" * 50)
    for i, M in enumerate(M_vals):
        row_str = f"{M:4d} | "
        row_str += " | ".join([f"{E0_matrix[i, j]:6.3f}" for j in range(len(d_vals))])
        print(row_str)

    print("\nDiagonal Boundary extraction:")
    for i, M in enumerate(M_vals):
        max_d = 0
        for j, d in enumerate(d_vals):
            if E0_matrix[i, j] > 0.01:
                max_d = d
            else:
                break
        print(f"  M = {M}: Confined up to depth d = {max_d}")

if __name__ == "__main__":
    run_diagonal_sweep()
