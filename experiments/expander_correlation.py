import os
import json
import numpy as np
import sympy as sp
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

def get_primes(n):
    return list(sp.primerange(2, n + 1))

def main():
    print("=" * 70)
    print("ADÈLIC SPECTRAL TRIPLE: EXPANDER CORRELATION SIMULATION (REFINED)")
    print("=" * 70)
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    
    traces_path = os.path.join(project_root, "data", "a5_hecke_traces.json")
    decay_figure_path = os.path.join(project_root, "figures", "expander_decay_analysis.png")
    zero_figure_path = os.path.join(project_root, "figures", "zero_mode_coupling.png")
    
    # Load traces
    if not os.path.exists(traces_path):
        raise FileNotFoundError(f"Traces database not found at {traces_path}. Please run lmfdb_trace_fetch.py first.")
        
    with open(traces_path, "r", encoding="utf-8") as f:
        traces_db = json.load(f)
        
    # Select Buhler's level 800 form
    target_label = "800.1.bh.a"
    if target_label not in traces_db:
        target_label = list(traces_db.keys())[0]
        
    print(f"Selected modular form for sweep: {target_label} (Level {traces_db[target_label]['level']})")
    
    a_p = traces_db[target_label]["traces"]
    
    # Primes up to 1000 for dense sum
    P_MAX = 1000
    primes = get_primes(P_MAX)
    print(f"Number of primes up to {P_MAX}: {len(primes)}")
    
    # Filter active primes present in database
    active_primes = [p for p in primes if str(p) in a_p]
    print(f"Active primes with available traces: {len(active_primes)}")
    
    # Cache log and math values
    log_p = {p: np.log(p) for p in active_primes}
    sqrt_p = {p: np.sqrt(p) for p in active_primes}
    a_p_val = {p: float(a_p[str(p)]) for p in active_primes}
    
    # ─── CALCULATE DECAY PARAMETERS ─────────────────────────────────────────
    # Local normalized spectral gap: lambda_1_norm(p) = (p + 1 - 2*sqrt(p)) / (p + 1)
    lambda_1_norm = {p: (p + 1 - 2.0 * sqrt_p[p]) / (p + 1) for p in active_primes}
    
    # Base decay rate gamma_0: chosen such that gamma_2 = 0.20
    # gamma_2 = gamma_0 * lambda_1_norm(2) => gamma_0 = 0.20 / lambda_1_norm(2)
    gap_2 = lambda_1_norm[2]
    gamma_0 = 0.20 / gap_2
    print(f"Base decay parameter gamma_0: {gamma_0:.6f} (normalized to gamma_2 = 0.20)")
    
    # Per-prime exponent gamma_p = gamma_0 * lambda_1_norm(p)
    gamma_p = {p: gamma_0 * lambda_1_norm[p] for p in active_primes}
    print(f"Sample exponents: gamma_2 = {gamma_p[2]:.4f}, gamma_3 = {gamma_p[3]:.4f}, gamma_5 = {gamma_p[5]:.4f}, gamma_997 = {gamma_p[997]:.4f}")
    
    # ─── 1. GLOBAL SPECTRAL COUPLING & ASYMPTOTIC SWEEP ──────────────────────
    T_vals = np.linspace(1.0, 100.0, 200)
    
    F_unreg = []
    F_reg_const = []
    F_reg_var = []
    
    print("\nSimulating global asymptotic frequency sweep T in [1, 100]...")
    for T in T_vals:
        sum_unreg = 0.0 + 0.0j
        sum_const = 0.0 + 0.0j
        sum_var = 0.0 + 0.0j
        
        # Double sum over distinct primes p != q
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
                
                # Standard Moiré phase coupling
                diff_log = lp - lq
                phase = np.exp(1j * T * diff_log)
                
                # Resolvent kernel factor
                kernel = 1.0 / np.sqrt(1.0 + (T * diff_log)**2)
                
                # Amplitude term
                amplitude = (ap * aq * lp * lq) / (sp_p * sp_q)
                term = amplitude * phase * kernel
                
                # 1. Unregularized
                sum_unreg += term
                
                # 2. Constant Regularization
                sum_const += term * ((p * q) ** -0.20)
                
                # 3. Variable Gap Regularization: tree-distance decay with per-prime gaps
                # d(p,q) = log(p*q) -> decay factor is p^(-gamma_p) * q^(-gamma_q)
                decay_factor_var = (p ** -gp_p) * (q ** -gp_q)
                sum_var += term * decay_factor_var
                
        # Symmetric multiply by 2
        F_unreg.append(2.0 * np.abs(sum_unreg))
        F_reg_const.append(2.0 * np.abs(sum_const))
        F_reg_var.append(2.0 * np.abs(sum_var))
        
    F_unreg = np.array(F_unreg)
    F_reg_const = np.array(F_reg_const)
    F_reg_var = np.array(F_reg_var)
    
    # ─── 2. QUANTITATIVE POWER-LAW EXPONENT FITTING ──────────────────────────
    # Fit F(T) ~ T^-alpha for T >= 10.0 (log-log linear fit)
    fit_idx = T_vals >= 10.0
    log_T_fit = np.log(T_vals[fit_idx])
    
    # Slope of log-log line gives -alpha
    slope_unreg, _ = np.polyfit(log_T_fit, np.log(F_unreg[fit_idx]), 1)
    slope_const, _ = np.polyfit(log_T_fit, np.log(F_reg_const[fit_idx]), 1)
    slope_var, _ = np.polyfit(log_T_fit, np.log(F_reg_var[fit_idx]), 1)
    
    alpha_unreg = -slope_unreg
    alpha_const = -slope_const
    alpha_var = -slope_var
    
    print(f"\nFitted Asymptotic Decay Exponents (for T >= 10):")
    print(f"  Unregularized: alpha = {alpha_unreg:.4f}")
    print(f"  Constant Decay (gamma=0.20): alpha = {alpha_const:.4f}")
    print(f"  Variable Gap Decay (gamma_p): alpha = {alpha_var:.4f}")
    
    # ─── 3. ZERO-MODE RESOLUTION SWEEP ───────────────────────────────────────
    # Buhler's level 800 zeros: 5.1015, 5.5613, 6.0244, 6.4910, 6.9613
    buhler_zeros = [5.1015, 5.5613, 6.0244, 6.4910, 6.9613]
    
    T_zero_sweep = np.linspace(4.5, 7.5, 400)
    F_unreg_zero = []
    F_const_zero = []
    F_var_zero = []
    
    print(f"\nSimulating high-resolution zero-mode sweep T in [4.5, 7.5] near Buhler's zeros...")
    for T in T_zero_sweep:
        sum_unreg = 0.0 + 0.0j
        sum_const = 0.0 + 0.0j
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
                amplitude = (ap * aq * lp * lq) / (sp_p * sp_q)
                term = amplitude * phase * kernel
                
                sum_unreg += term
                sum_const += term * ((p * q) ** -0.20)
                sum_var += term * ((p ** -gp_p) * (q ** -gp_q))
                
        F_unreg_zero.append(2.0 * np.abs(sum_unreg))
        F_const_zero.append(2.0 * np.abs(sum_const))
        F_var_zero.append(2.0 * np.abs(sum_var))
        
    F_unreg_zero = np.array(F_unreg_zero)
    F_const_zero = np.array(F_const_zero)
    F_var_zero = np.array(F_var_zero)
    
    # ─── PLOT 1: ASYMPTOTIC DECAY ANALYSIS ──────────────────────────────────
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))
    fig.patch.set_facecolor('#0b0b14')
    
    c_card = '#141426'
    c_pink = '#ff2a85'
    c_cyan = '#00f6ff'
    c_orange = '#ff9f1c'
    c_purple = '#9b5de5'
    c_white = '#f8f9fa'
    c_grid = '#2a2b44'
    
    for ax in [ax1, ax2]:
        ax.set_facecolor(c_card)
        ax.tick_params(colors=c_white)
        ax.xaxis.label.set_color(c_white)
        ax.yaxis.label.set_color(c_white)
        ax.title.set_color(c_white)
        for spine in ax.spines.values():
            spine.set_edgecolor(c_grid)
        ax.grid(True, color=c_grid, linestyle='--', alpha=0.5)
        
    # Plot 1: Off-Diagonal Resolvent Sweep
    ax1.plot(T_vals, F_unreg, color=c_pink, linewidth=1.5, label="Unregularized")
    ax1.plot(T_vals, F_reg_const, color=c_cyan, linewidth=2, label=r"Constant Regularized ($\gamma = 0.20$)")
    ax1.plot(T_vals, F_reg_var, color=c_orange, linewidth=2, label=r"Variable Gap Regularized ($\gamma_p$)")
    ax1.set_title("Off-Diagonal Resolvent Trace $|F_{off}(T)|$", fontsize=12, fontweight='bold', pad=15)
    ax1.set_xlabel("Frequency $T$", fontsize=10)
    ax1.set_ylabel("Trace Amplitude", fontsize=10)
    ax1.legend(facecolor=c_card, edgecolor=c_grid, labelcolor=c_white)
    
    # Plot 2: Log-Log plot showing decay rate asymptotic behavior
    ax2.loglog(T_vals, F_unreg, color=c_pink, linewidth=1.5, alpha=0.5, label=fr"Unregularized ($\alpha = {alpha_unreg:.2f}$)")
    ax2.loglog(T_vals, F_reg_const, color=c_cyan, linewidth=2, label=fr"Constant ($\alpha = {alpha_const:.2f}$)")
    ax2.loglog(T_vals, F_reg_var, color=c_orange, linewidth=2.5, label=fr"Variable Gap ($\alpha = {alpha_var:.2f}$)")
    
    # Add a reference line for 1/T decay
    ref_T = np.linspace(10.0, 100.0, 50)
    ref_decay = F_reg_var[int(len(F_reg_var)*0.4)] * (T_vals[int(len(T_vals)*0.4)] / ref_T)**1.0
    ax2.loglog(ref_T, ref_decay, color=c_purple, linestyle=':', linewidth=2, label="Asymptotic $O(T^{-1})$ Decay")
    
    ax2.set_title("Asymptotic Log-Log Resolvent Scaling", fontsize=12, fontweight='bold', pad=15)
    ax2.set_xlabel("Frequency $T$ (log scale)", fontsize=10)
    ax2.set_ylabel("Trace Amplitude (log scale)", fontsize=10)
    ax2.legend(facecolor=c_card, edgecolor=c_grid, labelcolor=c_white)
    
    plt.suptitle(f"Adèlic Spectral Triple: Expander Suppression & Power-Law Decay\n(Artin representation orbit trace database, Level {traces_db[target_label]['level']})", 
                 color=c_white, fontsize=14, fontweight='bold', y=0.98)
    
    plt.tight_layout(rect=[0, 0, 1, 0.93])
    os.makedirs(os.path.dirname(decay_figure_path), exist_ok=True)
    plt.savefig(decay_figure_path, dpi=300, facecolor=fig.get_facecolor())
    plt.close()
    print(f"[SUCCESS] Decay analysis plot saved to: {decay_figure_path}")
    
    # ─── PLOT 2: ZERO-MODE SWEEP AND COUPLING BEHAVIOR ───────────────────────
    fig_z, ax_z = plt.subplots(figsize=(10, 6))
    fig_z.patch.set_facecolor('#0b0b14')
    ax_z.set_facecolor(c_card)
    ax_z.tick_params(colors=c_white)
    ax_z.xaxis.label.set_color(c_white)
    ax_z.yaxis.label.set_color(c_white)
    ax_z.title.set_color(c_white)
    for spine in ax_z.spines.values():
        spine.set_edgecolor(c_grid)
    ax_z.grid(True, color=c_grid, linestyle='--', alpha=0.5)
    
    # Plot curves
    ax_z.plot(T_zero_sweep, F_unreg_zero, color=c_pink, linewidth=1.5, label="Unregularized Coupling")
    ax_z.plot(T_zero_sweep, F_const_zero, color=c_cyan, linewidth=2, label=r"Constant Regularized ($\gamma = 0.20$)")
    ax_z.plot(T_zero_sweep, F_var_zero, color=c_orange, linewidth=2.5, label=r"Variable Gap Regularized ($\gamma_p$)")
    
    # Add vertical lines for Buhler's zeros
    for idx, zero in enumerate(buhler_zeros):
        ax_z.axvline(x=zero, color=c_purple, linestyle='--', linewidth=1.5, alpha=0.8,
                     label="Buhler Zeros ($L(s,\\rho) = 0$)" if idx == 0 else "")
        # Add labels to the vertical lines
        ax_z.text(zero - 0.05, ax_z.get_ylim()[1] * 0.92, f"$t_{idx+1}={zero}$", 
                  color=c_purple, rotation=90, fontsize=8, alpha=0.9, ha='right')
        
    ax_z.set_title("Off-Diagonal Resolvent Trace Near Artin L-Function Zeros", fontsize=12, fontweight='bold', pad=15)
    ax_z.set_xlabel("Frequency $T$", fontsize=10)
    ax_z.set_ylabel("Trace Amplitude", fontsize=10)
    ax_z.legend(facecolor=c_card, edgecolor=c_grid, labelcolor=c_white, loc='upper right')
    
    plt.tight_layout()
    plt.savefig(zero_figure_path, dpi=300, facecolor=fig_z.get_facecolor())
    plt.close()
    print(f"[SUCCESS] Zero-mode coupling plot saved to: {zero_figure_path}")
    print("=" * 70)

if __name__ == "__main__":
    main()
