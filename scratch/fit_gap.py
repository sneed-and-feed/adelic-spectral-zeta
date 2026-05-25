import numpy as np
from scipy.optimize import curve_fit

def build_operators(depth):
    N = 1 << depth
    B_alg = np.zeros((N, N))
    inv_3 = 1
    if depth > 0:
        for i in range(1, N):
            if (3 * i) % N == 1:
                inv_3 = i
                break
    for x in range(N):
        y1 = (2 * x) % N
        B_alg[x, y1] += 0.5
        y2 = ((2 * x - 1) * inv_3) % N
        B_alg[x, y2] += 0.5
    return B_alg

def poly_growth(x, c, alpha):
    return c * (x**alpha)

depths = np.arange(3, 12)
lambdas = []
for d in depths:
    B_alg = build_operators(d)
    eigs = np.linalg.eigvals(B_alg)
    eigs_sorted = sorted(np.abs(eigs), reverse=True)
    lambda_1 = eigs_sorted[1] if len(eigs_sorted) > 1 else 0.0
    lambdas.append(lambda_1)

lambdas = np.array(lambdas)
print("Depths:", depths)
print("Lambda_1:", lambdas)

try:
    popt_poly, _ = curve_fit(poly_growth, depths, lambdas)
    print(f"Poly fit: c*d^alpha -> c={popt_poly[0]:.4f}, alpha={popt_poly[1]:.4f}")
except Exception as e:
    print("Poly fit failed:", e)

