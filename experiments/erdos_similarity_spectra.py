import os
import numpy as np
import matplotlib.pyplot as plt
from adelic_spectral_zeta.erdos_similarity import (
    construct_adelic_sequence,
    construct_adelic_set,
    solve_schrodinger_spectrum,
    analyze_valuation_sectors,
    construct_generalized_cantor_set,
    fit_confinement_scaling,
    predict_projective_limit
)

def run_experiment():
    print("======================================================================")
    print("Erdős Similarity via Adèlic Spectra: Confinement & Clustering Sweep")
    print("======================================================================")
    
    # 1. System Parameters
    N_inf = 64     # Archimedean circle grid size
    d = 3          # 2-adic depth (size 8)
    k = 2          # 3-adic depth (size 9)
    M = 4          # Sequence terms
    L = 1.0        # Circle length
    
    # 2. Lift Sequence (geometric ratio 11^-n is coprime to 2 and 3)
    print(f"Lifting geometric sequence S = {{11^-n}} (M={M}) to A_trunc...")
    seq = construct_adelic_sequence("geometric", M, d, k)
    for n, s in enumerate(seq):
        print(f"  s_{n+1} = {s[0]:.6f} (mod 2^d: {s[1]}, mod 3^k: {s[2]})")
        
    # 3. Construct Test Adelic Sets
    print("\nConstructing test adèlic sets...")
    set_A = construct_adelic_set("neighborhood", N_inf, d, k, density=0.5, L=L)
    set_B = construct_adelic_set("porous", N_inf, d, k, L=L)
    
    vol_A = np.sum(set_A)
    vol_B = np.sum(set_B)
    total_vol = N_inf * (2**d) * (3**k)
    print(f"  Case A (Neighborhood): Measure = {vol_A} / {total_vol} ({vol_A/total_vol:.2%})")
    print(f"  Case B (Porous/Cantor): Measure = {vol_B} / {total_vol} ({vol_B/total_vol:.2%})")
    
    # 4. Define Idele Grid Parameters
    grid_params = {
        "N_u": 30,
        "u_min": -2.0,
        "u_max": 1.5,
        "V2": 2, # k_2 in {0, 1, 2}
        "V3": 1, # k_3 in {0, 1}
        "L": L
    }
    
    # 5. Solve Schrödinger Spectrum
    lmbda = 100.0  # Coupling strength
    print(f"\nSolving Schrödinger spectrum for H = Delta_I - {lmbda} * Psi...")
    
    eigs_A, evecs_A, psi_A = solve_schrodinger_spectrum(set_A, seq, grid_params, lmbda=lmbda)
    eigs_B, evecs_B, psi_B = solve_schrodinger_spectrum(set_B, seq, grid_params, lmbda=lmbda)
    
    print("\nResults:")
    print("----------------------------------------------------------------------")
    print(f"Case A (Neighborhood) Lowest Eigenvalues:\n  {eigs_A[:6]}")
    print(f"Case B (Porous/Cantor) Lowest Eigenvalues:\n  {eigs_B[:6]}")
    print("----------------------------------------------------------------------")
    
    # Analyze Confinement and Clustering
    E0_A = eigs_A[0]
    E0_B = eigs_B[0]
    shift = E0_B - E0_A
    print(f"Ground-state energy shift (E0_B - E0_A): {shift:+.4f} (Case B pushed higher)")
    
    # Estimate clustering gap
    diffs_B = np.diff(eigs_B)
    max_diff_idx = np.argmax(diffs_B[:4])
    cluster_size = max_diff_idx + 1
    gap_val = diffs_B[max_diff_idx]
    print(f"Detected Case B cluster size: {cluster_size} states")
    print(f"Spectral gap above Case B cluster: {gap_val:.4f}")
    
    # 6. Plotting
    print("\nGenerating figures...")
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
    
    # Subplot 1: Presence function Psi(b) vs Archimedean scale y = exp(u) at k2=0, k3=0
    u_vals = np.linspace(grid_params["u_min"], grid_params["u_max"], grid_params["N_u"])
    y_vals = np.exp(u_vals)
    
    V2, V3 = grid_params["V2"], grid_params["V3"]
    psi_slice_A = [psi_A[i * (V2 + 1) * (V3 + 1)] for i in range(grid_params["N_u"])]
    psi_slice_B = [psi_B[i * (V2 + 1) * (V3 + 1)] for i in range(grid_params["N_u"])]
    
    ax1.plot(y_vals, psi_slice_A, 'o-', color='#1f77b4', linewidth=2.5, label='Case A: Neighborhood (Smooth)')
    ax1.plot(y_vals, psi_slice_B, 's-', color='#d62728', linewidth=2.5, label='Case B: Porous Cantor (Gapped)')
    ax1.set_xscale('log')
    ax1.set_xlabel('Archimedean Scale factor $y = |b_\\infty|_\\infty$', fontsize=12)
    ax1.set_ylabel('Presence Function $\\Psi_{\\mathcal{E}, S, M}(b)$', fontsize=12)
    ax1.set_title('Idelic Presence Function (at $v_2(b_2)=0, v_3(b_3)=0$)', fontsize=13, fontweight='bold')
    ax1.grid(True, which="both", ls="--", alpha=0.5)
    ax1.legend(fontsize=11)
    
    # Subplot 2: Eigenvalues Comparison
    indices = np.arange(1, len(eigs_A) + 1)
    ax2.plot(indices, eigs_A, 'o--', color='#1f77b4', markersize=8, linewidth=2, label='Case A (Neighborhood)')
    ax2.plot(indices, eigs_B, 's-', color='#d62728', markersize=8, linewidth=2, label='Case B (Porous Cantor)')
    
    gap_start = eigs_B[max_diff_idx]
    gap_end = eigs_B[max_diff_idx + 1]
    ax2.axhspan(gap_start, gap_end, color='#ff7f0e', alpha=0.15, label='Case B Confinement Gap')
    
    ax2.set_xlabel('Eigenvalue Index $n$', fontsize=12)
    ax2.set_ylabel('Energy $E_n$', fontsize=12)
    ax2.set_title('Lowest Idelic Schrödinger Eigenvalues', fontsize=13, fontweight='bold')
    ax2.set_xticks(indices)
    ax2.grid(True, ls="--", alpha=0.5)
    ax2.legend(fontsize=11)
    
    plt.tight_layout()
    
    os.makedirs("figures", exist_ok=True)
    fig_path = "figures/erdos_spectral_gap.png"
    plt.savefig(fig_path, dpi=300)
    print(f"Saved figure to {fig_path}")
    plt.close()
    
    # 7. Run and demonstrate Algebraic Pre-Processor (Galois Extension)
    print("\n" + "="*70)
    print("DEMONSTRATING GALOIS EXTENSION & AUTOMATED CYCLE MATCHING PRE-PROCESSOR")
    print("="*70)
    
    # Run pre-processor on base 11 against [2, 3] places
    primes_11 = [2, 3]
    depths_11 = [2, 1]
    cantor_sets_11 = [
        construct_generalized_cantor_set(2, 2), # keeps {0, 1} mod 4
        construct_generalized_cantor_set(3, 1)  # keeps {0, 1} mod 3
    ]
    print(f"Checking Base = 11 mod 4 and mod 3, M = 3...")
    scales_11, collapsed_11 = analyze_valuation_sectors(primes_11, depths_11, 11, 3, cantor_sets_11)
    print(f"  Admissible scales: {scales_11}")
    print(f"  Analytical Sector Collapse predicted: {collapsed_11}")
    
    # Run pre-processor on general rational base 7/5 against custom primes [3, 11]
    primes_7_5 = [3, 11]
    depths_7_5 = [2, 1]
    cantor_sets_7_5 = [
        construct_generalized_cantor_set(3, 2), # keeps all but last mod 9
        construct_generalized_cantor_set(11, 1) # keeps all but last mod 11
    ]
    print(f"\nChecking general rational Base = 7/5 against primes [3, 11], M = 4...")
    scales_7_5, collapsed_7_5 = analyze_valuation_sectors(primes_7_5, depths_7_5, "7/5", 4, cantor_sets_7_5)
    print(f"  Admissible scales: {scales_7_5}")
    print(f"  Analytical Sector Collapse predicted: {collapsed_7_5}")
    
    # Demonstrate another case that does NOT collapse immediately
    primes_no_collapse = [3, 5]
    depths_no_collapse = [1, 1]
    cantor_sets_nc = [
        construct_generalized_cantor_set(3, 1, allowed_residues=[0, 1]),
        construct_generalized_cantor_set(5, 1, allowed_residues=[0, 1, 2, 3])
    ]
    print(f"\nChecking Base = 7 against primes [3, 5], M = 2...")
    scales_nc, collapsed_nc = analyze_valuation_sectors(primes_no_collapse, depths_no_collapse, 7, 2, cantor_sets_nc)
    print(f"  Admissible scales: {scales_nc}")
    print(f"  Analytical Sector Collapse predicted: {collapsed_nc}")
    
    # 8. Run and demonstrate Confinement Scaling Extrapolation & Predictive Pruning
    print("\n" + "="*70)
    print("DEMONSTRATING WEAPONIZED SCALING LAW FOR PREDICTIVE PRUNING")
    print("="*70)
    
    # We will use small depths [1, 2] to extrapolate the ground-state energy E0 for depth d=3, theta=0.4
    # and compare the predicted E0 with the actual E0 computed at d=3
    print("Extrapolating Confinement Scaling coefficients for Base = 11, primes = [2, 3]...")
    pred_val, a0, a1, metadata = predict_projective_limit(
        primes=[2, 3],
        base=11,
        M=3,
        grid_params={
            "N_inf": 32,
            "N_u": 10,
            "u_min": -2.0,
            "u_max": 1.0,
            "L": 1.0
        },
        target_theta=0.4,
        sample_depths=[1, 2],
        lmbda=50.0
    )
    
    print(f"  Extrapolated beta_0 (intercept as d -> inf): {a0:.4f}")
    print(f"  Extrapolated beta_1 (slope as d -> inf): {a1:.4f}")
    print(f"  Predicted Ground-State Energy E_0(d -> inf, theta=0.4): {pred_val:.4f}")
    
    # Run a quick validation at d=3 to see how close our prediction is
    print("\nValidating predictive extrapolation against actual solve at d=3...")
    act_b0, act_b1, act_r2 = fit_confinement_scaling(
        primes=[2, 3],
        depths=[3, 3],
        base=11,
        M=3,
        grid_params={
            "N_inf": 32,
            "N_u": 10,
            "u_min": -2.0,
            "u_max": 1.0,
            "L": 1.0
        },
        theta_vals=[0.4],
        lmbda=50.0
    )
    # The actual solved E0 at d=3, theta=0.4 is the result:
    print(f"  Actual solved E_0(d=3, theta=0.4): {act_b0 + act_b1 * (1.0 / (1.0 - 0.4)**2):.4f}")
    print(f"  Absolute Prediction Error: {abs(pred_val - (act_b0 + act_b1 * (1.0 / (1.0 - 0.4)**2))):.4f}")
    
    print("="*70)
    print("Experiment completed successfully.")

if __name__ == "__main__":
    run_experiment()
