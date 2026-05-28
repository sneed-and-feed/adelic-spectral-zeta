"""
Task 4.1: GUE Pair Correlation from Spectral Triple Eigenvalues
================================================================
Computes the pair correlation function R_2(α) of the compressed Dirac
eigenvalues and compares against the Montgomery-Odlyzko GUE prediction:
    R_2(α) = 1 - (sin(πα) / (πα))^2
"""

import numpy as np
import scipy.linalg as la
import mpmath
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from adelic_spectral_zeta.primes import SMALL_PRIMES

def main():
    
    print("=" * 70)
    print("TASK 4.1: GUE PAIR CORRELATION FROM SPECTRAL EIGENVALUES")
    print("=" * 70)
    
    # ─── Reconstruct the optimal zeta(s) spectral triple ─────────────────────
    N = 500
    lam = 29.0
    log_lam = np.log(lam)
    n_vals = np.arange(-N, N + 1)
    dim = 2 * N + 1
    
    primes = SMALL_PRIMES
    
    D0_diag = n_vals * np.pi / log_lam
    
    xi = np.zeros(dim, dtype=complex)
    for p in primes:
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)
    for i, n in enumerate(n_vals):
        t = n * np.pi / log_lam
        s_val = 0.25 + 0.5j * t
        psi_val = complex(mpmath.psi(0, s_val))
        xi[i] += 0.5 * (psi_val + np.log(np.pi))
    
    xi_norm = xi / np.linalg.norm(xi)
    I_mat = np.eye(dim)
    P = np.outer(xi_norm, np.conj(xi_norm))
    Proj = I_mat - P
    D = Proj @ np.diag(D0_diag) @ Proj
    
    eigenvalues = la.eigvalsh(D)
    pos_evs = np.sort(eigenvalues[eigenvalues > 1e-6])
    
    print(f"Operator: lambda={lam}, N={N}, p_max={primes[-1]}")
    print(f"Number of positive eigenvalues: {len(pos_evs)}")
    
    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 1: UNFOLD THE SPECTRUM
    # ═══════════════════════════════════════════════════════════════════════════
    # The Weyl law gives average density: ρ(E) = ln(λ) / π
    # Unfolded eigenvalues: x_n = n-th eigenvalue × (mean density)
    mean_density = log_lam / np.pi
    unfolded = pos_evs * mean_density
    print(f"\nMean spectral density: ln(λ)/π = {mean_density:.6f}")
    
    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 2: NEAREST-NEIGHBOR SPACING DISTRIBUTION
    # ═══════════════════════════════════════════════════════════════════════════
    spacings = np.diff(unfolded)
    mean_spacing = np.mean(spacings)
    normalized_spacings = spacings / mean_spacing
    
    print(f"Mean spacing (should be ~1): {mean_spacing:.6f}")
    print(f"Variance of normalized spacings: {np.var(normalized_spacings):.6f}")
    print(f"  (GUE Wigner surmise predicts variance ≈ 0.178)")
    
    # Wigner surmise for GUE: P(s) = (32/π²) s² exp(-4s²/π)
    s_theory = np.linspace(0, 4, 200)
    wigner_gue = (32.0 / np.pi**2) * s_theory**2 * np.exp(-4.0 * s_theory**2 / np.pi)
    
    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 3: PAIR CORRELATION FUNCTION R_2(α)
    # ═══════════════════════════════════════════════════════════════════════════
    print("\nComputing pair correlation R_2(α)...")
    
    # Use a window of eigenvalues in the bulk (avoid edge effects)
    bulk_start = len(pos_evs) // 5
    bulk_end = 4 * len(pos_evs) // 5
    bulk_evs = unfolded[bulk_start:bulk_end]
    n_bulk = len(bulk_evs)
    
    # Compute all pairwise differences
    alpha_max = 4.0
    n_bins = 100
    alpha_bins = np.linspace(0, alpha_max, n_bins + 1)
    alpha_centers = 0.5 * (alpha_bins[:-1] + alpha_bins[1:])
    hist = np.zeros(n_bins)
    
    for i in range(n_bulk):
        diffs = np.abs(bulk_evs[i+1:] - bulk_evs[i])
        diffs_in_range = diffs[diffs < alpha_max]
        counts, _ = np.histogram(diffs_in_range, bins=alpha_bins)
        hist += counts
    
    # Normalize: R_2(α) = (1/N) * histogram / bin_width
    bin_width = alpha_bins[1] - alpha_bins[0]
    R2_empirical = hist / (n_bulk * bin_width)
    
    # GUE prediction: R_2(α) = 1 - (sin(πα) / (πα))^2
    R2_gue = np.where(alpha_centers > 0,
                       1.0 - (np.sin(np.pi * alpha_centers) / (np.pi * alpha_centers))**2,
                       0.0)
    
    # Poisson prediction: R_2(α) = 1 (uncorrelated)
    R2_poisson = np.ones_like(alpha_centers)
    
    # Compute L2 distance to GUE and Poisson
    mask = alpha_centers > 0.1  # avoid α ≈ 0 singularity
    l2_gue = np.sqrt(np.mean((R2_empirical[mask] - R2_gue[mask])**2))
    l2_poisson = np.sqrt(np.mean((R2_empirical[mask] - R2_poisson[mask])**2))
    
    print(f"L² distance to GUE prediction:     {l2_gue:.6f}")
    print(f"L² distance to Poisson prediction:  {l2_poisson:.6f}")
    print(f"GUE/Poisson ratio:                  {l2_gue / l2_poisson:.4f}")
    if l2_gue < l2_poisson:
        print("► Spectrum is closer to GUE than Poisson — consistent with random matrix universality")
    
    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 4: NUMBER VARIANCE Σ²(L)
    # ═══════════════════════════════════════════════════════════════════════════
    print("\nComputing number variance Σ²(L)...")
    L_values = np.linspace(0.5, 10, 40)
    sigma2_empirical = []
    
    for L in L_values:
        counts = []
        for start_idx in range(0, n_bulk - 1):
            start_val = bulk_evs[start_idx]
            n_in_window = np.sum((bulk_evs >= start_val) & (bulk_evs < start_val + L))
            counts.append(n_in_window)
        counts = np.array(counts)
        sigma2_empirical.append(np.var(counts))
    
    sigma2_empirical = np.array(sigma2_empirical)
    
    # GUE prediction: Σ²(L) ≈ (2/π²)(ln(2πL) + γ + 1) for large L
    gamma_euler = 0.5772156649
    sigma2_gue = (2.0 / np.pi**2) * (np.log(2 * np.pi * L_values) + gamma_euler + 1.0)
    sigma2_gue = np.maximum(sigma2_gue, 0)
    
    # Poisson: Σ²(L) = L
    sigma2_poisson = L_values
    
    # ═══════════════════════════════════════════════════════════════════════════
    # PLOTTING
    # ═══════════════════════════════════════════════════════════════════════════
    fig, axes = plt.subplots(1, 3, figsize=(20, 6))
    fig.patch.set_facecolor('#0f0f1a')
    for ax in axes:
        ax.set_facecolor('#0f0f1a')
        ax.tick_params(colors='white')
        ax.xaxis.label.set_color('white')
        ax.yaxis.label.set_color('white')
        ax.title.set_color('white')
        for spine in ax.spines.values():
            spine.set_edgecolor('#444')
    
    # Panel 1: Nearest-neighbor spacing distribution
    axes[0].hist(normalized_spacings, bins=50, density=True, color='#4cc9f0', alpha=0.6, 
                 label='Empirical', edgecolor='#2a6f97')
    axes[0].plot(s_theory, wigner_gue, color='#f72585', linewidth=2.5, label='GUE Wigner surmise')
    axes[0].set_xlabel('Normalized spacing s')
    axes[0].set_ylabel('P(s)')
    axes[0].set_title('Nearest-Neighbor Spacing Distribution', color='white')
    axes[0].legend(facecolor='#1a1a2e', labelcolor='white')
    axes[0].grid(True, linestyle='--', alpha=0.3, color='#555')
    
    # Panel 2: Pair correlation R_2(α)
    axes[1].plot(alpha_centers, R2_empirical, 'o', color='#4cc9f0', markersize=4, alpha=0.7, label='Empirical R₂(α)')
    axes[1].plot(alpha_centers, R2_gue, color='#f72585', linewidth=2.5, label='GUE: 1 - (sin πα/πα)²')
    axes[1].axhline(1.0, color='#888', linestyle=':', linewidth=1, label='Poisson: R₂ = 1')
    axes[1].set_xlabel('α (pair separation)')
    axes[1].set_ylabel('R₂(α)')
    axes[1].set_title(f'Pair Correlation Function\n(L² to GUE: {l2_gue:.4f})', color='white')
    axes[1].legend(facecolor='#1a1a2e', labelcolor='white')
    axes[1].grid(True, linestyle='--', alpha=0.3, color='#555')
    axes[1].set_ylim(-0.1, 1.5)
    
    # Panel 3: Number variance
    axes[2].plot(L_values, sigma2_empirical, 'o-', color='#4cc9f0', linewidth=2, label='Empirical Σ²(L)')
    axes[2].plot(L_values, sigma2_gue, color='#f72585', linewidth=2.5, label='GUE prediction')
    axes[2].plot(L_values, sigma2_poisson, color='#888', linewidth=1.5, linestyle=':', label='Poisson: Σ² = L')
    axes[2].set_xlabel('Interval length L')
    axes[2].set_ylabel('Σ²(L)')
    axes[2].set_title('Number Variance (Spectral Rigidity)', color='white')
    axes[2].legend(facecolor='#1a1a2e', labelcolor='white')
    axes[2].grid(True, linestyle='--', alpha=0.3, color='#555')
    
    plt.tight_layout()
    import os
    script_dir = os.path.dirname(os.path.abspath(__file__))
    out = os.path.join(script_dir, "..", "figures", "gue_pair_correlation.png")
    plt.savefig(out, dpi=300, facecolor=fig.get_facecolor())
    plt.close()
    
    print(f"\nTriple-panel plot saved to: {out}")
    print("=" * 70)
    print("TASK 4.1 COMPLETE")
    print("=" * 70)

if __name__ == "__main__":
    main()