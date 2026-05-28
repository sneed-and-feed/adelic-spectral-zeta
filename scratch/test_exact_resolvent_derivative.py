import os
import json
import numpy as np
import sympy as sp
import mpmath
import scipy.linalg as la

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    
    traces_path = os.path.join(project_root, "data", "a5_hecke_traces.json")
    with open(traces_path, "r", encoding="utf-8") as f:
        traces_db = json.load(f)
    a_p_orbit = traces_db["800.1.bh.a"]["traces"]
    
    exact_zeros = np.array([5.128673, 5.646348, 6.115696, 6.685053, 7.101472])
    derivatives = np.array([26.786862, 9.087135, 2.567694, 0.922821, 0.791152])
    
    P_MAX = 500
    primes = list(sp.primerange(2, P_MAX))
    active_primes = [p for p in primes if str(p) in a_p_orbit]
    
    L = 12
    n_vals = np.arange(-L//2, L//2)
    
    print("=" * 60)
    print("TESTING EXACT RESOLVENT DERIVATIVE AT THE ZEROS")
    print("=" * 60)
    
    G_vals_real_denom = []
    G_vals_complex_denom = []
    G_vals_complex_with_half = []
    
    for tz in exact_zeros:
        log_lam = np.log(tz)
        lambda_n = n_vals * np.pi / log_lam
        
        # Archimedean shift
        gamma_shift = np.zeros(L, dtype=complex)
        for i, n in enumerate(n_vals):
            t = n * np.pi / log_lam
            s_val = 0.5 + 1j * t
            try:
                gamma_shift[i] = 0.5 * complex(mpmath.psi(0, s_val))
            except:
                gamma_shift[i] = 0.0
                
        # Coupling vector xi
        xi = np.zeros(L, dtype=complex)
        for p in active_primes:
            ap = float(a_p_orbit[str(p)])
            if ap == 0: continue
            phases = -1j * n_vals * np.pi * np.log(p) / log_lam
            xi += ap * (np.log(p) / np.sqrt(p)) * np.exp(phases)
        xi += gamma_shift
        xi_norm = xi / np.linalg.norm(xi)
        
        # Compute exact sum: sum_n |xi_norm_n|^2 / (lambda_n - tz)**2 (real)
        g_real = np.sum(np.abs(xi_norm)**2 / (lambda_n - tz)**2)
        G_vals_real_denom.append(g_real)
        
        # Compute exact sum: sum_n |xi_norm_n|^2 / (lambda_n - 1j*tz)**2 (complex no half)
        g_complex = np.sum(np.abs(xi_norm)**2 / (lambda_n - 1j*tz)**2)
        G_vals_complex_denom.append(g_complex)
        
        # Compute exact sum: sum_n |xi_norm_n|^2 / (lambda_n - 0.5 - 1j*tz)**2 (complex with half)
        g_complex_half = np.sum(np.abs(xi_norm)**2 / (lambda_n - 0.5 - 1j*tz)**2)
        G_vals_complex_with_half.append(g_complex_half)
        
    G_vals_real_denom = np.array(G_vals_real_denom)
    G_vals_complex_denom = np.array(G_vals_complex_denom)
    G_vals_complex_with_half = np.array(G_vals_complex_with_half)
    
    H_vals = []
    for tz in exact_zeros:
        gamma_val = float(abs(mpmath.gamma(mpmath.mpc(0.5, tz))))
        h_val = (800.0 ** 0.25) * (2.0 * np.pi) ** (-0.5) * gamma_val
        H_vals.append(h_val)
    H_vals = np.array(H_vals)
    
    print("\n1. Real Denominator (lambda_n - tz)**2:")
    print(f"   G_vals: {G_vals_real_denom}")
    # Compute C_mag = G_vals / (H_vals * derivatives)
    C_mag_real = G_vals_real_denom / (H_vals * derivatives)
    print(f"   C_mag : {C_mag_real}")
    print(f"   C_mag std/mean: {np.std(C_mag_real)/np.mean(C_mag_real):.4f}")
    
    print("\n2. Complex Denominator (lambda_n - i*tz)**2:")
    print(f"   G_vals: {G_vals_complex_denom}")
    C_mag_complex = np.abs(G_vals_complex_denom) / (H_vals * derivatives)
    print(f"   C_mag : {C_mag_complex}")
    print(f"   C_mag std/mean: {np.std(C_mag_complex)/np.mean(C_mag_complex):.4f}")
    
    print("\n3. Complex with Half Denominator (lambda_n - 0.5 - i*tz)**2:")
    print(f"   G_vals: {G_vals_complex_with_half}")
    C_mag_complex_half = np.abs(G_vals_complex_with_half) / (H_vals * derivatives)
    print(f"   C_mag : {C_mag_complex_half}")
    print(f"   C_mag std/mean: {np.std(C_mag_complex_half)/np.mean(C_mag_complex_half):.4f}")

if __name__ == "__main__":
    main()
