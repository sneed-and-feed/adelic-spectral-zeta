import os
import numpy as np
import matplotlib.pyplot as plt
from adelic_spectral_zeta.erdos_similarity import (
    construct_adelic_sequence,
    construct_adelic_set,
    solve_schrodinger_spectrum
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
    # Case B should have eigenvalues corresponding to localized wells grouped together,
    # then a gap to bulk states.
    # Let's count how many eigenvalues are in the lowest cluster for Case B
    diffs_B = np.diff(eigs_B)
    max_diff_idx = np.argmax(diffs_B[:4]) # Find the largest gap in the first few levels
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
    
    # We extract the 1D slice from psi where k2 = 0 and k3 = 0
    # Flat index = i * (V2 + 1) * (V3 + 1) + j * (V3 + 1) + k
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
    
    # Highlight the gap in Case B
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
    
    # Ensure directory exists and save
    os.makedirs("figures", exist_ok=True)
    fig_path = "figures/erdos_spectral_gap.png"
    plt.savefig(fig_path, dpi=300)
    print(f"Saved figure to {fig_path}")
    plt.close()
    
    print("Experiment completed successfully.")

if __name__ == "__main__":
    run_experiment()
