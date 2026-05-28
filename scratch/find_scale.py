import numpy as np
import mpmath
from adelic_spectral_zeta.determinant import compute_eigenvalues, weierstrass_determinant

# Let's define a function to compute the rel_std for a given lambda_val and scaling factor
def test_ratio(lambda_val, t_scale=1.0):
    D0_eigs, Dglob_eigs = compute_eigenvalues(N_dim=150, lambda_val=lambda_val, p_max=151)
    D0_non_zero = D0_eigs[np.abs(D0_eigs) > 1e-9]
    
    t_arr = np.linspace(5.0, 12.0, 5)
    ratios = []
    for t in t_arr:
        val_w = weierstrass_determinant(t, D0_eigs, Dglob_eigs)
        
        # D0 Weierstrass product
        arg_d0 = 1.0 - t / D0_non_zero
        arg_d0_complex = arg_d0.astype(complex)
        arg_d0_complex[np.abs(arg_d0_complex) < 1e-30] = 1e-30
        term_log_d0 = np.log(arg_d0_complex)
        term_exp_d0 = t / D0_non_zero
        val_d0 = np.exp(np.sum(term_log_d0 + term_exp_d0))
        
        val_glob = val_w * val_d0
        
        # Scaled s
        s = 0.5 + 1j * t * t_scale
        val_L = float(np.abs(complex(mpmath.pi**(-s/2) * mpmath.gamma(s/2) * mpmath.zeta(s))))
        
        ratios.append(np.abs(val_glob) / val_L)
        
    ratios = np.array(ratios)
    rel_std = np.std(ratios) / np.mean(ratios)
    return rel_std

# Scan lambda_val around 2.2 and t_scale
for lam in [1.5, 2.0, 2.2, 2.5, 5.0, 29.0]:
    for scale in [0.5, 1.0, 2.0, 3.0]:
        try:
            r = test_ratio(lam, scale)
            print(f"lambda={lam:.2f}, scale={scale:.2f} | rel_std = {r:.6f}")
        except Exception as e:
            print(f"lambda={lam:.2f}, scale={scale:.2f} | Error: {e}")
