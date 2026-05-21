import os
import json
import numpy as np
import sympy as sp
import mpmath

def test_config(denom_type, L):
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
    
    n_vals = np.arange(-L//2, L//2)
    
    G_diag_vals = []
    G_off_vals = []
    
    for tz in exact_zeros:
        log_lam = np.log(tz)
        lambda_n = n_vals * np.pi / log_lam
        
        if denom_type == "complex_no_half":
            denom_n = (lambda_n - 1j * tz) ** 2
        elif denom_type == "complex_with_half":
            denom_n = (lambda_n - 0.5 - 1j * tz) ** 2
        elif denom_type == "real":
            denom_n = (lambda_n - tz) ** 2
        else:
            raise ValueError(f"Unknown denom_type: {denom_type}")
            
        # G_diag
        S_diag = 0.0
        for p in active_primes:
            ap = a_p_val[p]
            if ap == 0: continue
            S_diag += (ap**2 * log_p[p]**2) / p
            
        sum_diag_mode = np.sum(1.0 / denom_n)
        g_diag = S_diag * sum_diag_mode
        G_diag_vals.append(g_diag)
        
        # G_off
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
    
    C_mean = np.mean(C_mag_vals)
    H_mean = np.mean(H_vals)
    G_diag_mean = np.mean(np.real(G_diag_vals))
    predicted_slope = - C_mean * H_mean * beta_fit / (G_diag_mean ** 2)
    rel_error = abs(predicted_slope - (-592.3204)) / 592.3204 * 100
    
    print(f"Denom: {denom_type:<20} | L: {L:<4}")
    print(f"  C_mag std/mean: {np.std(C_mag_vals)/np.mean(C_mag_vals):.4f}")
    print(f"  C_mag values  : {C_mag_vals}")
    print(f"  G_diag values : {np.real(G_diag_vals)}")
    print(f"  beta_fit      : {beta_fit:.4f}")
    print(f"  Pred Slope    : {predicted_slope:.4f} (Rel Err: {rel_error:.2f}%)")
    print("-" * 55)

if __name__ == "__main__":
    for denom in ["complex_no_half", "complex_with_half", "real"]:
        for L in [12, 100, 600]:
            test_config(denom, L)
