"""
Adelic Spectral Zeta: run_spectral_gap_experiment.py
"""

import os
import sys
import numpy as np
import matplotlib.pyplot as plt

# Ensure src directory is in the import path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from src.spectral_gap import get_operators, padic_distance_matrix, simulate_decay, holder_norm

def run_experiment():
    print("=== Running 2-Adic Hölder Spectral Gap Experiment ===")
    
    d = 8
    N = 1 << d
    alpha = 0.5
    theta = 2.0 ** (-alpha)
    
    print(f"Tree Depth d={d} (N={N})")
    print(f"Hölder Exponent alpha={alpha} -> Essential Spectral Radius Boundary theta = {theta:.4f}")
    
    # 1. Get Operators
    _, B = get_operators(d)
    B_dense = B.toarray()
    
    # 2. Compute Eigenvalues
    eigenvalues = np.linalg.eigvals(B_dense)
    
    # 3. Simulate Hölder Norm Decay
    np.random.seed(42)
    # Generate a random state and subtract mean to ensure it's orthogonal to constants
    psi_0 = np.random.randn(N)
    psi_0 = psi_0 - np.mean(psi_0)
    
    dists = padic_distance_matrix(N)
    steps = 25
    norms, seminorms, sup_norms = simulate_decay(psi_0, B, steps, alpha, dists)
    
    # Compute initial norm for reference
    init_norm = holder_norm(psi_0, alpha, dists)
    all_norms = np.insert(norms, 0, init_norm)
    
    # --- Visualization ---
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(13, 6))
    
    # Plot 1: Eigenvalue Spectrum and Essential Radius
    circle_theta = np.linspace(0, 2*np.pi, 200)
    
    # Draw Unit Circle
    ax1.plot(np.cos(circle_theta), np.sin(circle_theta), color='gray', linestyle='--', alpha=0.5, label='Unit Circle (r=1.0)')
    # Draw Essential Spectral Radius Boundary
    ax1.plot(theta * np.cos(circle_theta), theta * np.sin(circle_theta), color='red', linestyle='-.', alpha=0.8, label=f'Essential Radius Boundary (r={theta:.3f})')
    
    # Separate eigenvalues inside and outside the essential boundary
    abs_eigs = np.abs(eigenvalues)
    outside = abs_eigs > theta + 1e-10
    inside = ~outside
    
    ax1.scatter(eigenvalues[inside].real, eigenvalues[inside].imag, color='royalblue', s=12, alpha=0.6, label='Eigenvalues (inside)')
    ax1.scatter(eigenvalues[outside].real, eigenvalues[outside].imag, color='crimson', s=25, marker='o', label='Eigenvalues (outside)')
    
    ax1.set_title(f"Spectrum of B_alg at d={d} (N={N})")
    ax1.set_xlabel("Re")
    ax1.set_ylabel("Im")
    ax1.axhline(0, color='black', linewidth=0.5)
    ax1.axvline(0, color='black', linewidth=0.5)
    ax1.grid(True, which='both', linestyle=':', alpha=0.5)
    ax1.legend(loc='upper right')
    ax1.axis('equal')
    
    # Plot 2: Exponential Decay of Hölder Norm (Semi-log plot)
    k_vals = np.arange(steps + 1)
    ax2.semilogy(k_vals, all_norms, 'o-', color='crimson', label=r'$||\psi_k||_\alpha$')
    
    # Fit a line to the log decay to find the empirical decay rate
    # Only fit on non-zero norms (norms > 1e-13) before the nilpotent cut-off
    valid_mask = all_norms > 1e-13
    k_fit = k_vals[valid_mask]
    norms_fit = all_norms[valid_mask]
    
    if len(k_fit) > 1:
        slope, intercept = np.polyfit(k_fit, np.log(norms_fit), 1)
        empirical_rate = np.exp(slope)
        # Plot the fit line
        ax2.plot(k_fit, np.exp(intercept + slope * k_fit), 'k--', alpha=0.7, label=f'Exponential Fit (r={empirical_rate:.3f})')
    else:
        empirical_rate = 0.0
    
    ax2.set_title(r"Decay of Hölder Norm $||\psi_k||_\alpha$ under iterations")
    ax2.set_xlabel("Steps (k)")
    ax2.set_ylabel("Norm (log scale)")
    ax2.grid(True, which='both', linestyle=':', alpha=0.5)
    ax2.legend()
    
    plt.tight_layout()
    
    # Save the figure
    figures_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'figures'))
    os.makedirs(figures_dir, exist_ok=True)
    plot_path = os.path.join(figures_dir, 'spectral_gap_plots.png')
    plt.savefig(plot_path, dpi=150)
    print(f"Successfully generated and saved plots to: {plot_path}")
    
    # Output findings
    print("\nFindings:")
    print(f"1. Maximum non-trivial eigenvalue magnitude: {np.sort(abs_eigs)[-2]:.6f}")
    print(f"2. Empirical decay rate of Hölder norm: {empirical_rate:.6f}")
    print(f"3. Theoretical upper bound of essential spectral radius: {theta:.6f}")
    print("Check if the empirical decay rate is less than 1.0 (indicating a spectral gap):", empirical_rate < 1.0)
    
if __name__ == "__main__":
    run_experiment()
