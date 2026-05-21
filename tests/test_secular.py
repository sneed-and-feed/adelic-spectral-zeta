import numpy as np
import mpmath
import matplotlib.pyplot as plt

# Set up parameters
lam = 2.2  # scale parameter
log_lam = np.log(lam)
primes = [2, 3, 5, 7, 11, 13]
N = 100  # size is 2N+1

# Diagonal entries for D_0
n_vals = np.arange(-N, N + 1)
D0_diag = n_vals * np.pi / log_lam

# Vector xi representing primes + Archimedean factor
xi = np.zeros(2*N + 1, dtype=complex)
for p in primes:
    phases = -1j * n_vals * np.pi * np.log(p) / log_lam
    xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)

# Add Archimedean factor
for i, n in enumerate(n_vals):
    t = n * np.pi / log_lam
    s = 0.25 + 0.5j * t
    psi_val = complex(mpmath.psi(0, s))
    xi[i] += 0.5 * (psi_val - np.log(np.pi))

# Normalize xi
xi = xi / np.linalg.norm(xi)
weights = np.abs(xi)**2

# Define the secular function S(z) = sum_n weights[n] / (z - lambda_n)
def S(z):
    return np.sum(weights / (z - D0_diag))

# Find the roots of S(z) = 0 (which corresponds to kappa -> infinity)
# The roots of S(z) = 0 interlace the poles lambda_n.
# We search for roots in the range [0, 50]
roots = []
for i in range(len(D0_diag) - 1):
    # Search between D0_diag[i] and D0_diag[i+1]
    left = D0_diag[i]
    right = D0_diag[i+1]
    if left < 0 or right > 60:
        continue
    # Use bisection to find the root of S(z)
    # Note that S(z) goes from -infinity to +infinity between poles, but has a pole at both ends.
    # To find roots of S(z) = 0:
    # Since S(z) has poles, we can search for sign changes in a fine grid.
    grid = np.linspace(left + 1e-5, right - 1e-5, 100)
    vals = [S(x) for x in grid]
    for j in range(len(grid) - 1):
        if vals[j] * vals[j+1] < 0:
            # Found a root!
            root = (grid[j] + grid[j+1]) / 2.0
            roots.append(root)
            break

roots = sorted(list(set(roots)))
true_zeros = [float(mpmath.zetazero(k).imag) for k in range(1, 51)]

print("First 50 roots of secular equation:")
for idx, r in enumerate(roots[:50]):
    print(f"Root {idx+1}: {r:.6f}")

print("\nFirst 50 True Riemann zeros:")
for idx, z_val in enumerate(true_zeros[:50]):
    print(f"Zero {idx+1}: {z_val:.6f}")

# Find matches (roots that are very close to Riemann zeros)
matches = []
for z_val in true_zeros[:20]:
    # Find the closest root
    closest_root = min(roots, key=lambda x: abs(x - z_val))
    diff = abs(closest_root - z_val)
    matches.append((z_val, closest_root, diff))

print("\nClosest matches for first 20 Riemann zeros:")
for z_val, r_val, diff in matches:
    print(f"Zero: {z_val:.6f} | Closest Root: {r_val:.6f} | Diff: {diff:.6f}")

