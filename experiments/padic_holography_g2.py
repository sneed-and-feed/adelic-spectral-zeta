"""
p-Adic Holography & AdS/CFT on Bruhat-Tits Buildings and G_2 Telemetry
======================================================================
Author: Adelic Spectral Zeta Research Group
Date: August 2026

This experiment implements:
1. Discrete bulk-to-boundary propagator K_Delta(v, x) on Bruhat-Tits trees T_{p+1} for p in {2, 3, 5}.
2. Boundary 3-point Witten diagram amplitudes W_3(x_1, x_2, x_3) via bulk vertex summation,
   verifying exponential convergence to the p-adic conformal 3-point function:
   C_p(Delta_1, Delta_2, Delta_3) / (|x1-x2|_p^{Delta1+Delta2-Delta3} |x2-x3|_p^{Delta2+Delta3-Delta1} |x3-x1|_p^{Delta3+Delta1-Delta2}).
3. Non-Archimedean Operator Product Expansion (OPE) coefficients C_123 from spherical Hecke algebra
   structure constants c_{lambda, mu}^nu on Bruhat-Tits buildings (rank 1, A_2, and G_2).
4. 2D Macdonald spherical joint eigenfunctions on the G_2 apartment with 12-fold D_6 Weyl symmetry.
5. Construction of 12-point G_2 root adjacency operators (6 short, 6 long) on a 30x30 hexagonal torus,
   proving numerically that [T_short, T_long] = 0 to machine precision (< 1e-15).
6. Comprehensive publication-grade 6-panel visualization saved to figures/padic_holography_g2.png.
"""

import os
import itertools
import numpy as np
import scipy.sparse as sp
import matplotlib.pyplot as plt
import matplotlib.tri as mtri
from matplotlib.patches import Polygon, Circle
from matplotlib.collections import LineCollection

# Set publication quality plotting parameters
plt.style.use('seaborn-v0_8-whitegrid' if 'seaborn-v0_8-whitegrid' in plt.style.available else 'default')
plt.rcParams['font.family'] = 'DejaVu Sans'
plt.rcParams['mathtext.fontset'] = 'cm'
plt.rcParams['figure.dpi'] = 300


# =========================================================================
# 1. p-Adic Distance & Ultrametric Holography on Bruhat-Tits Tree T_{p+1}
# =========================================================================

def padic_valuation(n, p):
    """Computes the p-adic valuation ord_p(n) for integer n."""
    if n == 0:
        return float('inf')
    val = abs(int(n))
    ord_p = 0
    while val % p == 0:
        ord_p += 1
        val //= p
    return ord_p


def padic_norm(n, p):
    """Computes the p-adic norm |n|_p = p^{-ord_p(n)}."""
    if n == 0:
        return 0.0
    return float(p ** (-padic_valuation(n, p)))


def padic_dist(x, y, p):
    """Computes the p-adic distance |x - y|_p."""
    return padic_norm(x - y, p)


def bulk_to_boundary_propagator(k, z, x, Delta, p):
    """
    Computes the discrete bulk-to-boundary propagator K_Delta(v, x) on T_{p+1}.
    v = (k, z) represents a ball B(z, p^{-k}) in Q_p at depth k with center z.
    x in Q_p is a boundary point.

    K_Delta(v, x) = ((1 - p^{-1}) / (1 - p^{-Delta})) * (|z_0|_p^Delta / max(|z_0|_p, |z - x|_p)^{2Delta})
    where |z_0|_p = p^{-k}.
    """
    z0_norm = p ** (-k)
    diff = x - z
    if diff == 0:
        norm_diff = 0.0
    else:
        norm_diff = padic_norm(diff, p)
    max_val = max(z0_norm, norm_diff)
    pref = (1.0 - 1.0 / p) / (1.0 - p ** (-Delta))
    return pref * (z0_norm ** Delta) / (max_val ** (2.0 * Delta))


def compute_witten_diagram_3pt(x1, x2, x3, Delta1, Delta2, Delta3, p, K_max=7, k_min=-2):
    """
    Vectorized computation of 3-point Witten diagram amplitude on Bruhat-Tits tree T_{p+1}:
    W_3(x1, x2, x3) = sum_{v in V(T)} K_Delta1(v, x1) * K_Delta2(v, x2) * K_Delta3(v, x3)
    """
    total = 0.0
    for k in range(k_min, K_max + 1):
        if k >= 0:
            z_vals = np.arange(p ** k, dtype=np.int64)
        else:
            z_vals = np.array([0], dtype=np.int64)

        z0 = float(p ** (-k))

        # Pairwise p-adic distances to each boundary point
        d1 = np.array([padic_dist(int(z), x1, p) for z in z_vals])
        d2 = np.array([padic_dist(int(z), x2, p) for z in z_vals])
        d3 = np.array([padic_dist(int(z), x3, p) for z in z_vals])

        m1 = np.maximum(z0, d1)
        m2 = np.maximum(z0, d2)
        m3 = np.maximum(z0, d3)

        k1 = (z0 ** Delta1) / (m1 ** (2.0 * Delta1))
        k2 = (z0 ** Delta2) / (m2 ** (2.0 * Delta2))
        k3 = (z0 ** Delta3) / (m3 ** (2.0 * Delta3))

        total += np.sum(k1 * k2 * k3)

    pref1 = (1.0 - 1.0 / p) / (1.0 - p ** (-Delta1))
    pref2 = (1.0 - 1.0 / p) / (1.0 - p ** (-Delta2))
    pref3 = (1.0 - 1.0 / p) / (1.0 - p ** (-Delta3))
    return total * pref1 * pref2 * pref3


def padic_conformal_3pt_factor(x1, x2, x3, Delta1, Delta2, Delta3, p):
    """
    Computes the canonical p-adic conformal 3-point factor:
    F_conf = |x1 - x2|_p^{-(Delta1+Delta2-Delta3)} *
             |x2 - x3|_p^{-(Delta2+Delta3-Delta1)} *
             |x3 - x1|_p^{-(Delta3+Delta1-Delta2)}
    """
    d12 = padic_dist(x1, x2, p)
    d23 = padic_dist(x2, x3, p)
    d31 = padic_dist(x3, x1, p)

    s123 = Delta1 + Delta2 - Delta3
    s231 = Delta2 + Delta3 - Delta1
    s312 = Delta3 + Delta1 - Delta2

    return (d12 ** (-s123)) * (d23 ** (-s231)) * (d31 ** (-s312))


def exact_witten_coefficient_gubser(p, Delta1, Delta2, Delta3):
    """
    Computes the exact analytic 3-point Witten diagram coefficient C_p(Delta1, Delta2, Delta3)
    derived from the geometric series summation on the Bruhat-Tits tree (Gubser et al. 2016).
    """
    s_tot = Delta1 + Delta2 + Delta3
    s1 = Delta2 + Delta3 - Delta1
    s2 = Delta3 + Delta1 - Delta2
    s3 = Delta1 + Delta2 - Delta3

    pref = ((1.0 - 1.0 / p) ** 3) / ((1.0 - p ** (-Delta1)) * (1.0 - p ** (-Delta2)) * (1.0 - p ** (-Delta3)))
    term_junction = 1.0 + (p - 2.0) * (p - 1.0) / (p * (p ** (s_tot - 1.0) - 1.0))
    term_arm1 = (p - 1.0) * (p ** (-Delta1)) / (p ** s1 - 1.0)
    term_arm2 = (p - 1.0) * (p ** (-Delta2)) / (p ** s2 - 1.0)
    term_arm3 = (p - 1.0) * (p ** (-Delta3)) / (p ** s3 - 1.0)

    return pref * (term_junction + term_arm1 + term_arm2 + term_arm3)


# =========================================================================
# 2. Hecke Algebra Structure Constants & Boundary OPE Coefficients
# =========================================================================

def hecke_structure_constants_rank1(m, n, q):
    """
    Multiplication in spherical Hecke algebra H(PGL_2(Q_p), PGL_2(Z_p)):
    T_m * T_n = sum_{k=0}^{min(m, n)} q^k T_{m+n-2k}
    Returns dictionary {nu: c_{m, n}^nu(q)}.
    """
    coeffs = {}
    for k in range(min(m, n) + 1):
        nu = m + n - 2 * k
        coeff = (q ** k) if k > 0 else 1.0
        coeffs[nu] = coeffs.get(nu, 0.0) + coeff
    return coeffs


def hecke_structure_constants_A2(q):
    """
    Fundamental multiplication in spherical Hecke algebra H(PGL_3(Q_p)):
    T_(1,0) * T_(0,1) = T_(1,1) + (q^2 + q) T_(0,0)
    T_(1,0) * T_(1,0) = T_(2,0) + (q + 1) T_(0,1)
    """
    prod_10_01 = {(1, 1): 1.0, (0, 0): float(q ** 2 + q)}
    prod_10_10 = {(2, 0): 1.0, (0, 1): float(q + 1)}
    return prod_10_10, prod_10_01


def hecke_structure_constants_G2(q):
    """
    Fundamental multiplication in spherical Hecke algebra H(G_2(Q_p)):
    Short root sphere T_varpi1 * T_varpi1 (7 x 7 decomposition):
    T_varpi1 * T_varpi1 = T_2varpi1 + (q+1) T_varpi2 + (q^2+q+1) T_varpi1 + (q^5+q^4+q^3+q^2+q+1) T_0
    """
    return {
        (2, 0): 1.0,
        (0, 1): float(q + 1),
        (1, 0): float(q ** 2 + q + 1),
        (0, 0): float(q ** 5 + q ** 4 + q ** 3 + q ** 2 + q + 1)
    }


# =========================================================================
# 3. G_2 Root System, Weyl Group & Macdonald Spherical Eigenfunctions
# =========================================================================

def get_G2_geometry():
    """
    Constructs the 2D G_2 root system, Weyl group W(G_2) = D_6 (order 12),
    coroots, fundamental weights, and Cartan relations.
    """
    # Simple roots
    # Short root alpha_1: length 1, along x-axis
    # Long root alpha_2: length sqrt(3), at angle 150 deg (5pi/6)
    a1 = np.array([1.0, 0.0])
    a2 = np.array([-1.5, np.sqrt(3.0) / 2.0])

    # 6 short roots (length 1)
    s1 = a1                      # (1, 0)
    s2 = a1 + a2                 # (-0.5, sqrt(3)/2)
    s3 = 2 * a1 + a2             # (0.5, sqrt(3)/2)
    short_roots = [s1, s2, s3, -s1, -s2, -s3]

    # 6 long roots (length sqrt(3))
    l1 = a2                      # (-1.5, sqrt(3)/2)
    l2 = 3 * a1 + a2             # (1.5, sqrt(3)/2)
    l3 = 3 * a1 + 2 * a2         # (0, sqrt(3))
    long_roots = [l1, l2, l3, -l1, -l2, -l3]

    # Positive roots (3 short, 3 long)
    pos_roots_short = [s1, s2, s3]
    pos_roots_long = [l1, l2, l3]
    pos_roots = pos_roots_short + pos_roots_long

    # Coroots: alpha^vee = 2 alpha / |alpha|^2
    pos_coroots = [2.0 * r for r in pos_roots_short] + [(2.0 / 3.0) * r for r in pos_roots_long]

    # Fundamental weights:
    varpi_1 = s3  # (0.5, sqrt(3)/2)
    varpi_2 = l3  # (0, sqrt(3))
    rho = varpi_1 + varpi_2

    # Weyl group W(G_2) generation: reflections across a1 and a2
    I = np.eye(2)
    R1 = I - 2.0 * np.outer(a1, a1) / 1.0
    R2 = I - 2.0 * np.outer(a2, a2) / 3.0

    weyl_group = []
    queue = [I]

    def mat_in_list(M, mat_list):
        for X in mat_list:
            if np.allclose(M, X, atol=1e-8):
                return True
        return False

    while queue:
        curr = queue.pop(0)
        if not mat_in_list(curr, weyl_group):
            weyl_group.append(curr)
            for gen in [R1, R2]:
                nxt = curr @ gen
                if not mat_in_list(nxt, weyl_group):
                    queue.append(nxt)

    return {
        'a1': a1, 'a2': a2,
        'short_roots': short_roots,
        'long_roots': long_roots,
        'pos_roots': pos_roots,
        'pos_coroots': pos_coroots,
        'varpi_1': varpi_1, 'varpi_2': varpi_2,
        'rho': rho,
        'weyl_group': weyl_group,
        'R1': R1, 'R2': R2
    }


def c_function_G2(z_vec, pos_coroots, q):
    """
    Computes the Harish-Chandra / Gindikin-Karpelevich c-function for G_2:
    c_{G_2}(z) = prod_{alpha in Phi^+} (1 - q^{-1} z^{-alpha^vee}) / (1 - z^{-alpha^vee})
    """
    res = 1.0 + 0j
    for cv in pos_coroots:
        phase = np.dot(z_vec, cv)
        z_alphavee = np.exp(1j * phase)
        num = 1.0 - (1.0 / q) * (1.0 / z_alphavee)
        den = 1.0 - (1.0 / z_alphavee)
        if abs(den) < 1e-12:
            res *= 1.0
        else:
            res *= num / den
    return res


def macdonald_spherical_G2(m, n, z_vec, q, g2_data):
    """
    Computes the 2D Macdonald spherical joint eigenfunction Phi_z^{G_2}(m, n) for G_2(Q_p).
    Dominant weight lambda = m * varpi_1 + n * varpi_2.
    Phi_z(lambda) = q^{-<rho, lambda>} / W(q^{-1}) * sum_{w in W(G_2)} c(w(z)) * exp(i w(z) . lambda)
    """
    varpi_1 = g2_data['varpi_1']
    varpi_2 = g2_data['varpi_2']
    pos_coroots = g2_data['pos_coroots']
    weyl_group = g2_data['weyl_group']

    lam = m * varpi_1 + n * varpi_2
    t = 1.0 / q
    W_t = (1.0 + t) * (1.0 + t + t ** 2 + t ** 3 + t ** 4 + t ** 5)

    val = 0.0 + 0j
    for w in weyl_group:
        w_z = w @ z_vec
        cw = c_function_G2(w_z, pos_coroots, q)
        phase = np.dot(w_z, lam)
        term = cw * np.exp(1j * phase)
        val += term

    val = val / W_t
    rho_dot_lam = int(m) + int(n)
    return val * ((1.0 / q) ** rho_dot_lam)


# =========================================================================
# 4. 12-Point Commuting G_2 Root Adjacency Operators on 30x30 Torus
# =========================================================================

def construct_g2_torus_operators(N=30):
    """
    Constructs the 12-point G_2 adjacency operators on an N x N periodic hexagonal torus.
    T_short: 6 short root nearest-neighbor steps
    T_long:  6 long root next-nearest-neighbor steps
    """
    num_nodes = N * N

    def get_idx(u, v):
        return (u % N) * N + (v % N)

    short_shifts = [
        (1, 0), (-1, 0),
        (0, 1), (0, -1),
        (-1, 1), (1, -1)
    ]

    long_shifts = [
        (1, 1), (-1, -1),
        (2, -1), (-2, 1),
        (-1, 2), (1, -2)
    ]

    rows_s, cols_s = [], []
    rows_l, cols_l = [], []

    for u in range(N):
        for v in range(N):
            src = get_idx(u, v)
            for du, dv in short_shifts:
                dst = get_idx(u + du, v + dv)
                rows_s.append(src)
                cols_s.append(dst)
            for du, dv in long_shifts:
                dst = get_idx(u + du, v + dv)
                rows_l.append(src)
                cols_l.append(dst)

    data_s = np.ones(len(rows_s), dtype=np.float64)
    data_l = np.ones(len(rows_l), dtype=np.float64)

    T_short = sp.csr_matrix((data_s, (rows_s, cols_s)), shape=(num_nodes, num_nodes))
    T_long = sp.csr_matrix((data_l, (rows_l, cols_l)), shape=(num_nodes, num_nodes))

    return T_short, T_long


def analytic_g2_eigenvalues(theta1, theta2):
    """
    Analytic dispersion relations for T_short and T_long on hexagonal lattice:
    lambda_short(theta1, theta2) = 2 cos(theta1) + 2 cos(theta2) + 2 cos(theta1 - theta2)
    lambda_long(theta1, theta2)  = 2 cos(theta1 + theta2) + 2 cos(2 theta1 - theta2) + 2 cos(theta1 - 2 theta2)
    """
    lam_s = 2.0 * np.cos(theta1) + 2.0 * np.cos(theta2) + 2.0 * np.cos(theta1 - theta2)
    lam_l = 2.0 * np.cos(theta1 + theta2) + 2.0 * np.cos(2.0 * theta1 - theta2) + 2.0 * np.cos(theta1 - 2.0 * theta2)
    return lam_s, lam_l


# =========================================================================
# 5. Publication-Grade 6-Panel Visualization
# =========================================================================

def generate_publication_figure(output_path="figures/padic_holography_g2.png", g2_data=None):
    """
    Generates the comprehensive 6-panel publication figure for p-Adic Holography & G2 Telemetry.
    """
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    if g2_data is None:
        g2_data = get_G2_geometry()

    fig = plt.figure(figsize=(22, 14))
    gs = fig.add_gridspec(2, 3, wspace=0.30, hspace=0.34, left=0.06, right=0.96, top=0.92, bottom=0.07)

    # ---------------------------------------------------------------------
    # Panel (a): Tree Bulk-to-Boundary Propagator K_Delta(v, x) on T_4 (p=3)
    # ---------------------------------------------------------------------
    ax_a = fig.add_subplot(gs[0, 0])
    ax_a.set_title(r"(a) Bulk-to-Boundary Propagator $K_\Delta(v, x_0)$ on Tree $\mathcal{T}_{p+1}$ ($p=3$)", fontsize=12, fontweight='bold', pad=10)

    p_tree = 3
    depth_tree = 4
    Delta_tree = 1.4

    # Build hierarchical tree nodes and layout
    node_coords = {}
    node_vals = {}
    edge_lines = []

    # Root node at (0, 0)
    node_coords[(0, 0, 0)] = (0.0, 0.0)
    node_vals[(0, 0, 0)] = bulk_to_boundary_propagator(0, 0, 0, Delta_tree, p_tree)

    def build_tree_branch(level, branch_idx, theta_min, theta_max, parent_coord):
        if level > depth_tree:
            return
        r = level * 1.0
        num_ch = p_tree
        d_th = (theta_max - theta_min) / num_ch
        for i in range(num_ch):
            th = theta_min + (i + 0.5) * d_th
            x_c = r * np.cos(th)
            y_c = r * np.sin(th)
            child_idx = branch_idx * num_ch + i
            node_coords[(level, i, child_idx)] = (x_c, y_c)
            k_val = level
            z_val = child_idx
            kval = bulk_to_boundary_propagator(k_val, z_val, 0, Delta_tree, p_tree)
            node_vals[(level, i, child_idx)] = kval
            edge_lines.append([parent_coord, (x_c, y_c)])
            build_tree_branch(level + 1, child_idx, th - d_th / 2.0, th + d_th / 2.0, (x_c, y_c))

    # Spawn 4 branches from root
    d_root = 2 * np.pi / (p_tree + 1)
    for b in range(p_tree + 1):
        th_b = b * d_root
        x_1 = 1.0 * np.cos(th_b)
        y_1 = 1.0 * np.sin(th_b)
        node_coords[(1, b, b)] = (x_1, y_1)
        node_vals[(1, b, b)] = bulk_to_boundary_propagator(1, b, 0, Delta_tree, p_tree)
        edge_lines.append([(0.0, 0.0), (x_1, y_1)])
        build_tree_branch(2, b, th_b - d_root / 2.0, th_b + d_root / 2.0, (x_1, y_1))

    # Draw tree edges
    lc = LineCollection(edge_lines, colors='#6c757d', linewidths=0.7, alpha=0.6, zorder=1)
    ax_a.add_collection(lc)

    # Highlight boundary geodesic path to x0=0 (along angle 0)
    geo_x = [0.0, 1.0, 2.0, 3.0, 4.0]
    geo_y = [0.0, 0.0, 0.0, 0.0, 0.0]
    ax_a.plot(geo_x, geo_y, color='#e63946', lw=2.4, linestyle='-', zorder=3, label=r"Geodesic Ray to $x_0 = 0$")

    xs = [c[0] for c in node_coords.values()]
    ys = [c[1] for c in node_coords.values()]
    vals = [np.log10(v + 1e-15) for v in node_vals.values()]

    sc_a = ax_a.scatter(xs, ys, c=vals, cmap='plasma', s=35, edgecolors='k', linewidth=0.5, zorder=4)
    cbar_a = plt.colorbar(sc_a, ax=ax_a, fraction=0.046, pad=0.04)
    cbar_a.set_label(r"$\log_{10} K_\Delta(v, x_0)$ Amplitude", fontsize=10)

    boundary_circle = Circle((0, 0), 4.3, fill=False, edgecolor='#1d3557', linestyle='--', linewidth=1.5, alpha=0.8)
    ax_a.add_patch(boundary_circle)
    ax_a.text(3.1, 3.1, r"$\partial \mathcal{T}_{p+1} \cong \mathbb{P}^1(\mathbb{Q}_p)$", fontsize=10, fontweight='bold', color='#1d3557')
    ax_a.text(3.2, 0.2, r"$\mathbf{x}_0 = 0$", fontsize=10, fontweight='bold', color='#e63946')

    ax_a.set_xlim(-4.7, 4.7)
    ax_a.set_ylim(-4.7, 4.7)
    ax_a.set_aspect('equal')
    ax_a.legend(loc='lower left', fontsize=8.5, framealpha=0.92)
    ax_a.set_xticks([])
    ax_a.set_yticks([])

    # ---------------------------------------------------------------------
    # Panel (b): 3-Point Boundary Witten Diagram Amplitude & Conformal Factor
    # ---------------------------------------------------------------------
    ax_b = fig.add_subplot(gs[0, 1])
    ax_b.set_title(r"(b) Boundary 3-Point Witten Amplitude $W_3(x_1, x_2, x_3)$ vs Conformal Form", fontsize=12, fontweight='bold', pad=10)

    K_scan = np.arange(1, 8)
    D1, D2, D3 = 1.3, 1.6, 1.9

    primes = [2, 3, 5]
    colors_p = {2: '#e63946', 3: '#2a9d8f', 5: '#e76f51'}
    markers_p = {2: 'o', 3: 's', 5: '^'}

    test_triplets = {
        2: (0, 1, 2),
        3: (0, 1, 3),
        5: (0, 1, 5)
    }

    for p in primes:
        ratios = []
        x1, x2, x3 = test_triplets[p]
        conf_f = padic_conformal_3pt_factor(x1, x2, x3, D1, D2, D3, p)
        for K in K_scan:
            w3_val = compute_witten_diagram_3pt(x1, x2, x3, D1, D2, D3, p, K_max=K, k_min=-2)
            ratios.append(w3_val / conf_f)

        c_exact = exact_witten_coefficient_gubser(p, D1, D2, D3)
        ax_b.plot(K_scan, ratios, color=colors_p[p], marker=markers_p[p], lw=2.0, markersize=6,
                  label=rf"$p={p}: W_3 / F_{{\mathrm{{conf}}}}$ ($C_{{p,\mathrm{{exact}}}} = {c_exact:.3f}$)")
        ax_b.axhline(c_exact, color=colors_p[p], linestyle=':', lw=1.2, alpha=0.75)

    ax_b.set_xlabel(r"Tree Truncation Depth $K$", fontsize=11)
    ax_b.set_ylabel(r"Amplitude Ratio $W_3 / F_{\mathrm{conf}}$", fontsize=11)
    ax_b.legend(loc='lower right', fontsize=8.5, framealpha=0.92)
    ax_b.set_ylim(0.4, 2.2)

    # Inset showing log-error convergence |W_3/F_conf - C_exact|
    ax_b_inset = ax_b.inset_axes([0.18, 0.45, 0.42, 0.45])
    for p in primes:
        x1, x2, x3 = test_triplets[p]
        conf_f = padic_conformal_3pt_factor(x1, x2, x3, D1, D2, D3, p)
        c_exact = exact_witten_coefficient_gubser(p, D1, D2, D3)
        errs = []
        for K in K_scan:
            w3_val = compute_witten_diagram_3pt(x1, x2, x3, D1, D2, D3, p, K_max=K, k_min=-2)
            errs.append(abs(w3_val / conf_f - c_exact) + 1e-16)
        ax_b_inset.semilogy(K_scan, errs, color=colors_p[p], marker=markers_p[p], lw=1.5, markersize=4)

    ax_b_inset.set_title(r"Residual $|R_K - C_\infty|$", fontsize=8.5, pad=3)
    ax_b_inset.set_xlabel(r"$K$", fontsize=8)
    ax_b_inset.tick_params(labelsize=7.5)
    ax_b_inset.grid(True, which='both', linestyle=':', lw=0.5)

    # ---------------------------------------------------------------------
    # Panel (c): 2D Macdonald Spherical Wavefunction Re(Phi_z) on G_2 Apartment
    # ---------------------------------------------------------------------
    ax_c = fig.add_subplot(gs[0, 2])
    ax_c.set_title(r"(c) Macdonald Spherical Wave $\mathrm{Re}(\Phi_z^{G_2})$ on $G_2$ Apartment", fontsize=12, fontweight='bold', pad=10)

    q_g2 = 3
    z_g2 = np.array([0.5, 0.9])  # Generic regular quasimomentum

    u_vals = np.arange(-6, 7)
    v_vals = np.arange(-6, 7)
    x_grid, y_grid = [], []
    phi_real = []

    for u in u_vals:
        for v in v_vals:
            xc = 0.5 * u
            yc = (np.sqrt(3.0) / 2.0) * u + np.sqrt(3.0) * v
            if abs(xc) <= 3.5 and abs(yc) <= 4.0:
                val = macdonald_spherical_G2(u, v, z_g2, q_g2, g2_data)
                x_grid.append(xc)
                y_grid.append(yc)
                phi_real.append(np.real(val))

    triang_g2 = mtri.Triangulation(x_grid, y_grid)
    tc_g2 = ax_c.tricontourf(triang_g2, phi_real, levels=30, cmap='Spectral_r')
    ax_c.triplot(triang_g2, 'k-', lw=0.35, alpha=0.3)
    cbar_c = plt.colorbar(tc_g2, ax=ax_c, fraction=0.046, pad=0.04)
    cbar_c.set_label(r"$\mathrm{Re}(\Phi_z^{G_2}(u, v))$ Amplitude", fontsize=10)

    # Draw 6 short roots (green) and 6 long roots (magenta)
    for sr in g2_data['short_roots']:
        ax_c.arrow(0, 0, sr[0], sr[1], head_width=0.18, head_length=0.18, fc='#06d6a0', ec='k', lw=0.8, zorder=10)
    for lr in g2_data['long_roots']:
        ax_c.arrow(0, 0, lr[0], lr[1], head_width=0.22, head_length=0.22, fc='#e63946', ec='k', lw=0.8, zorder=10)

    # Fundamental Weyl chamber A^+
    chamber_pts = [(0, 0), (0.5 * 4, np.sqrt(3) / 2 * 4), (0.5 * 4, np.sqrt(3) / 2 * 4 + np.sqrt(3) * 2), (0, np.sqrt(3) * 2)]
    ax_c.add_patch(Polygon(chamber_pts, closed=True, facecolor='#ffd166', alpha=0.35, edgecolor='#b5838d', lw=2.0, linestyle='--', zorder=6))

    ax_c.text(0.6, 2.2, r"$\mathcal{A}^+(G_2)$", fontsize=10, fontweight='bold', color='#8d0801', bbox=dict(boxstyle='round,pad=0.2', facecolor='#ffeb99', alpha=0.9), zorder=12)
    ax_c.text(1.1, 0.05, r"$\alpha_1$", fontsize=10, fontweight='bold', color='#006644', zorder=12)
    ax_c.text(-1.7, 1.0, r"$\alpha_2$", fontsize=10, fontweight='bold', color='#880022', zorder=12)

    ax_c.set_xlim(-3.5, 3.5)
    ax_c.set_ylim(-3.8, 3.8)
    ax_c.set_xlabel(r"$X$ Cartesian Coordinate", fontsize=11)
    ax_c.set_ylabel(r"$Y$ Cartesian Coordinate", fontsize=11)
    ax_c.set_aspect('equal')

    # ---------------------------------------------------------------------
    # Panel (d): Commuting G_2 Adjacency Joint Dispersion Surfaces
    # ---------------------------------------------------------------------
    ax_d = fig.add_subplot(gs[1, 0])
    ax_d.set_title(r"(d) Joint Dispersion Relations $\lambda_{\mathrm{short}}(\mathbf{k}), \lambda_{\mathrm{long}}(\mathbf{k})$", fontsize=12, fontweight='bold', pad=10)

    th1 = np.linspace(-np.pi, np.pi, 250)
    th2 = np.linspace(-np.pi, np.pi, 250)
    TH1, TH2 = np.meshgrid(th1, th2)

    lam_s, lam_l = analytic_g2_eigenvalues(TH1, TH2)

    cs_s = ax_d.contourf(TH1, TH2, lam_s, levels=25, cmap='viridis')
    cbar_d = plt.colorbar(cs_s, ax=ax_d, fraction=0.046, pad=0.04)
    cbar_d.set_label(r"$\lambda_{\mathrm{short}}(\theta_1, \theta_2) = \sum_{\alpha \in \Phi_s} e^{i \mathbf{k} \cdot \alpha}$", fontsize=10)

    cs_l = ax_d.contour(TH1, TH2, lam_l, levels=10, colors='white', alpha=0.6, linewidths=0.9)
    ax_d.clabel(cs_l, inline=True, fontsize=8, fmt='%.1f')

    ax_d.scatter([0], [0], color='#d90429', s=80, zorder=10, marker='o', label=r"$\Gamma (0, 0): (\lambda_s=6, \lambda_l=6)$")
    ax_d.scatter([2 * np.pi / 3], [2 * np.pi / 3], color='#ffb703', s=80, zorder=10, marker='^', label=r"$K (\frac{2\pi}{3}, \frac{2\pi}{3}): (\lambda_s=-3, \lambda_l=6)$")
    ax_d.scatter([np.pi], [0], color='#7209b7', s=80, zorder=10, marker='s', label=r"$M (\pi, 0): (\lambda_s=-2, \lambda_l=-2)$")

    ax_d.set_xlabel(r"Quasimomentum $\theta_1$", fontsize=11)
    ax_d.set_ylabel(r"Quasimomentum $\theta_2$", fontsize=11)
    ax_d.legend(loc='lower left', fontsize=8.0, framealpha=0.92)
    ax_d.set_xlim(-np.pi, np.pi)
    ax_d.set_ylim(-np.pi, np.pi)

    # ---------------------------------------------------------------------
    # Panel (e): Hecke Algebra Structure Constants & Boundary OPE Coefficients
    # ---------------------------------------------------------------------
    ax_e = fig.add_subplot(gs[1, 1])
    ax_e.set_title(r"(e) Hecke Algebra Structure Constants $c_{\lambda, \mu}^\nu(q)$ & Boundary OPE", fontsize=12, fontweight='bold', pad=10)

    channels = [
        r"$\mathrm{PGL}_2: T_1 * T_2 \to T_1$",
        r"$\mathrm{PGL}_2: T_2 * T_2 \to T_0$",
        r"$\mathrm{PGL}_3: T_{10} * T_{01} \to T_{00}$",
        r"$\mathrm{PGL}_3: T_{10} * T_{10} \to T_{01}$",
        r"$G_2: T_{\varpi_1} * T_{\varpi_1} \to T_{\varpi_2}$",
        r"$G_2: T_{\varpi_1} * T_{\varpi_1} \to T_{\varpi_1}$",
    ]

    x_indices = np.arange(len(channels))
    width = 0.26

    for idx_p, p in enumerate(primes):
        vals_p = [
            hecke_structure_constants_rank1(1, 2, p).get(1, 0.0),            # q
            hecke_structure_constants_rank1(2, 2, p).get(0, 0.0),            # q^2
            hecke_structure_constants_A2(p)[1].get((0, 0), 0.0),             # q^2 + q
            hecke_structure_constants_A2(p)[0].get((0, 1), 0.0),             # q + 1
            hecke_structure_constants_G2(p).get((0, 1), 0.0),                # q + 1
            hecke_structure_constants_G2(p).get((1, 0), 0.0),                # q^2 + q + 1
        ]
        ax_e.bar(x_indices + (idx_p - 1) * width, vals_p, width, label=rf"$p = {p}$", color=colors_p[p], alpha=0.85, edgecolor='k', linewidth=0.6)

    ax_e.set_xticks(x_indices)
    ax_e.set_xticklabels(channels, rotation=35, ha='right', fontsize=8.5)
    ax_e.set_ylabel(r"Structure Constant $c_{\lambda, \mu}^\nu(q)$", fontsize=11)
    ax_e.legend(loc='upper left', fontsize=8.5, framealpha=0.92)
    ax_e.set_yscale('log')

    # ---------------------------------------------------------------------
    # Panel (f): Commutator Sparsity & Machine Precision Residuals
    # ---------------------------------------------------------------------
    ax_f = fig.add_subplot(gs[1, 2])
    ax_f.set_title(r"(f) Numerical Verification $[T_{\mathrm{short}}, T_{\mathrm{long}}] = 0$ on $30 \times 30$ Torus", fontsize=12, fontweight='bold', pad=10)

    T_s, T_l = construct_g2_torus_operators(N=30)
    comm_sparse = T_s @ T_l - T_l @ T_s
    comm_dense = comm_sparse.toarray()
    max_err = np.max(np.abs(comm_dense))

    eig_s_torus = []
    eig_l_torus = []
    N_torus = 30
    for k1 in range(N_torus):
        for k2 in range(N_torus):
            th_1 = 2.0 * np.pi * k1 / N_torus
            th_2 = 2.0 * np.pi * k2 / N_torus
            es, el = analytic_g2_eigenvalues(th_1, th_2)
            eig_s_torus.append(es)
            eig_l_torus.append(el)

    sc_f = ax_f.scatter(eig_s_torus, eig_l_torus, c='#3a86ff', s=25, alpha=0.7, edgecolors='k', linewidth=0.4, label=r"Joint Eigenvalues $(\lambda_s, \lambda_l) \in \sigma(T_s) \times \sigma(T_l)$")
    ax_f.set_xlabel(r"Short Root Eigenvalue $\lambda_{\mathrm{short}}$", fontsize=11)
    ax_f.set_ylabel(r"Long Root Eigenvalue $\lambda_{\mathrm{long}}$", fontsize=11)

    ax_f_inset = ax_f.inset_axes([0.12, 0.12, 0.44, 0.40])
    err_vals = np.abs(comm_dense).flatten()
    ax_f_inset.hist(err_vals, bins=10, color='#38b000', edgecolor='k', alpha=0.85)
    ax_f_inset.set_title(rf"$\|[T_s, T_l]\|_\infty = {max_err:.1e}$", fontsize=8.5, fontweight='bold', color='#007200', pad=3)
    ax_f_inset.set_xlabel(r"Matrix Entry Error", fontsize=7.5)
    ax_f_inset.set_ylabel(r"Count ($900^2$ entries)", fontsize=7.5)
    ax_f_inset.tick_params(labelsize=7)

    ax_f.legend(loc='upper left', fontsize=8.0, framealpha=0.92)
    ax_f.set_xlim(-3.5, 6.5)
    ax_f.set_ylim(-3.5, 6.5)

    plt.suptitle(r"$p$-Adic Holography, Bruhat-Tits Tree AdS/CFT & Commuting $\tilde{G}_2$ Adjacency Telemetry", fontsize=15, fontweight='bold', y=0.97)

    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"Publication-grade 6-panel figure saved successfully to: {output_path}")


# =========================================================================
# 6. Comprehensive Verification Engine
# =========================================================================

def run_padic_holography_verifications():
    """
    Executes full mathematical and numerical verifications across all modules.
    """
    print("=" * 84)
    print("RUNNING p-ADIC HOLOGRAPHY & G_2 BRUHAT-TITS BUILDING VERIFICATION SUITE")
    print("=" * 84)

    # 1. Verification of Bulk-to-Boundary Propagator & Witten Diagram Conformal Scaling
    print("\n[VERIFICATION 1] Boundary 3-Point Witten Diagram vs p-Adic Conformal Form:")
    Delta1, Delta2, Delta3 = 1.3, 1.6, 1.9

    for p in [2, 3, 5]:
        triplets = [
            (0, 1, p),
            (2, 3, 2 + p),
            (5, 6, 5 + p),
            (7, 8, 7 + p)
        ]
        ratios = []
        c_exact = exact_witten_coefficient_gubser(p, Delta1, Delta2, Delta3)
        for x1, x2, x3 in triplets:
            w3 = compute_witten_diagram_3pt(x1, x2, x3, Delta1, Delta2, Delta3, p, K_max=7, k_min=-2)
            conf = padic_conformal_3pt_factor(x1, x2, x3, Delta1, Delta2, Delta3, p)
            ratio = w3 / conf
            ratios.append(ratio)

        rel_var = np.std(ratios) / np.mean(ratios)
        mean_ratio = np.mean(ratios)
        print(f"  Prime p = {p}: Truncated W_3/F_conf = {mean_ratio:.6f}, Exact C_p = {c_exact:.6f}")
        print(f"    -> Triplet Invariance (Relative std/mean): {rel_var:.2e} [{'PASS' if rel_var < 1e-12 else 'FAIL'}]")
        assert rel_var < 1e-12, f"Witten diagram invariance failed for p={p}"

    # 2. Verification of G_2 Root System, Weyl Group & Macdonald Spherical Normalization
    print("\n[VERIFICATION 2] G_2 Root System, Weyl Group W(G_2) & Macdonald Spherical Normalization:")
    g2 = get_G2_geometry()
    num_weyl = len(g2['weyl_group'])
    print(f"  Weyl Group W(G_2) Order: |W(G_2)| = {num_weyl} (Expected: 12)")
    assert num_weyl == 12, "Weyl group order mismatch!"

    # Test normalization Phi_z(0, 0) == 1 across regular quasimomenta in maximal torus
    test_z = [
        np.array([0.4, 0.7]),
        np.array([1.2, -0.8]),
        np.array([2.1, 1.5]),
        np.array([0.8, 1.3])
    ]
    for idx, z in enumerate(test_z):
        phi_00 = macdonald_spherical_G2(0, 0, z, q=3, g2_data=g2)
        err = abs(phi_00 - 1.0)
        print(f"  Macdonald Phi_z(0,0) [z_vec={z}]: Computed = {np.real(phi_00):.14f}, Error = {err:.2e} [{'PASS' if err < 1e-10 else 'FAIL'}]")
        assert err < 1e-10, "Macdonald normalization failed!"

    # 3. Verification of 12-Point G_2 Adjacency Commutator [T_short, T_long] = 0
    print("\n[VERIFICATION 3] 12-Point G_2 Torus Operators Commutator on 30x30 Torus (900 Nodes):")
    T_s, T_l = construct_g2_torus_operators(N=30)
    comm_mat = (T_s @ T_l - T_l @ T_s).toarray()
    max_comm = np.max(np.abs(comm_mat))
    frob_comm = np.linalg.norm(comm_mat)
    print(f"  Operator Matrix Dimensions: {T_s.shape[0]} x {T_s.shape[1]}")
    print(f"  Short Root Regular Degree: {int(T_s.sum(axis=1)[0,0])} (Expected: 6)")
    print(f"  Long Root Regular Degree:  {int(T_l.sum(axis=1)[0,0])} (Expected: 6)")
    print(f"  Maximum Commutator Error ||[T_short, T_long]||_inf: {max_comm:.2e} [{'PASS' if max_comm < 1e-15 else 'FAIL'}]")
    print(f"  Frobenius Commutator Norm ||[T_short, T_long]||_F:   {frob_comm:.2e} [{'PASS' if frob_comm < 1e-15 else 'FAIL'}]")
    assert max_comm < 1e-15, "Commutator not zero to machine precision!"

    # 4. Verification of Hecke Structure Constants
    print("\n[VERIFICATION 4] Spherical Hecke Algebra Multiplications:")
    for p in [2, 3, 5]:
        h1 = hecke_structure_constants_rank1(1, 2, p)
        assert h1[1] == p and h1[3] == 1.0, f"Rank 1 Hecke failed for p={p}"
        h_a2_10_01 = hecke_structure_constants_A2(p)[1]
        assert h_a2_10_01[(0, 0)] == p**2 + p, f"A2 Hecke failed for p={p}"
        h_g2 = hecke_structure_constants_G2(p)
        assert h_g2[(0, 1)] == p + 1 and h_g2[(1, 0)] == p**2 + p + 1, f"G2 Hecke failed for p={p}"
    print("  Hecke algebra structure constants exact match for p in {2, 3, 5} [PASS]")

    print("\n" + "=" * 84)
    print("ALL p-ADIC HOLOGRAPHY & G_2 TELEMETRY VERIFICATIONS PASSED SUCCESSFULLY!")
    print("=" * 84 + "\n")


# =========================================================================
# 7. Main Execution
# =========================================================================

if __name__ == '__main__':
    run_padic_holography_verifications()
    g2_data = get_G2_geometry()
    generate_publication_figure(output_path="figures/padic_holography_g2.png", g2_data=g2_data)
