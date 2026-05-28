import numpy as np

# Use previous data directly instead of regenerating since we know it
pf_vals = np.array([1.618034, 2.851212, 3.492968, 3.814643, 3.906643, 3.956203, 3.979167, 3.989888, 3.99503, 3.99755])
anti_vals = np.array([0.618034, 1.000000, 2.000000, 2.761199, 3.097184, 3.317667, 3.469671, 3.567528, 3.63693, 3.69246])
d_vals = np.arange(3, 13)

ratios = anti_vals / pf_vals

for d, pf, anti, ratio in zip(d_vals, pf_vals, anti_vals, ratios):
    print(f"d={d:2d}: PF={pf:.6f}, Anti={anti:.6f}, Ratio={ratio:.6f}, 1-Ratio={1-ratio:.6f}")

# Fit 1-ratio to a power law
from scipy.optimize import curve_fit

def power_law(x, C, alpha):
    return C * x**(-alpha)

popt, _ = curve_fit(power_law, d_vals[2:], (1-ratios)[2:])
print(f"\nFit (1-Ratio) = C*d^(-alpha): C={popt[0]:.4f}, alpha={popt[1]:.4f}")
