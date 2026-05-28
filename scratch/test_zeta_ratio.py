import numpy as np
import mpmath
from adelic_spectral_zeta.determinant import compute_eigenvalues, weierstrass_determinant

# Let's run with lambda_val = 2.2
D0_eigs, Dglob_eigs = compute_eigenvalues(N_dim=150, lambda_val=2.2, p_max=151)

t_arr = np.linspace(5.0, 12.0, 5)

for t in t_arr:
    val_w = weierstrass_determinant(t, D0_eigs, Dglob_eigs)
    
    # Evaluate Riemann zeta function |zeta(1/2+it)|
    s = 0.5 + 1j * t
    val_zeta = float(np.abs(complex(mpmath.zeta(s))))
    
    ratio_zeta = np.abs(val_w) / val_zeta
    print(f"t={t:.2f} | val_zeta={val_zeta:.6f} | val_w={np.abs(val_w):.6f} | ratio_zeta={ratio_zeta:.6f}")
