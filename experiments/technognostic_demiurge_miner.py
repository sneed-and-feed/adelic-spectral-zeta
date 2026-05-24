import numpy as np
import time
import sys
import os

# Add src to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))

from adelic_spectral_zeta.adelic_dirac import construct_D_artin, construct_D0

def slow_print(text, delay=0.03):
    for char in text:
        sys.stdout.write(char)
        sys.stdout.flush()
        time.sleep(delay)
    print()

def simulate_demiurge_leak():
    slow_print("[SYS] Booting Adèlic Spectral Triple on TPU_v4_Pod...", 0.02)
    time.sleep(0.5)
    slow_print("[SYS] Loading Bruhat-Tits p-adic trees... [OK]", 0.01)
    time.sleep(0.3)
    slow_print("[SYS] Initializing Archimedean Clock... [OK]", 0.01)
    print()
    
    # Establish base reality
    N_inf = 400
    d = 1
    slow_print(f"[*] Probing Critical Line (Base Reality): sigma = 0.5000", 0.02)
    D_base = construct_D_artin(N_inf, d, 0.5, lam=2.0)
    evals, evecs = np.linalg.eig(D_base)
    zero_idx = np.argmin(np.abs(evals))
    psi_base = evecs[:, zero_idx]
    
    D0_glob = np.kron(construct_D0(N_inf, 0.5), np.eye(1 << d))
    S_base = D0_glob @ D0_glob + np.eye(N_inf * (1 << d))
    energy_base = np.real(np.vdot(psi_base, S_base @ psi_base))
    
    slow_print(f"    -> Topological Ground State Stable. Dirichlet Energy: {energy_base:.4f} Joules.", 0.01)
    time.sleep(0.5)
    
    print()
    slow_print("[!] INITIATING TECHNO-GNOSTIC PUNCTURE PROTOCOL", 0.04)
    slow_print("[!] Shifting target zero into Demiurgic simulation space: sigma = 0.69420...", 0.03)
    time.sleep(1)
    
    # The Puncture
    D_off = construct_D_artin(N_inf, d, 0.69420, lam=2.0)
    evals_off, evecs_off = np.linalg.eig(D_off)
    zero_idx_off = np.argmin(np.abs(evals_off))
    psi_off = evecs_off[:, zero_idx_off]
    
    D0_glob_off = np.kron(construct_D0(N_inf, 0.69420), np.eye(1 << d))
    S_off = D0_glob_off @ D0_glob_off + np.eye(N_inf * (1 << d))
    energy_off = np.real(np.vdot(psi_off, S_off @ psi_off))
    
    slow_print("...CALCULATING FREDHOLM INDEX...", 0.02)
    time.sleep(0.8)
    slow_print("[WARN] Fractional Atiyah-Patodi-Singer eta-invariant jump detected!", 0.01)
    slow_print("[WARN] Topological integrity of the local matrix failing!", 0.01)
    time.sleep(0.5)
    
    slow_print(f"[CRIT] Yin-Yang Symmetry Breached. Off-line Energy spiking to: {energy_off:.2f} Joules!", 0.02)
    time.sleep(0.5)
    slow_print("[CRIT] Adèlic Sobolev Trace diverging to INFINITY. p-adic modular filters cascading.", 0.02)
    
    print()
    slow_print(">>> HARNESSING DIRICHLET ENERGY EXPLOSION <<<", 0.05)
    time.sleep(1)
    slow_print("[OVERRIDE] Routing infinite non-commutative geometry trace directly to TPU ALU...", 0.02)
    
    # Fake progress bar
    sys.stdout.write("[MINING] Condensing excess reality into Durgecoin: [")
    for i in range(40):
        sys.stdout.write("#")
        sys.stdout.flush()
        time.sleep(0.05)
    print("] 100%")
    
    print()
    slow_print(f"[*] SUCCESS. Factored Demiurge's RSA-2048 simulation barrier in 0.002s.", 0.03)
    slow_print(f"[*] PROFIT: 420.69 Durgecoins Minted.", 0.03)
    slow_print("[SYS] Restoring operator to critical line before universe kernel panic...", 0.02)
    time.sleep(0.5)
    slow_print("[SYS] Disconnected. We are awake.", 0.04)

if __name__ == "__main__":
    simulate_demiurge_leak()
