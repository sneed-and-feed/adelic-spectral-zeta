"""
Adelic Spectral Zeta: entanglement_phase_transition.py
"""

import os
import json
import numpy as np
import scipy.sparse as sp
import scipy.linalg as la
from scipy.sparse.linalg import eigsh
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import time
from itertools import combinations
import mpmath
import sympy as sp_math

from adelic_spectral_zeta.quantum import build_many_body_H_sparse, get_entanglement_entropy

print("=" * 70)
print("MACROSCOPIC ENTANGLEMENT PHASE TRANSITION: THERMODYNAMIC LIMIT (L>=14)")
print("=" * 70)

L_modes = [12, 14]
t_vals = np.linspace(4.5, 7.5, 80)
U_vals = [0.1, 3.0, 10.0]

script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, ".."))
traces_path = os.path.join(project_root, "data", "a5_hecke_traces.json")

with open(traces_path, "r", encoding="utf-8") as f:
    traces_db = json.load(f)
a_p_orbit = traces_db["800.1.bh.a"]["traces"]

P_MAX = 500
primes = list(sp_math.primerange(2, P_MAX))
active_primes = [p for p in primes if str(p) in a_p_orbit]

def get_D_matrix(t_lam, L):
    n_vals = np.arange(-L//2, L//2) if L % 2 == 0 else np.arange(-L//2, L//2 + 1)
    n_vals = n_vals[:L]
    log_lam = np.log(t_lam)
    D0_diag = n_vals * np.pi / log_lam
    
    gamma_shift = np.zeros(L, dtype=complex)
    for i, n in enumerate(n_vals):
        t = n * np.pi / log_lam
        s_val = 0.5 + 1j * t
        try:
            gamma_shift[i] = 0.5 * complex(mpmath.psi(0, s_val))
        except Exception:
            gamma_shift[i] = 0.0
            
    xi = np.zeros(L, dtype=complex)
    for p in active_primes:
        ap = float(a_p_orbit[str(p)])
        if ap == 0:
            continue
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        xi += ap * (np.log(p) / np.sqrt(p)) * np.exp(phases)
    xi += gamma_shift
    
    if np.linalg.norm(xi) > 0:
        xi_norm = xi / np.linalg.norm(xi)
    else:
        xi_norm = xi
        
    P = np.outer(xi_norm, np.conj(xi_norm))
    D = (np.eye(L) - P) @ np.diag(D0_diag) @ (np.eye(L) - P)
    return D

def main():
    results = {L: {U: [] for U in U_vals} for L in L_modes}
    
    for L in L_modes:
        N_f = L // 2
        basis = list(combinations(range(L), N_f))
        dim_fock = len(basis)
        state_to_idx = {state: i for i, state in enumerate(basis)}
        print(f"\n[+] Constructing limits for L={L} (Fock space dim: {dim_fock})")
        
        for U in U_vals:
            print(f"  -> Sweeping U = {U}")
            start_u = time.time()
            for idx, t in enumerate(t_vals):
                D = get_D_matrix(t, L)
                H_sparse = build_many_body_H_sparse(D, U, L, basis, state_to_idx)
                
                try:
                    evals, evecs = eigsh(H_sparse, k=1, which='SA')
                    psi_gs = evecs[:, 0]
                except Exception:
                    H_dense = H_sparse.toarray()
                    evals, evecs = la.eigh(H_dense)
                    psi_gs = evecs[:, 0]
                    
                S = get_entanglement_entropy(psi_gs, L, N_f, basis)
                results[L][U].append(S)
                
                if idx % 20 == 0:
                    print(f"     [t={t:.2f}] S={S:.4f}")
                    
            print(f"  -> U = {U} sweep completed in {time.time() - start_u:.2f}s")
    
    fig, axes = plt.subplots(1, len(L_modes), figsize=(14, 6))
    fig.patch.set_facecolor('#0b0b14')
    
    colors = ['#00f2fe', '#C4A6D1', '#ff0055']
    buhler_zeros = [5.1015, 5.5613, 6.0244, 6.4910, 6.9613]
    
    for ax_idx, L in enumerate(L_modes):
        ax = axes[ax_idx] if len(L_modes) > 1 else axes
        ax.set_facecolor('#141426')
        ax.tick_params(colors='white')
        ax.xaxis.label.set_color('white')
        ax.yaxis.label.set_color('white')
        ax.title.set_color('white')
        for spine in ax.spines.values(): spine.set_edgecolor('#2a2b44')
        ax.grid(True, linestyle='--', alpha=0.3, color='#555')
        
        for idx, U in enumerate(U_vals):
            ax.plot(t_vals, results[L][U], color=colors[idx], linewidth=2.5, label=f'$U = {U}$')
            
        for idx, kz in enumerate(buhler_zeros):
            ax.axvline(kz, color='white', linestyle=':', linewidth=1.0, alpha=0.5)
            
        ax.set_title(f"Modes: L={L}", color='white', fontsize=14)
        ax.set_xlabel(r"Scaling Parameter $\lambda$ (Height $t$)", color='white', fontsize=12)
        if ax_idx == 0:
            ax.set_ylabel("von Neumann Entanglement Entropy $S$", color='white', fontsize=12)
        ax.legend(facecolor='#141426', edgecolor='#2a2b44', labelcolor='white')
    
    plt.tight_layout()
    out = os.path.join(project_root, "figures", "entanglement_phase_transition_thermodynamic.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    plt.savefig(out, dpi=300, facecolor=fig.get_facecolor())
    plt.close()
    print(f"\n[*] Plot saved to {out}")
    print("=" * 70)

if __name__ == "__main__":
    main()
