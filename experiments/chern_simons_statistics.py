"""
Task 5.1: Arithmetic Chern-Simons / Sato-Tate Statistics
===========================================================
Computes the distribution of the secondary characteristic class
tilde_tau(p)^2 - 2 = alpha_p^2 + beta_p^2 across primes p <= 10000
and compares against the Sato-Tate measure for GL(2) cusp forms:
    dmu_ST = (2/pi) * sqrt(1 - x^2/4) dx  on [-2, 2]
The class tilde_tau(p)^2 - 2 is a measure of the "curvature" of the
automorphic local system — the arithmetic Chern-Simons invariant
identified in the Geometric Index Theorem (§3.4).
"""

import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from collections import defaultdict

print("=" * 70)
print("TASK 5.1: ARITHMETIC CHERN-SIMONS / SATO-TATE STATISTICS")
print("=" * 70)

# ─── 1. Sieve of Eratosthenes for primes up to 10000 ────────────────────
P_MAX = 10000

def sieve(n):
    is_prime = np.ones(n + 1, dtype=bool)
    is_prime[:2] = False
    for i in range(2, int(n**0.5) + 1):
        if is_prime[i]:
            is_prime[i*i::i] = False
    return np.where(is_prime)[0]

primes = sieve(P_MAX)
print(f"Number of primes up to {P_MAX}: {len(primes)}")

# ─── 2. Compute Ramanujan tau via q-expansion up to degree P_MAX ─────────
print(f"\nComputing tau(n) for n up to {P_MAX} via eta^24 product...")
M = P_MAX

poly = np.zeros(M + 1)
poly[0] = 1.0
for n in range(1, M + 1):
    nxt = poly.copy()
    for i in range(M + 1 - n):
        nxt[i + n] -= poly[i]
    poly = nxt

# Raise to 24th power iteratively
delta_poly = np.zeros(M + 1)
delta_poly[0] = 1.0
for _ in range(24):
    nxt = np.zeros(M + 1)
    # Convolution: only up to degree M
    for i in range(M + 1):
        if delta_poly[i] == 0:
            continue
        for j in range(min(M + 1 - i, len(poly))):
            nxt[i + j] += delta_poly[i] * poly[j]
    delta_poly = nxt

tau = np.zeros(M + 1)
for i in range(M):
    tau[i + 1] = delta_poly[i]

print(f"  tau(2)  = {int(tau[2])}  (expected: -24)")
print(f"  tau(3)  = {int(tau[3])}  (expected: 252)")
print(f"  tau(7)  = {int(tau[7])}  (expected: -16744)")
print(f"  tau(11) = {int(tau[11])}  (expected: 534612)")

# ─── 3. Compute normalized tau_tilde and the Chern-Simons invariant ──────
print(f"\nComputing arithmetic Chern-Simons invariant tilde_tau(p)^2 - 2 ...")

tau_tildes = []
cs_invariants = []          # tau_tilde(p)^2 - 2  = alpha_p^2 + beta_p^2
satake_angles = []           # theta_p: alpha_p = e^{i*theta_p}, beta_p = e^{-i*theta_p}

ramanujan_violations = 0

for p in primes:
    if p > M:
        break
    tt = float(tau[p]) * (p ** -5.5)
    tau_tildes.append(tt)
    cs = tt**2 - 2.0            # = alpha_p^2 + beta_p^2 - 2
    cs_invariants.append(cs)

    # Ramanujan-Petersson: |tilde_tau(p)| <= 2 <=> theta is real
    if abs(tt) <= 2.0:
        theta = np.arccos(tt / 2.0)    # theta in [0, pi]
        satake_angles.append(theta)
    else:
        ramanujan_violations += 1

tau_tildes = np.array(tau_tildes)
cs_invariants = np.array(cs_invariants)
satake_angles = np.array(satake_angles)

print(f"  Ramanujan-Petersson violations (|tilde_tau| > 2): {ramanujan_violations}")
print(f"  (should be 0 by Deligne's theorem)")
print(f"  Range of tilde_tau(p): [{tau_tildes.min():.6f}, {tau_tildes.max():.6f}]")
print(f"  Range of CS invariant tilde_tau^2 - 2: [{cs_invariants.min():.6f}, {cs_invariants.max():.6f}]")

# ─── 4. Sato-Tate distribution for GL(2) ────────────────────────────────
# mu_ST(theta) = (2/pi) * sin^2(theta)  for theta in [0, pi]
# In terms of x = tilde_tau = 2*cos(theta):
# mu_ST(x) = (2/pi) * sqrt(1 - x^2/4)  for x in [-2, 2]
# For CS invariant y = x^2 - 2 = 2*cos(2*theta):
# Push-forward: mu_ST(y) = (1/pi) * 1/sqrt(1 - y^2/4)  ... (arcsine-like)

x_theory = np.linspace(-2.0, 2.0, 400)
sato_tate_x = (2.0 / np.pi) * np.sqrt(np.maximum(0, 1.0 - x_theory**2 / 4.0))

# CS invariant pushforward: y = x^2 - 2, dy = 2x dx
# p(y) = p_x(x) / |dy/dx| = p_x(x) / |2x| = p_x(sqrt(y+2)) / (2*sqrt(y+2))
# Only valid for y in [-2, 2] (since x in [-2,2] => x^2 in [0,4] => x^2-2 in [-2,2])
y_theory = np.linspace(-2.0, 2.0, 400)
eps = 1e-6
x_from_y = np.sqrt(np.maximum(eps, y_theory + 2.0))
sato_tate_cs = (2.0 / np.pi) * np.sqrt(np.maximum(0, 1.0 - x_from_y**2 / 4.0)) / (2.0 * x_from_y)

# ─── 5. Statistical tests ────────────────────────────────────────────────
print(f"\n--- Statistical Summary ---")
print(f"  Mean of tilde_tau(p):      {tau_tildes.mean():.6f}  (Sato-Tate predicts 0)")
print(f"  Variance of tilde_tau(p):  {tau_tildes.var():.6f}  (Sato-Tate predicts 1)")
print(f"  Mean of CS invariant:      {cs_invariants.mean():.6f}  (pushforward mean = 0)")
print(f"  Variance of CS invariant:  {cs_invariants.var():.6f}")
print(f"  Skewness of tilde_tau:     {(((tau_tildes - tau_tildes.mean())/tau_tildes.std())**3).mean():.6f}")
print(f"  Kurtosis of tilde_tau:     {(((tau_tildes - tau_tildes.mean())/tau_tildes.std())**4).mean():.6f}  (Sato-Tate predicts 2)")

# Kolmogorov-Smirnov test against Sato-Tate
from scipy.stats import ks_1samp

def sato_tate_cdf(x):
    """CDF of Sato-Tate: F(x) = (1/pi)*(arcsin(x/2) + pi/2 + (x/2)*sqrt(1 - x^2/4)) for x in [-2,2]"""
    x_clipped = np.clip(x, -2.0, 2.0)
    return (1.0 / np.pi) * (np.arcsin(x_clipped / 2.0) + np.pi / 2.0 
                              + (x_clipped / 2.0) * np.sqrt(np.maximum(0, 1.0 - x_clipped**2 / 4.0)))

ks_stat, ks_pvalue = ks_1samp(tau_tildes, sato_tate_cdf)
print(f"\n  Kolmogorov-Smirnov test vs. Sato-Tate:")
print(f"    KS statistic: {ks_stat:.6f}")
print(f"    p-value:      {ks_pvalue:.6f}")
if ks_pvalue > 0.05:
    print(f"    ✓ CONSISTENT with Sato-Tate at 95% confidence")
else:
    print(f"    Data deviates from Sato-Tate (finite-N effect expected)")

# ─── 6. Prime-by-prime convergence to Sato-Tate ─────────────────────────
# Track running KS statistic as we include more primes
chunk_sizes = np.geomspace(10, len(primes), 20, dtype=int)
ks_running = []
for k in chunk_sizes:
    subset = tau_tildes[:k]
    ks, _ = ks_1samp(subset, sato_tate_cdf)
    ks_running.append(ks)

print(f"\n  KS convergence: {chunk_sizes[0]} primes → KS={ks_running[0]:.4f},  "
      f"{chunk_sizes[-1]} primes → KS={ks_running[-1]:.4f}")

# ─── 7. Plotting ─────────────────────────────────────────────────────────
fig, axes = plt.subplots(1, 3, figsize=(20, 6))
fig.patch.set_facecolor('#0f0f1a')
for ax in axes:
    ax.set_facecolor('#0f0f1a')
    ax.tick_params(colors='white')
    ax.xaxis.label.set_color('white')
    ax.yaxis.label.set_color('white')
    ax.title.set_color('white')
    for spine in ax.spines.values():
        spine.set_edgecolor('#444')

# Panel 1: tilde_tau(p) vs. Sato-Tate density
axes[0].hist(tau_tildes, bins=60, density=True, color='#4cc9f0', alpha=0.65,
             edgecolor='#2a6f97', label=f'Empirical ({len(primes)} primes)')
axes[0].plot(x_theory, sato_tate_x, color='#f72585', linewidth=2.5,
             label='Sato-Tate density')
axes[0].set_xlabel(r'$\tilde{\tau}(p) = \tau(p) \cdot p^{-11/2}$')
axes[0].set_ylabel('Probability density')
axes[0].set_title(f'Normalized Ramanujan Coefficients\nvs. Sato-Tate ($p \leq {P_MAX}$)', color='white')
axes[0].legend(facecolor='#1a1a2e', labelcolor='white', fontsize=9)
axes[0].grid(True, linestyle='--', alpha=0.3, color='#555')

# Panel 2: Chern-Simons invariant tilde_tau^2 - 2
axes[1].hist(cs_invariants, bins=60, density=True, color='#7b2d8b', alpha=0.65,
             edgecolor='#4a1a5c', label=r'Empirical $\tilde{\tau}(p)^2 - 2$')
valid_y = (y_theory > -1.99) & (sato_tate_cs > 0) & np.isfinite(sato_tate_cs)
axes[1].plot(y_theory[valid_y], sato_tate_cs[valid_y], color='#f72585', linewidth=2.5,
             label='Pushforward Sato-Tate')
axes[1].set_xlabel(r'$\tilde{\tau}(p)^2 - 2 = \alpha_p^2 + \beta_p^2 - 2$')
axes[1].set_ylabel('Probability density')
axes[1].set_title(r'Arithmetic Chern-Simons Invariant $\tilde{\tau}(p)^2 - 2$' + '\n(deviation from trivial Satake repr.)', color='white')
axes[1].legend(facecolor='#1a1a2e', labelcolor='white', fontsize=9)
axes[1].grid(True, linestyle='--', alpha=0.3, color='#555')
axes[1].set_xlim(-2.1, 2.1)

# Panel 3: KS convergence to Sato-Tate
axes[2].semilogx(chunk_sizes, ks_running, 'o-', color='#4cc9f0', linewidth=2,
                  markersize=6, label='KS statistic')
axes[2].semilogx(chunk_sizes, 1.36 / np.sqrt(chunk_sizes), '--', color='#f72585',
                  linewidth=1.5, label='1.36/√n (KS critical @ 95%)')
axes[2].set_xlabel('Number of primes included')
axes[2].set_ylabel('Kolmogorov-Smirnov statistic')
axes[2].set_title('Convergence to Sato-Tate Distribution', color='white')
axes[2].legend(facecolor='#1a1a2e', labelcolor='white', fontsize=9)
axes[2].grid(True, linestyle='--', alpha=0.3, color='#555')

plt.tight_layout()
import os
script_dir = os.path.dirname(os.path.abspath(__file__))
out = os.path.join(script_dir, "..", "figures", "chern_simons_statistics.png")
plt.savefig(out, dpi=300, facecolor=fig.get_facecolor())
plt.close()

print(f"\nTriple-panel plot saved to: {out}")
print("=" * 70)
print("TASK 5.1 COMPLETE")
print("=" * 70)
