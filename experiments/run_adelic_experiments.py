"""
Adelic Spectral Zeta: run_adelic_experiments.py
"""

import os
import numpy as np
import matplotlib.pyplot as plt
from adelic_spectral_zeta.spectral_gap import (
    compute_restricted_spectral_gap,
    compute_gauge_twisted_gap,
)
from adelic_spectral_zeta.adelic_dirac import (
    sweep_eigenvalues,
)

# Ensure figures directory exists
os.makedirs("figures", exist_ok=True)

# Set premium plotting style
plt.style.use("tableau-colorblind10")
plt.rcParams.update({
    "font.size": 11,
    "axes.labelsize": 12,
    "axes.titlesize": 14,
    "xtick.labelsize": 10,
    "ytick.labelsize": 10,
    "figure.titlesize": 16,
    "grid.alpha": 0.3,
    "grid.linestyle": "--",
})

def run_spectral_flow_experiment():
    print("Running Spectral Flow Experiment...")
    N_inf = 8
    d = 3
    sigmas = np.linspace(-1.5, 1.5, 41)
    
    # Run sweeps for unramified and ramified cases
    unram_eigenvalues = sweep_eigenvalues(N_inf, d, sigmas, case="unramified")
    ram_eigenvalues = sweep_eigenvalues(N_inf, d, sigmas, case="ramified")
    
    # Process eigenvalues for plotting
    unram_real = np.array([np.real(unram_eigenvalues[s]) for s in sigmas])
    ram_real = np.array([np.real(ram_eigenvalues[s]) for s in sigmas])
    
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6), sharey=True)
    
    # Plot unramified
    for i in range(unram_real.shape[1]):
        ax1.plot(sigmas, unram_real[:, i], color="#2C3E50", alpha=0.6, linewidth=1.2)
    # Highlight the zero mode
    ax1.axhline(0, color="#E74C3C", linestyle="--", linewidth=1.5, label="Zero-Mode")
    ax1.set_title("Unramified Case ($a_2 \\neq 0$)")
    ax1.set_xlabel("$\\sigma$ (Archimedean Drift)")
    ax1.set_ylabel("Re($\\lambda$) of $D_{\\text{artin}}(\\sigma)$")
    ax1.grid(True)
    ax1.legend()
    
    # Plot ramified
    for i in range(ram_real.shape[1]):
        ax2.plot(sigmas, ram_real[:, i], color="#2980B9", alpha=0.6, linewidth=1.2)
    # Highlight the zero mode
    ax2.axhline(0, color="#E74C3C", linestyle="--", linewidth=1.5, label="Zero-Mode")
    ax2.set_title("Ramified Case ($a_2 = 0$, Topological Shielding)")
    ax2.set_xlabel("$\\sigma$ (Archimedean Drift)")
    ax2.grid(True)
    ax2.legend()
    
    plt.suptitle("Spectral Flow & Zero-Modes of $D_{\\text{artin}}(\\sigma)$", y=0.98)
    plt.tight_layout()
    plt.savefig("figures/spectral_flow.png", dpi=300)
    plt.close()
    print("Saved figures/spectral_flow.png")

def run_deformed_gap_experiment():
    print("Running Gauge-Deformed Spectral Gap Experiment...")
    d = 5  # Dimension 32
    thetas = np.linspace(0, 2 * np.pi, 51)
    
    gaps = []
    max_eigenvalues = []
    
    for theta in thetas:
        sorted_eigs, gap = compute_gauge_twisted_gap(d, theta)
        gaps.append(gap)
        max_eigenvalues.append(np.abs(sorted_eigs[0]))
        
    fig, ax = plt.subplots(figsize=(9, 5.5))
    ax.plot(thetas, gaps, color="#8E44AD", linewidth=2.5, label="Spectral Gap $\\Delta(\\theta) = 1 - |\\lambda_2|$")
    ax.plot(thetas, max_eigenvalues, color="#D35400", linewidth=2.0, linestyle=":", label="Dominant Eigenvalue $|\\lambda_1|$")
    
    ax.set_title("Gauge-Twisted Transfer Operator $B(\\theta)$")
    ax.set_xlabel("Gauge Angle $\\theta$ (radians)")
    ax.set_ylabel("Spectral Metrics")
    ax.set_xticks([0, np.pi/2, np.pi, 3*np.pi/2, 2*np.pi])
    ax.set_xticklabels(["0", "$\\pi/2$", "$\\pi$", "$3\\pi/2$", "$2\\pi$"])
    ax.grid(True)
    ax.legend(loc="best")
    
    plt.tight_layout()
    plt.savefig("figures/deformed_spectral_gap.png", dpi=300)
    plt.close()
    print("Saved figures/deformed_spectral_gap.png")

def run_diagonal_descent_experiment():
    print("Running Diagonal Descent Experiment...")
    d = 4
    k = 3
    M_vals = np.arange(2, 120, 4)
    
    gaps = []
    for M in M_vals:
        _, gap = compute_restricted_spectral_gap(d, k, int(M))
        gaps.append(gap)
        
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))
    
    # Plot spectral gap vs M
    ax1.plot(M_vals, gaps, color="#16A085", marker="o", markersize=4, linewidth=2, label="$\\Delta(M) = 1 - |\\lambda_2|$")
    ax1.set_title("Restricted Spectral Gap vs. Projection Dimension $M$")
    ax1.set_xlabel("Subset Size $M$ (Physical Integers)")
    ax1.set_ylabel("Spectral Gap $\\Delta(M)$")
    ax1.grid(True)
    ax1.legend()
    
    # Plot eigenvalue decay for specific M values
    select_M = [10, 50, 100]
    colors = ["#3498DB", "#E67E22", "#2C3E50"]
    for M, color in zip(select_M, colors):
        eigs, _ = compute_restricted_spectral_gap(d, k, M)
        mags = np.abs(eigs)
        ax2.plot(np.arange(1, M + 1), mags, color=color, linewidth=2, label=f"$M = {M}$")
        
    ax2.set_title("Eigenvalue Magnitude Spectrum Decay")
    ax2.set_xlabel("Eigenvalue Rank Index")
    ax2.set_ylabel("Magnitude $|\\lambda_i|$")
    ax2.set_yscale("log")
    ax2.grid(True)
    ax2.legend()
    
    plt.suptitle("Diagonal Descent & CRT Joint Operator Restriction", y=0.98)
    plt.tight_layout()
    plt.savefig("figures/diagonal_descent.png", dpi=300)
    plt.close()
    print("Saved figures/diagonal_descent.png")

if __name__ == "__main__":
    run_spectral_flow_experiment()
    run_deformed_gap_experiment()
    run_diagonal_descent_experiment()
    print("All experiments completed successfully.")
