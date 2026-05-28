"""
Test suite: test_perturbation_bounds.py
Tests mathematical properties and correctness invariants.
"""
import pytest
import numpy as np
import scipy.linalg as la
from adelic_spectral_zeta.universality import (
    compute_perturbation_bound, compute_frobenius_gap, get_tau
)

class TestPerturbationBounds:
    """Checks Hoffman-Wielandt perturbation bounds and subspace nesting for GL(3) and GL(4)."""

    def setup_operator_components(self, degree=4, lambda_val=29.0, N_dim=150, p_max=100):
        dim = 2 * N_dim + 1
        n_vals = np.arange(-N_dim, N_dim + 1)
        log_lam = np.log(lambda_val)
        D0_diag = n_vals * np.pi / log_lam

        # Sieve primes
        is_prime = np.ones(p_max + 1, dtype=bool)
        is_prime[:2] = False
        for i in range(2, int(p_max**0.5) + 1):
            if is_prime[i]:
                is_prime[i*i::i] = False
        primes = np.where(is_prime)[0]

        tau = get_tau(p_max)

        # Archimedean shift vector
        import mpmath
        gamma_shift = np.zeros(dim, dtype=complex)
        for i, n in enumerate(n_vals):
            t = n * np.pi / log_lam
            s_val = 0.5 + 1j * t
            if degree == 4:
                psi1 = complex(mpmath.psi(0, s_val + 16.5)) - np.log(2*np.pi)
                psi2 = complex(mpmath.psi(0, s_val + 5.5)) - np.log(2*np.pi)
                gamma_shift[i] = 0.5 * (psi1 + psi2)
            else:
                psi_R = complex(mpmath.psi(0, (s_val + 22.0)/2.0)) - np.log(np.pi)
                psi_C1 = complex(mpmath.psi(0, s_val + 11.0)) - np.log(2*np.pi)
                psi_C2 = complex(mpmath.psi(0, s_val + 22.0)) - np.log(2*np.pi)
                gamma_shift[i] = 0.5 * (psi_R + psi_C1 + psi_C2)

        # Rank-1 xi vector
        xi_r1 = np.zeros(dim, dtype=complex)
        for p in primes:
            tp = float(tau[p] * (p ** -5.5))
            if degree == 4:
                A_prime = tp**3 - 2.0 * tp
            else:
                A_prime = tp**4 - 3.0 * tp**2 + 1.0
            phases = -1j * n_vals * np.pi * np.log(p) / log_lam
            xi_r1 += A_prime * (np.log(p) / np.sqrt(p)) * np.exp(phases)
        xi_r1 += gamma_shift

        # Rank-N component vectors
        xi_rn = []
        for j in range(degree):
            xi_j = np.zeros(dim, dtype=complex)
            for p in primes:
                tp = float(tau[p] * (p ** -5.5))
                if abs(tp) > 2.0:
                    theta = 0.0
                else:
                    theta = np.arccos(tp / 2.0)
                if degree == 4:
                    alpha = np.exp(1j * (3 - 2*j) * theta)
                else:
                    alpha = np.exp(1j * (4 - 2*j) * theta)
                phases = -1j * n_vals * np.pi * np.log(p) / log_lam
                xi_j += alpha * (np.log(p) / np.sqrt(p)) * np.exp(phases)
            xi_j += gamma_shift / degree
            xi_rn.append(xi_j)

        return D0_diag, xi_r1, xi_rn

    @pytest.mark.parametrize("degree", [4, 5])
    def test_subspace_nesting(self, degree):
        """Checks that the rank-1 coupling vector lies in the span of the component vectors."""
        D0_diag, xi_r1, xi_rn = self.setup_operator_components(degree=degree)
        
        # Normalize xi_r1
        xi_r1_norm = xi_r1 / np.linalg.norm(xi_r1)
        
        # Build projection onto span of xi_rn
        V = np.column_stack(xi_rn)
        Q, _ = np.linalg.qr(V)
        PN = Q @ Q.T.conj()
        
        # Overlap norm should be close to 1
        overlap = np.linalg.norm(PN @ xi_r1_norm)**2
        assert overlap > 0.95, f"Subspace nesting overlap for degree {degree} is {overlap}, expected > 0.95"

    @pytest.mark.parametrize("degree", [4, 5])
    def test_hoffman_wielandt_bound(self, degree):
        """Checks that the eigenvalue difference is bounded by the Hoffman-Wielandt bound."""
        D0_diag, xi_r1, xi_rn = self.setup_operator_components(degree=degree)
        
        dim = len(D0_diag)
        xi_r1_norm = xi_r1 / np.linalg.norm(xi_r1)
        P1 = np.outer(xi_r1_norm, np.conj(xi_r1_norm))
        
        V = np.column_stack(xi_rn)
        Q, _ = np.linalg.qr(V)
        PN = Q @ Q.T.conj()
        
        D1 = (np.eye(dim) - P1) @ np.diag(D0_diag) @ (np.eye(dim) - P1)
        DN = (np.eye(dim) - PN) @ np.diag(D0_diag) @ (np.eye(dim) - PN)
        
        evs1 = np.sort(la.eigvalsh(D1))
        evsN = np.sort(la.eigvalsh(DN))
        
        # Squared differences of eigenvalues
        sum_sq_diff = np.sum((evs1 - evsN)**2)
        
        # Hoffman-Wielandt Bound: ||D1 - DN||_F^2
        frob_diff = np.linalg.norm(D1 - DN, 'fro')**2
        
        # Upper bound: 4.0 * ||P_N - P_1||_F^2 * ||D_0||_F^2
        frob_projs = compute_frobenius_gap(P1, PN)
        bound = 4.0 * (frob_projs**2) * np.sum(D0_diag**2)
        
        assert sum_sq_diff <= frob_diff + 1e-9, f"Spectral diff {sum_sq_diff} exceeded operator diff {frob_diff}"
        assert frob_diff <= bound + 1e-9, f"Operator diff {frob_diff} exceeded theoretical bound {bound}"
        
        # Test Frobenius gap is bounded by sqrt(k) where k = degree - 1
        k = degree - 1
        assert frob_projs <= np.sqrt(k) + 1e-9, f"Frobenius projection gap {frob_projs} exceeded sqrt(k)={np.sqrt(k)}"

    @pytest.mark.parametrize("degree", [4, 5])
    def test_mae_bound(self, degree):
        """Checks that Mean Absolute Error satisfies the MAE <= 2 * sqrt(k) * ||D0||_F / sqrt(N) bound."""
        D0_diag, xi_r1, xi_rn = self.setup_operator_components(degree=degree)
        
        dim = len(D0_diag)
        xi_r1_norm = xi_r1 / np.linalg.norm(xi_r1)
        P1 = np.outer(xi_r1_norm, np.conj(xi_r1_norm))
        
        V = np.column_stack(xi_rn)
        Q, _ = np.linalg.qr(V)
        PN = Q @ Q.T.conj()
        
        D1 = (np.eye(dim) - P1) @ np.diag(D0_diag) @ (np.eye(dim) - P1)
        DN = (np.eye(dim) - PN) @ np.diag(D0_diag) @ (np.eye(dim) - PN)
        
        evs1 = np.sort(la.eigvalsh(D1))
        evsN = np.sort(la.eigvalsh(DN))
        
        mae = np.mean(np.abs(evs1 - evsN))
        
        # Theoretical bound: 2 * sqrt(k) * ||D0||_F / sqrt(N)
        k = degree - 1
        D0_frob = np.linalg.norm(D0_diag)
        theoretical_bound = 2.0 * np.sqrt(k) * D0_frob / np.sqrt(dim)
        
        assert mae <= theoretical_bound + 1e-9, f"MAE {mae} exceeded theoretical bound {theoretical_bound}"
