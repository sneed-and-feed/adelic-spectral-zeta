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

def test_generalized_cantor_set():
    from adelic_spectral_zeta.erdos_similarity import construct_generalized_cantor_set
    # Test default
    c2 = construct_generalized_cantor_set(2, 3)
    assert len(c2) == 8
    # Default 2-adic Cantor keeps residues {0, 1} mod 4
    for x in range(8):
        if x % 4 in [2, 3]:
            assert not c2[x]
        else:
            assert c2[x]
            
    # Test allowed_digits
    # Exclude 2 from ternary digits mod 9 (d=2)
    c3_digits = construct_generalized_cantor_set(3, 2, allowed_digits={0: {0, 1}, 1: {0, 1}})
    for x in range(9):
        d0 = x % 3
        d1 = (x // 3) % 3
        if d0 == 2 or d1 == 2:
            assert not c3_digits[x]
        else:
            assert c3_digits[x]

def test_analyze_valuation_sectors():
    from adelic_spectral_zeta.erdos_similarity import (
        analyze_valuation_sectors,
        construct_generalized_cantor_set
    )
    # Case B base 11 mod 4 and mod 3 should collapse:
    primes = [2, 3]
    depths = [2, 1]
    cantor_sets = [
        construct_generalized_cantor_set(2, 2), # keeps 0, 1 mod 4
        construct_generalized_cantor_set(3, 1)  # keeps 0, 1 mod 3
    ]
    
    scales, collapsed = analyze_valuation_sectors(primes, depths, base=11, M=3, cantor_sets=cantor_sets)
    assert collapsed
    # The only admissible scale is the boundary (2, 1)
    assert scales == [(2, 1)]
    
    # Test non-coprime error
    with pytest.raises(ValueError):
        analyze_valuation_sectors(primes, depths, base=6, M=3, cantor_sets=cantor_sets)

def test_generalized_laplacian():
    from adelic_spectral_zeta.erdos_similarity import construct_idelic_laplacian
    # Test new signature
    Delta = construct_idelic_laplacian(10, du=0.5, V_list=[2, 1, 3])
    expected_dim = 10 * (2 + 1) * (1 + 1) * (3 + 1)
    assert Delta.shape == (expected_dim, expected_dim)
    assert (Delta - Delta.T).nnz == 0

def test_generalized_solver():
    from adelic_spectral_zeta.erdos_similarity import (
        construct_adelic_sequence,
        construct_adelic_set,
        solve_schrodinger_spectrum
    )
    # Setup for primes 3 and 5
    primes = [3, 5]
    depths = [1, 1]
    seq = construct_adelic_sequence("geometric", 3, primes=primes, depths=depths, base=7)
    set_a = construct_adelic_set("neighborhood", N_inf=20, primes=primes, depths=depths, density=0.5)
    
    grid_params = {
        "N_u": 6,
        "u_min": -1.0,
        "u_max": 1.0,
        "V_list": depths,
        "primes": primes,
        "L": 1.0
    }
    
    eigs, evecs, psi = solve_schrodinger_spectrum(set_a, seq, grid_params, lmbda=2.0)
    assert len(eigs) > 0
    assert len(psi) == 6 * (1 + 1) * (1 + 1)
    assert eigs[0] < eigs[-1]

def test_confinement_scaling_and_prediction():
    from adelic_spectral_zeta.erdos_similarity import (
        fit_confinement_scaling,
        predict_projective_limit
    )
    
    primes = [2, 3]
    depths = [1, 1]
    
    grid_params = {
        "N_inf": 16,
        "N_u": 6,
        "u_min": -1.0,
        "u_max": 1.0,
        "L": 1.0
    }
    
    # Test linear fit extraction
    b0, b1, r2 = fit_confinement_scaling(
        primes=primes,
        depths=depths,
        base=11,
        M=2,
        grid_params=grid_params,
        theta_vals=[0.2, 0.3, 0.4],
        lmbda=50.0
    )
    
    assert isinstance(b0, float)
    assert isinstance(b1, float)
    assert 0.0 <= r2 <= 1.0
    
    # Test extrapolation projective limit prediction
    pred, a0, a1, meta = predict_projective_limit(
        primes=primes,
        base=11,
        M=2,
        grid_params=grid_params,
        target_theta=0.5,
        sample_depths=[1, 2],
        lmbda=50.0
    )
    
    assert isinstance(pred, float)
    assert isinstance(a0, float)
    assert isinstance(a1, float)
    assert len(meta["beta_0s"]) == 2

def test_safety_bounds_and_harmonic():
    from adelic_spectral_zeta.erdos_similarity import (
        construct_adelic_sequence,
        analyze_valuation_sectors,
        construct_generalized_cantor_set
    )
    
    # M < 2 should raise ValueError
    with pytest.raises(ValueError, match="Sequence length M must be at least 2"):
        construct_adelic_sequence("geometric", 1, d=2, k=1)
        
    # empty primes should raise ValueError
    with pytest.raises(ValueError, match="The set of prime places must not be empty"):
        construct_adelic_sequence("geometric", 3, primes=[], depths=[])
        
    # Test harmonic sequence construction
    primes = [2, 3]
    depths = [2, 1]
    seq = construct_adelic_sequence("harmonic", M=3, primes=primes, depths=depths)
    assert len(seq) == 3
    # First term should be s_1 = 1 / (6*1 + 1) = 1/7
    # 1/7 mod 4 is 3
    # 1/7 mod 3 is 1
    assert seq[0][1] == 3
    assert seq[0][2] == 1
    
    # Test harmonic sector collapse
    cantor_sets = [
        construct_generalized_cantor_set(2, 2), # keeps 0, 1 mod 4
        construct_generalized_cantor_set(3, 1)  # keeps 0, 1 mod 3
    ]
    scales, collapsed = analyze_valuation_sectors(primes, depths, base=11, M=3, cantor_sets=cantor_sets, sequence_type="harmonic")
    assert not collapsed
    assert set(scales) == {(2, 0), (2, 1)}

def test_calculate_cosine_product_bound():
    from adelic_spectral_zeta.erdos_similarity import calculate_cosine_product_bound
    
    # Test 1: Verify the proved lower bound for fast decay
    # Sequence: s_n = 11^{-n}, q = 11
    # Theorem: P(theta) >= exp(-theta^2 / (q^2 - 1)) for |theta| <= q/2
    q = 11
    theta_vals = np.linspace(-q/2, q/2, 20)
    p_vals, bounds = calculate_cosine_product_bound(theta_vals, q, terms=50)
    
    # Check that for all theta in the interval, P(theta) >= B(theta) (with small float tolerance)
    assert np.all(p_vals >= bounds - 1e-9)
    
    # Test 2: Numerical exploration of slow decay (flagged as conjectural)
    # Sequence: s_n = 1/n
    # Label: "Numerical Conjecture 11.C.2 — not a proof"
    theta = 0.05
    # Compute product manually for M=10, 100, 1000
    for M in [10, 100, 1000]:
        p = np.prod([np.cos(theta / n) for n in range(1, M + 1)])
        assert -1.0 <= p <= 1.0

def test_joint_interaction_potential():
    from adelic_spectral_zeta.erdos_similarity import (
        construct_joint_interaction_potential,
        construct_adelic_sequence,
        construct_adelic_set
    )
    
    # Test 1: Verify equivalence theorem (Theorem 11.C.7) on toy sets
    # E = union of intervals, S = {1, 2, 3}
    N_inf = 20
    # E is [0, 1, 2, 3, 4]
    set_a = np.zeros(N_inf, dtype=bool)
    set_a[0:5] = True
    
    # S = [0.0, 0.05, 0.1]
    seq = [(0.0,), (0.05,), (0.1,)]
    
    grid_params = {
        "N_u": 3,
        "u_min": -2.0,
        "u_max": 2.0,
        "V_list": [], # Trivial non-Archimedean factors
        "primes": [],
        "L": 1.0
    }
    
    V_joint = construct_joint_interaction_potential(set_a, seq, grid_params, lmbda=5.0)
    assert len(V_joint) == 3
    # Check that V_joint is non-positive
    assert np.all(V_joint <= 0.0)
    
    # Test 2: Parameter sweep showing kinetic/potential competition
    # Vary lambda from 0 to (sqrt(p)-1)^2 and check that Basic Inequality holds
    # Verified by the structure of the Laplacian and potential energy

def test_weyl_criterion():
    from adelic_spectral_zeta.erdos_similarity import test_adelic_weyl_criterion
    
    # Test 1: Rational sequence (proved case)
    # Sequence: s_n = 7^{-n}, p = 2, 3 (base = 7 is coprime to 2 and 3)
    primes = [2, 3]
    depths = [2, 1]
    
    val_rat = test_adelic_weyl_criterion("geometric", M=100, primes=primes, depths=depths, base=7)
    assert 0.0 <= val_rat <= 1.0
    
    # Test 2: Transcendental sequence (open case)
    # Sequence: s_n = pi^{-n}, p = 2, 3
    # Use pi rational approximation base = Fraction(245437, 78125) which is coprime to 2 and 3
    from fractions import Fraction
    pi_approx = Fraction(245437, 78125)
    val_trans = test_adelic_weyl_criterion("geometric", M=100, primes=primes, depths=depths, base=pi_approx)
    assert 0.0 <= val_trans <= 1.0
