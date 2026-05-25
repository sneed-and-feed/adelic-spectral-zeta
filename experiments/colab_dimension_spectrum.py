"""
Task 1.2: Discrete Dimension Spectrum Exploration
===================================================
DESIGNED FOR EXECUTION ON GOOGLE COLAB (T4 / A100)

This script computes the spectral zeta function of the Dirac operator:
    zeta_D(z) = Tr(|D|^{-z}) = sum_{n} |lambda_n|^{-z}
and maps its poles in the complex z-plane. 

According to the Connes-Moscovici axioms, the Dimension Spectrum 
(the set of singularities of zeta_D(z)) must be discrete. For this 
adèlic spectral triple, we expect poles at:
  - z = 1 (the spectral dimension, giving the Dixmier trace)
  - Complex poles corresponding to the critical zeros of L(s)
  - z = 0, -1, -2, ... (trivial poles)
"""

import numpy as np
import scipy.linalg as la
import mpmath
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import time

print("=" * 70)
print("TASK 1.2: DISCRETE DIMENSION SPECTRUM EXPLORATION (COLAB)")
print("=" * 70)

# ─── HIGH-RESOLUTION OPERATOR SETUP ────────────────────────────────────────
# In Colab, we can push N to 2000-5000. For local testing, keep N around 500.
N = 2500  # Change this to 5000 if you have A100 RAM
lam = 45.0
log_lam = np.log(lam)
n_vals = np.arange(-N, N + 1)
dim = 2 * N + 1

# Prime ceiling (use a large prime comb for high N)
def sieve(n):
    is_prime = np.ones(n + 1, dtype=bool)
    is_prime[:2] = False
    for i in range(2, int(n**0.5) + 1):
        if is_prime[i]:
            is_prime[i*i::i] = False
    return np.where(is_prime)[0]

primes = sieve(300)

print(f"Matrix Dimension: {dim}x{dim}")
print(f"Prime ceiling p_max: {primes[-1]}")
print("Constructing Dirac operator... (this may take a minute)")

start_time = time.time()
D0_diag = n_vals * np.pi / log_lam

xi = np.zeros(dim, dtype=complex)
for p in primes:
    phases = -1j * n_vals * np.pi * np.log(p) / log_lam
    xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)

for i, n in enumerate(n_vals):
    t = n * np.pi / log_lam
    s_val = 0.25 + 0.5j * t
    psi_val = complex(mpmath.psi(0, s_val))
    xi[i] += 0.5 * (psi_val + np.log(np.pi))

xi_norm = xi / np.linalg.norm(xi)
I_mat = np.eye(dim)
P = np.outer(xi_norm, np.conj(xi_norm))
Proj = I_mat - P

# Compressed Dirac Operator
D = Proj @ np.diag(D0_diag) @ Proj

print(f"Operator built in {time.time() - start_time:.2f} seconds.")
print("Computing eigenvalues...")

start_time = time.time()
eigenvalues = la.eigvalsh(D)
# Filter out the zero modes (the kernel)
pos_evs = np.sort(np.abs(eigenvalues[np.abs(eigenvalues) > 1e-6]))
print(f"Eigenvalues computed in {time.time() - start_time:.2f} seconds.")
print(f"Number of non-zero eigenvalues: {len(pos_evs)}")

# ─── SPECTRAL ZETA FUNCTION EVALUATION ───────────────────────────────────
print("\nMapping the complex plane for zeta_D(z) poles...")

# We will scan the complex plane z = x + iy
# To see the poles, we plot the magnitude |zeta_D(z)|
# We expect a pole at z = 1 (x=1, y=0)

x_min, x_max = -0.5, 1.5
y_min, y_max = -15.0, 15.0
x_res, y_res = 200, 400

x_vals = np.linspace(x_min, x_max, x_res)
y_vals = np.linspace(y_min, y_max, y_res)
X, Y = np.meshgrid(x_vals, y_vals)
Z_complex = X + 1j * Y

# Compute zeta_D(z) = sum |lambda_n|^{-z}
# Since computing this for 5000 eigenvalues x 80000 grid points is heavy,
# we use broadcasting.
zeta_grid = np.zeros_like(Z_complex, dtype=complex)

# Batch the computation to avoid memory overflow
batch_size = 500
for i in range(0, len(pos_evs), batch_size):
    ev_batch = pos_evs[i:i+batch_size]
    # ev_batch is shape (B,), Z_complex is (y_res, x_res)
    # We want sum_n (ev_n ** -z).
    # Since ev_n is real positive, ev_n ** -z = exp(-z * log(ev_n))
    log_evs = np.log(ev_batch)
    for j, log_e in enumerate(log_evs):
        zeta_grid += np.exp(-Z_complex * log_e)

zeta_mag = np.abs(zeta_grid)

# Plotting the heat map
fig, ax = plt.subplots(figsize=(10, 8))
fig.patch.set_facecolor('#0f0f1a')
ax.set_facecolor('#0f0f1a')
ax.tick_params(colors='white')
ax.xaxis.label.set_color('white')
ax.yaxis.label.set_color('white')
ax.title.set_color('white')

# Use a logarithmic color scale to handle the singularities (poles)
c = ax.pcolormesh(X, Y, np.log10(zeta_mag + 1), cmap='magma', shading='auto')
cbar = fig.colorbar(c, ax=ax)
cbar.set_label('log10 |zeta_D(z)|', color='white')
cbar.ax.yaxis.set_tick_params(color='white')
plt.setp(plt.getp(cbar.ax.axes, 'yticklabels'), color='white')

# Highlight expected pole at z=1
ax.axvline(x=1.0, color='cyan', linestyle='--', alpha=0.5, label='z = 1 (Spectral Dimension)')
ax.axhline(y=0.0, color='white', linestyle='-', alpha=0.3)

ax.set_xlabel('Re(z)')
ax.set_ylabel('Im(z)')
ax.set_title(f'Dimension Spectrum: Poles of Spectral Zeta Function\n$N={N}$, $\lambda={lam}$', color='white')
ax.legend(facecolor='#1a1a2e', labelcolor='white')

plt.tight_layout()
import os
script_dir = os.path.dirname(os.path.abspath(__file__))
out = os.path.join(script_dir, "..", "figures", "dimension_spectrum.png")
plt.savefig(out, dpi=300, facecolor=fig.get_facecolor())
plt.close()

print(f"Plot saved to {out}.")
print("=" * 70)
print("TASK 1.2 COMPLETE")
print("=" * 70)
