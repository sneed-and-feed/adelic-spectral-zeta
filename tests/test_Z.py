"""
Test suite: test_Z.py
Tests mathematical properties and correctness invariants.
"""
import numpy as np
import mpmath
from scipy.optimize import bisect

# We must use dps=50 because regularized gammainc internally divides two very small numbers
mpmath.mp.dps = 50

M = 100
poly = np.zeros(M + 1)
poly[0] = 1.0
for n in range(1, M + 1):
    next_poly = poly.copy()
    for i in range(M + 1 - n):
        next_poly[i + n] -= poly[i]
    poly = next_poly

delta_poly = np.zeros(M + 1)
delta_poly[0] = 1.0
for power in range(24):
    next_delta = np.zeros(M + 1)
    for i in range(M + 1):
        for j in range(M + 1 - i):
            next_delta[i + j] += delta_poly[i] * poly[j]
    delta_poly = next_delta

tau = np.zeros(M + 1)
for i in range(M):
    tau[i + 1] = delta_poly[i]

def Z_delta(t):
    s = mpmath.mpc(0.5, t)
    a = s + 5.5  # 6.0 + it
    
    # Compute the phase factor e^{-i theta_Gamma(t)}
    # theta_Gamma(t) = arg(gamma(6 + it)) - t * ln(2*pi)
    gamma_val = mpmath.gamma(a)
    arg_gamma = mpmath.arg(gamma_val)
    theta = arg_gamma - t * mpmath.log(2 * mpmath.pi)
    phase = mpmath.exp(1j * theta)
    
    total = mpmath.mpc(0.0)
    # n up to 30 is plenty for double precision
    for n in range(1, 30):
        coeff = float(tau[n] * (n**(-5.5)))
        # regularized=True gives gammainc(a, x) / gamma(a)
        Q = mpmath.gammainc(a, 2 * mpmath.pi * n, regularized=True)
        val = coeff / (n**s) * Q
        total += val
        
    z_val = 2 * (phase * total).real
    return float(z_val)

# Locate first 25 zeros using a wider range of t up to 150
t_grid = np.linspace(0, 150, 1500)
y_vals = [Z_delta(t) for t in t_grid]

true_zeros = []
for i in range(len(t_grid) - 1):
    if y_vals[i] * y_vals[i+1] < 0:
        root = bisect(Z_delta, t_grid[i], t_grid[i+1])
        if len(true_zeros) == 0 or abs(root - true_zeros[-1]) > 1e-3:
            true_zeros.append(root)
            if len(true_zeros) == 25:
                break

print("Found zeros:", len(true_zeros))
print("Zeros:")
print(true_zeros)
