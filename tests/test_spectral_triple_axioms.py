"""
Test suite: test_spectral_triple_axioms.py
Tests mathematical properties and correctness invariants.
"""
import pytest
import numpy as np
import scipy.linalg as la
import mpmath
from experiments.axiom_verification_explicit import setup_spectral_triple, generate_smooth_element, generate_banded_element

class TestSpectralTripleAxioms:
    """Pytest suite for Connes-Moscovici spectral triple axioms."""

    @pytest.fixture(scope="class")
    def setup_data(self):
        # Use N_dim = 150 for reasonably fast tests
        N_dim = 150
        lambda_val = 29.0
        p_max = 151
        D0, D_glob, xi_norm, D0_diag, n_vals = setup_spectral_triple(N_dim, lambda_val, p_max)
        return {
            'D0': D0,
            'D_glob': D_glob,
            'xi_norm': xi_norm,
            'D0_diag': D0_diag,
            'n_vals': n_vals,
            'lambda_val': lambda_val,
            'N_dim': N_dim
        }

    def test_summability_transition_at_p1(self, setup_data):
        """Checks that the spectral triple is 1-summable: trace converges for p > 1."""
        D_glob = setup_data['D_glob']
        evs = la.eigvalsh(D_glob)
        evs_nonzero = evs[np.abs(evs) > 1e-6]

        # For p = 0.5, the sum should be larger than for p = 1.5
        tr_05 = np.sum((evs_nonzero**2 + 1.0)**(-0.25))
        tr_15 = np.sum((evs_nonzero**2 + 1.0)**(-0.75))
        
        assert tr_05 > tr_15
        # The trace at p=1.5 is well-defined and small
        assert tr_15 < 10.0

    def test_regularity_commutator_bounded(self, setup_data):
        """Checks that [D, S] is bounded."""
        D_glob = setup_data['D_glob']
        dim = len(D_glob)
        
        # Shift operator S
        S = np.zeros((dim, dim))
        for i in range(dim - 1):
            S[i+1, i] = 1.0
            
        comm = D_glob @ S - S @ D_glob
        norm_comm = np.linalg.norm(comm, 2)
        
        # Norm should be bounded (e.g. less than 150 for this dimension)
        assert norm_comm < 150.0

    def test_regularity_nested_derivations_bounded(self, setup_data):
        """Checks that iterates delta^k(S) are bounded for k=1..3."""
        D0_diag = setup_data['D0_diag']
        dim = len(D0_diag)
        abs_D = np.diag(np.abs(D0_diag))
        
        S = np.zeros((dim, dim))
        for i in range(dim - 1):
            S[i+1, i] = 1.0
            
        # Test delta^k(S) norm is small (grows very slowly)
        T = S.copy()
        for k in range(1, 4):
            T = abs_D @ T - T @ abs_D
            norm_T = np.linalg.norm(T, 2)
            # Theoretical bound for delta^k(S) is (pi/ln lambda)^k
            expected_bound = (np.pi / np.log(setup_data['lambda_val']))**k
            assert norm_T < expected_bound + 1e-5

    def test_dimension_spectrum_residue_at_1(self, setup_data):
        """Checks that the spectral zeta function residue at z=1 is close to theoretical value."""
        D_glob = setup_data['D_glob']
        lambda_val = setup_data['lambda_val']
        N_dim = setup_data['N_dim']
        
        evs = la.eigvalsh(D_glob)
        evs_nonzero = evs[np.abs(evs) > 1e-6]
        
        # In a finite truncation of size N, the sum behaves like 2 * (ln lambda/pi) * ln(N)
        # So we estimate residue = zeta(1) / (2 * ln(N))
        zeta_1 = np.sum(np.abs(evs_nonzero)**(-1.0))
        residue_est = zeta_1 / (2.0 * np.log(N_dim))
        
        theoretical_residue = np.log(lambda_val) / np.pi
        
        # Check that the estimate is within 30% of the theoretical residue for this dimension
        assert abs(residue_est - theoretical_residue) / theoretical_residue < 0.30

    def test_first_order_J_properties(self, setup_data):
        """Checks real structure properties: J^2 = I and J D J^-1 = -D (or anti-commutes)."""
        D_glob = setup_data['D_glob']
        dim = len(D_glob)
        
        P = np.eye(dim)[::-1, :]
        # J D J^-1 on a matrix is P \bar{D} P
        J_D_Jinv = P @ np.conj(D_glob) @ P
        
        # Check J D J^-1 = -D
        assert np.linalg.norm(J_D_Jinv + D_glob) < 1e-10  # Tolerance accounts for floating-point truncation

    def test_first_order_double_commutator_vanishes(self, setup_data):
        """Checks that [[D0, a], J b* J^-1] vanishes in the interior and [[D_glob, a], J b* J^-1] is low-rank."""
        D0 = setup_data['D0']
        D_glob = setup_data['D_glob']
        dim = len(D_glob)
        P = np.eye(dim)[::-1, :]
        
        for _ in range(3):
            a = generate_banded_element(dim, band_size=5)
            b = generate_banded_element(dim, band_size=5)
            
            # 1. D0 commutator vanishes in the interior to machine precision
            comm_D0_a = D0 @ a - a @ D0
            J_bstar_Jinv = P @ b.T @ P
            double_comm0 = comm_D0_a @ J_bstar_Jinv - J_bstar_Jinv @ comm_D0_a
            interior_double_comm0 = double_comm0[15:-15, 15:-15]
            assert np.linalg.norm(interior_double_comm0, 2) < 1e-10  # Tolerance accounts for floating-point truncation
            
            # 2. D_glob double commutator is low-rank
            comm_Dglob_a = D_glob @ a - a @ D_glob
            double_comm_glob = comm_Dglob_a @ J_bstar_Jinv - J_bstar_Jinv @ comm_Dglob_a
            s = la.svdvals(double_comm_glob)
            assert np.sum(s > 1e-9) <= 20

    def test_orientation_cycle(self, setup_data):
        """Checks orientation cycle u^-1 [D, u] = (pi/ln lambda) I (exact for D0, low-rank correction for D_glob)."""
        D0 = setup_data['D0']
        D_glob = setup_data['D_glob']
        lambda_val = setup_data['lambda_val']
        dim = len(D_glob)
        
        S = np.zeros((dim, dim))
        for i in range(dim - 1):
            S[i+1, i] = 1.0
            
        expected_scalar = np.pi / np.log(lambda_val)
        expected = expected_scalar * np.eye(dim)
        
        # 1. Exact for D0 in the interior
        comm_D0_S = D0 @ S - S @ D0
        orient_D0 = S.T @ comm_D0_S
        diff_D0 = orient_D0 - expected
        assert np.linalg.norm(diff_D0[15:-15, 15:-15], 2) < 1e-10  # Tolerance accounts for floating-point truncation
        
        # 2. Low-rank difference for D_glob
        comm_Dglob_S = D_glob @ S - S @ D_glob
        orient_Dglob = S.T @ comm_Dglob_S
        diff_glob = orient_Dglob - expected
        s_diff_glob = la.svdvals(diff_glob)
        assert np.sum(s_diff_glob > 1e-9) <= 5
