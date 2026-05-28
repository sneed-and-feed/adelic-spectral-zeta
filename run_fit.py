import numpy as np
d_vals = np.array([4,5,6,7,8,9,10,11,12])
gaps = np.array([1.85121, 1.49297, 1.05344, 0.80946, 0.63854, 0.50950, 0.42236, 0.35810, 0.30509])

# try to fit gaps = C * d^(-alpha)
from scipy.optimize import curve_fit

def power_law(x, C, alpha):
    return C * x**(-alpha)

def power_law_with_asymp(x, C, alpha, asymp):
    return C * x**(-alpha) + asymp

popt, _ = curve_fit(power_law, d_vals[2:], gaps[2:])
print(f"Fit C*d^(-alpha): C={popt[0]:.4f}, alpha={popt[1]:.4f}")

try:
    popt2, _ = curve_fit(power_law_with_asymp, d_vals[2:], gaps[2:], maxfev=5000)
    print(f"Fit C*d^(-alpha) + asymp: C={popt2[0]:.4f}, alpha={popt2[1]:.4f}, asymp={popt2[2]:.4f}")
except:
    print("Failed to fit with asymptote")

# Also let's check lambda_anti vs 4
lambda_anti = np.array([1.00000, 2.00000, 2.76120, 3.09718, 3.31767, 3.46967, 3.56753, 3.63693, 3.69246])
# lambda_anti approaches 4? 
diffs = 4 - lambda_anti
print("4 - lambda_anti:", diffs)
