import numpy as np
from adelic_spectral_zeta.erdos_similarity import (
    construct_adelic_sequence,
    construct_adelic_set,
    solve_schrodinger_spectrum
)

def run_convergence():
    print("======================================================================")
    print("Projective Limit Convergence Test (d -> infinity)")
    print("======================================================================")
    
    N_inf = 32     # Discretization size
    k = 1          # 3-adic depth fixed
    M = 3          # Sequence terms
    L = 1.0
    lmbda = 50.0   # Coupling strength
    
    # Grid parameters
    N_u = 12
    u_min, u_max = -1.0, 1.0
    
    depths = [1, 2, 3, 4]
    eigs_ground = []
    
    print("Sweeping 2-adic depth d...")
    for d in depths:
        seq = construct_adelic_sequence("geometric", M, d, k)
        set_B = construct_adelic_set("porous", N_inf, d, k, L=L, theta=0.4)
        
        # Grid parameters: we scale V2 = d - 1 to represent scaling mod 2^d
        grid_params = {
            "N_u": N_u,
            "u_min": u_min,
            "u_max": u_max,
            "V2": d - 1, # valuation k_2 in {0, ..., d-1}
            "V3": 0,     # valuation k_3 = 0
            "L": L
        }
        
        eigs, _, _ = solve_schrodinger_spectrum(set_B, seq, grid_params, lmbda=lmbda)
        E0 = eigs[0]
        eigs_ground.append(E0)
        print(f"  d = {d} (2-adic size: {2**d:2d}) -> Ground State E0 = {E0:.6f}")
        
    print("\nConvergence Analysis (treating d = 4 as reference limit):")
    print("----------------------------------------------------------------------")
    print(" d | 2-adic size |    E0_d     |  Error |E0_d - E0_4| | Conv. Ratio")
    print("----------------------------------------------------------------------")
    
    E0_ref = eigs_ground[-1]
    errors = []
    for idx, d in enumerate(depths[:-1]):
        err = abs(eigs_ground[idx] - E0_ref)
        errors.append(err)
        ratio_str = "-"
        if idx > 0 and errors[idx-1] > 0:
            ratio = errors[idx-1] / err
            ratio_str = f"{ratio:.2f}x"
        print(f" {d} |      {2**d:2d}     | {eigs_ground[idx]:11.6f} | {err:17.6f} | {ratio_str}")
    print(f" 4 |      16     | {E0_ref:11.6f} |         -         | -")
    print("----------------------------------------------------------------------")
    
    # Assert that the error decreases from d=1 to d=3
    assert errors[1] < errors[0], "Convergence error did not decrease between d=1 and d=2"
    assert errors[2] < errors[1], "Convergence error did not decrease between d=2 and d=3"
    print("\nSUCCESS: Projective limit convergence numerically confirmed.")

if __name__ == "__main__":
    run_convergence()
