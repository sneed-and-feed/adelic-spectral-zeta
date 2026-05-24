import numpy as np
import mpmath
from adelic_spectral_zeta.determinant import compute_eigenvalues, weierstrass_determinant

# Let's run with lambda_val = 2.2
D0_eigs, Dglob_eigs = compute_eigenvalues(N_dim=150, lambda_val=2.2, p_max=151)

# Try different ranges of t
ranges = [
    (1.0, 5.0),
    (2.0, 6.0),
    (3.0, 7.0),
    (4.0, 8.0),
    (5.0, 9.0),
    (6.0, 10.0),
    (5.0, 12.0)
]

for r_min, r_max in ranges:
    t_arr = np.linspace(r_min, r_max, 5)
    ratios = []
    for t in t_arr:
        val_w = weierstrass_determinant(t, D0_eigs, Dglob_eigs)
        s = 0.5 + 1j * t
        val_zeta = float(np.abs(complex(mpmath.zeta(s))))
        ratios.append(np.abs(val_w) / val_zeta)
        
    ratios = np.array(ratios)
    rel_std = np.std(ratios) / np.mean(ratios)
    print(f"Range [{r_min:.1f}, {r_max:.1f}] | rel_std = {rel_std:.6f}")
