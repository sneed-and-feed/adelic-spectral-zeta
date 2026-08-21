"""
Unit tests for Continuous 2-Adic Transfer Operator on L^2(Z_2) and C^alpha(Z_2).
"""

import unittest
import numpy as np
from experiments.continuous_2adic_transfer_operator import (
    TwoAdicTransferOperator,
    compute_orbits_and_weights,
    verify_conformal_gibbs_measure,
    verify_spectral_circles,
    verify_galois_cyclotomic_invariance,
    simulate_correlation_decay
)


class TestContinuous2AdicTransferOperator(unittest.TestCase):
    """Test suite for 2-adic transfer operator spectral theorems."""

    def test_matrix_construction(self):
        """Verify D_n out-degree is exactly 2 for all rows."""
        for n in [2, 3, 4, 5]:
            op = TwoAdicTransferOperator(n)
            D = op.dense_matrix()
            self.assertEqual(D.shape, (2**n, 2**n))
            row_sums = np.sum(D, axis=1)
            np.testing.assert_allclose(row_sums, 2.0)

    def test_conformal_gibbs_invariance(self):
        """Verify L^* mu = 2 mu on Z/2^n Z."""
        for n in [2, 3, 4, 5, 6]:
            op = TwoAdicTransferOperator(n)
            D = op.dense_matrix()
            mu = np.ones(op.N) / op.N
            D_T_mu = D.T @ mu
            np.testing.assert_allclose(D_T_mu, 2.0 * mu, atol=1e-12)

    def test_monomial_character_action(self):
        """Verify (L chi_{m, k})(x) = (1 + omega_k^-m) chi_{3m mod 2^k, k}(x)."""
        for n in [3, 4, 5]:
            op = TwoAdicTransferOperator(n)
            D = op.dense_matrix()
            N = op.N
            omega_N = np.exp(2j * np.pi / N)

            for k in range(1, n + 1):
                omega_k = np.exp(2j * np.pi / (2**k))
                for m in range(1, 2**k, 2):
                    chi_in = op.character_vector(k, m)
                    chi_out = D @ chi_in

                    multiplier = 1.0 + omega_k ** (-m)
                    expected_chi = multiplier * op.character_vector(k, (3 * m) % (2**k))
                    np.testing.assert_allclose(chi_out, expected_chi, atol=1e-10)

    def test_cyclotomic_product_identity(self):
        """Verify prod_{m odd} (1 + omega_k^-m) = 2 for k = 2..10."""
        for k in range(2, 11):
            N = 2**k
            omega = np.exp(2j * np.pi / N)
            prod_val = np.prod([1.0 + omega ** (-m) for m in range(1, N, 2)])
            self.assertAlmostEqual(prod_val.real, 2.0, places=10)
            self.assertAlmostEqual(prod_val.imag, 0.0, places=10)

    def test_galois_orbit_magnitudes(self):
        """Verify |W_{C_1}| = |W_{C_2}| = sqrt(2) for k >= 3."""
        for k in range(3, 9):
            orbits = compute_orbits_and_weights(k)
            self.assertEqual(len(orbits), 2)
            for orb in orbits:
                self.assertAlmostEqual(abs(orb['weight_product']), np.sqrt(2.0), places=10)
                expected_radius = 2.0 ** (2.0 ** (-(k - 1)))
                self.assertAlmostEqual(orb['radius'], expected_radius, places=10)

    def test_spectral_circles_partition(self):
        """Verify all 2^n eigenvalues lie on concentric circles r_k."""
        for n in range(2, 7):
            op = TwoAdicTransferOperator(n)
            D = op.dense_matrix()
            eigs = np.linalg.eigvals(D)
            mags = np.abs(eigs)

            # Perron eigenvalue
            perron_cnt = np.sum(np.isclose(mags, 2.0, atol=1e-4))
            self.assertEqual(perron_cnt, 1)

            # Zero mode
            zero_cnt = np.sum(np.isclose(mags, 0.0, atol=1e-4))
            self.assertEqual(zero_cnt, 1)

            # Levels k=2..n
            for k in range(2, n + 1):
                rk = 2.0 ** (2.0 ** (-(k - 1)))
                k_cnt = np.sum(np.isclose(mags, rk, atol=1e-4))
                self.assertEqual(k_cnt, 2**(k - 1))

    def test_correlation_decay_eigenmode(self):
        """Verify exact exponential decay rate on leading resonance eigenmode."""
        decay_res = simulate_correlation_decay(n=8, t_max=16)
        self.assertAlmostEqual(decay_res['empirical_rate'], 0.5 * np.log(2.0), places=6)


if __name__ == "__main__":
    unittest.main()
