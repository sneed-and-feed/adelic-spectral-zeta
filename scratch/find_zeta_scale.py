import numpy as np
import mpmath
from adelic_spectral_zeta.determinant import compute_eigenvalues, weierstrass_determinant

def test_zeta_ratio_scan(lambda_val, N_dim=150):
    D0_eigs, Dglob_eigs = compute_eigenvalues(N_dim=N_dim, lambda_val=lambda_val, p_max=151)
    
    t_arr = np.linspace(5.0, 12.0, 5)
    ratios = []
    for t in t_arr:
        val_w = weierstrass_determinant(t, D0_eigs, Dglob_eigs)
        s = 0.5 + 1j * t
        val_zeta = float(np.abs(complex(mpmath.zeta(s))))
        ratios.append(np.abs(val_w) / val_zeta)
        
    ratios = np.array(ratios)
    rel_std = np.std(ratios) / np.mean(ratios)
    return rel_std

for lam in [1.5, 2.0, 2.2, 2.5, 5.0, 10.0, 29.0]:
    for N in [100, 150, 200, 300]:
        r = test_zeta_ratio_scan(lam, N)
        print(f"lambda={lam:.2f}, N={N} | rel_std = {r:.6f}")
