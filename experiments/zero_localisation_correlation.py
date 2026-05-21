import os
import json
import math
import numpy as np
import mpmath
import sympy as sp
import scipy.optimize as opt
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from scipy.stats import pearsonr

mpmath.mp.dps = 35

def get_primes(n):
    return list(sp.primerange(2, n + 1))

def main():
    print("=" * 70)
    print("ZERO-MODE LOCALISATION CORRELATION ANALYSIS")
    print("=" * 70)
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    
    traces_path = os.path.join(project_root, "data", "a5_hecke_traces.json")
    correlation_figure_path = os.path.join(project_root, "figures", "zero_localisation_correlation.png")
    
    # Load step 1334 complex traces
    ap_path = os.path.join(project_root, "data", "artin_800_ap.json")
    with open(ap_path, "r", encoding="utf-8") as f:
        ap_raw = json.load(f)
    N = 800
    
    zeta20 = np.exp(2j * np.pi / 20.0)
    def parse_coeff(terms):
        if not terms: return 0.0 + 0.0j
        return sum(c * (zeta20 ** k) for c, k in terms)
        
    primes_list = list(sp.primerange(2, 2001))
    a_p_complex = {}
    for idx, p in enumerate(primes_list):
        if idx < len(ap_raw):
            a_p_complex[p] = parse_coeff(ap_raw[idx])
            
    # Build character chi
    lut_32 = {}
    for x1 in [0, 1]:
        for x2 in range(8):
            lut_32[((-1)**x1 * 5**x2) % 32] = (x1, x2)
    lut_25 = {}
    for x3 in range(20):
        lut_25[(2**x3) % 25] = x3
        
    def chi(n):
        n = int(n)
        if math.gcd(n, 800) > 1: return 0.0 + 0.0j
        x1, _ = lut_32[n % 32]
        x3 = lut_25[n % 25]
        val = (5*x1 + 4*x3) % 10
        return np.exp(2j * np.pi * val / 10)
        
    # Build a_n for L-function evaluation
    M = 1500
    primes = [p for p in primes_list if p <= M]
    a = np.zeros(M+1, dtype=complex)
    a[1] = 1.0
    
    for p in primes:
        ap = a_p_complex.get(p, 0.0+0j)
        chip = chi(p)
        pk_coeffs = [1.0+0j, ap]
        k = 2
        while p**k <= M:
            pk_coeffs.append(ap * pk_coeffs[k-1] - chip * pk_coeffs[k-2])
            k += 1
        for k in range(1, len(pk_coeffs)):
            if p**k <= M:
                a[p**k] = pk_coeffs[k]
                
    for i in range(2, M+1):
        if abs(a[i]) < 1e-14:
            continue
        for p in primes:
            if i * p > M:
                break
            if math.gcd(i, p) > 1:
                continue
            ap = a_p_complex.get(p, 0.0+0j)
            chip = chi(p)
            pk_coeffs = [1.0+0j, ap]
            kk = 2
            while i * p**kk <= M:
                pk_coeffs.append(ap * pk_coeffs[kk-1] - chip * pk_coeffs[kk-2])
                kk += 1
            for k in range(1, len(pk_coeffs)):
                pk = p**k
                if i * pk > M:
                    break
                a[i*pk] = a[i] * pk_coeffs[k]
                
    log_n = np.log(np.arange(1, M+1))
    a_arr = a[1:]
    
    def eval_L(t, w_val, max_n=1200):
        s = 0.5 + 1j*t
        powers = np.exp(-s * log_n[:max_n])
        S1 = np.dot(a_arr[:max_n], powers)
        
        s2 = 0.5 - 1j*t
        powers2 = np.exp(-s2 * log_n[:max_n])
        S2 = np.dot(np.conj(a_arr[:max_n]), powers2)
        
        gamma_s = mpmath.gamma(mpmath.mpc(0.5, t))
        gamma_1ms = mpmath.gamma(mpmath.mpc(0.5, -t))
        cond = mpmath.mpf(N) / (4 * mpmath.pi**2)
        cond_factor = mpmath.power(cond, mpmath.mpc(0, t))
        P = gamma_1ms / gamma_s * cond_factor
        P_c = complex(float(P.real), float(P.imag))
        
        return S1 + w_val * P_c * S2

    # Load Hecke traces database for F_off calculation
    with open(traces_path, "r", encoding="utf-8") as f:
        traces_db = json.load(f)
    a_p_orbit = traces_db["800.1.bh.a"]["traces"]
    
    P_MAX = 1000
    primes_orbit = get_primes(P_MAX)
    active_primes = [p for p in primes_orbit if str(p) in a_p_orbit]
    
    log_p = {p: np.log(p) for p in active_primes}
    sqrt_p = {p: np.sqrt(p) for p in active_primes}
    a_p_val = {p: float(a_p_orbit[str(p)]) for p in active_primes}
    
    lambda_1_norm = {p: (p + 1 - 2.0 * sqrt_p[p]) / (p + 1) for p in active_primes}
    gap_2 = lambda_1_norm[2]
    gamma_0 = 0.20 / gap_2
    gamma_p = {p: gamma_0 * lambda_1_norm[p] for p in active_primes}
    
    def compute_F_var(T):
        sum_var = 0.0 + 0.0j
        for i, p in enumerate(active_primes):
            ap = a_p_val[p]
            if ap == 0:
                continue
            lp = log_p[p]
            sp_p = sqrt_p[p]
            gp_p = gamma_p[p]
            
            for q in active_primes[i+1:]:
                aq = a_p_val[q]
                if aq == 0:
                    continue
                lq = log_p[q]
                sp_q = sqrt_p[q]
                gp_q = gamma_p[q]
                
                diff_log = lp - lq
                phase = np.exp(1j * T * diff_log)
                kernel = 1.0 / np.sqrt(1.0 + (T * diff_log)**2)
                decay_factor_var = (p ** -gp_p) * (q ** -gp_q)
                term = (ap * aq * lp * lq) / (sp_p * sp_q) * phase * kernel * decay_factor_var
                sum_var += term
        return 2.0 * np.abs(sum_var)

    # 1. Locate exact zeros
    buhler_zeros = [5.1015, 5.5613, 6.0244, 6.4910, 6.9613]
    w_vals = [-1j, -1j, -1j, 1j, 1j]
    
    exact_zeros = []
    derivatives = []
    F_vals = []
    
    print("\nLocating exact zeros and computing derivatives & coupling...")
    for idx, (t0, w) in enumerate(zip(buhler_zeros, w_vals)):
        res = opt.minimize_scalar(lambda t: abs(eval_L(t, w)), bounds=(t0-0.3, t0+0.3), method='bounded')
        tz = res.x
        exact_zeros.append(tz)
        
        # Derivative with respect to s (using numerical differentiation w.r.t t)
        eps = 1e-4
        L_plus = eval_L(tz + eps, w)
        L_minus = eval_L(tz - eps, w)
        dL_ds = -1j * ((L_plus - L_minus) / (2 * eps))
        D_k = abs(dL_ds)
        derivatives.append(D_k)
        
        # F_var coupling
        F_k = compute_F_var(tz)
        F_vals.append(F_k)
        
        print(f"Zero t_{idx+1}: exact t={tz:.6f} (Buhler {t0:.4f})")
        print(f"  |L'(1/2+it)| = {D_k:.6f}")
        print(f"  F_var(t)     = {F_k:.6f}")
        
    exact_zeros = np.array(exact_zeros)
    derivatives = np.array(derivatives)
    F_vals = np.array(F_vals)
    
    inv_derivatives = 1.0 / derivatives
    inv_derivatives_sq = 1.0 / (derivatives ** 2)
    
    # 2. Correlation analysis
    r_inv, p_inv = pearsonr(F_vals, inv_derivatives)
    r_inv_sq, p_inv_sq = pearsonr(F_vals, inv_derivatives_sq)
    
    print("\nCorrelation Results:")
    print(f"  Pearson correlation r(F_var, |L'|^-1)    = {r_inv:.6f} (p-value: {p_inv:.4f})")
    print(f"  Pearson correlation r(F_var, |L'|^-2)    = {r_inv_sq:.6f} (p-value: {p_inv_sq:.4f})")
    
    # Linear regression: inv_derivatives = slope * F_vals + intercept
    slope, intercept = np.polyfit(F_vals, inv_derivatives, 1)
    print(f"  Linear regression fit: |L'|^-1 = {slope:.4f} * F_var + {intercept:.4f}")
    
    # 3. Create correlation plot
    fig, ax = plt.subplots(figsize=(8, 6))
    fig.patch.set_facecolor('#0b0b14')
    
    c_card = '#141426'
    c_cyan = '#00f6ff'
    c_pink = '#ff2a85'
    c_orange = '#ff9f1c'
    c_white = '#f8f9fa'
    c_grid = '#2a2b44'
    
    ax.set_facecolor(c_card)
    ax.tick_params(colors=c_white)
    ax.xaxis.label.set_color(c_white)
    ax.yaxis.label.set_color(c_white)
    ax.title.set_color(c_white)
    for spine in ax.spines.values():
        spine.set_edgecolor(c_grid)
    ax.grid(True, color=c_grid, linestyle='--', alpha=0.5)
    
    # Scatter points
    ax.scatter(F_vals, inv_derivatives, color=c_pink, s=100, zorder=5, label='Artin Zeros')
    for idx, (f_v, inv_d) in enumerate(zip(F_vals, inv_derivatives)):
        ax.annotate(f" $t_{idx+1}={exact_zeros[idx]:.2f}$", (f_v, inv_d), color=c_white, fontsize=9, va='center')
        
    # Regression line
    x_fit = np.linspace(np.min(F_vals)*0.9, np.max(F_vals)*1.1, 100)
    y_fit = slope * x_fit + intercept
    ax.plot(x_fit, y_fit, color=c_cyan, linestyle='--', linewidth=1.5,
            label=f'Linear Fit (r = {r_inv:.4f})')
            
    ax.set_title("Correlation: Off-Diagonal Coupling vs. Inverse L-Derivative", fontsize=12, fontweight='bold', pad=15)
    ax.set_xlabel("Off-Diagonal Coupling Trace $F_{\\mathrm{var}}(t_k^*)$", fontsize=10)
    ax.set_ylabel("Inverse L-Derivative $|L'(\\frac{1}{2}+it_k^*)|^{-1}$", fontsize=10)
    ax.legend(facecolor=c_card, edgecolor=c_grid, labelcolor=c_white)
    
    # Add text box with correlation and p-value
    textstr = '\n'.join((
        f'Pearson $r = {r_inv:.4f}$',
        f'$p$-value $= {p_inv:.4f}$',
        f'Fit: $|L\'|^{-1} = {slope:.2f} F + {intercept:.2f}$'
    ))
    props = dict(boxstyle='round', facecolor=c_card, edgecolor=c_grid, alpha=0.8)
    ax.text(0.05, 0.95, textstr, transform=ax.transAxes, fontsize=10, color=c_white,
            verticalalignment='top', bbox=props)
            
    plt.tight_layout()
    os.makedirs(os.path.dirname(correlation_figure_path), exist_ok=True)
    plt.savefig(correlation_figure_path, dpi=300, facecolor=fig.get_facecolor())
    plt.close()
    print(f"[SUCCESS] Correlation plot saved to: {correlation_figure_path}")
    print("=" * 70)
    
if __name__ == "__main__":
    main()
