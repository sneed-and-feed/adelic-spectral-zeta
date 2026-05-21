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
    print("ADÈLIC SPECTRAL TRIPLE: EXPANDER CORRELATION SIMULATION")
    print("=" * 70)
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    
    traces_path = os.path.join(project_root, "data", "a5_hecke_traces.json")
    figure_path = os.path.join(project_root, "figures", "expander_decay_analysis.png")
    
    # Load traces
    if not os.path.exists(traces_path):
        raise FileNotFoundError(f"Traces database not found at {traces_path}. Please run lmfdb_trace_fetch.py first.")
        
    with open(traces_path, "r", encoding="utf-8") as f:
        traces_db = json.load(f)
        
    # Select Buhler's level 800 form, or fallback to the first available form
    target_label = "800.1.bh.a"
    if target_label not in traces_db:
        target_label = list(traces_db.keys())[0]
        
    print(f"Selected modular form for sweep: {target_label} (Level {traces_db[target_label]['level']})")
    
    a_p = traces_db[target_label]["traces"]
    
    # We will use primes up to 1000 for the simulation to get a dense sum
    P_MAX = 1000
    primes = get_primes(P_MAX)
    print(f"Number of primes up to {P_MAX}: {len(primes)}")
    
    # Filter primes that are present in the trace database
    active_primes = [p for p in primes if str(p) in a_p]
    print(f"Active primes with available traces: {len(active_primes)}")
    
    # ─── COMPUTE SPECTRAL COUPLING AND DECAY ────────────────────────────────
    # We will sweep frequency T from 1.0 to 100.0
    T_vals = np.linspace(1.0, 100.0, 200)
    
    # We set gamma proportional to the bottom of the local Ramanujan spectral gaps.
    # The spectral gap for a prime p is lambda_1 = p + 1 - 2*sqrt(p).
    # For p=2, the gap is 3 - 2*sqrt(2) approx 0.1716.
    # We set gamma = 0.2, representing the global decay rate.
    gamma = 0.20
    
    F_unreg = []
    F_reg = []
    
    print("\nSimulating off-diagonal resolvent trace...")
    # Cache log values to speed up computation
    log_p = {p: np.log(p) for p in active_primes}
    sqrt_p = {p: np.sqrt(p) for p in active_primes}
    a_p_val = {p: float(a_p[str(p)]) for p in active_primes}
    
    for T in T_vals:
        sum_unreg = 0.0 + 0.0j
        sum_reg = 0.0 + 0.0j
        
        # Double sum over distinct primes p != q
        for i, p in enumerate(active_primes):
            ap = a_p_val[p]
            lp = log_p[p]
            sp_p = sqrt_p[p]
            if ap == 0:
                continue
                
            for q in active_primes[i+1:]:
                aq = a_p_val[q]
                if aq == 0:
                    continue
                lq = log_p[q]
                sp_q = sqrt_p[q]
                
                # Standard Moiré phase coupling
                diff_log = lp - lq
                phase = np.exp(1j * T * diff_log)
                
                # Resolvent kernel factor
                kernel = 1.0 / np.sqrt(1.0 + (T * diff_log)**2)
                
                # Standard amplitude term
                amplitude = (ap * aq * lp * lq) / (sp_p * sp_q)
                
                # Unregularized contribution (no expander decay)
                term = amplitude * phase * kernel
                sum_unreg += term
                
                # Expander-regularized contribution: scaled by (p*q)^(-gamma)
                # representing the exponential decay in tree distance d(p,q) = log(p*q)
                decay_factor = (p * q) ** (-gamma)
                sum_reg += term * decay_factor
                
        # The sum is symmetric under p <-> q, so we multiply by 2 for the full off-diagonal part
        F_unreg.append(2.0 * np.abs(sum_unreg))
        F_reg.append(2.0 * np.abs(sum_reg))
        
    F_unreg = np.array(F_unreg)
    F_reg = np.array(F_reg)
    
    print("Simulation complete. Generating plot...")
    
    # ─── PLOT RESULTS WITH PREMIUM RICH AESTHETICS ──────────────────────────
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))
    fig.patch.set_facecolor('#0b0b14')
    
    # Palette definition
    c_dark = '#0b0b14'
    c_card = '#141426'
    c_pink = '#ff2a85'
    c_cyan = '#00f6ff'
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
    ax1.plot(T_vals, F_unreg, color=c_pink, linewidth=2, label="Unregularized (Standard Large Sieve)")
    ax1.plot(T_vals, F_reg, color=c_cyan, linewidth=2.5, label=f"Expander Regularized ($\\gamma = {gamma}$)")
    ax1.set_title("Off-Diagonal Resolvent Trace $|F_{off}(T)|$", fontsize=12, fontweight='bold', pad=15)
    ax1.set_xlabel("Frequency $T$", fontsize=10)
    ax1.set_ylabel("Trace Amplitude", fontsize=10)
    ax1.legend(facecolor=c_card, edgecolor=c_grid, labelcolor=c_white)
    
    # Plot 2: Log-Log plot showing decay rate asymptotic behavior
    ax2.loglog(T_vals, F_unreg, color=c_pink, linewidth=2, alpha=0.6, label="Unregularized")
    ax2.loglog(T_vals, F_reg, color=c_cyan, linewidth=2.5, label="Expander Regularized")
    
    # Add a reference line for 1/T decay
    ref_T = np.linspace(10.0, 100.0, 50)
    ref_decay = F_reg[int(len(F_reg)*0.4)] * (T_vals[int(len(T_vals)*0.4)] / ref_T)**1.0
    ax2.loglog(ref_T, ref_decay, color=c_purple, linestyle=':', linewidth=2, label="Asymptotic $O(T^{-1})$ Decay")
    
    ax2.set_title("Asymptotic Log-Log Resolvent Scaling", fontsize=12, fontweight='bold', pad=15)
    ax2.set_xlabel("Frequency $T$ (log scale)", fontsize=10)
    ax2.set_ylabel("Trace Amplitude (log scale)", fontsize=10)
    ax2.legend(facecolor=c_card, edgecolor=c_grid, labelcolor=c_white)
    
    plt.suptitle(f"Adèlic Spectral Triple: Expander Suppression of Off-Diagonal Coupling\n(Artin representation orbit trace database, Level {traces_db[target_label]['level']})", 
                 color=c_white, fontsize=14, fontweight='bold', y=0.98)
    
    plt.tight_layout(rect=[0, 0, 1, 0.93])
    
    os.makedirs(os.path.dirname(figure_path), exist_ok=True)
    plt.savefig(figure_path, dpi=300, facecolor=fig.get_facecolor())
    plt.close()
    
    print(f"[SUCCESS] Decay analysis plot saved to: {figure_path}")
    print("=" * 70)

if __name__ == "__main__":
    main()
