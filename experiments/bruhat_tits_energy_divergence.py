"""
Adelic Spectral Zeta: bruhat_tits_energy_divergence.py
"""

import numpy as np
import argparse

def compute_bruhat_tits_energy(sigma, p=2, R_max=20):
    """
    Computes the Dirichlet energy of an Adelic eigenstate on the 
    local p-adic Bruhat-Tits tree up to radius R_max.
    
    By the Adelic Product Formula, a state that is square-integrable 
    at the infinite (real) place but sits off the critical line (sigma != 1/2) 
    must balance this by growing/decaying exponentially in the p-adic places.
    
    The wave function on the tree scales as: f(r) = p^(r * (sigma - 1/2))
    where r is the radial distance from the origin vertex.
    
    The Dirichlet energy is E = sum_{edges (u,v)} |f(u) - f(v)|^2.
    """
    
    energy = 0.0
    
    # At radius r=0, there is 1 node.
    # At radius r, there are (p+1) * p^(r-1) nodes.
    # The number of edges connecting radius r to r+1 is exactly the number of nodes at r+1.
    
    # f(r) represents the amplitude at radius r.
    # We normalize so that f(0) = 1.0.
    
    print(f"\n--- Bruhat-Tits Energy Divergence (p={p}, σ={sigma}) ---")
    print(f"{'Radius (R)':<12} | {'Amplitude f(R)':<20} | {'Shell Energy':<20} | {'Total Energy':<20}")
    print("-" * 75)
    
    for r in range(R_max):
        # The wave function amplitude
        # If sigma = 0.5, f(r) = 1.0 (a constant bounded state, though technically a plane wave)
        # If sigma != 0.5, it scales exponentially.
        f_r = p**(r * (sigma - 0.5))
        f_next = p**((r + 1) * (sigma - 0.5))
        
        # Number of edges from shell r to shell r+1
        if r == 0:
            edges = p + 1
        else:
            edges = (p + 1) * (p**(r - 1)) * p  # which is (p+1) * p^r
            
        # Energy contribution of this shell transition
        shell_energy = edges * (abs(f_next - f_r)**2)
        energy += shell_energy
        
        # Print every few steps or the first/last few
        if r < 5 or r > R_max - 3:
            print(f"{r:<12} | {f_r:<20.4e} | {shell_energy:<20.4e} | {energy:<20.4e}")
        elif r == 5:
            print(f"{'...':<12} | {'...':<20} | {'...':<20} | {'...':<20}")

    return energy

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Bruhat-Tits p-adic Energy Probe")
    parser.add_argument("--R", type=int, default=30, help="Maximum tree radius")
    args = parser.parse_args()
    
    # Test on the critical line
    compute_bruhat_tits_energy(0.5, p=2, R_max=args.R)
    
    # Test slightly off the critical line (e.g., sigma = 0.6)
    compute_bruhat_tits_energy(0.6, p=2, R_max=args.R)
    
    # Test significantly off the critical line
    compute_bruhat_tits_energy(0.9, p=2, R_max=args.R)
