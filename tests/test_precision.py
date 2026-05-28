"""
Test suite: test_precision.py
Tests mathematical properties and correctness invariants.
"""
import numpy as np
import mpmath
from scipy.optimize import bisect

# Set mpmath precision to 50 decimal places
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

def Xi_delta(t):
    s = mpmath.mpc(0.5, t)
    total = mpmath.mpc(0.0)
    # The approximate functional equation only needs n up to ~25 for double precision,
    # and up to ~40 is extremely safe.
    for n in range(1, 40):
        coeff = float(tau[n] * (n**(-5.5)))
        val = coeff / (n**s) * mpmath.gammainc(s + 5.5, 2 * mpmath.pi * n)
        total += val
    xi_val = 2 * ( (2 * mpmath.pi)**(-s) * total ).real
    return float(xi_val)

t_grid = np.linspace(0, 100, 1000)
y_vals = [Xi_delta(t) for t in t_grid]

true_zeros = []
for i in range(len(t_grid) - 1):
    if y_vals[i] * y_vals[i+1] < 0:
        root = bisect(Xi_delta, t_grid[i], t_grid[i+1])
        if len(true_zeros) == 0 or abs(root - true_zeros[-1]) > 1e-3:
            true_zeros.append(root)
            if len(true_zeros) == 25:
                break

print("True Zeros with dps=50:")
print(true_zeros)
print("Length of true_zeros:", len(true_zeros))
