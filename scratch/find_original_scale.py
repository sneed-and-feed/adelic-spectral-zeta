import numpy as np
import mpmath
from adelic_spectral_zeta.determinant import compute_eigenvalues, weierstrass_determinant

def test_original_ratio(lambda_val, t_scale=1.0):
    D0_eigs, Dglob_eigs = compute_eigenvalues(N_dim=150, lambda_val=lambda_val, p_max=151)
    
    t_arr = np.linspace(5.0, 12.0, 5)
    ratios = []
    for t in t_arr:
        val_w = weierstrass_determinant(t, D0_eigs, Dglob_eigs)
        
        # Completed L-function
        s = 0.5 + 1j * t * t_scale
        val_L = float(np.abs(complex(mpmath.pi**(-s/2) * mpmath.gamma(s/2) * mpmath.zeta(s))))
        
        ratios.append(np.abs(val_w) / val_L)
        
    ratios = np.array(ratios)
    rel_std = np.std(ratios) / np.mean(ratios)
    return rel_std

# Let's scan some lambda values and scales for the original ratio
for lam in [1.5, 2.0, 2.2, 2.5, 5.0, 10.0, 29.0, 50.0]:
    for scale in [0.1, 0.25, 0.5, 1.0, 2.0]:
        try:
            r = test_original_ratio(lam, scale)
            if r < 0.25:
                print(f"MATCH: lambda={lam:.2f}, scale={scale:.2f} | rel_std = {r:.6f}")
            else:
                pass
        except Exception as e:
            pass
print("Scan done.")
