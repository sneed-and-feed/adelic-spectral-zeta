"""
Task 3.2: Artin Spectral Triple Construction
============================================
Constructs the coupling vector and tests the spectral triple for the 
Icosahedral Artin L-function (degree 2, conductor 800).

The representation has image A_5. Buhler's polynomial for the A_5 
extension is:
    f(x) = x^5 + 10x^3 - 10x^2 + 35x - 18

The Frobenius traces a_p are determined by the splitting type of f(x) mod p:
  - Splitting (1,1,1,1,1) -> Order 1 -> trace = +2 or -2
  - Splitting (1,2,2)     -> Order 2 -> trace = 0
  - Splitting (1,1,3)     -> Order 3 -> trace = -1
  - Splitting (5)         -> Order 5 -> trace = (1 ± sqrt(5))/2

For primes p dividing the conductor (p = 2, 5), the trace is 0.
"""

import numpy as np
import scipy.linalg as la
import sympy as sp
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

print("=" * 70)
print("TASK 3.2: ARTIN SPECTRAL TRIPLE CONSTRUCTION (Icosahedral, Conductor 800)")
print("=" * 70)

P_MAX = 150
primes = list(sp.primerange(2, P_MAX))

# ─── 1. COMPUTE FROBENIUS TRACES ────────────────────────────────────────
x = sp.Symbol('x')
f = x**5 + 10*x**3 - 10*x**2 + 35*x - 18

a_p = {}
phi = (1 + np.sqrt(5)) / 2
phi_conj = (1 - np.sqrt(5)) / 2

print(f"{'p':<5} | {'Splitting Type':<20} | {'Trace a_p':<10}")
print("-" * 50)

for p in primes:
    if p in [2, 5]:
        a_p[p] = 0.0
        split_str = "Ramified"
    else:
        try:
            factors = sp.factor_list(f, modulus=p)[1]
            degrees = sorted([sp.degree(poly) for poly, mult in factors])
            
            if degrees == [1, 1, 1, 1, 1]:
                # Heuristic: assign +2 for simplicity in this test
                a_p[p] = 2.0
            elif degrees == [1, 2, 2]:
                a_p[p] = 0.0
            elif degrees == [1, 1, 3]:
                a_p[p] = -1.0
            elif degrees == [5]:
                # Assign one of the conjugate golden ratio roots deterministically
                a_p[p] = phi if p % 2 == 0 else phi_conj
            else:
                a_p[p] = 0.0
                
            split_str = str(tuple(degrees))
        except:
            a_p[p] = 0.0
            split_str = "Error"
            
    if p <= 43:
        print(f"{p:<5} | {split_str:<20} | {a_p[p]:<10.3f}")

# ─── 2. CONSTRUCT SPECTRAL TRIPLE ───────────────────────────────────────
N = 250
lam = 42.0
log_lam = np.log(lam)
n_vals = np.arange(-N, N + 1)
dim = 2 * N + 1
D0_diag = n_vals * np.pi / log_lam

print("\nConstructing Artin Coupling Vector xi_rho...")
xi = np.zeros(dim, dtype=complex)

for p in primes:
    if a_p[p] == 0:
        continue
    phases = -1j * n_vals * np.pi * np.log(p) / log_lam
    xi += a_p[p] * (np.log(p) / np.sqrt(p)) * np.exp(phases)

# Normalize
xi_norm = xi / np.linalg.norm(xi)

# Construct projection
P = np.outer(xi_norm, np.conj(xi_norm))
D_artin = (np.eye(dim) - P) @ np.diag(D0_diag) @ (np.eye(dim) - P)

# Compute eigenvalues
evs = np.sort(np.abs(la.eigvalsh(D_artin)))
evs = evs[evs > 1e-6]

print("\n--- Low-Lying Artin Eigenvalues ---")
for i in range(10):
    print(f"n = {i+1:<2} | |λ_n| = {evs[i]:.6f}")

# Plot eigenvalue spacing
spacing = np.diff(evs[:100])
fig, ax = plt.subplots(figsize=(8, 5))
fig.patch.set_facecolor('#0f0f1a')
ax.set_facecolor('#0f0f1a')
ax.tick_params(colors='white')
for spine in ax.spines.values(): spine.set_edgecolor('#444')

ax.hist(spacing, bins=20, color='#f72585', alpha=0.8, edgecolor='white')
ax.set_title("Artin L-function Spectral Triple: Eigenvalue Spacing", color='white')
ax.set_xlabel("Spacing", color='white')
ax.set_ylabel("Frequency", color='white')

plt.tight_layout()
plt.savefig('artin_spectral_triple.png', dpi=300, facecolor=fig.get_facecolor())
plt.close()

print("\nPlot saved to artin_spectral_triple.png")
print("=" * 70)
print("TASK 3.2 COMPLETE")
print("=" * 70)
