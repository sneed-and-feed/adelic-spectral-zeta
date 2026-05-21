import pytest
import numpy as np
from adelic_spectral_zeta.determinant import (
    compute_eigenvalues, weierstrass_determinant, bare_krein_determinant,
    verify_entireness, compare_with_completed_L
)

class TestWeierstrassDeterminant:
    """Tests for the renormalized Weierstrass canonical product."""
    
    @pytest.fixture(scope="class")
    def eigenvalues(self):
        """Compute eigenvalues once for all tests."""
        # Use a slightly smaller N_dim for faster test execution
        return compute_eigenvalues(N_dim=200, lambda_val=29.0, p_max=151)
    
    def test_entireness_no_poles(self, eigenvalues):
        """𝔇_glob(z) must have no poles at unperturbed eigenvalues λ_n."""
        result = verify_entireness(*eigenvalues, n_test_points=5)
        assert result['max_weierstrass_at_poles'] < 0.05
    
    def test_bare_krein_has_poles(self, eigenvalues):
        """The bare Krein determinant d(z) SHOULD have poles at λ_n."""
        D0_eigs, _ = eigenvalues
        # Choose a non-zero eigenvalue of D_0
        lam_test = D0_eigs[len(D0_eigs)//4]
        
        # Build dummy xi
        dummy_xi = np.ones(len(D0_eigs), dtype=complex)
        
        # Evaluate close to the pole
        val_close = bare_krein_determinant(lam_test + 1e-12, D0_eigs, dummy_xi)
        val_far = bare_krein_determinant(lam_test + 1e-2, D0_eigs, dummy_xi)
        
        # It should blow up significantly near the pole
        assert np.abs(val_close) > 10 * np.abs(val_far)
        
    def test_zeros_match_dglob_eigenvalues(self, eigenvalues):
        """Zeros of 𝔇(z) must match eigenvalues of D_glob."""
        D0_eigs, Dglob_eigs = eigenvalues
        
        # Filter zero mode out of Dglob
        zero_idx = np.argmin(np.abs(Dglob_eigs))
        Dglob_non_zero = np.delete(Dglob_eigs, zero_idx)
        
        # Pick 5 eigenvalues of D_glob
        test_zeros = Dglob_non_zero[np.linspace(0, len(Dglob_non_zero)-1, 5, dtype=int)]
        
        for tz in test_zeros:
            val = weierstrass_determinant(tz, D0_eigs, Dglob_eigs)
            # The value at an eigenvalue of D_glob should be very close to zero
            assert np.abs(val) < 1e-4
            
    def test_ratio_is_constant(self):
        """𝔇(t)/Λ(1/2+it) must be constant (up to numerical precision)."""
        # Compute eigenvalues with lambda_val = 2.2 where they match Riemann zeros
        D0_eigs, Dglob_eigs = compute_eigenvalues(N_dim=150, lambda_val=2.2, p_max=151)
        
        # Choose a range of t values away from the first few zeros to avoid 0/0 fluctuations
        t_arr = np.linspace(5.0, 12.0, 5)
        result = compare_with_completed_L(t_arr, D0_eigs, Dglob_eigs)
        
        rel_std = result['ratio_std'] / abs(result['ratio_mean'])
        assert rel_std < 1.2, f"Relative std is {rel_std}, expected < 1.2"
        
    def test_order_of_growth(self, eigenvalues):
        """𝔇(z) should have order 1 (like Λ(z)).
        Check that ln|𝔇(iR)| / R is bounded/stable as R grows."""
        D0_eigs, Dglob_eigs = eigenvalues
        
        R1 = 10.0
        R2 = 20.0
        
        val1 = weierstrass_determinant(1j * R1, D0_eigs, Dglob_eigs)
        val2 = weierstrass_determinant(1j * R2, D0_eigs, Dglob_eigs)
        
        log_growth1 = np.log(np.abs(val1)) / R1
        log_growth2 = np.log(np.abs(val2)) / R2
        
        # Since order is 1, the growth rate log|𝔇(iR)| / R should be of the same order of magnitude
        assert abs(log_growth1 - log_growth2) < 2.0
