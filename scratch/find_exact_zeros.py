import numpy as np
import scipy.optimize as opt
from test_derivatives import eval_L

buhler_zeros = [5.1015, 5.5613, 6.0244, 6.4910, 6.9613]
w_vals = [-1j, -1j, -1j, 1j, 1j]

print("Finding exact zeros:")
for idx, (t0, w) in enumerate(zip(buhler_zeros, w_vals)):
    res = opt.minimize_scalar(lambda t: abs(eval_L(t, w)), bounds=(t0-0.3, t0+0.3), method='bounded')
    print(f"Buhler t0={t0:.4f}: exact zero at t={res.x:.6f}, |L|={res.fun:.6f}")
