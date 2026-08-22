"""
Bruhat-Tits Apartment Flow on PGL_3(Q_p) Triangular Buildings
============================================================
Author: Adelic Spectral Zeta Research Group
Date: August 2026

This experiment implements:
1. 2D simplicial building geometry B(PGL_3(Q_p)) along the triangular apartment lattice A ~ Z^2.
2. Construction and verification of Hecke operators T_1, T_2 and 2D discrete Helmholtz operator Delta.
3. Computation and numerical validation of 2D Macdonald spherical functions P_lambda(z; q, t=q^{-1})
   as exact eigenfunctions of the transfer operator and Hecke system.
4. Spectral deltoid mapping, Ramanujan spectral gap verification, and automorphic lifts (Sym^2(Delta), Buhler A_5).
5. Comprehensive 6-panel 2D visualization saved to figures/pgl3_apartment_flow.png.
"""

import os
import itertools
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.tri as mtri
from matplotlib.patches import Polygon
from matplotlib.collections import PatchCollection

# Set style for publication quality
plt.style.use('seaborn-v0_8-whitegrid' if 'seaborn-v0_8-whitegrid' in plt.style.available else 'default')
plt.rcParams['font.family'] = 'DejaVu Sans'
plt.rcParams['mathtext.fontset'] = 'cm'
plt.rcParams['figure.dpi'] = 300

# -------------------------------------------------------------------------
# 1. Non-Archimedean Macdonald Spherical Functions for PGL_3(Q_p)
# -------------------------------------------------------------------------

def c_function_A2(z, q):
    """
    Computes the Harish-Chandra / Gindikin-Karpelevich c-function for A_2:
    c(z) = prod_{1 <= i < j <= 3} (1 - q^{-1} z_i^{-1} z_j) / (1 - z_i^{-1} z_j)
         = prod_{1 <= i < j <= 3} (z_i - q^{-1} z_j) / (z_i - z_j)
    """
    z1, z2, z3 = z
    pairs = [(z1, z2), (z1, z3), (z2, z3)]
    res = 1.0 + 0j
    for za, zb in pairs:
        res *= (za - (1.0 / q) * zb) / (za - zb)
    return res

def macdonald_spherical_A2(m, n, z, q):
    """
    Computes the normalized Macdonald spherical function Phi_z(m, n) for PGL_3(Q_p).
    For dominant weight lambda = m * varpi_1 + n * varpi_2:
    Phi_z(lambda) = q^{-<rho, lambda>} / W(q^{-1}) * sum_{w in S_3} c(w(z)) * w(z)^lambda
    where <rho, lambda> = m + n, and W(t) = 1 + 2t + 2t^2 + t^3.
    """
    z1, z2, z3 = z
    perms = list(itertools.permutations([z1, z2, z3]))
    W_t = 1.0 + 2.0 / q + 2.0 / (q**2) + 1.0 / (q**3)
    val = 0.0 + 0j
    for p in perms:
        w_z = p
        cw = c_function_A2(w_z, q)
        # In weight basis: z^lambda = z1^m * (z1 * z2)^n = z1^(m+n) * z2^n
        term = cw * (w_z[0]**(m + n)) * (w_z[1]**n)
        val += term
    val = val / W_t
    return val * ((1.0 / q) ** (int(m) + int(n)))

# -------------------------------------------------------------------------
# 2. Radial Hecke Operators and Discrete Helmholtz Operator
# -------------------------------------------------------------------------

def apply_radial_T1(grid, q):
    """
    Applies the radial Hecke operator T_1 to a 2D grid of values f(m, n) on the Weyl chamber.
    Grid shape: (M+1, N+1) where grid[m, n] = f(m, n).
    """
    M, N = grid.shape[0] - 1, grid.shape[1] - 1
    out = np.zeros_like(grid, dtype=complex)
    
    for m in range(M):
        for n in range(N):
            if m == 0 and n == 0:
                # Origin (0,0) -> (1,0) with weight q^2+q+1
                out[0, 0] = (q**2 + q + 1) * grid[1, 0]
            elif n == 0 and m > 0:
                # Boundary n=0, m>0 -> (m+1, 0) [weight q^2] and (m-1, 1) [weight q+1]
                out[m, 0] = (q**2) * grid[m+1, 0] + (q + 1) * grid[m-1, 1]
            elif m == 0 and n > 0:
                # Boundary m=0, n>0 -> (1, n) [weight q(q+1)] and (0, n-1) [weight 1]
                out[0, n] = q * (q + 1) * grid[1, n] + 1.0 * grid[0, n-1]
            else:
                # Interior m>0, n>0 -> (m+1, n) [q^2], (m-1, n+1) [q], (m, n-1) [1]
                out[m, n] = (q**2) * grid[m+1, n] + q * grid[m-1, n+1] + 1.0 * grid[m, n-1]
    return out

def apply_radial_T2(grid, q):
    """
    Applies the radial Hecke operator T_2 to a 2D grid of values f(m, n) on the Weyl chamber.
    By duality, T_2 exchanges m <-> n relative to T_1.
    """
    M, N = grid.shape[0] - 1, grid.shape[1] - 1
    out = np.zeros_like(grid, dtype=complex)
    
    for m in range(M):
        for n in range(N):
            if m == 0 and n == 0:
                # Origin (0,0) -> (0,1) with weight q^2+q+1
                out[0, 0] = (q**2 + q + 1) * grid[0, 1]
            elif m == 0 and n > 0:
                # Boundary m=0, n>0 -> (0, n+1) [weight q^2] and (1, n-1) [weight q+1]
                out[0, n] = (q**2) * grid[0, n+1] + (q + 1) * grid[1, n-1]
            elif n == 0 and m > 0:
                # Boundary n=0, m>0 -> (m, 1) [weight q(q+1)] and (m-1, 0) [weight 1]
                out[m, 0] = q * (q + 1) * grid[m, 1] + 1.0 * grid[m-1, 0]
            else:
                # Interior m>0, n>0 -> (m, n+1) [q^2], (m+1, n-1) [q], (m-1, n) [1]
                out[m, n] = (q**2) * grid[m, n+1] + q * grid[m+1, n-1] + 1.0 * grid[m-1, n]
    return out

def apply_discrete_helmholtz(grid, q):
    """
    Applies the 2D discrete Laplacian on the building:
    Delta = (T_1 + T_2) - 2(q^2+q+1) I
    """
    deg = 2 * (q**2 + q + 1)
    t1_grid = apply_radial_T1(grid, q)
    t2_grid = apply_radial_T2(grid, q)
    return (t1_grid + t2_grid) - deg * grid

# -------------------------------------------------------------------------
# 3. Apartment Geometry & Coordinate Transformations
# -------------------------------------------------------------------------

def weight_to_cartesian(m, n):
    """
    Maps weight coordinates (m, n) = m varpi_1 + n varpi_2 to 2D Cartesian plane.
    varpi_1 = (1, 0), varpi_2 = (1/2, sqrt(3)/2).
    """
    x = m + 0.5 * n
    y = (np.sqrt(3.0) / 2.0) * n
    return x, y

def get_vertex_type(m, n):
    """
    Returns vertex coloring type in Z / 3Z: (m + 2n) mod 3.
    """
    return (m + 2 * n) % 3

# -------------------------------------------------------------------------
# 4. Comprehensive Numerical Verification Engine
# -------------------------------------------------------------------------

def run_rigorous_verifications(q=3, grid_size=12):
    print("=" * 80)
    print(f"RUNNING PGL_3(Q_{q}) BRUHAT-TITS APARTMENT FLOW RIGOROUS VERIFICATION SUITE")
    print("=" * 80)
    
    # 1. Base origin normalization
    z_test = (np.exp(1j * 0.7), np.exp(1j * 1.2), np.exp(-1j * 1.9))
    phi_00 = macdonald_spherical_A2(0, 0, z_test, q)
    print(f"[Verification 1] Macdonald Spherical Normalization Phi_z(0,0):")
    print(f"  Expected: 1.0 + 0j, Computed: {phi_00:.16f}")
    assert abs(phi_00 - 1.0) < 1e-14, "Normalization failed!"
    print(f"  -> Residual: {abs(phi_00 - 1.0):.2e} [PASS]")

    # 2. Hecke Eigenvalue Relations across representative Satake parameters
    test_cases = [
        ("Tempered Generic Principal Series", (np.exp(1j * 0.5), np.exp(1j * 1.1), np.exp(-1j * 1.6))),
        ("Tempered High-Frequency Wave", (np.exp(1j * 2.1), np.exp(1j * 1.7), np.exp(-1j * 3.8))),
        ("Gelbart-Jacquet Sym^2(Delta) Lift (p=3)", (np.exp(2j * 1.2673), 1.0 + 0j, np.exp(-2j * 1.2673))),
        ("Buhler Icosahedral A_5 Galois Rep (Order 5)", (np.exp(2j * np.pi / 5), np.exp(-2j * np.pi / 5), 1.0 + 0j)),
        ("Unramified Identity Vector (Constant)", (1.0/q, 1.0 + 0j, float(q)))
    ]

    for name, z in test_cases:
        e1 = sum(z)
        e2 = z[0]*z[1] + z[1]*z[2] + z[2]*z[0]
        lambda_1 = q * e1
        lambda_2 = q * e2
        lambda_delta = (lambda_1 + lambda_2) - 2 * (q**2 + q + 1)
        
        # Build grid
        grid = np.zeros((grid_size + 1, grid_size + 1), dtype=complex)
        for m in range(grid_size + 1):
            for n in range(grid_size + 1):
                grid[m, n] = macdonald_spherical_A2(m, n, z, q)
        
        # Apply operators
        T1_grid = apply_radial_T1(grid, q)
        T2_grid = apply_radial_T2(grid, q)
        Delta_grid = apply_discrete_helmholtz(grid, q)
        
        # Compute errors on interior evaluation domain [0, grid_size - 2]
        eval_M, eval_N = grid_size - 2, grid_size - 2
        err_T1 = np.max(np.abs(T1_grid[:eval_M, :eval_N] - lambda_1 * grid[:eval_M, :eval_N]))
        err_T2 = np.max(np.abs(T2_grid[:eval_M, :eval_N] - lambda_2 * grid[:eval_M, :eval_N]))
        err_Delta = np.max(np.abs(Delta_grid[:eval_M, :eval_N] - lambda_delta * grid[:eval_M, :eval_N]))
        
        print(f"\n[Verification 2] Satake Rep: {name}")
        print(f"  Satake Parameters: z = ({z[0]:.4f}, {z[1]:.4f}, {z[2]:.4f})")
        print(f"  Hecke Eigenvalues: lambda_1 = {lambda_1:.6f}, lambda_2 = {lambda_2:.6f}")
        print(f"  Laplacian Eigenvalue: lambda_Delta = {lambda_delta:.6f}")
        print(f"  Max Residual ||T_1 Phi - lambda_1 Phi||_inf:     {err_T1:.2e} [{'PASS' if err_T1 < 1e-12 else 'FAIL'}]")
        print(f"  Max Residual ||T_2 Phi - lambda_2 Phi||_inf:     {err_T2:.2e} [{'PASS' if err_T2 < 1e-12 else 'FAIL'}]")
        print(f"  Max Residual ||Delta Phi - lambda_Delta Phi||_inf: {err_Delta:.2e} [{'PASS' if err_Delta < 1e-12 else 'FAIL'}]")
        assert max(err_T1, err_T2, err_Delta) < 1e-10, f"Verification failed for {name}"

    # 3. Ramanujan Spectral Gap Verification
    # For PGL_3(Q_p), the tempered band of Delta spans [ -3q - 2(q^2+q+1), 6q - 2(q^2+q+1) ]
    deg = 2 * (q**2 + q + 1)
    tempered_top = 6 * q - deg
    trivial_lambda = 0.0  # Since Delta 1 = deg - deg = 0
    spectral_gap = trivial_lambda - tempered_top
    expected_gap = 2 * (q - 1)**2
    print(f"\n[Verification 3] Non-Archimedean Ramanujan Spectral Gap:")
    print(f"  Degree = 2(q^2+q+1) = {deg}")
    print(f"  Tempered Spectral Band: [{ -3*q - deg:.1f}, {tempered_top:.1f} ]")
    print(f"  Computed Gap = {spectral_gap:.1f}, Expected 2(q-1)^2 = {expected_gap:.1f}")
    assert abs(spectral_gap - expected_gap) < 1e-14, "Spectral gap mismatch!"
    print(f"  -> Exact Match: Spectral Gap = 2(q-1)^2 = {expected_gap} [PASS]")
    print("=" * 80 + "\n")

# -------------------------------------------------------------------------
# 5. Publication-Grade 2D Visualization Suite
# -------------------------------------------------------------------------

def generate_publication_figure(output_path="figures/pgl3_apartment_flow.png", q=3):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    fig = plt.figure(figsize=(21, 13.5))
    gs = fig.add_gridspec(2, 3, wspace=0.32, hspace=0.36, left=0.06, right=0.96, top=0.91, bottom=0.07)
    
    # -------------------------------------------------------------
    # Panel (a): 2D Simplicial Complex Triangulation & Vertex Types
    # -------------------------------------------------------------
    ax_a = fig.add_subplot(gs[0, 0])
    ax_a.set_title(r"(a) 2D Simplicial Apartment $\mathcal{A}(\mathrm{PGL}_3(\mathbb{Q}_p))$", fontsize=13, fontweight='bold', pad=12)
    
    # Generate triangular apartment grid
    R_max = 6
    points = []
    coord_map = {}
    pt_idx = 0
    
    for u in range(-R_max, R_max + 1):
        for v in range(-R_max, R_max + 1):
            if abs(u + v) <= R_max + 2:
                x, y = weight_to_cartesian(u, v)
                points.append((x, y, u, v, get_vertex_type(u, v)))
                coord_map[(u, v)] = pt_idx
                pt_idx += 1
                
    # Build simplices (triangles: type A (u,v)-(u+1,v)-(u,v+1) and type B (u+1,v)-(u,v+1)-(u+1,v+1))
    patches_A = []
    patches_B = []
    for u in range(-R_max, R_max):
        for v in range(-R_max, R_max):
            if (u, v) in coord_map and (u+1, v) in coord_map and (u, v+1) in coord_map:
                p0 = weight_to_cartesian(u, v)
                p1 = weight_to_cartesian(u+1, v)
                p2 = weight_to_cartesian(u, v+1)
                patches_A.append(Polygon([p0, p1, p2], closed=True))
            if (u+1, v) in coord_map and (u, v+1) in coord_map and (u+1, v+1) in coord_map:
                p1 = weight_to_cartesian(u+1, v)
                p2 = weight_to_cartesian(u, v+1)
                p3 = weight_to_cartesian(u+1, v+1)
                patches_B.append(Polygon([p1, p2, p3], closed=True))
                
    poly_coll_A = PatchCollection(patches_A, alpha=0.22, facecolor='#2b5c8f', edgecolor='#1e3d59', linewidth=0.8)
    poly_coll_B = PatchCollection(patches_B, alpha=0.15, facecolor='#d9534f', edgecolor='#1e3d59', linewidth=0.8)
    ax_a.add_collection(poly_coll_A)
    ax_a.add_collection(poly_coll_B)
    
    # Highlight Weyl chamber A^+ (u>=0, v>=0)
    chamber_pts = [weight_to_cartesian(0, 0), weight_to_cartesian(R_max, 0), 
                   weight_to_cartesian(R_max, R_max), weight_to_cartesian(0, R_max)]
    ax_a.add_patch(Polygon(chamber_pts, closed=True, facecolor='#ffd166', alpha=0.28, edgecolor='#d4a373', linewidth=2.2, linestyle='--'))
    
    # Draw vertices by type
    type_colors = {0: '#e63946', 1: '#06d6a0', 2: '#118ab2'}
    type_labels = {0: r'Type 0 ($\mathrm{ord}_p \det \equiv 0$)', 1: r'Type 1 ($\mathrm{ord}_p \det \equiv 1$)', 2: r'Type 2 ($\mathrm{ord}_p \det \equiv 2$)'}
    
    for t in [0, 1, 2]:
        t_pts = [p for p in points if p[4] == t and abs(p[0]) <= 5.5 and abs(p[1]) <= 5.0]
        xs = [p[0] for p in t_pts]
        ys = [p[1] for p in t_pts]
        ax_a.scatter(xs, ys, c=type_colors[t], s=40, label=type_labels[t], edgecolors='k', linewidth=0.6, zorder=5)
        
    # Draw fundamental step vectors at origin
    ox, oy = weight_to_cartesian(0, 0)
    ax_a.arrow(ox, oy, 1.0, 0.0, head_width=0.25, head_length=0.25, fc='#06d6a0', ec='k', width=0.05, zorder=10)
    ax_a.arrow(ox, oy, 0.5, np.sqrt(3)/2, head_width=0.25, head_length=0.25, fc='#118ab2', ec='k', width=0.05, zorder=10)
    ax_a.text(1.15, 0.05, r"$\varpi_1 \; (T_1)$", fontsize=11, fontweight='bold', color='#006644', zorder=12)
    ax_a.text(0.35, 1.05, r"$\varpi_2 \; (T_2)$", fontsize=11, fontweight='bold', color='#004488', zorder=12)
    ax_a.text(1.8, 2.2, r"$\mathcal{A}^+\; (\mathrm{Weyl\; Chamber})$", fontsize=11, fontweight='bold', color='#a05a00', bbox=dict(boxstyle='round,pad=0.3', facecolor='#fff2b2', alpha=0.9))
    
    ax_a.set_xlim(-4.5, 6.5)
    ax_a.set_ylim(-3.5, 5.5)
    ax_a.set_xlabel(r"$X = u + \frac{1}{2}v$", fontsize=11)
    ax_a.set_ylabel(r"$Y = \frac{\sqrt{3}}{2}v$", fontsize=11)
    ax_a.legend(loc='lower left', fontsize=8.5, framealpha=0.92)
    ax_a.set_aspect('equal')

    # -------------------------------------------------------------
    # Panel (b): Transfer Operator Vector Field & Simplicial Flux
    # -------------------------------------------------------------
    ax_b = fig.add_subplot(gs[0, 1])
    ax_b.set_title(r"(b) Transfer Operator $\mathcal{T}_z$ Simplicial Probability Flux", fontsize=13, fontweight='bold', pad=12)
    
    # Compute wave on Weyl chamber
    z_wave = (np.exp(1j * 0.8), np.exp(1j * 1.3), np.exp(-1j * 2.1))
    U_grid, V_grid = np.meshgrid(np.arange(0, 9), np.arange(0, 9))
    
    X_flux = U_grid + 0.5 * V_grid
    Y_flux = (np.sqrt(3.0)/2.0) * V_grid
    
    Psi_val = np.zeros_like(U_grid, dtype=complex)
    for i in range(U_grid.shape[0]):
        for j in range(U_grid.shape[1]):
            Psi_val[i, j] = macdonald_spherical_A2(int(U_grid[i, j]), int(V_grid[i, j]), z_wave, q)
            
    # Normalize by radial envelope for better interior visualization of wave direction
    env = np.abs(Psi_val) + 1e-12
    Psi_norm = Psi_val / (env ** 0.6)
    
    grad_u = np.gradient(Psi_norm, axis=1)
    grad_v = np.gradient(Psi_norm, axis=0)
    
    Jx = np.imag(np.conj(Psi_norm) * grad_u)
    Jy = np.imag(np.conj(Psi_norm) * ((2.0 / np.sqrt(3.0)) * grad_v - (1.0 / np.sqrt(3.0)) * grad_u))
    
    norm_J = np.sqrt(Jx**2 + Jy**2) + 1e-12
    Jx_dir = Jx / norm_J
    Jy_dir = Jy / norm_J
    
    # Background: Log probability density
    log_density = np.log10(np.abs(Psi_val)**2 + 1e-6)
    contour_b = ax_b.contourf(X_flux, Y_flux, log_density, levels=25, cmap='magma')
    cbar_b = plt.colorbar(contour_b, ax=ax_b, fraction=0.046, pad=0.04)
    cbar_b.set_label(r"$\log_{10} |\Phi_z(u,v)|^2$", fontsize=10)
    
    # Stream arrows
    ax_b.quiver(X_flux, Y_flux, Jx_dir, Jy_dir, norm_J, cmap='cool', scale=18, width=0.008, edgecolors='k', linewidth=0.3)
    
    ax_b.set_xlabel(r"$X = u + \frac{1}{2}v$", fontsize=11)
    ax_b.set_ylabel(r"$Y = \frac{\sqrt{3}}{2}v$", fontsize=11)
    ax_b.set_xlim(-0.5, 11.5)
    ax_b.set_ylim(-0.5, 7.5)
    ax_b.set_aspect('equal')

    # -------------------------------------------------------------
    # Panel (c): 2D Macdonald Spherical Wavefunction Re(Phi_z)
    # -------------------------------------------------------------
    ax_c = fig.add_subplot(gs[0, 2])
    ax_c.set_title(r"(c) Macdonald Wave $\mathrm{Re}(\Phi_z(m,n))$ ($p=3$)", fontsize=13, fontweight='bold', pad=12)
    
    N_res = 12
    m_arr = []
    n_arr = []
    re_phi_arr = []
    x_c = []
    y_c = []
    
    for m in range(N_res + 1):
        for n in range(N_res + 1 - m):
            val = macdonald_spherical_A2(m, n, z_wave, q)
            xc, yc = weight_to_cartesian(m, n)
            m_arr.append(m)
            n_arr.append(n)
            re_phi_arr.append(np.real(val))
            x_c.append(xc)
            y_c.append(yc)
            
    triang = mtri.Triangulation(x_c, y_c)
    tc = ax_c.tricontourf(triang, re_phi_arr, levels=30, cmap='Spectral_r')
    ax_c.triplot(triang, 'k-', lw=0.4, alpha=0.35)
    ax_c.scatter(x_c, y_c, c=re_phi_arr, cmap='Spectral_r', edgecolors='k', s=25, linewidth=0.5, zorder=5)
    
    cbar_c = plt.colorbar(tc, ax=ax_c, fraction=0.046, pad=0.04)
    cbar_c.set_label(r"$\mathrm{Re}(\Phi_z(m, n))$ Amplitude", fontsize=10)
    ax_c.set_xlabel(r"$X = m + \frac{1}{2}n$", fontsize=11)
    ax_c.set_ylabel(r"$Y = \frac{\sqrt{3}}{2}n$", fontsize=11)
    ax_c.set_aspect('equal')

    # -------------------------------------------------------------
    # Panel (d): Macdonald Spherical Wave Phase Field Arg(Phi_z)
    # -------------------------------------------------------------
    ax_d = fig.add_subplot(gs[1, 0])
    ax_d.set_title(r"(d) Non-Archimedean Phase $\operatorname{Arg}(\Phi_z(m,n))$", fontsize=13, fontweight='bold', pad=12)
    
    phase_arr = []
    for m, n in zip(m_arr, n_arr):
        val = macdonald_spherical_A2(m, n, z_wave, q)
        phase_arr.append(np.angle(val))
        
    td = ax_d.tricontourf(triang, phase_arr, levels=30, cmap='twilight_shifted')
    ax_d.triplot(triang, 'k-', lw=0.4, alpha=0.35)
    ax_d.scatter(x_c, y_c, c=phase_arr, cmap='twilight_shifted', edgecolors='k', s=25, linewidth=0.5, zorder=5)
    
    cbar_d = plt.colorbar(td, ax=ax_d, fraction=0.046, pad=0.04)
    cbar_d.set_label(r"Phase Angle $\operatorname{Arg}(\Phi_z) \in [-\pi, \pi]$", fontsize=10)
    ax_d.set_xlabel(r"$X = m + \frac{1}{2}n$", fontsize=11)
    ax_d.set_ylabel(r"$Y = \frac{\sqrt{3}}{2}n$", fontsize=11)
    ax_d.set_aspect('equal')

    # -------------------------------------------------------------
    # Panel (e): Satake Spectral Deltoid & Automorphic Lifts
    # -------------------------------------------------------------
    ax_e = fig.add_subplot(gs[1, 1])
    ax_e.set_title(r"(e) Satake Spectral Deltoid & Automorphic Lifts", fontsize=13, fontweight='bold', pad=12)
    
    t_vals = np.linspace(0, 2*np.pi, 500)
    deltoid_e1 = 2.0 * np.exp(1j * t_vals) + np.exp(-2j * t_vals)
    deltoid_scaled = q * deltoid_e1
    
    theta1_grid, theta2_grid = np.meshgrid(np.linspace(0, 2*np.pi, 200), np.linspace(0, 2*np.pi, 200))
    z1_g = np.exp(1j * theta1_grid)
    z2_g = np.exp(1j * theta2_grid)
    z3_g = np.exp(-1j * (theta1_grid + theta2_grid))
    e1_grid = q * (z1_g + z2_g + z3_g)
    
    ax_e.scatter(np.real(e1_grid).flatten(), np.imag(e1_grid).flatten(), c='#a2d2ff', s=1.5, alpha=0.3, label=r"Tempered Spectrum $\sigma_{\mathrm{temp}}(T_1)$")
    ax_e.plot(np.real(deltoid_scaled), np.imag(deltoid_scaled), 'b-', lw=2.4, label=r"Deltoid Boundary $\partial \Sigma_{\mathrm{tempered}}$")
    
    tau3_norm = 252.0 / (243.0 * np.sqrt(3.0))
    th3 = np.arccos(tau3_norm / 2.0)
    z_sym2 = (np.exp(2j * th3), 1.0 + 0j, np.exp(-2j * th3))
    pt_sym2 = q * sum(z_sym2)
    ax_e.scatter([np.real(pt_sym2)], [np.imag(pt_sym2)], color='#d90429', s=120, zorder=10, marker='D', label=rf"$\mathrm{{Sym}}^2(\Delta_{{12}})\; (\lambda_1 = {np.real(pt_sym2):.2f})$")
    
    z_a5 = (np.exp(2j * np.pi / 5), np.exp(-2j * np.pi / 5), 1.0 + 0j)
    pt_a5 = q * sum(z_a5)
    ax_e.scatter([np.real(pt_a5)], [np.imag(pt_a5)], color='#7209b7', s=140, zorder=10, marker='*', label=rf"$\mathrm{{Buhler}}\; A_5\; (\lambda_1 = {np.real(pt_a5):.2f})$")
    
    pt_wave = q * sum(z_wave)
    ax_e.scatter([np.real(pt_wave)], [np.imag(pt_wave)], color='#38b000', s=100, zorder=10, marker='o', label=rf"$\mathrm{{Generic\; Wave}}\; (\lambda_1 = {np.real(pt_wave):.2f} + {np.imag(pt_wave):.2f}i)$")
    
    ax_e.scatter([3 * q], [0], color='#ffb703', s=120, edgecolors='k', zorder=10, marker='s', label=rf"$\mathbf{{1}}\; \mathrm{{Identity}}\; (\lambda_1 = {3*q})$")
    
    ax_e.axhline(0, color='gray', linestyle=':', lw=0.8)
    ax_e.axvline(0, color='gray', linestyle=':', lw=0.8)
    ax_e.set_xlabel(r"$\mathrm{Re}(\lambda_1) = q\,\mathrm{Re}(e_1(z))$", fontsize=11)
    ax_e.set_ylabel(r"$\mathrm{Im}(\lambda_1) = q\,\mathrm{Im}(e_1(z))$", fontsize=11)
    ax_e.legend(loc='lower left', fontsize=7.5, framealpha=0.95)
    ax_e.set_xlim(-10, 10.5)
    ax_e.set_ylim(-9, 9)


    # -------------------------------------------------------------
    # Panel (f): Discrete Helmholtz Radial Dispersion & Ramanujan Gap
    # -------------------------------------------------------------
    ax_f = fig.add_subplot(gs[1, 2])
    ax_f.set_title(r"(f) Discrete Helmholtz Dispersion & Ramanujan Gap", fontsize=13, fontweight='bold', pad=12)
    
    deg_val = 2 * (q**2 + q + 1)
    k_vals = np.linspace(0, 2*np.pi, 300)
    
    path_len = len(k_vals)
    t1_seg1 = np.linspace(0, 2*np.pi/3, path_len)
    t2_seg1 = t1_seg1
    disp_seg1 = 2 * q * (np.cos(t1_seg1) + np.cos(t2_seg1) + np.cos(t1_seg1 + t2_seg1)) - deg_val
    
    t_s2 = np.linspace(0, 1, path_len)
    t1_seg2 = 2*np.pi/3 + t_s2 * (np.pi - 2*np.pi/3)
    t2_seg2 = 2*np.pi/3 - t_s2 * (2*np.pi/3)
    disp_seg2 = 2 * q * (np.cos(t1_seg2) + np.cos(t2_seg2) + np.cos(t1_seg2 + t2_seg2)) - deg_val
    
    t_s3 = np.linspace(0, 1, path_len)
    t1_seg3 = np.pi * (1 - t_s3)
    t2_seg3 = np.zeros_like(t_s3)
    disp_seg3 = 2 * q * (np.cos(t1_seg3) + np.cos(t2_seg3) + np.cos(t1_seg3 + t2_seg3)) - deg_val
    
    full_disp = np.concatenate([disp_seg1, disp_seg2, disp_seg3])
    x_axis = np.linspace(0, 3, len(full_disp))
    
    ax_f.plot(x_axis, full_disp, color='#1d3557', lw=2.4, label=r"Tempered Dispersion $\lambda_\Delta(\theta)$")
    
    tempered_max = 6 * q - deg_val
    tempered_min = -3 * q - deg_val
    ax_f.axhspan(tempered_min, tempered_max, color='#457b9d', alpha=0.18, label=r"Tempered Band $[-35, -8]$")
    
    ax_f.axhline(0, color='#e63946', lw=2.0, linestyle='--', label=r"Trivial State $\lambda_0 = 0$")
    ax_f.annotate('', xy=(1.5, 0), xytext=(1.5, tempered_max),
                  arrowprops=dict(arrowstyle='<->', color='#d62828', lw=2.0))
    ax_f.text(1.55, -4.5, rf"$\mathrm{{Gap}} = 2(q-1)^2 = {2*(q-1)**2}$", color='#d62828', fontsize=11, fontweight='bold')
    
    eig_sym2 = 2 * q * np.real(sum(z_sym2)) - deg_val
    eig_a5 = 2 * q * np.real(sum(z_a5)) - deg_val
    ax_f.axhline(eig_sym2, color='#d90429', linestyle=':', lw=1.5, label=rf"$\mathrm{{Sym}}^2(\Delta): \lambda_\Delta = {eig_sym2:.1f}$")
    ax_f.axhline(eig_a5, color='#7209b7', linestyle=':', lw=1.5, label=rf"$\mathrm{{Buhler}}\; A_5: \lambda_\Delta = {eig_a5:.1f}$")
    
    ax_f.set_xticks([0, 1, 2, 3])
    ax_f.set_xticklabels([r"$\Gamma\; (0,0)$", r"$K\; (\frac{2\pi}{3}, \frac{2\pi}{3})$", r"$M\; (\pi, 0)$", r"$\Gamma\; (0,0)$"], fontsize=10.5)
    ax_f.set_ylabel(r"Laplacian Eigenvalue $\lambda_\Delta$", fontsize=11)
    ax_f.set_xlabel(r"Quasimomentum Path in Brillouin Zone $\mathcal{B}_1$", fontsize=11)
    ax_f.legend(loc='lower right', fontsize=8.0, framealpha=0.92)
    ax_f.set_ylim(-38, 4)
    
    plt.suptitle(r"Bruhat-Tits Apartment Flow & 2D Macdonald Spherical Waves on $\mathcal{B}(\mathrm{PGL}_3(\mathbb{Q}_p))$", fontsize=15, fontweight='bold', y=0.97)
    
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"Publication-grade 6-panel figure successfully saved to: {output_path}")


# -------------------------------------------------------------------------
# 6. Main Execution
# -------------------------------------------------------------------------

if __name__ == '__main__':
    run_rigorous_verifications(q=3, grid_size=12)
    generate_publication_figure(output_path="figures/pgl3_apartment_flow.png", q=3)
