import os
import numpy as np
import mpmath
import scipy.linalg as la
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from scipy.optimize import bisect

print("=== Starting Automorphic Spectral Triple for Ramanujan Delta Function ===")

# ─── 1. Compute Ramanujan tau coefficients ──────────────────────────────────
M = 100
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
        for j in range(M + 1 - i):
            nxt[i + j] += delta_poly[i] * poly[j]
    delta_poly = nxt

tau = np.zeros(M + 1)
for i in range(M):
    tau[i + 1] = delta_poly[i]

def tau_tilde(p):
    return float(tau[int(p)] * (p ** -5.5))

primes_43 = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43]

# Verify tau values
print("Verified tau coefficients:")
for p in primes_43[:6]:
    print(f"  tau({p}) = {int(tau[p])},  tau_tilde = {tau_tilde(p):.8f}")

# ─── 2. Hardy Z-function for L(s, Delta) ────────────────────────────────────
# The functional equation is Lambda(s) = Lambda(12-s), where
# Lambda(s) = (2pi)^{-s} Gamma(s + 11/2) L(s, Delta) [centered at s=6]
# We work with the normalized form centered at Re(s)=1/2 by defining:
#   s = 1/2 + it,  a = s + 11/2 = 6 + it
# Hardy Z-function: Z(t) = 2 * Re[ e^{i*theta(t)} * sum_n tau_tilde(n)/n^{1/2+it} * Q(6+it, 2pi*n) ]
# where theta(t) = arg Gamma(6+it) - t*log(2pi)

mpmath.mp.dps = 50

def Z_delta(t):
    """Hardy Z-function for the Ramanujan Delta L-function."""
    s = mpmath.mpc(0.5, t)
    a = s + mpmath.mpf('5.5')   # = 6 + it

    gamma_val = mpmath.gamma(a)
    theta = mpmath.arg(gamma_val) - t * mpmath.log(2 * mpmath.pi)
    phase = mpmath.exp(1j * theta)

    total = mpmath.mpc(0.0)
    for n in range(1, 80):
        coeff = float(tau[n] * (n ** -5.5))
        if abs(coeff) < 1e-30:
            continue
        Q = mpmath.gammainc(a, 2 * mpmath.pi * n, regularized=True)
        total += coeff / (n ** s) * Q

    return float(2 * (phase * total).real)

# ─── 3. Find first 20 zeros ─────────────────────────────────────────────────
print("\nLocating non-trivial zeros of L(s, Delta)...")
N_ZEROS = 20
t_scan = np.linspace(0.5, 120, 3000)
y_scan = [Z_delta(t) for t in t_scan]

true_zeros = []
for i in range(len(t_scan) - 1):
    if y_scan[i] * y_scan[i + 1] < 0:
        root = bisect(Z_delta, t_scan[i], t_scan[i + 1], xtol=1e-10)
        if not true_zeros or abs(root - true_zeros[-1]) > 0.01:
            true_zeros.append(root)
        if len(true_zeros) == N_ZEROS:
            break

true_zeros = np.array(true_zeros)
print(f"Found {len(true_zeros)} zeros.")
print("Sample zeros:", true_zeros[:5])

# ─── 4. Lambda sweep: optimize lambda in [15, 30] ───────────────────────────
print("\nSweeping lambda in [15.0, 30.0] with N=250...")
N = 250
n_idx = np.arange(-N, N + 1)
I_mat = np.eye(2 * N + 1)

mpmath.mp.dps = 15  # restore standard for speed during sweep

best_err = float('inf')
best_lam = 0.0
best_evs = None

for lam in np.arange(15.0, 30.1, 0.5):
    log_lam = np.log(lam)
    D0_diag = n_idx * np.pi / log_lam

    # --- Build automorphic xi vector ---
    xi = np.zeros(2 * N + 1, dtype=complex)

    # Non-Archimedean sum: weight-12 Satake twisting
    for p in primes_43:
        tt = tau_tilde(p)
        phases = -1j * n_idx * np.pi * np.log(p) / log_lam
        xi += tt * (np.log(p) / np.sqrt(p)) * np.exp(phases)

    # Archimedean envelope: weight-12 Gamma shift s -> s + 5.5
    for i, n in enumerate(n_idx):
        t_val = n * np.pi / log_lam
        s_val = 0.5 + 1j * t_val
        psi_val = complex(mpmath.digamma(s_val + 5.5))
        xi[i] += 0.5 * (psi_val - np.log(2 * np.pi))

    xi /= np.linalg.norm(xi)
    Proj = I_mat - np.outer(xi, np.conj(xi))
    D = Proj @ np.diag(D0_diag) @ Proj

    evs = la.eigvalsh(D)
    pos_evs = np.array(sorted(v for v in evs if v > 1e-6))

    diffs = [abs(pos_evs[np.argmin(np.abs(pos_evs - z))] - z) for z in true_zeros]
    mae = np.mean(diffs)

    if mae < best_err:
        best_err = mae
        best_lam = lam
        best_evs = pos_evs

print(f"\n--- Automorphic Optimization Results ---")
print(f"Optimal Lambda:               {best_lam:.1f}")
print(f"Mean Absolute Error ({N_ZEROS} zeros):  {best_err:.6f}")
print(f"Sliwinski Lower Bound:        {1.0 / (4.0 * np.log(best_lam)):.6f}")

# ─── 5. Closest eigenvalue matches ──────────────────────────────────────────
closest = [best_evs[np.argmin(np.abs(best_evs - z))] for z in true_zeros]

# ─── 6. Automorphic Weil trace matching ─────────────────────────────────────
T_grid = np.linspace(5.0, 80.0, 1000)
N_T = np.array([np.sum(best_evs <= T) for T in T_grid], dtype=float)
N_fluc = N_T - T_grid * np.log(best_lam) / np.pi

W_T = np.zeros_like(T_grid)
for p in primes_43:
    W_T += tau_tilde(p) * (np.log(p) / np.sqrt(p)) * np.cos(T_grid * np.log(p))

N_fluc_n = (N_fluc - N_fluc.mean()) / N_fluc.std()
W_T_n = (W_T - W_T.mean()) / W_T.std()
corr = float(np.corrcoef(N_fluc, W_T)[0, 1])
print(f"Weil Automorphic Comb Corr:   {corr:.6f}")

# ─── 7. Dual-panel plot ──────────────────────────────────────────────────────
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
fig.patch.set_facecolor('#0f0f1a')
for ax in (ax1, ax2):
    ax.set_facecolor('#0f0f1a')
    ax.tick_params(colors='white')
    ax.xaxis.label.set_color('white')
    ax.yaxis.label.set_color('white')
    ax.title.set_color('white')
    for spine in ax.spines.values():
        spine.set_edgecolor('#444')

idx = range(1, len(true_zeros) + 1)
ax1.plot(idx, true_zeros, 'o-', color='#4cc9f0', linewidth=2, label='True Ramanujan Zeros', zorder=3)
ax1.plot(idx, closest, 'x--', color='#f72585', linewidth=2, markersize=9, label='Automorphic Eigenvalues', zorder=4)
for i, (t, e) in enumerate(zip(true_zeros, closest)):
    ax1.plot([i + 1, i + 1], [t, e], color='#888', linewidth=0.8, alpha=0.6)
ax1.set_xlabel('Zero Index', color='white')
ax1.set_ylabel('Imaginary Part (t)', color='white')
ax1.set_title(f'Eigenvalue Alignment — Ramanujan Δ Zeros\n(λ={best_lam:.1f}, N={N}, MAE={best_err:.4f})', color='white')
ax1.legend(facecolor='#1a1a2e', labelcolor='white')
ax1.grid(True, linestyle='--', alpha=0.3, color='#555')

ax2.plot(T_grid, N_fluc_n, color='#f72585', alpha=0.8, linewidth=1.2, label='Spectral Fluctuation N̄(T)')
ax2.plot(T_grid, W_T_n, color='#4cc9f0', alpha=0.7, linewidth=1.2, label='Automorphic Weil Comb W(T)')
ax2.axhline(0, color='#666', linewidth=0.8)
ax2.set_xlabel('Spectral Energy T', color='white')
ax2.set_ylabel('Normalized Amplitude', color='white')
ax2.set_title(f'Twisted Fluctuation vs Automorphic Weil Comb\n(corr = {corr:.4f})', color='white')
ax2.legend(facecolor='#1a1a2e', labelcolor='white')
ax2.grid(True, linestyle='--', alpha=0.3, color='#555')

plt.tight_layout()
out_path = "C:/Users/x/.gemini/antigravity/scratch/adelic_spectral_zeta/automorphic_resonance_landscape.png"
plt.savefig(out_path, dpi=300, facecolor=fig.get_facecolor())
plt.close()
print(f"\nPlot saved to: {out_path}")
print("=== Automorphic Sandbox Sweep Finished ===")
