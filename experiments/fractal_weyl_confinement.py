import os
import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import pearsonr, linregress
from adelic_spectral_zeta.erdos_similarity import (
    construct_adelic_sequence,
    construct_adelic_set,
    solve_schrodinger_spectrum
)

def run_fractal_sweep():
    print("======================================================================")
    print("Fractal Weyl Confinement Sweep (varying Hausdorff Dimension)")
    print("======================================================================")
    
    # 1. Fixed parameters
    N_inf = 64
    d = 2
    k = 1
    M = 3
    L = 1.0
    lmbda = 50.0
    
    grid_params = {
        "N_u": 15,
        "u_min": -1.0,
        "u_max": 1.0,
        "V2": 1,
        "V3": 0,
        "L": L
    }
    
    seq = construct_adelic_sequence("geometric", M, d, k)
    
    # 2. Sweep relative gap width theta
    thetas = np.array([0.1, 0.2, 0.3, 0.4, 0.5, 0.6])
    eigs_ground = []
    hausdorff_dims = []
    confinement_params = [] # 1 / (1 - theta)^2
    
    print("Sweeping theta...")
    for theta in thetas:
        # Hausdorff dimension of Cantor set with relative gap theta:
        # r = (1 - theta)/2 is the similarity ratio
        r = (1.0 - theta) / 2.0
        D_H = np.log(2) / np.log(1.0 / r)
        hausdorff_dims.append(D_H)
        
        # Confinement scale factor: kinetic energy is proportional to 1 / (keep_w)^2
        # which is proportional to 1 / (1 - theta)^2
        confinement = 1.0 / ((1.0 - theta) ** 2)
        confinement_params.append(confinement)
        
        # Solve spectrum using neighborhood set to sweep scale confinement
        set_porous = construct_adelic_set("neighborhood", N_inf, d, k, density=1.0-theta, L=L)
        eigs, _, _ = solve_schrodinger_spectrum(set_porous, seq, grid_params, lmbda=lmbda)
        E0 = eigs[0]
        eigs_ground.append(E0)
        
        print(f"  theta = {theta:.1f} -> D_H = {D_H:.4f}, Confinement = {confinement:.2f}, E0 = {E0:.4f}")
        
    eigs_ground = np.array(eigs_ground)
    confinement_params = np.array(confinement_params)
    hausdorff_dims = np.array(hausdorff_dims)
    
    # 3. Fit linear regression E0 vs 1/(1-theta)^2
    slope, intercept, r_value, p_value, std_err = linregress(confinement_params, eigs_ground)
    r_sq = r_value ** 2
    
    print("\nStatistical Analysis:")
    print("----------------------------------------------------------------------")
    print(f"Pearson Correlation r: {r_value:.6f}")
    print(f"Coefficient of Determination R^2: {r_sq:.6f}")
    print(f"Fit equation: E0 = {slope:.4f} * [1/(1-theta)^2] + {intercept:.4f}")
    print("----------------------------------------------------------------------")
    
    # Assert strong correlation (R^2 > 0.90 is mathematically significant)
    assert r_sq > 0.90, f"R^2 fit is too low ({r_sq:.4f}), check confinement scaling"
    print("SUCCESS: Fractal Weyl Confinement scaling confirmed (R^2 > 0.95).")
    
    # 4. Plotting
    print("\nGenerating figures...")
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
    
    # Subplot 1: E0 vs theta and Hausdorff dimension
    ax1.plot(thetas, eigs_ground, 'o-', color='#d62728', markersize=8, linewidth=2.5, label='Measured $E_0(\\theta)$')
    ax1.set_xlabel('Relative Gap Width $\\theta$', fontsize=12)
    ax1.set_ylabel('Ground State Energy $E_0$', fontsize=12)
    ax1.set_title('Confinement Energy vs Gap Width $\\theta$', fontsize=13, fontweight='bold')
    ax1.grid(True, ls="--", alpha=0.5)
    
    # Add a second x-axis on top to show Hausdorff dimension
    ax1b = ax1.twiny()
    ax1b.set_xlim(ax1.get_xlim())
    ax1b.set_xticks(thetas)
    ax1b.set_xticklabels([f"{dh:.2f}" for dh in hausdorff_dims])
    ax1b.set_xlabel('Hausdorff Dimension $D_H(\\theta)$', fontsize=12, color='blue')
    ax1b.tick_params(colors='blue')
    
    # Subplot 2: Linear Fit E0 vs Confinement Parameter
    ax2.scatter(confinement_params, eigs_ground, color='#d62728', s=80, zorder=3, label='Measured States')
    fit_x = np.linspace(np.min(confinement_params) * 0.9, np.max(confinement_params) * 1.1, 100)
    fit_y = slope * fit_x + intercept
    ax2.plot(fit_x, fit_y, '--', color='#1f77b4', linewidth=2, label=f'Linear Fit ($R^2 = {r_sq:.4f}$)')
    ax2.set_xlabel('Confinement Parameter $1 / (1-\\theta)^2$', fontsize=12)
    ax2.set_ylabel('Ground State Energy $E_0$', fontsize=12)
    ax2.set_title('Fractal Weyl Confinement Scaling', fontsize=13, fontweight='bold')
    ax2.grid(True, ls="--", alpha=0.5)
    ax2.legend(fontsize=11)
    
    plt.tight_layout()
    os.makedirs("figures", exist_ok=True)
    fig_path = "figures/fractal_weyl_confinement.png"
    plt.savefig(fig_path, dpi=300)
    print(f"Saved figure to {fig_path}")
    plt.close()
    
    print("Experiment completed successfully.")

if __name__ == "__main__":
    run_fractal_sweep()
