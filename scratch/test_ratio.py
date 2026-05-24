import numpy as np
import mpmath
from adelic_spectral_zeta.determinant import compute_eigenvalues, weierstrass_determinant

# Let's run with lambda_val = 2.2
D0_eigs, Dglob_eigs = compute_eigenvalues(N_dim=150, lambda_val=2.2, p_max=151)
D0_non_zero = D0_eigs[np.abs(D0_eigs) > 1e-9]

t_arr = np.linspace(5.0, 12.0, 5)

for t in t_arr:
    val_w = weierstrass_determinant(t, D0_eigs, Dglob_eigs)
    
    # Compute Weierstrass product of D0: D0_non_zero
    arg_d0 = 1.0 - t / D0_non_zero
    arg_d0_complex = arg_d0.astype(complex)
    arg_d0_complex[np.abs(arg_d0_complex) < 1e-30] = 1e-30
    term_log_d0 = np.log(arg_d0_complex)
    term_exp_d0 = t / D0_non_zero
    val_d0 = np.exp(np.sum(term_log_d0 + term_exp_d0))
    
    val_glob = val_w * val_d0
    
    s = 0.5 + 1j * t
    val_L = float(np.abs(complex(mpmath.pi**(-s/2) * mpmath.gamma(s/2) * mpmath.zeta(s))))
    
    ratio_w = np.abs(val_w) / val_L
    ratio_glob = np.abs(val_glob) / val_L
    print(f"t={t:.2f} | val_L={val_L:.6f} | val_w={np.abs(val_w):.6f} | ratio_w={ratio_w:.6f} | ratio_glob={ratio_glob:.6f}")
