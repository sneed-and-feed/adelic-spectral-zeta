"""
Adelic Spectral Zeta: fractal_singular_potential.py
"""

import numpy as np
import scipy.sparse as sp
from scipy.sparse.linalg import eigsh
from time import time

def generate_cantor_indicator(n, kept_digits, k, points_per_interval=1):
    """
    Generate the indicator function for a generalized Cantor set at depth k.
    n: base (e.g. 3 for standard Cantor)
    kept_digits: list of digits to keep (e.g. [0, 2])
    k: depth
    points_per_interval: number of grid points inside the smallest interval (n^-k)
    """
    total_intervals = n**k
    N = total_intervals * points_per_interval
    indicator = np.zeros(total_intervals, dtype=bool)
    
    # We can determine if an index j is kept by checking its base-n representation.
    # To do this efficiently for all j, we can build it iteratively.
    current_kept = np.array([0])
    for step in range(k):
        next_kept = []
        for val in current_kept:
            for digit in kept_digits:
                next_kept.append(val * n + digit)
        current_kept = np.array(next_kept)
        
    indicator[current_kept] = True
    
    if points_per_interval > 1:
        indicator = np.repeat(indicator, points_per_interval)
        
    return indicator, N

def solve_fractal_ground_state(n, kept_digits, k, lmbda=10.0, points_per_interval=1):
    indicator, N = generate_cantor_indicator(n, kept_digits, k, points_per_interval)
    dx = 1.0 / N
    
    # Measure of the set at depth k
    m = len(kept_digits)
    measure_k = (m / n)**k
    
    # Potential: L1 norm is lambda. 
    # V(x) = lambda / measure_k * indicator
    V_amplitude = lmbda / measure_k
    V = V_amplitude * indicator
    
    # Construct 1D Laplacian with periodic boundary conditions
    main_diag = 2.0 / (dx**2) * np.ones(N)
    off_diag = -1.0 / (dx**2) * np.ones(N - 1)
    
    Delta = sp.diags([main_diag, off_diag, off_diag], [0, 1, -1], format='lil')
    
    # Periodic boundary
    Delta[0, N-1] = -1.0 / (dx**2)
    Delta[N-1, 0] = -1.0 / (dx**2)
    
    # Hamiltonian
    H = Delta.tocsr() - sp.diags([V], [0], format='csr')
    
    # Solve for lowest eigenvalue using shift-invert mode (sigma) to avoid Lanczos hanging
    eigs, _ = eigsh(H, k=1, sigma=-50.0, which='LM')
    return eigs[0]

def run_hausdorff_sweep():
    print("======================================================================")
    print("Program 11.P.1: Singular Continuous Fractal Potential Binding")
    print("======================================================================")
    
    lmbda = 50.0
    points_per_int = 2
    
    # Define geometries to sweep
    # (n, kept_digits, max_k)
    geometries = [
        (3, [0, 2], 9, "Standard Middle-Third"),             # alpha = ln(2)/ln(3) = 0.63
        (4, [0, 3], 7, "Quarter-Edge"),                      # alpha = ln(2)/ln(4) = 0.50
        (5, [0, 2, 4], 6, "Middle-Fifth (3 kept)"),          # alpha = ln(3)/ln(5) = 0.68
        (5, [0, 4], 6, "Middle-Fifth (2 kept)")              # alpha = ln(2)/ln(5) = 0.43
    ]
    
    for n, kept, max_k, name in geometries:
        alpha = np.log(len(kept)) / np.log(n)
        print(f"\nGeometry: {name} | n={n}, m={len(kept)} | Hausdorff Dim alpha = {alpha:.4f}", flush=True)
        print("-" * 70, flush=True)
        
        for k in range(1, max_k + 1):
            t0 = time()
            E0 = solve_fractal_ground_state(n, kept, k, lmbda=lmbda, points_per_interval=points_per_int)
            t1 = time()
            
            # Theoretical measure at depth k
            measure = (len(kept) / n)**k
            print(f"  k = {k:2d} | N = {n**k * points_per_int:6d} | Measure = {measure:6.4f} | E_0 = {E0:9.4f} | Time: {t1-t0:.3f}s", flush=True)

if __name__ == "__main__":
    run_hausdorff_sweep()
