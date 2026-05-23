import numpy as np
import pytest
from adelic_spectral_zeta.erdos_similarity import (
    v_p,
    construct_adelic_sequence,
    construct_adelic_set,
    compute_correlation,
    construct_idelic_laplacian,
    solve_schrodinger_spectrum,
)

def test_v_p():
    assert v_p(0, 5) == float('inf')
    assert v_p(5, 5) == 1
    assert v_p(25, 5) == 2
    assert v_p(1, 5) == 0
    assert v_p(0.2, 5) == -1  # 1/5
    assert v_p(0.04, 5) == -2 # 1/25
    assert v_p(2.0, 5) == 0
    assert v_p(2.0, 2) == 1

def test_sequence_lift():
    d = 3
    k = 2
    M = 4
    seq = construct_adelic_sequence("geometric", M, d, k)
    assert len(seq) == M
    for s_inf, s_2, s_3 in seq:
        assert 0 <= s_2 < 2**d
        assert 0 <= s_3 < 3**k
        assert isinstance(s_inf, float)

def test_set_construction():
    N_inf = 100
    d = 3
    k = 2
    
    # Neighborhood set
    set_a = construct_adelic_set("neighborhood", N_inf, d, k, density=0.5)
    assert set_a.shape == (N_inf, 2**d, 3**k)
    assert np.sum(set_a) > 0
    
    # Porous set
    set_b = construct_adelic_set("porous", N_inf, d, k)
    assert set_b.shape == (N_inf, 2**d, 3**k)
    assert np.sum(set_b) > 0
    assert np.sum(set_b) < N_inf * (2**d) * (3**k)

def test_correlation():
    N_inf = 40
    d = 2
    k = 1
    seq = construct_adelic_sequence("geometric", 3, d, k)
    set_a = construct_adelic_set("neighborhood", N_inf, d, k, density=0.8)
    
    # Test correlation at unit scale and zero p-adic scale
    corr = compute_correlation(set_a, seq, b_y=0.1, b_k2=0, b_k3=0)
    assert isinstance(corr, float)
    assert corr >= 0.0

def test_laplacian():
    N_u = 10
    V2 = 2
    V3 = 1
    du = 0.5
    
    Delta = construct_idelic_laplacian(N_u, V2, V3, du)
    expected_dim = N_u * (V2 + 1) * (V3 + 1)
    assert Delta.shape == (expected_dim, expected_dim)
    # Check that it is symmetric
    assert (Delta - Delta.T).nnz == 0

def test_solver():
    N_inf = 20
    d = 2
    k = 1
    
    seq = construct_adelic_sequence("geometric", 3, d, k)
    set_a = construct_adelic_set("neighborhood", N_inf, d, k, density=0.5)
    
    grid_params = {
        "N_u": 8,
        "u_min": -2.0,
        "u_max": 2.0,
        "V2": 2,
        "V3": 1,
        "L": 1.0
    }
    
    eigs, evecs, psi = solve_schrodinger_spectrum(set_a, seq, grid_params, lmbda=5.0)
    
    assert len(eigs) > 0
    assert len(psi) == grid_params["N_u"] * (grid_params["V2"] + 1) * (grid_params["V3"] + 1)
    assert eigs[0] < eigs[-1] # Eigenvalues should be sorted
