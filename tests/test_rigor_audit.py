"""
Test suite: test_rigor_audit.py
Tests mathematical properties and correctness invariants.
"""
import numpy as np
import pytest
from adelic_spectral_zeta.erdos_similarity import (
    construct_adelic_set,
    construct_adelic_sequence,
    solve_schrodinger_spectrum
)

def test_porous_set_theta_scaling():
    N_inf = 64
    d = 2
    k = 1
    
    # Larger theta (larger gap) should keep fewer points, thus smaller sum
    set_theta_3 = construct_adelic_set("porous", N_inf, d, k, theta=0.3)
    set_theta_6 = construct_adelic_set("porous", N_inf, d, k, theta=0.6)
    
    sum_3 = np.sum(set_theta_3)
    sum_6 = np.sum(set_theta_6)
    
    assert sum_3 > sum_6
    assert sum_6 > 0

def test_solver_with_theta():
    N_inf = 32
    d = 2
    k = 1
    
    seq = construct_adelic_sequence("geometric", 3, d, k)
    set_porous = construct_adelic_set("porous", N_inf, d, k, theta=0.5)
    
    grid_params = {
        "N_u": 6,
        "u_min": -1.0,
        "u_max": 1.0,
        "V2": 1,
        "V3": 1,
        "L": 1.0
    }
    
    eigs, _, _ = solve_schrodinger_spectrum(set_porous, seq, grid_params, lmbda=10.0)
    assert len(eigs) > 0
    assert eigs[0] < eigs[-1]
