"""
Task 2.2: Rank-3 Coupling Vector Construction for GL(3) Sym^2(Delta)
======================================================================
Tests whether a rank-1 projection (using the combined trace A_p) 
or a rank-3 projection (using the individual Satake roots) is required
to stabilize the GL(3) spectral triple.
"""

import numpy as np
import scipy.linalg as la
import mpmath
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import time

print("=" * 70)
print("TASK 2.2: GL(3) PROJECTION RANK TEST")
print("=" * 70)

N = 250
lam = 42.0  # arbitrary starting lambda for testing
log_lam = np.log(lam)
n_vals = np.arange(-N, N + 1)
dim = 2 * N + 1
D0_diag = n_vals * np.pi / log_lam

# Sieve for primes
def sieve(n):
    is_prime = np.ones(n + 1, dtype=bool)
    is_prime[:2] = False
    for i in range(2, int(n**0.5) + 1):
        if is_prime[i]:
            is_prime[i*i::i] = False
    return np.where(is_prime)[0]

P_MAX = 150
primes = sieve(P_MAX)

# Compute tau(n) to get A_p
M = P_MAX
poly = np.zeros(M + 1)
poly[0] = 1.0
for n in range(1, M + 1):
    nxt = poly.copy()
    for i in range(M + 1 - n):
        nxt[i + n] -= poly[i]
    poly = nxt

delta_poly = np.zeros(M + 1)
delta_poly[0] = 1.0
for _ in range(24):
    nxt = np.zeros(M + 1)
    for i in range(M + 1):
        if delta_poly[i] == 0: continue
        for j in range(min(M + 1 - i, len(poly))):
            nxt[i + j] += delta_poly[i] * poly[j]
    delta_poly = nxt

tau = np.zeros(M + 1)
for i in range(M):
    tau[i + 1] = delta_poly[i]

A_p = {}
root1_p = {}
root2_p = {}
root3_p = {}

for p in primes:
    tp = float(tau[p])
    ttp = tp * (p ** -5.5)
    A_p[p] = ttp**2 - 1.0
    if abs(ttp) <= 2.0:
        theta = np.arccos(ttp / 2.0)
        root1_p[p] = np.exp(2j * theta)
        root2_p[p] = 1.0
        root3_p[p] = np.exp(-2j * theta)
    else:
        root1_p[p] = 1.0
        root2_p[p] = 1.0
        root3_p[p] = 1.0

# Archimedean Gamma shift for Sym^2(Delta)
# L_infty(s) = Gamma_R(s+1) Gamma_C(s+11)
# Log-derivative ~ 0.5*psi((s+1)/2) + psi(s+11)
gamma_shift = np.zeros(dim, dtype=complex)
for i, n in enumerate(n_vals):
    t = n * np.pi / log_lam
    s_val = 0.5 + 1j * t
    try:
        # Gamma_R(s+1) -> psi((s+1)/2) / 2
        psi_R = complex(mpmath.psi(0, (s_val + 1.0)/2.0)) / 2.0
        # Gamma_C(s+11) -> psi(s+11)
        psi_C = complex(mpmath.psi(0, s_val + 11.0))
        gamma_shift[i] = 0.5 * (psi_R + psi_C)
    except:
        gamma_shift[i] = 0.0

# ─── CASE 1: RANK-1 PROJECTION ───────────────────────────────────────────
print("\nConstructing Rank-1 Projection Operator (using combined trace A_p)...")
xi_rank1 = np.zeros(dim, dtype=complex)
for p in primes:
    phases = -1j * n_vals * np.pi * np.log(p) / log_lam
    xi_rank1 += A_p[p] * (np.log(p) / np.sqrt(p)) * np.exp(phases)

xi_rank1 += gamma_shift
xi_rank1_norm = xi_rank1 / np.linalg.norm(xi_rank1)
P1 = np.outer(xi_rank1_norm, np.conj(xi_rank1_norm))
Proj_1 = np.eye(dim) - P1
D_rank1 = Proj_1 @ np.diag(D0_diag) @ Proj_1
evs_rank1 = np.sort(np.abs(la.eigvalsh(D_rank1)))
evs_rank1 = evs_rank1[evs_rank1 > 1e-6]

# ─── CASE 2: RANK-3 PROJECTION ───────────────────────────────────────────
print("Constructing Rank-3 Projection Operator (using individual Satake roots)...")
xi_r1 = np.zeros(dim, dtype=complex)
xi_r2 = np.zeros(dim, dtype=complex)
xi_r3 = np.zeros(dim, dtype=complex)

for p in primes:
    phases = -1j * n_vals * np.pi * np.log(p) / log_lam
    term = (np.log(p) / np.sqrt(p)) * np.exp(phases)
    xi_r1 += root1_p[p] * term
    xi_r2 += root2_p[p] * term
    xi_r3 += root3_p[p] * term

# Distribute the gamma shift across the 3 vectors equally
xi_r1 += gamma_shift / 3.0
xi_r2 += gamma_shift / 3.0
xi_r3 += gamma_shift / 3.0

# Orthogonalize the 3 vectors using QR decomposition
V = np.column_stack((xi_r1, xi_r2, xi_r3))
Q, R = np.linalg.qr(V)
P3 = Q @ Q.T.conj()
Proj_3 = np.eye(dim) - P3
D_rank3 = Proj_3 @ np.diag(D0_diag) @ Proj_3
evs_rank3 = np.sort(np.abs(la.eigvalsh(D_rank3)))
evs_rank3 = evs_rank3[evs_rank3 > 1e-6]

# ─── COMPARISON ──────────────────────────────────────────────────────────
print("\n--- Spectral Density Comparison ---")
mean_spacing_r1 = np.mean(np.diff(evs_rank1[:50]))
mean_spacing_r3 = np.mean(np.diff(evs_rank3[:50]))
theoretical_spacing = np.pi / log_lam

print(f"Theoretical Weyl spacing: {theoretical_spacing:.6f}")
print(f"Rank-1 mean spacing:      {mean_spacing_r1:.6f}")
print(f"Rank-3 mean spacing:      {mean_spacing_r3:.6f}")

print("\n--- Low-Lying Eigenvalues ---")
print(f"{'n':<5} | {'Rank-1 |λ_n|':<15} | {'Rank-3 |λ_n|':<15}")
print("-" * 40)
for i in range(10):
    print(f"{i+1:<5} | {evs_rank1[i]:<15.6f} | {evs_rank3[i]:<15.6f}")

# Plot the difference
fig, ax = plt.subplots(figsize=(12, 6))
fig.patch.set_facecolor('#0f0f1a')
ax.set_facecolor('#0f0f1a')
ax.tick_params(colors='white')
for spine in ax.spines.values(): spine.set_edgecolor('#444')

ax.plot(evs_rank1[:50], 'o-', color='#4cc9f0', label='Rank-1 Projection', markersize=4)
ax.plot(evs_rank3[:50], 'x-', color='#f72585', label='Rank-3 Projection', markersize=4)

ax.set_title("GL(3) Spectral Compression: Rank-1 vs Rank-3 Projection", color='white')
ax.set_xlabel("Eigenvalue Index n", color='white')
ax.set_ylabel("Eigenvalue |λ_n|", color='white')
ax.legend(facecolor='#1a1a2e', labelcolor='white')
ax.grid(True, linestyle='--', alpha=0.3, color='#555')

plt.tight_layout()
plt.savefig('gl3_projection_test.png', dpi=300, facecolor=fig.get_facecolor())
plt.close()

print("\nPlot saved to gl3_projection_test.png")
print("=" * 70)
print("TASK 2.2 COMPLETE")
print("=" * 70)
