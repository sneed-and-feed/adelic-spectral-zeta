import os
import json
import numpy as np
import sympy as sp
import scipy.linalg as la
import mpmath

def main():
    print("=" * 70)
    print("EXACT RESOLVENT ANALYSIS: DIAGONAL & OFF-DIAGONAL SUMS")
    print("=" * 70)
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    
    traces_path = os.path.join(project_root, "data", "a5_hecke_traces.json")
    with open(traces_path, "r", encoding="utf-8") as f:
        traces_db = json.load(f)
    a_p_orbit = traces_db["800.1.bh.a"]["traces"]
    
    exact_zeros = np.array([5.128673, 5.646348, 6.115696, 6.685053, 7.101472])
    derivatives = np.array([26.786862, 9.087135, 2.567694, 0.922821, 0.791152])
    inv_derivatives = 1.0 / derivatives
    
    # Primes for calculation
    P_MAX = 100
    primes = list(sp.primerange(2, P_MAX))
    active_primes = [p for p in primes if str(p) in a_p_orbit]
    
    log_p = {p: np.log(p) for p in active_primes}
    sqrt_p = {p: np.sqrt(p) for p in active_primes}
    a_p_val = {p: float(a_p_orbit[str(p)]) for p in active_primes}
    
    # Mode grid
    L = 12
    n_vals = np.arange(-L//2, L//2) # [-6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5]
    
    # Let's compute G_diag and G_off using the exact modes sum
    print("\nComputing exact G_diag and G_off via mode summation...")
    
    G_diag_vals = []
    G_off_vals = []
    
    for tz in exact_zeros:
        log_lam = np.log(tz)
        lambda_n = n_vals * np.pi / log_lam
        
        # 1. G_diag
        S_diag = 0.0
        for p in active_primes:
            ap = a_p_val[p]
            if ap == 0: continue
            S_diag += (ap**2 * log_p[p]**2) / p
            
        denom_n = (lambda_n - 1j * tz) ** 2
        sum_diag_mode = np.sum(1.0 / denom_n)
        g_diag = S_diag * sum_diag_mode
        G_diag_vals.append(g_diag)
        
        # 2. G_off (exact double sum over p != q)
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
                
                # Sum over modes
                theta = np.pi * np.log(p/q) / log_lam
                mode_sum = np.sum(np.exp(-1j * n_vals * theta) / denom_n)
                
                term = (ap * aq * lp * lq) / (sp_p * sp_q) * mode_sum
                # Symmetric contribution (p,q and q,p)
                g_off += 2.0 * term
                
        G_off_vals.append(g_off)
        print(f"t = {tz:.6f}:")
        print(f"  G_diag = {g_diag:.6f}")
        print(f"  G_off  = {g_off:.6f}")
        
    G_diag_vals = np.array(G_diag_vals)
    G_off_vals = np.array(G_off_vals)
    
    # 3. Compute the Gamma-conductor factor H(t)
    # H(t) = N^(1/4) * (2*pi)^(-1/2) * |Gamma(1/2 + it)|
    H_vals = []
    for tz in exact_zeros:
        # compute absolute value of Gamma(1/2 + i*tz)
        gamma_val = float(abs(mpmath.gamma(mpmath.mpc(0.5, tz))))
        h_val = (800.0 ** 0.25) * (2.0 * np.pi) ** (-0.5) * gamma_val
        H_vals.append(h_val)
    H_vals = np.array(H_vals)
    print(f"\nH_vals (gamma-conductor factors): {H_vals}")
    
    # 4. Check the Fredholm determinant relation derivative:
    # Lambda'(1/2 + it) * C = G_diag + G_off
    # So C = (G_diag + G_off) / Lambda'(1/2 + it)
    # The derivative of the completed L-function has magnitude:
    # |Lambda'(1/2 + it)| = H(t) * |L'(1/2 + it)|
    # So we can calculate C_mag = |G_diag + G_off| / (H(t) * D_k)
    C_mag_vals = np.abs(G_diag_vals + G_off_vals) / (H_vals * derivatives)
    print(f"Computed C_mag values at each zero: {C_mag_vals}")
    print(f"Mean C_mag: {np.mean(C_mag_vals):.6f} (std: {np.std(C_mag_vals):.6f})")
    
    # 5. Let's compare Re(G_off) with the regularized F_var
    # For baseline gamma_2=0.20 and P_MAX=1000:
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
    print(f"\nCoupling F_var: {F_vals}")
    
    # Fit Re(G_off) = beta * F_var (Model 0: Baseline)
    beta_fit, _ = np.polyfit(F_vals, np.real(G_off_vals), 1)
    print(f"Fitted scaling beta (Re(G_off) = beta * F_var): {beta_fit:.4f}")
    
    # 6. Predict the slope c1 from first principles:
    # c1 = - <C_mag * H> * beta / <|G_diag + G_off|>^2
    mean_C_H = np.mean(C_mag_vals * H_vals)
    mean_G_total = np.mean(np.abs(G_diag_vals + G_off_vals))
    predicted_slope = - mean_C_H * beta_fit / (mean_G_total ** 2)
    
    print(f"\nMean <C_mag * H>: {mean_C_H:.6f}")
    print(f"Mean <|G_diag + G_off|>: {mean_G_total:.6f}")
    print(f"Baseline Predicted Slope (c1): {predicted_slope:.4f}")
    print(f"Actual Numerical Slope: -592.3204")
    
    err_base = abs(predicted_slope - (-592.3204)) / 592.3204 * 100
    print(f"Relative error: {err_base:.2f}%")
    
    # --- MODEL 1: Separated Real/Imag fits with intercept ---
    beta_real, alpha_real = np.polyfit(F_vals, np.real(G_off_vals), 1)
    beta_imag, alpha_imag = np.polyfit(F_vals, np.imag(G_off_vals), 1)
    
    G_off_pred_1 = (beta_real * F_vals + alpha_real) + 1j * (beta_imag * F_vals + alpha_imag)
    y_pred_1 = C_mag_vals * H_vals / np.abs(G_diag_vals + G_off_pred_1)
    slope_pred_1, _ = np.polyfit(F_vals, y_pred_1, 1)
    err_m1 = abs(slope_pred_1 - (-592.3204)) / 592.3204 * 100
    
    print(f"\nModel 1 (Real/Imag fit) Predicted Slope: {slope_pred_1:.4f}")
    print(f"Model 1 Relative error: {err_m1:.2f}%")
    
    # --- MODEL 2: t-dependent beta(t) fit ---
    ratio_real = np.real(G_off_vals) / F_vals
    ratio_imag = np.imag(G_off_vals) / F_vals
    
    w0_real, w1_real = np.polyfit(exact_zeros, ratio_real, 1)
    w0_imag, w1_imag = np.polyfit(exact_zeros, ratio_imag, 1)
    
    beta_real_t = w0_real * exact_zeros + w1_real
    beta_imag_t = w0_imag * exact_zeros + w1_imag
    
    G_off_pred_2 = (beta_real_t * F_vals) + 1j * (beta_imag_t * F_vals)
    y_pred_2 = C_mag_vals * H_vals / np.abs(G_diag_vals + G_off_pred_2)
    slope_pred_2, _ = np.polyfit(F_vals, y_pred_2, 1)
    err_m2 = abs(slope_pred_2 - (-592.3204)) / 592.3204 * 100
    
    print(f"\nModel 2 (t-dependent beta) Predicted Slope: {slope_pred_2:.4f}")
    print(f"Model 2 Relative error: {err_m2:.2f}%")
    
    # --- MODEL 3: Pointwise Quotient Limit ---
    G_off_pred_3 = G_off_vals
    y_pred_3 = C_mag_vals * H_vals / np.abs(G_diag_vals + G_off_pred_3)
    slope_pred_3, _ = np.polyfit(F_vals, y_pred_3, 1)
    err_m3 = abs(slope_pred_3 - (-592.3204)) / 592.3204 * 100
    
    print(f"\nModel 3 (Pointwise Quotient) Predicted Slope: {slope_pred_3:.4f}")
    print(f"Model 3 Relative error: {err_m3:.2f}%")

if __name__ == "__main__":
    main()
