import numpy as np
import scipy.linalg as la
from scipy.signal import fftconvolve
import mpmath
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import time
from scipy.optimize import bisect

print("=" * 70)
print("TASK 8.1: GL(4) & GL(5) UNIVERSALITY TEST")
print("=" * 70)

# 1. Exact Divisor Sum Recurrence for Tau (M = 8000)
M = 8000

print("Calculating Ramanujan tau coefficients using divisor sum recurrence...")
sigma = np.zeros(M + 1)
for i in range(1, M + 1):
    for j in range(i, M + 1, i):
        sigma[j] += i

delta = np.zeros(M + 1)
delta[0] = 1.0
for n in range(1, M + 1):
    val = 0.0
    for k in range(1, n + 1):
        val -= 24.0 * sigma[k] * delta[n - k]
    delta[n] = val / n

tau = np.zeros(M + 2)
tau[1:M + 2] = delta[:M + 1]
print("Tau calculation complete.")

# 2. Sieve Primes
is_prime = np.ones(M + 1, dtype=bool)
is_prime[:2] = False
for i in range(2, int(M**0.5) + 1):
    if is_prime[i]:
        is_prime[i*i::i] = False
primes = np.where(is_prime)[0]

# 3. Compute coefficients for Sym^3(Delta) (GL(4)) and Sym^4(Delta) (GL(5))
b3 = np.zeros(M + 1)
b3[1] = 1.0
for p in primes:
    tp = float(tau[p] * (p ** -5.5))
    if abs(tp) > 2.0:
        print(f"Warning: |tau~({p})| = {abs(tp):.6f} > 2")
        theta = 0.0
    else:
        theta = np.arccos(tp / 2.0)
        
    B1 = tp**3 - 2.0 * tp
    B2 = tp**4 - 3.0 * tp**2 + 2.0
    B3 = B1
    B4 = 1.0
    
    pk_coeffs = [1.0, B1]
    pk_coeffs.append(B1 * pk_coeffs[1] - B2 * pk_coeffs[0])
    pk_coeffs.append(B1 * pk_coeffs[2] - B2 * pk_coeffs[1] + B3 * pk_coeffs[0])
    k = 4
    while p**k <= M:
        pk_coeffs.append(B1 * pk_coeffs[k-1] - B2 * pk_coeffs[k-2] + B3 * pk_coeffs[k-3] - B4 * pk_coeffs[k-4])
        k += 1
        
    for i in range(M, 0, -1):
        if b3[i] == 0: continue
        k = 1
        while True:
            pk = p**k
            if i * pk > M:
                break
            b3[i * pk] = b3[i] * pk_coeffs[k]
            k += 1

b4 = np.zeros(M + 1)
b4[1] = 1.0
for p in primes:
    tp = float(tau[p] * (p ** -5.5))
    if abs(tp) > 2.0:
        theta = 0.0
    else:
        theta = np.arccos(tp / 2.0)
    
    alphas = [np.exp(1j * (4 - 2*j) * theta) for j in range(5)]
    
    max_k = 1
    while p**(max_k + 1) <= M:
        max_k += 1
        
    denom = np.array([1.0], dtype=complex)
    for alpha in alphas:
        denom = np.convolve(denom, [1.0, -alpha])
        
    coeffs = [1.0]
    for n in range(1, max_k + 1):
        val = 0.0
        for i in range(1, min(n + 1, len(denom))):
            val -= denom[i] * coeffs[n - i]
        coeffs.append(val)
        
    for i in range(M, 0, -1):
        if b4[i] == 0: continue
        k = 1
        while True:
            pk = p**k
            if i * pk > M:
                break
            b4[i * pk] = b4[i] * coeffs[k].real
            k += 1

# 4. Z-function setup (Vectorized)
n_arr = np.arange(1, M + 1)
log_n = np.log(n_arr)
sqrt_n = np.sqrt(n_arr)

mpmath.mp.dps = 20

def get_phase_sym3(t):
    s = 0.5 + 1j * t
    g1 = complex(mpmath.loggamma(s + 16.5))
    g2 = complex(mpmath.loggamma(s + 5.5))
    return np.exp(1j * (g1.imag + g2.imag - 2.0 * t * np.log(2.0 * np.pi)))

def Z_sym3_batch(t_arr, W=1000.0):
    phases = np.array([get_phase_sym3(t) for t in t_arr])
    weights = b3[1:] * np.exp(-n_arr / W) / sqrt_n
    exps = np.exp(-1j * np.outer(t_arr, log_n))
    return (phases * (exps @ weights)).real

def get_phase_sym4(t):
    s = 0.5 + 1j * t
    g_R = complex(mpmath.loggamma((s + 22.0)/2.0)) - 0.5*(s+22.0)*np.log(np.pi)
    g_C1 = complex(mpmath.loggamma(s + 11.0)) - (s+11.0)*np.log(2.0*np.pi)
    g_C2 = complex(mpmath.loggamma(s + 22.0)) - (s+22.0)*np.log(2.0*np.pi)
    return np.exp(1j * (g_R.imag + g_C1.imag + g_C2.imag))

def Z_sym4_batch(t_arr, W=1000.0):
    phases = np.array([get_phase_sym4(t) for t in t_arr])
    weights = b4[1:] * np.exp(-n_arr / W) / sqrt_n
    exps = np.exp(-1j * np.outer(t_arr, log_n))
    return (phases * (exps @ weights)).real

print("Computing exact reference zeros using high-resolution batch scans...")
t_scan = np.linspace(5.0, 25.0, 1000)
z_scan3 = Z_sym3_batch(t_scan)
z_scan4 = Z_sym4_batch(t_scan)

zeros3 = []
for i in range(len(t_scan) - 1):
    if z_scan3[i] * z_scan3[i+1] < 0:
        zeros3.append(bisect(lambda t: Z_sym3_batch([t])[0], t_scan[i], t_scan[i+1], xtol=1e-8))

zeros4 = []
for i in range(len(t_scan) - 1):
    if z_scan4[i] * z_scan4[i+1] < 0:
        zeros4.append(bisect(lambda t: Z_sym4_batch([t])[0], t_scan[i], t_scan[i+1], xtol=1e-8))

ref_zeros_gl4 = np.array(zeros3[:5])
ref_zeros_gl5 = np.array(zeros4[:5])
print(f"GL(4) Sym^3 Target Zeros: {ref_zeros_gl4}")
print(f"GL(5) Sym^4 Target Zeros: {ref_zeros_gl5}")

# 5. Operators and Sweep Simulation
N_dim = 600
dim = 2 * N_dim + 1
n_vals = np.arange(-N_dim, N_dim + 1)

# Truncate primes for operator coupling
OP_P_MAX = 200
op_primes = primes[primes <= OP_P_MAX]

def simulate_universality(degree, ref_zeros, b_coeff, get_phase, lambda_val):
    log_lam = np.log(lambda_val)
    D0_diag = n_vals * np.pi / log_lam
    
    # Archimedean shift
    gamma_shift = np.zeros(dim, dtype=complex)
    for i, n in enumerate(n_vals):
        t = n * np.pi / log_lam
        gamma_shift[i] = 0.5 * np.log(np.abs(get_phase(t))) # approximate phase shift
        # Actually, let's use the logarithmic derivative of the Gamma factors directly:
        s_val = 0.5 + 1j * t
        if degree == 4:
            psi1 = complex(mpmath.psi(0, s_val + 16.5)) - np.log(2*np.pi)
            psi2 = complex(mpmath.psi(0, s_val + 5.5)) - np.log(2*np.pi)
            gamma_shift[i] = 0.5 * (psi1 + psi2)
        else:
            psi_R = complex(mpmath.psi(0, (s_val + 22.0)/2.0)) - np.log(np.pi)
            psi_C1 = complex(mpmath.psi(0, s_val + 11.0)) - np.log(2*np.pi)
            psi_C2 = complex(mpmath.psi(0, s_val + 22.0)) - np.log(2*np.pi)
            gamma_shift[i] = 0.5 * (psi_R + psi_C1 + psi_C2)

    # Rank-1 Construction
    xi_r1 = np.zeros(dim, dtype=complex)
    for p in op_primes:
        tp = float(tau[p] * (p ** -5.5))
        if degree == 4:
            A_prime = tp**3 - 2.0 * tp
        else:
            A_prime = tp**4 - 3.0 * tp**2 + 1.0
            
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        xi_r1 += A_prime * (np.log(p) / np.sqrt(p)) * np.exp(phases)
    xi_r1 += gamma_shift
    xi_r1_norm = xi_r1 / np.linalg.norm(xi_r1)
    
    P1 = np.outer(xi_r1_norm, np.conj(xi_r1_norm))
    D_rank1 = (np.eye(dim) - P1) @ np.diag(D0_diag) @ (np.eye(dim) - P1)
    
    # Rank-N Construction
    xi_rn = []
    for j in range(degree):
        xi_j = np.zeros(dim, dtype=complex)
        for p in op_primes:
            tp = float(tau[p] * (p ** -5.5))
            if abs(tp) > 2.0:
                theta = 0.0
            else:
                theta = np.arccos(tp / 2.0)
            
            # Satake parameters
            if degree == 4:
                alpha = np.exp(1j * (3 - 2*j) * theta)
            else:
                alpha = np.exp(1j * (4 - 2*j) * theta)
                
            phases = -1j * n_vals * np.pi * np.log(p) / log_lam
            xi_j += alpha * (np.log(p) / np.sqrt(p)) * np.exp(phases)
        xi_j += gamma_shift / degree
        xi_rn.append(xi_j)
        
    V = np.column_stack(xi_rn)
    Q, _ = np.linalg.qr(V)
    P_N = Q @ Q.T.conj()
    D_rankN = (np.eye(dim) - P_N) @ np.diag(D0_diag) @ (np.eye(dim) - P_N)
    
    # Solve eigenvalues
    evs_r1 = np.sort(np.abs(la.eigvalsh(D_rank1)))
    evs_r1 = evs_r1[evs_r1 > 1e-6][::2]
    
    evs_rN = np.sort(np.abs(la.eigvalsh(D_rankN)))
    evs_rN = evs_rN[evs_rN > 1e-6][::2]
    
    # Compute MAE
    k = len(ref_zeros)
    mae1 = np.mean(np.abs(evs_r1[:k] - ref_zeros)) if len(evs_r1) >= k else np.inf
    maeN = np.mean(np.abs(evs_rN[:k] - ref_zeros)) if len(evs_rN) >= k else np.inf
    
    # Dominance overlap: overlap of rank-1 vector with the rank-N projection subspace
    # overlap = || P_N @ xi_r1_norm ||^2
    overlap = np.linalg.norm(P_N @ xi_r1_norm)**2
    
    return mae1, maeN, overlap

# Run sweep for GL(4)
lambda_vals = np.linspace(15.0, 35.0, 50)
mae1_gl4, maeN_gl4, overlap_gl4 = [], [], []

print("\nSweeping scaling parameter lambda for GL(4)...")
for lam in lambda_vals:
    m1, mN, ov = simulate_universality(4, ref_zeros_gl4, b3, get_phase_sym3, lam)
    mae1_gl4.append(m1)
    maeN_gl4.append(mN)
    overlap_gl4.append(ov)

# Run sweep for GL(5)
mae1_gl5, maeN_gl5, overlap_gl5 = [], [], []
print("Sweeping scaling parameter lambda for GL(5)...")
for lam in lambda_vals:
    m1, mN, ov = simulate_universality(5, ref_zeros_gl5, b4, get_phase_sym4, lam)
    mae1_gl5.append(m1)
    maeN_gl5.append(mN)
    overlap_gl5.append(ov)

# Print dominance statistics
print("\n--- SWEEP STATISTICS ---")
print(f"GL(4) Rank-1 Min MAE: {np.min(mae1_gl4):.6f} (Rank-4: {np.min(maeN_gl4):.6f})")
print(f"GL(4) Average Subspace Overlap: {np.mean(overlap_gl4):.6f}")
print(f"GL(5) Rank-1 Min MAE: {np.min(mae1_gl5):.6f} (Rank-5: {np.min(maeN_gl5):.6f})")
print(f"GL(5) Average Subspace Overlap: {np.mean(overlap_gl5):.6f}")

# Plotting
fig, axs = plt.subplots(2, 2, figsize=(14, 10))
fig.patch.set_facecolor('#0f0f1a')

colors = ['#4cc9f0', '#f72585', '#7209b7']

for row, (degree, mae1, maeN, overlap, ref_zeros) in enumerate([
    (4, mae1_gl4, maeN_gl4, overlap_gl4, ref_zeros_gl4),
    (5, mae1_gl5, maeN_gl5, overlap_gl5, ref_zeros_gl5)
]):
    ax_mae = axs[row, 0]
    ax_ov = axs[row, 1]
    
    for ax in [ax_mae, ax_ov]:
        ax.set_facecolor('#0f0f1a')
        ax.tick_params(colors='white')
        ax.xaxis.label.set_color('white')
        ax.yaxis.label.set_color('white')
        ax.title.set_color('white')
        for spine in ax.spines.values(): spine.set_edgecolor('#444')
        ax.grid(True, linestyle='--', alpha=0.3, color='#555')
        
    ax_mae.plot(lambda_vals, mae1, color=colors[0], linewidth=2.5, label='Rank-1 Projection')
    ax_mae.plot(lambda_vals, maeN, color=colors[1], linewidth=2.5, label=f'Rank-{degree} Projection')
    ax_mae.set_yscale('log')
    ax_mae.set_title(f"GL({degree}) Dissonance Sweep")
    ax_mae.set_xlabel(r'$\lambda$')
    ax_mae.set_ylabel('MAE')
    ax_mae.legend(facecolor='#1a1a2e', labelcolor='white')
    
    ax_ov.plot(lambda_vals, overlap, color=colors[2], linewidth=2.5, label='Subspace Overlap')
    ax_ov.set_title(f"GL({degree}) Rank-1 Overlap with Rank-{degree} Subspace")
    ax_ov.set_xlabel(r'$\lambda$')
    ax_ov.set_ylabel('Overlap Factor')
    ax_ov.legend(facecolor='#1a1a2e', labelcolor='white')

plt.suptitle("GL(4) and GL(5) Rank-1 Universality Sweep", color='white', fontsize=16)
plt.tight_layout()
plt.savefig('gl_n_universality_test.png', dpi=300, facecolor=fig.get_facecolor())
plt.close()
print("\nPlot saved to gl_n_universality_test.png")
print("=" * 70)
print("TASK 8.1 COMPLETE")
print("=" * 70)
