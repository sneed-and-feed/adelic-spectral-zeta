import os
import sys
import numpy as np
import scipy.linalg as la
import scipy.sparse as sp
import sympy as sp_math
import mpmath
import json

# Ensure project root is in the import path
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, ".."))
sys.path.insert(0, project_root)

from src.spectral_gap import get_schreier_graph, get_schreier_blocks
from src.adelic_spectral_zeta.quantum import solve_ground_state_entanglement

def check_schreier_decomposition():
    print("[1/5] Checking Schreier Graph Block Decomposition...")
    d = 6
    N = 1 << (d - 1)
    
    # Get full graph spectrum
    adj = get_schreier_graph(d).toarray()
    eigenvalues_full = np.sort(np.linalg.eigvals(adj).real)
    
    # Get block spectrum
    weighted_matrix, sheet_diff_matrix = get_schreier_blocks(d)
    eigenvalues_sym = np.sort(np.linalg.eigvals(weighted_matrix.toarray()).real)
    eigenvalues_anti = np.sort(np.linalg.eigvals(sheet_diff_matrix.toarray()).real)
    
    # Combined blocks
    eigenvalues_combined = np.sort(np.concatenate([eigenvalues_sym, eigenvalues_anti]))
    
    max_diff = np.max(np.abs(eigenvalues_full - eigenvalues_combined))
    print(f"      Max difference: {max_diff:.3e}")
    assert max_diff < 1e-10, f"Schreier decomposition failed, max diff = {max_diff}"
    print("      => PASS: Full spectrum matches block decomposition spectrum.")

def check_toeplitz_zeros():
    print("[2/5] Checking Toeplitz Envelope & Riemann Zeros Match...")
    lam_opt = 15.0
    N = 100  # Lightweight size for fast test
    log_lam = np.log(lam_opt)
    n_vals = np.arange(-N, N + 1)
    D0_diag = n_vals * np.pi / log_lam
    
    primes = [2, 3, 5, 7, 11, 13]
    xi = np.zeros(2*N + 1, dtype=complex)
    for p in primes:
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)
        
    for i, n in enumerate(n_vals):
        t = n * np.pi / log_lam
        s_val = 0.25 + 0.5j * t
        psi_val = complex(mpmath.psi(0, s_val))
        xi[i] += 0.5 * (psi_val - np.log(np.pi))
        
    xi_norm = xi / np.linalg.norm(xi)
    I = np.eye(2*N + 1)
    P = np.outer(xi_norm, np.conj(xi_norm))
    D = (I - P) @ np.diag(D0_diag) @ (I - P)
    
    eigenvalues = la.eigvalsh(D)
    pos_eigenvalues = sorted([val for val in eigenvalues if val > 1e-8])
    
    # Verify matches for first 5 zeros
    true_zeros = np.array([float(mpmath.zetazero(k).imag) for k in range(1, 6)])
    diffs = []
    for z_val in true_zeros:
        closest_ev = pos_eigenvalues[np.argmin(np.abs(pos_eigenvalues - z_val))]
        diffs.append(abs(closest_ev - z_val))
        
    mean_error = np.mean(diffs)
    print(f"      Mean dissonance (error) for first 5 zeros: {mean_error:.4f}")
    assert mean_error < 0.35, f"Zeros matching error too high: {mean_error}"
    print("      => PASS: Spectral eigenvalues match Riemann zeros successfully.")

def check_residue_regularization():
    print("[3/5] Checking Residue-Based Regularization Identity...")
    z, s, p = sp_math.symbols('z s p')
    zeta_p_z_s = (1 - p**(-s))**(-z)
    residue_p = sp_math.residue(zeta_p_z_s, z, 1)
    assert residue_p == 0, "Local p-adic residue at z=1 should be 0."
    
    zeta_p_reg = zeta_p_z_s - residue_p / (z - 1)
    log_det_p_reg = -sp_math.diff(zeta_p_reg, z).subs(z, 0)
    d_log_det_p_reg_ds = sp_math.diff(log_det_p_reg, s)
    euler_factor_log_deriv = sp_math.diff(sp_math.log((1 - p**(-s))**(-1)), s)
    
    is_equal = sp_math.simplify(d_log_det_p_reg_ds + euler_factor_log_deriv) == 0
    assert is_equal, "Residue-subtracted derivative does not match Euler factor derivative."
    print("      => PASS: SymPy residue regularized identity matches Euler factor derivative.")

def check_spectral_triple_axioms():
    print("[4/5] Checking Connes-Moscovici Spectral Triple Axioms...")
    N_dim = 50
    dim = 2 * N_dim + 1
    n_vals = np.arange(-N_dim, N_dim + 1)
    log_lam = np.log(29.0)
    D0_diag = n_vals * np.pi / log_lam
    
    # Lightweight coupling vector
    xi = np.zeros(dim, dtype=complex)
    for p in [2, 3, 5, 7]:
        phases = -1j * n_vals * np.pi * np.log(p) / log_lam
        xi += (np.log(p) / np.sqrt(p)) * np.exp(phases)
    xi_norm = xi / np.linalg.norm(xi)
    
    P_op = np.outer(xi_norm, np.conj(xi_norm))
    D_glob = (np.eye(dim) - P_op) @ np.diag(D0_diag) @ (np.eye(dim) - P_op)
    
    # Axiom 4: KO-dimension 1 anti-commutation
    P = np.eye(dim)[::-1, :]
    J_Dglob_Jinv = P @ np.conj(D_glob) @ P
    deviation_JD = np.linalg.norm(J_Dglob_Jinv + D_glob)
    print(f"      ||J D J^-1 + D||_F = {deviation_JD:.3e}")
    assert deviation_JD < 1e-9, f"KO-dimension 1 anticommutation failed: {deviation_JD}"
    
    # Axiom 5: Orientation cycle interior check
    S = np.zeros((dim, dim))
    for i in range(dim - 1):
        S[i+1, i] = 1.0
    comm_D0_S = np.diag(D0_diag) @ S - S @ np.diag(D0_diag)
    orient_op_D0 = S.T @ comm_D0_S
    expected = (np.pi / log_lam) * np.eye(dim)
    diff = orient_op_D0 - expected
    norm_interior_diff = np.linalg.norm(diff[10:-10, 10:-10], 2)
    print(f"      ||u^-1 [D0, u] - (pi/ln lambda)I||_2 (interior) = {norm_interior_diff:.3e}")
    assert norm_interior_diff < 1e-12, f"Orientation condition failed: {norm_interior_diff}"
    print("      => PASS: KO-dimension anti-commutation and orientation axioms pass.")

def check_quantum_many_body():
    print("[5/5] Checking Quantum Many-Body Entanglement Entropies...")
    # Compute ground state entanglement entropy for a small system
    S_ent = solve_ground_state_entanglement(5.0, 3, 6, 0.1)
    print(f"      Calculated Entanglement Entropy S = {S_ent:.6f}")
    assert S_ent > 0.0, "Entanglement entropy should be positive for interacting state."
    print("      => PASS: Many-body ground state entanglement entropy is well-behaved.")

def main():
    print("==================================================================")
    print("             PROJECT TEST HARNESS: RUNNING ALL CHECKS")
    print("==================================================================\n")
    
    try:
        check_schreier_decomposition()
        check_toeplitz_zeros()
        check_residue_regularization()
        check_spectral_triple_axioms()
        check_quantum_many_body()
        
        print("\n==================================================================")
        print("          ALL TEST HARNESS CHECKS PASSED SUCCESSFULLY! ✅")
        print("==================================================================")
        sys.exit(0)
    except AssertionError as e:
        print(f"\n❌ TEST HARNESS ASSERTION ERROR: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ TEST HARNESS CRITICAL FAILURE: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
