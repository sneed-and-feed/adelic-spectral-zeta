"""
Adelic Spectral Zeta: experiments/affine_cyclotomic_classifier.py

Comprehensive Algebraic Dynamics and Cyclotomic Product Classifier for General
Affine Systems y = qx and y = qx - r (mod p^n).

This module investigates:
1. The discrete relation operator D_n^{(p,q,r)} on Z/p^n Z.
2. The monomial character action D_n chi_k = (1 + omega^{-rk}) chi_{qk}.
3. The Galois orbit weights W_C = prod_{k in C} (1 + omega^{-rk}) on (Z/p^n Z)^x / <q>.
4. Total cyclotomic product identity prod_C W_C = Phi_{p^n}(-1).
5. Exact classification of single spectral circles vs concentric symplectic tori.
6. Multi-level p-adic detail space tower decomposition.
7. Fredholm determinants, dynamical zeta functions, and trace formulas.
"""

import os
import sys
import math
import cmath
import argparse
from typing import List, Tuple, Dict, Any, Optional
import numpy as np
import matplotlib.pyplot as plt

class AffineDynamicalSystem:
    """
    Represents an affine dynamical system on Z/p^n Z with branches:
        y = q*x - r_j (mod p^n) for j = 0, ..., m-1.
    Default standard 2-branch system: y = q*x and y = q*x - r (mod p^n).
    """
    def __init__(self, p: int, n: int, q: int, r: int = 1, shifts: Optional[List[int]] = None):
        self.p = p
        self.n = n
        self.N = p**n
        self.q = q % self.N
        if math.gcd(self.q, self.p) != 1:
            raise ValueError(f"Multiplier q={q} must be coprime to prime p={p}")
        
        if shifts is not None:
            self.shifts = [s % self.N for s in shifts]
        else:
            self.shifts = [0, r % self.N]
        self.r = self.shifts[1] if len(self.shifts) > 1 else 0
        self.m_branches = len(self.shifts)
        self.omega = np.exp(2j * np.pi / self.N)

    def build_direct_matrix(self) -> np.ndarray:
        """
        Constructs the spatial N x N relation matrix D_n.
        D_n(x, y) = number of branches mapping x to y.
        """
        D = np.zeros((self.N, self.N), dtype=np.complex128)
        for x in range(self.N):
            for s in self.shifts:
                y = (self.q * x - s) % self.N
                D[x, y] += 1.0
        return D

    def compute_direct_spectrum(self) -> np.ndarray:
        """Computes eigenvalues of the spatial relation matrix D_n."""
        D = self.build_direct_matrix()
        return np.linalg.eigvals(D)

    def character_weight(self, k: int) -> complex:
        """
        Computes the Fourier character weight:
            w(k) = sum_{j=0}^{m-1} omega^{-r_j * k}.
        For standard 2-branch system: w(k) = 1 + omega^{-rk}.
        """
        return sum(self.omega**(-s * k) for s in self.shifts)

    def get_orbits_at_level(self, level: int = 0) -> List[List[int]]:
        """
        Computes the orbit decomposition of level j under multiplication by q.
        Level j corresponds to elements with v_p(k) == level.
        Level 0 is the unit group (Z/p^n Z)^x.
        """
        step = self.p**level
        elements = [x for x in range(self.N) if x % step == 0 and (x // step) % self.p != 0]
        visited = set()
        orbits = []
        for elem in elements:
            if elem not in visited:
                orb = []
                curr = elem
                while curr not in visited:
                    visited.add(curr)
                    orb.append(curr)
                    curr = (curr * self.q) % self.N
                orbits.append(orb)
        return orbits

    def compute_orbit_weights(self, level: int = 0) -> List[Tuple[List[int], complex, float]]:
        """
        For each orbit C at the given level:
        Computes:
          - orbit elements C
          - orbit product W_C = prod_{k in C} w(k)
          - circle radius R_C = |W_C|^{1 / |C|}
        """
        orbits = self.get_orbits_at_level(level)
        results = []
        for orb in orbits:
            # High precision accumulation
            w = 1.0 + 0.0j
            for k in orb:
                w *= self.character_weight(k)
            L = len(orb)
            radius = float(abs(w)**(1.0 / L)) if L > 0 else 0.0
            results.append((orb, w, radius))
        return results

    def compute_full_algebraic_spectrum(self) -> np.ndarray:
        """
        Reconstructs the complete spectrum of D_n from the character orbits
        across all p-adic valuation levels j = 0, ..., n-1 plus the zero character k=0.
        """
        eigs = [float(self.m_branches)] # k = 0 mode (Perron-Frobenius root = branch count)
        for level in range(self.n):
            level_results = self.compute_orbit_weights(level)
            for orb, w_c, radius in level_results:
                L = len(orb)
                if abs(w_c) < 1e-15:
                    for _ in range(L):
                        eigs.append(0.0 + 0.0j)
                else:
                    phase = cmath.phase(w_c)
                    for m in range(L):
                        lam = radius * cmath.exp(1j * (phase + 2.0 * math.pi * m) / L)
                        eigs.append(lam)
        return np.array(eigs, dtype=np.complex128)

    def verify_spectral_equivalence(self, tol: float = 1e-7) -> Tuple[bool, float]:
        """
        Validates exact equivalence between spatial matrix eigenvalues and algebraic character spectrum.
        """
        eigs_direct = np.sort_complex(np.round(self.compute_direct_spectrum(), 8))
        eigs_alg = np.sort_complex(np.round(self.compute_full_algebraic_spectrum(), 8))
        max_err = float(np.max(np.abs(eigs_direct - eigs_alg)))
        return (max_err < tol, max_err)

    def classify_spectral_geometry(self) -> Dict[str, Any]:
        """
        Performs exhaustive algebraic classification of the primitive spectrum (level 0).
        """
        level_0_data = self.compute_orbit_weights(level=0)
        orbits = [x[0] for x in level_0_data]
        weights = [x[1] for x in level_0_data]
        radii = [x[2] for x in level_0_data]
        
        M = len(orbits)
        L = len(orbits[0]) if orbits else 0
        
        # Check if -1 is in <q>
        curr = 1
        neg_1_in_q = False
        for _ in range(L):
            if curr == (self.N - 1):
                neg_1_in_q = True
                break
            curr = (curr * self.q) % self.N
            
        # Group unique radii
        unique_radii = []
        for r_val in radii:
            if not any(abs(r_val - u) < 1e-6 for u in unique_radii):
                unique_radii.append(r_val)
        unique_radii.sort()
        
        # Theoretical evaluation of cyclotomic product Phi_{p^n}(-1)
        if self.p == 2:
            phi_val = 0.0 if self.n == 1 else 2.0
        else:
            phi_val = 1.0
            
        total_weight_prod = np.prod(weights) if weights else 1.0
        is_single_circle = (len(unique_radii) == 1)
        
        # Determine classification regime
        if self.p == 2:
            if self.n >= 3 and self.q % 8 in (3, 5):
                regime = "Class II (2-Adic Collatz Circle: |λ| = 2^{2^{-(n-1)}})"
            elif self.n == 2:
                regime = "Class II (Base 2-Adic Circle: |λ| = √2)"
            elif self.n == 1:
                regime = "Degenerate Nilpotent (λ = 0)"
            else:
                regime = "2-Adic Concentric Tori"
        else:
            if M == 1:
                regime = "Class I (Primitive Root: Exact Unit Circle |λ| = 1)"
            elif M == 2 and not neg_1_in_q:
                regime = "Class II (QR Generator with p ≡ 3 mod 4: Exact Unit Circle |λ| = 1)"
            elif self.p % 4 == 1 and M == 2:
                regime = "Class IV (Reciprocal Golden Ratio Pair: Radii R and 1/R)"
            elif neg_1_in_q:
                regime = f"Class III (Self-Conjugate Cosets: {M} Positive Real Weights)"
            else:
                regime = f"Class V (Concentric Symplectic Tori: {len(unique_radii)} Circles)"

        return {
            'p': self.p,
            'n': self.n,
            'q': self.q,
            'r': self.r,
            'N': self.N,
            'M_orbits': M,
            'L_orbit_len': L,
            'neg_1_in_q': neg_1_in_q,
            'weights': weights,
            'radii': radii,
            'unique_radii': unique_radii,
            'is_single_circle': is_single_circle,
            'total_weight_prod': total_weight_prod,
            'theoretical_cyclotomic_prod': phi_val,
            'regime': regime
        }

    def compute_fredholm_determinant_coefficients(self, max_degree: int = 16) -> List[complex]:
        """
        Computes the Taylor expansion of log(1 / det(I - u D_n)) = sum_{m=1}^infty u^m / m * Tr(D_n^m).
        """
        traces = []
        D = self.build_direct_matrix()
        D_pow = np.eye(self.N, dtype=np.complex128)
        for m in range(1, max_degree + 1):
            D_pow = D_pow @ D
            traces.append(np.trace(D_pow))
        return traces


def run_comprehensive_classification_suite() -> List[Dict[str, Any]]:
    """
    Executes a comprehensive scan across primes p in {2, 3, 5, 7, 11, 13, 17, 19},
    various prime powers n, coprime multipliers q, and shifts r.
    """
    records = []
    cases = [
        # (p, n, q, r)
        # 2-adic Collatz and variants
        (2, 2, 3, 1), (2, 3, 3, 1), (2, 4, 3, 1), (2, 5, 3, 1),
        (2, 3, 5, 1), (2, 4, 5, 1), (2, 3, 7, 1), (2, 4, 7, 1),
        # p = 3 families
        (3, 1, 2, 1), (3, 2, 2, 1), (3, 3, 2, 1), # Primitive root q=2
        (3, 1, 1, 1), (3, 2, 4, 1), (3, 3, 4, 1), # QR generator q=4
        (3, 2, 7, 1), (3, 2, 8, 1),
        # p = 5 families
        (5, 1, 2, 1), (5, 2, 2, 1), (5, 3, 2, 1), # Primitive root q=2
        (5, 1, 4, 1), (5, 2, 4, 1), (5, 3, 4, 1), # QR generator (p=1 mod 4)
        (5, 2, 7, 1), (5, 2, 6, 1),
        # p = 7 families (p = 3 mod 4)
        (7, 1, 3, 1), (7, 2, 3, 1), # Primitive root q=3
        (7, 1, 2, 1), (7, 2, 2, 1), (7, 3, 2, 1), # QR generator q=2
        (7, 1, 4, 1), (7, 1, 6, 1),
        # p = 11 families (p = 3 mod 4)
        (11, 1, 2, 1), (11, 2, 2, 1), # Primitive root q=2
        (11, 1, 3, 1), (11, 2, 4, 1), # QR generator
        # p = 13 families (p = 1 mod 4)
        (13, 1, 2, 1), (13, 2, 2, 1), # Primitive root q=2
        (13, 1, 3, 1), (13, 1, 4, 1),
        # p = 17 families
        (17, 1, 3, 1), (17, 1, 2, 1),
        # p = 19 families (p = 3 mod 4)
        (19, 1, 2, 1), (19, 1, 4, 1),
    ]

    print("=" * 110)
    print(f"{'p':>2} {'n':>2} {'N':>4} {'q':>3} {'r':>2} | {'M':>3} {'L':>3} {'-1∈<q>':>6} | {'Regime':<42} | {'Radii':<22} | {'Prod(W)':>7} {'MaxErr':>9}")
    print("=" * 110)

    for p, n, q, r in cases:
        sys_obj = AffineDynamicalSystem(p=p, n=n, q=q, r=r)
        equiv, max_err = sys_obj.verify_spectral_equivalence()
        info = sys_obj.classify_spectral_geometry()
        info['max_spectral_error'] = max_err
        info['equivalence_passed'] = equiv
        records.append(info)
        
        rad_str = "[" + ", ".join(f"{u:.3f}" for u in info['unique_radii'][:4])
        if len(info['unique_radii']) > 4:
            rad_str += ", ..."
        rad_str += "]"
        
        prod_val = abs(info['total_weight_prod'])
        print(f"{p:2d} {n:2d} {info['N']:4d} {q:3d} {r:2d} | {info['M_orbits']:3d} {info['L_orbit_len']:3d} {str(info['neg_1_in_q']):>6} | {info['regime']:<42} | {rad_str:<22} | {prod_val:7.4f} {max_err:9.1e}")

    print("=" * 110)
    return records


def generate_spectral_circle_plots(output_dir: str = "figures"):
    """
    Renders publication-grade multi-panel figures of the exact spectral circles,
    concentric tori, and cyclotomic orbit weights.
    """
    os.makedirs(output_dir, exist_ok=True)
    plot_path = os.path.join(output_dir, "affine_spectral_circles.png")
    
    fig, axes = plt.subplots(2, 3, figsize=(18, 12))
    axes = axes.flatten()

    configurations = [
        # (p, n, q, r, title, color)
        (2, 4, 3, 1, "Collatz Family: (2, 4, 3, 1)\nExact Circle |λ| = 2^{1/8} ≈ 1.0905", "crimson"),
        (3, 2, 2, 1, "Odd Primitive Root: (3, 2, 2, 1)\nExact Unit Circle |λ| = 1.0", "navy"),
        (7, 2, 2, 1, "Odd QR Family (p ≡ 3 mod 4): (7, 2, 2, 1)\nExact Unit Circle |λ| = 1.0", "darkgreen"),
        (5, 1, 4, 1, "Golden Ratio Split (p ≡ 1 mod 4): (5, 1, 4, 1)\nConcentric Circles R = φ, 1/φ", "darkorange"),
        (13, 1, 3, 1, "Reciprocal Concentric Tori: (13, 1, 3, 1)\nConcentric Circles R ≈ 0.671, 1.489", "purple"),
        (3, 3, 4, 1, "Stratified Tower (p=3, n=3, q=4, r=1)\nAll Primitive Levels Lie on |λ| = 1.0", "teal"),
    ]

    theta = np.linspace(0, 2 * np.pi, 400)

    for idx, (p, n, q, r, title, color) in enumerate(configurations):
        ax = axes[idx]
        sys_obj = AffineDynamicalSystem(p=p, n=n, q=q, r=r)
        eigs = sys_obj.compute_direct_spectrum()
        info = sys_obj.classify_spectral_geometry()
        
        # Plot unit circle for reference
        ax.plot(np.cos(theta), np.sin(theta), 'k--', alpha=0.3, label="Unit Circle ($|z|=1$)")
        
        # Plot predicted circles
        for u_rad in info['unique_radii']:
            ax.plot(u_rad * np.cos(theta), u_rad * np.sin(theta), ':', color=color, alpha=0.8,
                    label=f"Predicted Circle (R={u_rad:.4f})")
            
        # Plot eigenvalues
        ax.scatter(eigs.real, eigs.imag, color=color, alpha=0.85, edgecolors='black', s=45, zorder=5, label="Eigenvalues $\\mathrm{spec}(D_n)$")
        
        # Mark Perron root
        ax.scatter([2.0], [0.0], color='gold', edgecolors='black', s=120, marker='*', zorder=6, label="Perron Root $\\lambda_0=2$")

        ax.set_title(title, fontsize=12, fontweight='bold')
        ax.set_xlabel("$\\mathrm{Re}(\\lambda)$", fontsize=10)
        ax.set_ylabel("$\\mathrm{Im}(\\lambda)$", fontsize=10)
        ax.grid(True, alpha=0.25)
        ax.set_aspect('equal', 'box')
        
        # Adjust limits
        max_r = max(2.2, max(info['unique_radii']) * 1.25 if info['unique_radii'] else 2.2)
        ax.set_xlim(-max_r, max_r)
        ax.set_ylim(-max_r, max_r)
        ax.legend(loc="upper right", fontsize=8)

    plt.suptitle("Exact Spectral Circles and Concentric Tori in Generalized Affine Cyclotomic Systems", fontsize=16, fontweight='bold', y=0.98)
    plt.tight_layout(rect=[0, 0.03, 1, 0.95])
    plt.savefig(plot_path, dpi=300)
    plt.close()
    print(f"\n[+] Successfully generated multi-panel spectral circle figure: {plot_path}")


def run_automated_tests():
    """
    Pytest-compatible automated assertions testing all core algebraic properties.
    """
    print("\nRunning automated algebraic test suite...")
    
    # 1. Test character monomial action
    for p, n, q, r in [(2, 3, 3, 1), (3, 2, 2, 1), (5, 1, 2, 1), (7, 1, 2, 1)]:
        sys_obj = AffineDynamicalSystem(p, n, q, r)
        passed, err = sys_obj.verify_spectral_equivalence()
        assert passed, f"Spectral equivalence failed for ({p}, {n}, {q}, {r}) with err={err}"
    print("  [✓] Character Monomial Action & Spectral Reconstruction verified.")

    # 2. Test Cyclotomic Product Identity prod_C W_C = Phi_{p^n}(-1)
    # p=2: Phi_{2^n}(-1) = 2 for n >= 2
    for n in [2, 3, 4, 5]:
        sys_obj = AffineDynamicalSystem(p=2, n=n, q=3, r=1)
        info = sys_obj.classify_spectral_geometry()
        assert abs(info['total_weight_prod'] - 2.0) < 1e-8, f"Cyclotomic product failed for 2^{n}"
    # odd p: Phi_{p^n}(-1) = 1 for all n >= 1
    for p in [3, 5, 7, 11, 13]:
        for n in [1, 2]:
            q_cand = 2 if p != 2 else 3
            if math.gcd(q_cand, p) != 1: q_cand = 3
            sys_obj = AffineDynamicalSystem(p=p, n=n, q=q_cand, r=1)
            info = sys_obj.classify_spectral_geometry()
            assert abs(info['total_weight_prod'] - 1.0) < 1e-8, f"Cyclotomic product failed for {p}^{n}"
    print("  [✓] Cyclotomic Product Identity prod_C W_C = Phi_{p^n}(-1) verified.")

    # 3. Test Exact Unit Circle Theorem for p = 3 mod 4 with QR generators
    for p in [3, 7, 11, 19]:
        # find QR generator
        N = p
        # find primitive root g
        for g in range(2, p):
            if len(set(pow(g, k, p) for k in range(1, p))) == p - 1:
                q_qr = pow(g, 2, p) # generates QR
                sys_obj = AffineDynamicalSystem(p=p, n=1, q=q_qr, r=1)
                info = sys_obj.classify_spectral_geometry()
                assert info['is_single_circle'], f"Single circle failed for QR at prime {p}"
                assert abs(info['unique_radii'][0] - 1.0) < 1e-8, f"Radius != 1.0 for QR at prime {p}"
                break
    print("  [✓] QR Exact Unit Circle Theorem (p ≡ 3 mod 4) verified.")

    # 4. Test Reciprocal Concentric Circles for p = 5, n = 1, q = 4
    sys_5 = AffineDynamicalSystem(p=5, n=1, q=4, r=1)
    info_5 = sys_5.classify_spectral_geometry()
    assert len(info_5['unique_radii']) == 2, "Failed to find 2 concentric circles for (5, 1, 4, 1)"
    r1, r2 = info_5['unique_radii']
    assert abs(r1 * r2 - 1.0) < 1e-8, "Reciprocal property R1 * R2 = 1 failed for (5, 1, 4, 1)"
    phi = (1 + math.sqrt(5)) / 2
    assert abs(r2 - phi) < 1e-5 and abs(r1 - 1/phi) < 1e-5, "Golden ratio radii failed for (5, 1, 4, 1)"
    print("  [✓] Reciprocal Golden Ratio Radii verified for (5, 1, 4, 1).")

    print("\nAll automated tests passed successfully!")


def main():
    parser = argparse.ArgumentParser(description="Affine Dynamical Systems & Cyclotomic Product Classifier")
    parser.add_argument("--sweep", action="store_true", help="Run comprehensive classification sweep")
    parser.add_argument("--plot", action="store_true", help="Generate spectral circle figures")
    parser.add_argument("--test", action="store_true", help="Run automated test suite")
    parser.add_argument("-p", type=int, default=2, help="Prime base p")
    parser.add_argument("-n", type=int, default=3, help="Power n")
    parser.add_argument("-q", type=int, default=3, help="Affine multiplier q")
    parser.add_argument("-r", type=int, default=1, help="Shift r")
    args = parser.parse_args()

    if args.test:
        run_automated_tests()
    elif args.sweep:
        run_comprehensive_classification_suite()
    elif args.plot:
        generate_spectral_circle_plots()
    else:
        # Default: run all three
        print(f"\nAnalyzing Affine System: y = {args.q}x and y = {args.q}x - {args.r} (mod {args.p}^{args.n})...")
        sys_obj = AffineDynamicalSystem(p=args.p, n=args.n, q=args.q, r=args.r)
        info = sys_obj.classify_spectral_geometry()
        equiv, max_err = sys_obj.verify_spectral_equivalence()
        print(f"Modulus N = {info['N']}, Total Orbits M = {info['M_orbits']}, Orbit Length L = {info['L_orbit_len']}")
        print(f"Regime: {info['regime']}")
        print(f"Single Circle: {info['is_single_circle']}")
        print(f"Radii: {[round(x, 5) for x in info['unique_radii']]}")
        print(f"Total Orbit Weight Product: {info['total_weight_prod']:.6f} (Theory: {info['theoretical_cyclotomic_prod']})")
        print(f"Spectral Equivalence Check: {'PASSED' if equiv else 'FAILED'} (Max Error = {max_err:.2e})")
        print("\nRunning full sweep and generating figures...")
        run_comprehensive_classification_suite()
        generate_spectral_circle_plots()
        run_automated_tests()

if __name__ == '__main__':
    main()
