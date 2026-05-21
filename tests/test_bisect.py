import numpy as np
import mpmath
from scipy.optimize import bisect

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
    for n in range(1, 60):
        coeff = float(tau[n] * (n**(-5.5)))
        val = coeff / (n**s) * mpmath.gammainc(s + 5.5, 2 * mpmath.pi * n)
        total += val
    xi_val = 2 * ( (2 * mpmath.pi)**(-s) * total ).real
    return float(xi_val)

t_grid = np.linspace(0, 100, 2000)
# Evaluate on grid first to avoid duplicate sign changes
y_vals = [Xi_delta(t) for t in t_grid]

true_zeros = []
for i in range(len(t_grid) - 1):
    if y_vals[i] * y_vals[i+1] < 0:
        # Guarantee root is in [t_grid[i], t_grid[i+1]]
        root = bisect(Xi_delta, t_grid[i], t_grid[i+1])
        # Avoid duplicate roots due to floating point tolerances
        if len(true_zeros) == 0 or abs(root - true_zeros[-1]) > 1e-4:
            true_zeros.append(root)
            if len(true_zeros) == 25:
                break

print("True Zeros (first 25):")
print(true_zeros)
print("Length of true_zeros:", len(true_zeros))
