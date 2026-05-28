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
    y_vals = 1.0 / derivatives
    
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
    
    # Let's compute C_mag for each zero
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
    
    # 1. Pointwise correlation analysis and direct slope from covariance
    # Cov(F_var, |L'|^-1) / Var(F_var)
    cov_matrix = np.cov(F_vals, y_vals)
    empirical_slope = cov_matrix[0, 1] / cov_matrix[0, 0]
    print(f"Empirical Slope: {empirical_slope:.4f}")
    
    # Let's test the pointwise analytic slope.
    # At each zero, the derivative of y = (C_mag * H) / |G_diag + G_off|
    # under Re(G_off) = beta_fit * F_var is:
    # dy/dF_var = - (C_mag * H) * beta_fit * Re( (G_diag + G_off) ) / |G_diag + G_off|^3
    # Wait, let's write out the exact derivative of |G_diag + G_off|:
    # Let G = G_diag + G_off. |G| = sqrt(G_real^2 + G_imag^2)
    # If G_off_real = beta * F_var, then d|G|/dF_var = beta * G_real / |G|
    # Therefore, d(|G|^-1)/dF_var = - (d|G|/dF_var) / |G|^2 = - beta * G_real / |G|^3
    # Thus, dy/dF_var = - (C_mag * H) * beta * G_real / |G|^3
    
    beta_fit, _ = np.polyfit(F_vals, np.real(G_off_vals), 1)
    
    pointwise_slopes = []
    for i in range(len(exact_zeros)):
        g_real = np.real(G_diag_vals[i] + G_off_vals[i])
        g_abs = np.abs(G_diag_vals[i] + G_off_vals[i])
        c_h = C_mag_vals[i] * H_vals[i]
        
        # Exact pointwise derivative
        slope_k = - c_h * beta_fit * g_real / (g_abs ** 3)
        pointwise_slopes.append(slope_k)
        print(f"t = {exact_zeros[i]:.4f}: g_real = {g_real:.4f}, g_abs = {g_abs:.4f}, slope_k = {slope_k:.4f}")
        
    mean_pointwise = np.mean(pointwise_slopes)
    print(f"Mean Pointwise Slope: {mean_pointwise:.4f}")
    print(f"Relative error: {abs(mean_pointwise - empirical_slope) / abs(empirical_slope) * 100:.2f}%")
    
    # Wait, can we compute the covariance Cov(F_var, y_vals) using the derivative?
    # By Taylor's theorem, Cov(x, y) \approx Cov(x, y_0 + dy/dx * (x - x_0)) = dy/dx * Var(x)
    # Therefore, the slope of the regression line is exactly Cov(x, y)/Var(x) \approx dy/dx !
    # But dy/dx varies with x (i.e., at each zero). What is the weighted average of the slope?
    # Let's check if the mean of dy/dx or a weighted mean is closer.
    # Actually, let's look at the projection of G_off!
    # DeepSeek suggested: "Instead of beta * F_var, use the full complex G_off and take its projection onto the real axis.
    # This may require fitting a complex scaling factor beta * e^{i delta}."
    # Let's test this!
    # We want to relate G_off to the complex F_var_complex.
    # Wait, F_var is defined as 2 * abs(sum_var) or 2 * sum_var (which is complex).
    
    def compute_F_var_complex(T):
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
        return 2.0 * sum_var
        
    F_complex = np.array([compute_F_var_complex(tz) for tz in exact_zeros])
    
    # Fit complex beta: G_off = beta_c * F_complex
    # Since G_off is complex, we fit a complex coefficient beta_c
    beta_c = np.sum(G_off_vals * np.conj(F_complex)) / np.sum(F_complex * np.conj(F_complex))
    print(f"\nComplex beta fit: {beta_c} (magnitude: {abs(beta_c):.4f}, phase: {np.angle(beta_c):.4f} rad)")
    
    # Let's see the error in G_off_vals reconstruction using beta_c * F_complex
    G_off_pred = beta_c * F_complex
    for i in range(len(exact_zeros)):
        print(f"t = {exact_zeros[i]:.4f}: Actual G_off = {G_off_vals[i]:.4f}, Pred G_off = {G_off_pred[i]:.4f}")
        
    # Now let's calculate the pointwise slope using complex beta_c:
    # G_off = beta_c * F_complex
    # F_complex = F_var * e^{i theta_F}
    # Re(G_off) = Re(beta_c * F_complex) = Re(beta_c * e^{i theta_F}) * F_var
    # So the effective beta_eff(t) is Re(beta_c * F_complex / |F_complex|) = Re(beta_c * F_complex / F_vals)
    # Let's compute beta_eff(t) at each zero:
    beta_eff = np.real(beta_c * F_complex / np.abs(F_complex))
    print(f"\nEffective beta_eff at each zero: {beta_eff}")
    
    pointwise_slopes_complex = []
    for i in range(len(exact_zeros)):
        g_real = np.real(G_diag_vals[i] + G_off_vals[i])
        g_abs = np.abs(G_diag_vals[i] + G_off_vals[i])
        c_h = C_mag_vals[i] * H_vals[i]
        
        slope_k = - c_h * beta_eff[i] * g_real / (g_abs ** 3)
        pointwise_slopes_complex.append(slope_k)
        print(f"t = {exact_zeros[i]:.4f}: slope_k = {slope_k:.4f}")
        
    mean_pointwise_complex = np.mean(pointwise_slopes_complex)
    print(f"Mean Pointwise Slope (with complex phase): {mean_pointwise_complex:.4f}")
    print(f"Relative error: {abs(mean_pointwise_complex - empirical_slope) / abs(empirical_slope) * 100:.2f}%")

if __name__ == "__main__":
    main()
