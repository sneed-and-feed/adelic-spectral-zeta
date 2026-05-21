import os
import json
import numpy as np
import sympy as sp
import mpmath

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    
    traces_path = os.path.join(project_root, "data", "a5_hecke_traces.json")
    with open(traces_path, "r", encoding="utf-8") as f:
        traces_db = json.load(f)
    a_p_orbit = traces_db["800.1.bh.a"]["traces"]
    
    exact_zeros = np.array([5.128673, 5.646348, 6.115696, 6.685053, 7.101472])
    derivatives = np.array([26.786862, 9.087135, 2.567694, 0.922821, 0.791152])
    
    P_MAX = 100
    primes = list(sp.primerange(2, P_MAX))
    active_primes = [p for p in primes if str(p) in a_p_orbit]
    
    log_p = {p: np.log(p) for p in active_primes}
    sqrt_p = {p: np.sqrt(p) for p in active_primes}
    a_p_val = {p: float(a_p_orbit[str(p)]) for p in active_primes}
    
    L = 12
    n_vals = np.arange(-L//2, L//2)
    
    G_diag_vals = []
    G_off_vals = []
    
    for tz in exact_zeros:
        log_lam = np.log(tz)
        lambda_n = n_vals * np.pi / log_lam
        denom_n = (lambda_n - 1j * tz) ** 2
        
        S_diag = 0.0
        for p in active_primes:
            ap = a_p_val[p]
            if ap == 0: continue
            S_diag += (ap**2 * log_p[p]**2) / p
            
        sum_diag_mode = np.sum(1.0 / denom_n)
        g_diag = S_diag * sum_diag_mode
        G_diag_vals.append(g_diag)
        
        g_off = 0.0 + 0.0j
        for i, p in enumerate(active_primes):
            ap = a_p_val[p]
            if ap == 0: continue
            lp = log_p[p]
            sp_p = sqrt_p[p]
            
            for q in active_primes[i+1:]:
                aq = a_p_val[q]
                if aq == 0: continue
                lq = log_p[q]
                sp_q = sqrt_p[q]
                
                theta = np.pi * np.log(p/q) / log_lam
                mode_sum = np.sum(np.exp(-1j * n_vals * theta) / denom_n)
                term = (ap * aq * lp * lq) / (sp_p * sp_q) * mode_sum
                g_off += 2.0 * term
        G_off_vals.append(g_off)
        
    G_diag_vals = np.array(G_diag_vals)
    G_off_vals = np.array(G_off_vals)
    
    H_vals = []
    for tz in exact_zeros:
        gamma_val = float(abs(mpmath.gamma(mpmath.mpc(0.5, tz))))
        h_val = (800.0 ** 0.25) * (2.0 * np.pi) ** (-0.5) * gamma_val
        H_vals.append(h_val)
    H_vals = np.array(H_vals)
    
    C_mag_vals = np.abs(G_diag_vals + G_off_vals) / (H_vals * derivatives)
    
    P_MAX_base = 1000
    primes_base = list(sp.primerange(2, P_MAX_base))
    active_primes_base = [p for p in primes_base if str(p) in a_p_orbit]
    log_p_base = {p: np.log(p) for p in active_primes_base}
    sqrt_p_base = {p: np.sqrt(p) for p in active_primes_base}
    a_p_val_base = {p: float(a_p_orbit[str(p)]) for p in active_primes_base}
    lambda_1_norm_base = {p: (p + 1 - 2.0 * sqrt_p_base[p]) / (p + 1) for p in active_primes_base}
    gap_2 = lambda_1_norm_base[2]
    gamma_0 = 0.20 / gap_2
    gamma_p = {p: gamma_0 * lambda_1_norm_base[p] for p in active_primes_base}
    
    def compute_F_var(T):
        sum_var = 0.0 + 0.0j
        for i, p in enumerate(active_primes_base):
            ap = a_p_val_base[p]
            if ap == 0: continue
            lp = log_p_base[p]
            sp_p = sqrt_p_base[p]
            gp_p = gamma_p[p]
            
            for q in active_primes_base[i+1:]:
                aq = a_p_val_base[q]
                if aq == 0: continue
                lq = log_p_base[q]
                sp_q = sqrt_p_base[q]
                gp_q = gamma_p[q]
                
                diff_log = lp - lq
                phase = np.exp(1j * T * diff_log)
                kernel = 1.0 / np.sqrt(1.0 + (T * diff_log)**2)
                decay_factor_var = (p ** -gp_p) * (q ** -gp_q)
                term = (ap * aq * lp * lq) / (sp_p * sp_q) * phase * kernel * decay_factor_var
                sum_var += term
        return 2.0 * np.abs(sum_var)
        
    F_vals = np.array([compute_F_var(tz) for tz in exact_zeros])
    beta_fit, _ = np.polyfit(F_vals, np.real(G_off_vals), 1)
    
    print("=" * 60)
    print("REFINED INDIVIDUAL SLOPE PREDICTIONS AT EACH ZERO")
    print("=" * 60)
    
    slopes = []
    for idx, tz in enumerate(exact_zeros):
        c_val = C_mag_vals[idx]
        h_val = H_vals[idx]
        denom = np.abs(G_diag_vals[idx] + G_off_vals[idx]) ** 2
        slope_k = - c_val * h_val * beta_fit / denom
        slopes.append(slope_k)
        print(f"Zero t_{idx+1} = {tz:.4f}:")
        print(f"  C_mag = {c_val:.4f}")
        print(f"  H     = {h_val:.6f}")
        print(f"  |G_diag + G_off|^2 = {denom:.4f}")
        print(f"  Slope = {slope_k:.4f}")
        
    slopes = np.array(slopes)
    print(f"\nMean Slope: {np.mean(slopes):.4f} (std: {np.std(slopes):.4f})")
    print(f"Actual Slope: -592.3204")
    print(f"Relative error of Mean: {abs(np.mean(slopes) - (-592.3204)) / 592.3204 * 100:.2f}%")

if __name__ == "__main__":
    main()
