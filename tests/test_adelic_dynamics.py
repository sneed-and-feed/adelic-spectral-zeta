"""
Test suite: test_adelic_dynamics.py
Tests mathematical properties and correctness invariants.
"""
import pytest
import numpy as np
from adelic_spectral_zeta.spectral_gap import (
    construct_diagonal_vectors,
)
from adelic_spectral_zeta.adelic_dirac import (
    construct_omega2,
    construct_xi_and_P,
    construct_D_cov,
    construct_D_artin,
)

def test_shielding_identity():
    N_inf = 4
    d = 3
    
    # 1. Ramified Case: P_rho * (I \otimes \omega_2) * P_rho = 0
    _, P_rho_ram = construct_xi_and_P(N_inf, d, case="ramified")
    omega2 = construct_omega2(d)
    I_inf = np.eye(N_inf, dtype=complex)
    I_omega = np.kron(I_inf, omega2)
    
    op_ram = P_rho_ram @ I_omega @ P_rho_ram
    norm_ram = np.linalg.norm(op_ram)
    
    # Assert it is extremely close to 0
    assert norm_ram < 1e-14, f"Ramified norm should be 0, got {norm_ram}"  # Tolerance accounts for floating-point truncation
    
    # 2. Unramified Case: P_rho * (I \otimes \omega_2) * P_rho != 0
    _, P_rho_unram = construct_xi_and_P(N_inf, d, case="unramified")
    op_unram = P_rho_unram @ I_omega @ P_rho_unram
    norm_unram = np.linalg.norm(op_unram)
    
    # Assert it is non-zero
    assert norm_unram > 1e-3, f"Unramified norm should be non-zero, got {norm_unram}"

def test_diagonal_vectors_orthonormality():
    d = 3
    k = 2
    M = 15
    
    # Construct diagonal vectors
    V = construct_diagonal_vectors(d, k, M)
    
    # Check shape: M x (2^d * 3^k)
    assert V.shape == (M, 8 * 9)
    
    # Check V * V^dagger is the identity matrix of size M x M
    inner_products = V @ V.conj().T
    expected_identity = np.eye(M, dtype=complex)
    
    assert np.allclose(inner_products, expected_identity), "Diagonal vectors |e_n> are not orthonormal"

def test_artin_dirac_properties():
    N_inf = 6
    d = 2
    sigma = 0.5
    
    for case in ["unramified", "ramified"]:
        D_art = construct_D_artin(N_inf, d, sigma, case=case)
        dim = N_inf * (1 << d)
        
        # 1. Check that Artin Dirac operator has a zero eigenvalue
        eigs = np.linalg.eigvals(D_art)
        min_eig_mag = np.min(np.abs(eigs))
        assert min_eig_mag < 1e-12, f"Artin Dirac operator in {case} case does not have a zero mode. Min eigenvalue magnitude is {min_eig_mag}"  # Tolerance accounts for floating-point truncation
        
        # 2. Check the trace identity: Tr(D_artin) = Tr(D_cov) - <xi_rho| D_cov |xi_rho>
        D_cov = construct_D_cov(N_inf, d, sigma)
        xi_rho, _ = construct_xi_and_P(N_inf, d, case=case)
        
        trace_artin = np.trace(D_art)
        trace_cov = np.trace(D_cov)
        overlap = xi_rho.conj().T @ D_cov @ xi_rho
        
        expected_trace = trace_cov - overlap
        assert np.isclose(trace_artin, expected_trace), f"Trace identity failed for {case} case: got {trace_artin}, expected {expected_trace}"
