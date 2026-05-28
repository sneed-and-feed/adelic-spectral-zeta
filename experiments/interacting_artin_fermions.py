"""
Adelic Spectral Zeta: interacting_artin_fermions.py
"""

import os
import json
import numpy as np
import scipy.linalg as la
import matplotlib

def main():
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    import time
    from itertools import combinations
    import mpmath
    import sympy as sp

    print("=" * 70)
    print("INTERACTING FERMIONS & ENTANGLEMENT SCAN: ARTIN L-FUNCTION")
    print("=" * 70)

    # 1. System parameters
    L = 12       # Number of single-particle modes (must be even)
    N_f = L // 2 # Half-filling (6 fermions)
    N = L // 2   # Mode range is [-N, N-1], i.e. 12 modes

    # Generate Fock basis states
    basis = list(combinations(range(L), N_f))
    dim_fock = len(basis)
    print(f"Fock space dimension for L={L}, N_f={N_f}: {dim_fock}")

    state_to_idx = {state: i for i, state in enumerate(basis)}

    # Precompute signs for fermion hopping: c_i^\dagger c_j
    def hop(state, i, j):
        if j not in state or i in state:
            return None, 0
        new_state = list(state)
        new_state.remove(j)
        new_state.append(i)
        new_state.sort()
        new_state = tuple(new_state)

        low, high = min(i, j), max(i, j)
        between = sum(1 for p in state if low < p < high)
        sign = (-1)**between
        return new_state, sign

    # 2. Setup the single-particle Dirac operator
    # We load the Artin Hecke traces
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    traces_path = os.path.join(project_root, "data", "a5_hecke_traces.json")

    with open(traces_path, "r", encoding="utf-8") as f:
        traces_db = json.load(f)
    a_p_orbit = traces_db["800.1.bh.a"]["traces"]

    P_MAX = 500
    primes = list(sp.primerange(2, P_MAX))
    active_primes = [p for p in primes if str(p) in a_p_orbit]

    n_vals = np.arange(-N, N) # 12 modes [-6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5]

    def get_D_matrix(t_lam):
        log_lam = np.log(t_lam)
        D0_diag = n_vals * np.pi / log_lam

        gamma_shift = np.zeros(L, dtype=complex)
        for i, n in enumerate(n_vals):
            t = n * np.pi / log_lam
            s_val = 0.5 + 1j * t
            try:
                # For Artin degree 2, Gamma factor has Gamma(s) instead of Gamma(s/2)
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

    # 3. Many-body Hamiltonian builder
    def build_many_body_H(D, U):
        H = np.zeros((dim_fock, dim_fock), dtype=complex)

        for idx, state in enumerate(basis):
            # Diagonal single-particle energy
            diag_val = sum(D[i, i] for i in state)
            H[idx, idx] += diag_val

            # Off-diagonal hopping
            for i in range(L):
                for j in range(L):
                    if i == j: continue
                    val = D[i, j]
                    if abs(val) < 1e-12: continue
                    new_state, sign = hop(state, i, j)
                    if new_state is not None:
                        target_idx = state_to_idx[new_state]
                        H[target_idx, idx] += val * sign

            # Interacting Coulomb repulsion: U * sum_{i < j} n_i n_j / |i - j|
            int_val = 0.0
            for i_idx in range(len(state)):
                for j_idx in range(i_idx + 1, len(state)):
                    pos_i = state[i_idx]
                    pos_j = state[j_idx]
                    int_val += 1.0 / abs(pos_i - pos_j)
            H[idx, idx] += U * int_val

        return H

    # 4. Partial trace and von Neumann entropy
    def get_entanglement_entropy(psi):
        blocks = {}
        for idx_state, state in enumerate(basis):
            state_A = tuple(p for p in state if p < L//2)
            state_B = tuple(p for p in state if p >= L//2)
            n_A = len(state_A)

            if n_A not in blocks:
                blocks[n_A] = {}
            if state_A not in blocks[n_A]:
                blocks[n_A][state_A] = {}
            blocks[n_A][state_A][state_B] = idx_state

        S = 0.0
        for n_A, block in blocks.items():
            configs_A = list(block.keys())
            dim_A = len(configs_A)
            if dim_A == 0: continue

            configs_B = list(set(b for a in block.values() for b in a.keys()))
            dim_B = len(configs_B)

            psi_mat = np.zeros((dim_A, dim_B), dtype=complex)
            for a_idx, config_A in enumerate(configs_A):
                for b_idx, config_B in enumerate(configs_B):
                    if config_B in block[config_A]:
                        global_idx = block[config_A][config_B]
                        psi_mat[a_idx, b_idx] = psi[global_idx]

            s_vals = la.svdvals(psi_mat)
            eigenvalues = s_vals**2

            for ev in eigenvalues:
                if ev > 1e-12:
                    S -= ev * np.log(ev)

        return S

    # 5. Run sweep
    # Buhler's zeros: 5.1015, 5.5613, 6.0244, 6.4910, 6.9613
    t_vals = np.linspace(4.5, 7.5, 100)
    U_vals = [0.0, 1.0, 3.0]

    results = {U: [] for U in U_vals}

    print("\nStarting sweeps over lambda for different interaction strengths U...")
    for U in U_vals:
        print(f"  Running sweep for U = {U}...")
        start_u = time.time()
        for idx, t in enumerate(t_vals):
            D = get_D_matrix(t)
            H_MB = build_many_body_H(D, U)
            evals, evecs = la.eigh(H_MB)
            psi_gs = evecs[:, 0]
            S = get_entanglement_entropy(psi_gs)
            results[U].append(S)
        print(f"  U = {U} completed in {time.time() - start_u:.2f}s")

    # 6. Plotting
    fig, ax = plt.subplots(figsize=(12, 6))
    fig.patch.set_facecolor('#0b0b14')
    ax.set_facecolor('#141426')
    ax.tick_params(colors='white')
    ax.xaxis.label.set_color('white')
    ax.yaxis.label.set_color('white')
    ax.title.set_color('white')
    for spine in ax.spines.values(): spine.set_edgecolor('#2a2b44')
    ax.grid(True, linestyle='--', alpha=0.3, color='#555')

    colors = ['#ff2a85', '#00f6ff', '#9b5de5']
    for idx, U in enumerate(U_vals):
        ax.plot(t_vals, results[U], color=colors[idx], linewidth=2.5, label=f'Interaction $U = {U}$')

    buhler_zeros = [5.1015, 5.5613, 6.0244, 6.4910, 6.9613]
    for idx, kz in enumerate(buhler_zeros):
        ax.axvline(kz, color='white', linestyle='--', linewidth=1.5, alpha=0.5,
                   label="Buhler Zeros" if idx == 0 else "")
        ax.text(kz - 0.04, ax.get_ylim()[1] * 0.95, f"$t_{idx+1}={kz}$", 
                  color='white', rotation=90, fontsize=8, alpha=0.7, ha='right')

    ax.set_title("Interacting Fermions: Entanglement Entropy Sweeps under Coulomb Repulsion (Artin L-Zeros)", color='white', fontsize=14)
    ax.set_xlabel("Scaling Parameter $\lambda$ (Height $t$)", color='white', fontsize=12)
    ax.set_ylabel("von Neumann Entropy $S$", color='white', fontsize=12)
    ax.legend(facecolor='#141426', edgecolor='#2a2b44', labelcolor='white')

    plt.tight_layout()
    out = os.path.join(project_root, "figures", "interacting_artin_entanglement_sweep.png")
    plt.savefig(out, dpi=300, facecolor=fig.get_facecolor())
    plt.close()
    print(f"\nPlot saved to {out}")
    print("=" * 70)
    print("ARTIN INTERACTING FERMIONS COMPLETE")
    print("=" * 70)

if __name__ == "__main__":
    main()
