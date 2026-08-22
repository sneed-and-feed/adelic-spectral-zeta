r"""
Vector 1: Non-Archimedean Monster VOA & Borcherds Automorphic Products
======================================================================
Author: Adelic Spectral Zeta Research Group
Date: August 2026
Artifact Output: figures/monster_voa_borcherds.png
Lean 4 Module: formalization/Formalization/MonsterVOA.lean (0 sorrys)
Monograph Output: docs/monster_voa_and_borcherds_products.md

Comprehensive numerical verification and visualization script for:
1. Graded Monster Vertex Operator Algebra V^♮ = ⨁_{n=0}^∞ V_n:
   - Central charge c = 24.
   - Graded dimensions: dim V_0 = 1, dim V_1 = 0, dim V_2 = 196,884 (Griess algebra).
   - McKay-Thompson decompositions into Monster irreducible representations.
   - Comparison with asymptotic Cardy formula: dim V_n ~ (1/√2) n^{-3/4} exp(4π √n).
2. Borcherds Automorphic Product Φ(p, q) on B(E_8)/PGL_2(ℤ):
   - Product expansion: Φ(p, q) = p⁻¹ ∏_{m>0, n} (1 - p^m q^n)^{c(mn)} = j(p) - j(q).
   - Faber polynomial Hecke log-expansion proof verified to order p^5.
3. Borcherds Fake Monster Lie Superalgebra 𝔪 on II_{1,1}:
   - Hyperbolic root lattice II_{1,1} with metric α² = -2 m n.
   - Root space multiplicities mult(m, n) = c(mn) = dim V_{1 + mn}.
   - Real roots α² = 2 (mult 1), lightlike roots α² = 0 (mult 0), imaginary roots α² < 0 (mult c(mn)).
4. Hecke Operator Logarithmic Product Decomposition:
   - log Φ(p, q) = -log p - ∑_{k=1}^∞ (1/k) p^k T_k(j(q) - 744).
5. Monster Character Trace:
   - Tr_{V^♮}(q^{L_0 - 1}) = q⁻¹ ∑_{n=0}^∞ (dim V_n) q^n = j(q) - 744.
6. Publication-grade 6-panel figure saved to figures/monster_voa_borcherds.png.
"""

import os
import sys
import time
import math
import numpy as np
import sympy as sp
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

# =============================================================================
# 1. MCKAY-THOMPSON MOONSHINE COEFFICIENTS & MONSTER IRREPS
# =============================================================================

# Fourier coefficients c(n) of J(τ) = j(τ) - 744 = q⁻¹ + ∑ c(n) q^n
MOONSHINE_COEFFS = {
    -1: 1,
    0: 0,
    1: 196884,
    2: 21493760,
    3: 864299970,
    4: 20245856256,
    5: 333202640600,
    6: 4252023300096,
    7: 44656994071935,
    8: 401490886656000,
}

# Graded VOA state counts dim V_n = c(n - 1)
VOA_DIMS = {
    0: 1,              # Vacuum |0⟩ (dim 1)
    1: 0,              # No weight-1 currents (dim 0)
    2: 196884,         # Griess algebra (dim 196,884)
    3: 21493760,
    4: 864299970,
    5: 20245856256,
    6: 333202640600,
    7: 4252023300096,
    8: 44656994071935,
    9: 401490886656000,
}

# Irreducible representation dimensions of the Monster Group M (from ATLAS)
MONSTER_IRREP_DIMS = [
    1,             # χ_1
    196883,        # χ_2 (Griess algebra minimal irrep)
    21296876,      # χ_3
    842609326,     # χ_4
    18538750076,   # χ_5
    19363245657,   # χ_6
    293553734298,  # χ_7
    312803657750,  # χ_8
]

# Decompositions of V_n in terms of Monster irreducible representations
MONSTER_DECOMPOSITIONS = {
    0: [1, 0, 0, 0, 0, 0, 0, 0],                         # 1 = 1
    1: [0, 0, 0, 0, 0, 0, 0, 0],                         # 0 = 0
    2: [1, 1, 0, 0, 0, 0, 0, 0],                         # 196884 = 1 + 196883
    3: [1, 1, 1, 0, 0, 0, 0, 0],                         # 21493760 = 1 + 196883 + 21296876
    4: [2, 2, 1, 1, 0, 0, 0, 0],                         # 864299970 = 2(1) + 2(196883) + 21296876 + 842609326
    5: [3, 3, 1, 2, 1, 0, 0, 0],                         # 20245856256 = 3(1) + 3(196883) + 21296876 + 2(842609326) + 18538750076
    6: [5, 5, 2, 3, 2, 0, 1, 0],                         # 333202640600 = 5(1) + 5(196883) + 2(...) + 3(...) + 2(...) + 293553734298
}

def verify_monster_decompositions():
    """Verifies that the Monster representation decompositions reproduce the exact VOA dimensions."""
    print("--- Verifying Monster Group Representation Decompositions ---")
    for n, mults in MONSTER_DECOMPOSITIONS.items():
        total_dim = sum(m * d for m, d in zip(mults, MONSTER_IRREP_DIMS))
        expected_dim = VOA_DIMS[n]
        assert total_dim == expected_dim, f"Mismatch at degree {n}: {total_dim} != {expected_dim}"
        irrep_str = " + ".join(f"{m}·χ_{i+1}({d})" for i, (m, d) in enumerate(zip(mults, MONSTER_IRREP_DIMS)) if m > 0)
        if not irrep_str:
            irrep_str = "0"
        print(f"  V_{n}: dim = {total_dim:>14} = {irrep_str}")
    print("  [SUCCESS] All Monster representation decompositions verified 100%!\n")

def cardy_asymptotic_dimension(n):
    """
    Cardy / Hardy-Ramanujan asymptotic formula for c = 24 Monster VOA:
    dim V_n ~ (1 / √2) * n^(-3/4) * exp(4π √n).
    """
    if n <= 0:
        return 1.0
    return (1.0 / np.sqrt(2.0)) * (n ** (-0.75)) * np.exp(4.0 * np.pi * np.sqrt(n))

# =============================================================================
# 2. BORCHERDS AUTOMORPHIC PRODUCT FABER POLYNOMIAL EXPANSION
# =============================================================================

def verify_borcherds_faber_expansion(max_order=5):
    """
    Verifies Borcherds' exact theorem:
    Φ(p, q) = p⁻¹ exp( - ∑_{m=1}^∞ (1/m) p^m P_m(J(q)) ) = j(p) - j(q)
    where P_m(J) are the Faber polynomials of J(q) = j(q) - 744:
    P_1(J) = J
    P_2(J) = J² - 2 c(1)
    P_3(J) = J³ - 3 c(1) J - 3 c(2)
    P_4(J) = J⁴ - 4 c(1) J² - 4 c(2) J + 2 c(1)² - 4 c(3)
    P_5(J) = J⁵ - 5 c(1) J³ - 5 c(2) J² + 5 (c(1)² - c(3)) J + 5 c(1) c(2) - 5 c(4).
    """
    print(f"--- Verifying Borcherds Product Exponentiation to Order p^{max_order} ---")
    J = sp.symbols('J')
    c = MOONSHINE_COEFFS
    
    # Construct Faber polynomials P_m(J)
    P = {}
    P[1] = J
    P[2] = J**2 - 2*c[1]
    P[3] = J**3 - 3*c[1]*J - 3*c[2]
    P[4] = J**4 - 4*c[1]*J**2 - 4*c[2]*J + 2*c[1]**2 - 4*c[3]
    P[5] = J**5 - 5*c[1]*J**3 - 5*c[2]*J**2 + 5*(c[1]**2 - c[3])*J + 5*c[1]*c[2] - 5*c[4]
    
    # Exponentiate the series S = ∑_{m=1}^max_order -(1/m) p^m P_m(J)
    # Using log-derivative recurrence: E_0 = 1, E_k = (1/k) ∑_{i=1}^k i L_i E_{k-i} where L_i = -P_i / i
    E = {0: sp.Integer(1)}
    for k in range(1, max_order + 1):
        term = sp.Integer(0)
        for i in range(1, k + 1):
            term += -P[i] * E[k - i]
        E[k] = sp.simplify(sp.Rational(1, k) * term)
    
    # Multiply by p⁻¹: coefficient of p^{k-1} is E_k
    print("  Expanded coefficients of Φ(p, q) in powers of p:")
    # p⁻¹ term (k = 0):
    print(f"    p^{ -1 }: coeff = {int(E[0]):>14} | expected = {1:>14} [MATCH]")
    assert E[0] == 1
    
    # p⁰ term (k = 1):
    print(f"    p^{  0 }: coeff = {str(E[1]):>14} | expected = {'-J(q)':>14} [MATCH]")
    assert sp.simplify(E[1] - (-J)) == 0
    
    # Higher p^k terms (k >= 1):
    for k in range(1, max_order):
        c_k = c[k]
        coeff_val = sp.simplify(E[k + 1])
        print(f"    p^{  k }: coeff = {int(coeff_val):>14} | expected = {c_k:>14} [MATCH]")
        assert coeff_val == c_k, f"Mismatch at p^{k}: {coeff_val} != {c_k}"
    
    print(f"  [SUCCESS] Borcherds product expansion Φ(p, q) = j(p) - j(q) verified algebraically to order p^{max_order}!\n")

# =============================================================================
# 3. PUBLICATION-GRADE 6-PANEL FIGURE GENERATION
# =============================================================================

def generate_publication_figure(output_path="figures/monster_voa_borcherds.png"):
    """
    Generates the comprehensive 6-panel publication figure visualizing:
    - Panel A: Graded Monster VOA Dimension Spectrum & Cardy Growth.
    - Panel B: Borcherds Automorphic Product 2D Contour on B(E_8)/PGL_2(ℤ).
    - Panel C: Borcherds Fake Monster Lie Superalgebra Root Multiplicities on II_{1,1}.
    - Panel D: McKay-Thompson Monster Irrep Decomposition Multiplicities.
    - Panel E: Hecke Logarithmic Decomposition & Product Convergence.
    - Panel F: Graded Monster Character Trace vs Modular j(τ) - 744.
    """
    print(f"--- Generating 6-Panel Figure: {output_path} ---")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Modern publication style
    plt.style.use('seaborn-v0_8-whitegrid' if 'seaborn-v0_8-whitegrid' in plt.style.available else 'default')
    fig = plt.figure(figsize=(20, 13), dpi=300)
    gs = gridspec.GridSpec(2, 3, figure=fig, hspace=0.32, wspace=0.28)
    
    # Palette
    c_blue = '#1f77b4'
    c_red = '#d62728'
    c_green = '#2ca02c'
    c_purple = '#9467bd'
    c_orange = '#ff7f0e'
    c_teal = '#17becf'
    
    # -------------------------------------------------------------------------
    # PANEL A: Graded Monster VOA Dimension Spectrum & Cardy Asymptotics
    # -------------------------------------------------------------------------
    ax1 = fig.add_subplot(gs[0, 0])
    ns = np.array(list(range(2, 10)))
    dims_exact = np.array([VOA_DIMS[n] for n in ns], dtype=float)
    dims_cardy = np.array([cardy_asymptotic_dimension(n - 1) for n in ns])
    
    ax1.semilogy(ns, dims_exact, 'o-', color=c_blue, lw=2.5, markersize=8, label=r'Exact $\dim V_n = c(n-1)$')
    ax1.semilogy(ns, dims_cardy, '--', color=c_red, lw=2.0, label=r'Cardy $\frac{1}{\sqrt{2}} n^{-3/4} e^{4\pi\sqrt{n}}$')
    
    # Highlight Griess algebra and vacuum
    ax1.annotate(r'$V_2$ (Griess): $196,884$', xy=(2, VOA_DIMS[2]), xytext=(2.2, 5e5),
                 arrowprops=dict(facecolor=c_blue, arrowstyle='->', lw=1.5),
                 fontsize=10, fontweight='bold', color=c_blue)
    ax1.annotate(r'$V_3$: $21,493,760$', xy=(3, VOA_DIMS[3]), xytext=(3.2, 6e7),
                 arrowprops=dict(facecolor=c_blue, arrowstyle='->', lw=1.5),
                 fontsize=10, fontweight='bold', color=c_blue)
    ax1.annotate(r'$V_5$: $2.02\times 10^{10}$', xy=(5, VOA_DIMS[5]), xytext=(4.5, 3e11),
                 arrowprops=dict(facecolor=c_blue, arrowstyle='->', lw=1.5),
                 fontsize=10, fontweight='bold', color=c_blue)
    
    ax1.set_title(r'(A) Graded Monster VOA Dimensions $\dim V_n$', fontsize=13, fontweight='bold', pad=10)
    ax1.set_xlabel(r'Conformal Weight / Degree $n$', fontsize=11)
    ax1.set_ylabel(r'State Count $\dim V_n$ (Log Scale)', fontsize=11)
    ax1.legend(loc='lower right', frameon=True, fontsize=10)
    ax1.grid(True, which='both', linestyle=':', alpha=0.6)
    
    # -------------------------------------------------------------------------
    # PANEL B: Borcherds Automorphic Product 2D Contour: Φ(p, q) = j(p) - j(q)
    # -------------------------------------------------------------------------
    ax2 = fig.add_subplot(gs[0, 1])
    p_vals = np.linspace(0.02, 0.35, 150)
    q_vals = np.linspace(0.02, 0.35, 150)
    P, Q = np.meshgrid(p_vals, q_vals)
    
    # J(p) - J(q) function
    def J_approx(z):
        return 1.0/z + 196884.0*z + 21493760.0*(z**2) + 864299970.0*(z**3)
    
    Z_diff = J_approx(P) - J_approx(Q)
    norm_val = np.sign(Z_diff) * np.log10(1.0 + np.abs(Z_diff))
    
    cp = ax2.contourf(P, Q, norm_val, levels=40, cmap='RdBu_r', alpha=0.9)
    ax2.plot(p_vals, p_vals, 'k--', lw=2.0, label=r'Zero Locus $p = q$ ($\Phi = 0$)')
    
    cbar2 = fig.colorbar(cp, ax=ax2, pad=0.03)
    cbar2.set_label(r'$\mathrm{sgn}(\Phi) \log_{10}(1 + |\Phi(p, q)|)$', fontsize=10)
    
    ax2.set_title(r'(B) Borcherds Product $\Phi(p, q) = j(p) - j(q)$', fontsize=13, fontweight='bold', pad=10)
    ax2.set_xlabel(r'Modular Parameter $p = e^{2\pi i \sigma}$', fontsize=11)
    ax2.set_ylabel(r'Modular Parameter $q = e^{2\pi i \tau}$', fontsize=11)
    ax2.legend(loc='upper left', frameon=True, fontsize=10)
    ax2.grid(True, linestyle=':', alpha=0.5)
    
    # -------------------------------------------------------------------------
    # PANEL C: Borcherds Root Lattice II_{1,1} Multiplicities
    # -------------------------------------------------------------------------
    ax3 = fig.add_subplot(gs[0, 2])
    m_grid = np.arange(1, 6)
    n_grid = np.arange(-2, 6)
    
    M_mesh, N_mesh = np.meshgrid(m_grid, n_grid)
    mult_matrix = np.zeros_like(M_mesh, dtype=float)
    
    for i in range(len(n_grid)):
        for j in range(len(m_grid)):
            m_val = m_grid[j]
            n_val = n_grid[i]
            mn = m_val * n_val
            c_val = MOONSHINE_COEFFS.get(mn, 0)
            mult_matrix[i, j] = np.log10(max(c_val, 1)) if c_val > 0 else 0
    
    im3 = ax3.imshow(mult_matrix, origin='lower', extent=[0.5, 5.5, -2.5, 5.5],
                     cmap='viridis', aspect='auto')
    cbar3 = fig.colorbar(im3, ax=ax3, pad=0.03)
    cbar3.set_label(r'$\log_{10}(\mathrm{mult}(\alpha)) = \log_{10} c(mn)$', fontsize=10)
    
    # Annotate real root and lightlike roots
    ax3.scatter([1], [-1], color='red', s=120, zorder=5, label=r'Real Root $(1, -1)$ ($\alpha^2=2$, mult $1$)')
    ax3.scatter(m_grid, np.zeros_like(m_grid), color='white', edgecolor='black', s=80, zorder=5,
                label=r'Lightlike Roots $(m, 0)$ (mult $0$)')
    
    # Hyperbola for imaginary roots of fixed mass
    x_hyp = np.linspace(0.8, 5.2, 100)
    ax3.plot(x_hyp, 1.0/x_hyp, 'r--', lw=1.5, label=r'Mass Shell $mn = 1$ ($\dim 196,884$)')
    ax3.plot(x_hyp, 2.0/x_hyp, 'm:', lw=1.5, label=r'Mass Shell $mn = 2$ ($\dim 21,493,760$)')
    
    ax3.set_title(r'(C) Borcherds Lie Algebra $\mathfrak{m}$ Root Spaces on $\mathrm{II}_{1,1}$', fontsize=13, fontweight='bold', pad=10)
    ax3.set_xlabel(r'Root Coordinate $m$', fontsize=11)
    ax3.set_ylabel(r'Root Coordinate $n$', fontsize=11)
    ax3.legend(loc='upper right', frameon=True, fontsize=8)
    ax3.grid(True, linestyle=':', alpha=0.4)
    
    # -------------------------------------------------------------------------
    # PANEL D: McKay-Thompson Monster Irreducible Representation Multiplicities
    # -------------------------------------------------------------------------
    ax4 = fig.add_subplot(gs[1, 0])
    degrees = [2, 3, 4, 5, 6]
    bar_width = 0.12
    x_indices = np.arange(len(degrees))
    
    colors_irrep = [c_blue, c_green, c_orange, c_purple, c_red, c_teal, '#8c564b', '#e377c2']
    labels_irrep = [r'$\mathbf{1}$', r'$\mathbf{196,883}$', r'$\mathbf{21,296,876}$',
                    r'$\mathbf{842,609,326}$', r'$\mathbf{1.85\times 10^{10}}$',
                    r'$\mathbf{1.93\times 10^{10}}$', r'$\mathbf{2.93\times 10^{11}}$', r'$\mathbf{3.12\times 10^{11}}$']
    
    for irrep_idx in range(6):
        mults = [MONSTER_DECOMPOSITIONS[d][irrep_idx] for d in degrees]
        offset = (irrep_idx - 2.5) * bar_width
        ax4.bar(x_indices + offset, mults, width=bar_width, color=colors_irrep[irrep_idx],
                label=labels_irrep[irrep_idx], alpha=0.85, edgecolor='black', lw=0.6)
    
    ax4.set_title(r'(D) McKay-Thompson Monster Irrep Multiplicities in $V_n$', fontsize=13, fontweight='bold', pad=10)
    ax4.set_xticks(x_indices)
    ax4.set_xticklabels([f'$V_{d}$' for d in degrees], fontsize=11)
    ax4.set_xlabel(r'Monster VOA Graded Level $V_n$', fontsize=11)
    ax4.set_ylabel(r'Irrep Multiplicity $m_i(V_n)$', fontsize=11)
    ax4.legend(title='Monster Irreps', loc='upper left', frameon=True, fontsize=8)
    ax4.grid(True, axis='y', linestyle=':', alpha=0.6)
    
    # -------------------------------------------------------------------------
    # PANEL E: Hecke Operator Logarithmic Decomposition & Convergence
    # -------------------------------------------------------------------------
    ax5 = fig.add_subplot(gs[1, 1])
    q_scan = np.linspace(0.005, 0.15, 100)
    
    for k in range(1, 5):
        p_fixed = 0.05
        hecke_series = np.zeros_like(q_scan)
        for n_mode in range(1, 5):
            c_val = MOONSHINE_COEFFS.get(n_mode, 0)
            hecke_series += c_val * (q_scan ** (n_mode * k))
        term_val = (1.0 / k) * (p_fixed ** k) * hecke_series
        label_str = rf'$k = {k}$ Hecke Mode $\frac{{1}}{{{k}}} p^{{{k}}} T_{{{k}}}(J)$'
        ax5.plot(q_scan, term_val, lw=2.2, label=label_str)
    
    ax5.set_title(r'(E) Hecke Modes $\frac{1}{k} p^k T_k(J(q))$ in $\log \Phi(p, q)$', fontsize=13, fontweight='bold', pad=10)
    ax5.set_xlabel(r'Modular Parameter $q$', fontsize=11)
    ax5.set_ylabel(r'Hecke Mode Amplitude ($p = 0.05$)', fontsize=11)
    ax5.legend(loc='upper right', frameon=True, fontsize=9)
    ax5.grid(True, linestyle=':', alpha=0.6)
    
    # -------------------------------------------------------------------------
    # PANEL F: Monster Character Trace vs Modular j(τ) - 744
    # -------------------------------------------------------------------------
    ax6 = fig.add_subplot(gs[1, 2])
    y_vals = np.linspace(0.6, 2.5, 150)
    q_imag = np.exp(-2.0 * np.pi * y_vals)
    
    # Graded trace partial sums
    trace_deg0 = 1.0 / q_imag
    trace_deg2 = trace_deg0 + 196884.0 * q_imag
    trace_deg3 = trace_deg2 + 21493760.0 * (q_imag ** 2)
    trace_full = trace_deg3 + 864299970.0 * (q_imag ** 3) + 20245856256.0 * (q_imag ** 4)
    
    ax6.semilogy(y_vals, trace_deg0, ':', color='gray', lw=1.8, label=r'Vacuum Pole $q^{-1}$')
    ax6.semilogy(y_vals, trace_deg2, '--', color=c_purple, lw=2.0, label=r'Tr up to $V_2$ (Griess)')
    ax6.semilogy(y_vals, trace_deg3, '-.', color=c_orange, lw=2.0, label=r'Tr up to $V_3$')
    ax6.semilogy(y_vals, trace_full, '-', color=c_red, lw=2.5, label=r'Tr up to $V_5$ $\equiv J(i y)$')
    
    ax6.set_title(r'(F) Character Trace $\mathrm{Tr}_{V^\natural}(q^{L_0 - 1}) = j(i y) - 744$', fontsize=13, fontweight='bold', pad=10)
    ax6.set_xlabel(r'Modular Height $y = \mathrm{Im}(\tau)$ ($\tau = i y$)', fontsize=11)
    ax6.set_ylabel(r'Partition Function $Z_{V^\natural}(i y)$ (Log Scale)', fontsize=11)
    ax6.legend(loc='upper right', frameon=True, fontsize=9)
    ax6.grid(True, which='both', linestyle=':', alpha=0.6)
    
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"  [SUCCESS] Publication-grade 6-panel figure saved to {output_path}!\n")

# =============================================================================
# MAIN EXECUTION
# =============================================================================

def main():
    print("===============================================================================")
    print("Vector 1: Non-Archimedean Monster VOA & Borcherds Automorphic Products")
    print("===============================================================================\n")
    
    # 1. Verify Monster irrep decompositions
    verify_monster_decompositions()
    
    # 2. Verify Borcherds product expansion to order p^5
    verify_borcherds_faber_expansion(max_order=5)
    
    # 3. Generate publication figure
    generate_publication_figure("figures/monster_voa_borcherds.png")
    
    print("===============================================================================")
    print("ALL TESTS PASSED WITH 100% VERIFICATION SUCCESS!")
    print("===============================================================================")

if __name__ == "__main__":
    main()
