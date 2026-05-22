import os
import sys
import pytest
import numpy as np

# Ensure src directory is in path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from src.spectral_gap import v2, padic_distance_matrix, holder_seminorm, get_operators

def test_v2():
    N = 16
    assert v2(0, N) == np.inf
    assert v2(1, N) == 0
    assert v2(2, N) == 1
    assert v2(4, N) == 2
    assert v2(8, N) == 3
    assert v2(16, N) == np.inf
    assert v2(17, N) == 0

def test_padic_metric_properties():
    d = 4
    N = 1 << d
    dists = padic_distance_matrix(N)
    
    # 1. Positivity
    for i in range(N):
        for j in range(N):
            if i == j:
                assert dists[i, j] == 0.0
            else:
                assert dists[i, j] > 0.0
                
    # 2. Symmetry
    assert np.allclose(dists, dists.T)
    
    # 3. Ultrametric Inequality: d(x, z) <= max(d(x, y), d(y, z))
    for x in range(N):
        for y in range(N):
            for z in range(N):
                assert dists[x, z] <= max(dists[x, y], dists[y, z]) + 1e-15

def test_holder_seminorm_constants():
    d = 4
    N = 1 << d
    # Constant vector
    psi_const = np.ones(N) * 3.5
    
    # Hölder seminorm of a constant function must be exactly 0
    for alpha in [0.1, 0.5, 1.0]:
        assert holder_seminorm(psi_const, alpha) == 0.0

def test_seminorm_contraction():
    # Test the theoretical result: v_alpha(B psi) <= 2^-alpha * v_alpha(psi)
    np.random.seed(42)
    d = 5
    N = 1 << d
    alpha = 0.5
    theta = 2.0 ** (-alpha)
    
    dists = padic_distance_matrix(N)
    _, B = get_operators(d)
    B_dense = B.toarray()
    
    for _ in range(20):
        psi = np.random.randn(N)
        # Exclude constant functions (whose seminorm is 0)
        if holder_seminorm(psi, alpha, dists) > 1e-10:
            psi_next = B_dense.dot(psi)
            
            val_current = holder_seminorm(psi, alpha, dists)
            val_next = holder_seminorm(psi_next, alpha, dists)
            
            # Seminorm must strictly contract by at least 2^-alpha
            assert val_next <= theta * val_current + 1e-12

def test_doubly_stochastic():
    d = 4
    _, B = get_operators(d)
    B_dense = B.toarray()
    
    # Row sums and column sums must be exactly 1.0
    row_sums = B_dense.sum(axis=1)
    col_sums = B_dense.sum(axis=0)
    
    assert np.allclose(row_sums, 1.0)
    assert np.allclose(col_sums, 1.0)
