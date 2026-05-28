"""
Adelic Spectral Zeta: run_harmonic_preprocessor.py
"""

import sys
import numpy as np
from adelic_spectral_zeta.erdos_similarity import (
    analyze_valuation_sectors,
    construct_generalized_cantor_set
)

def main():
    print("======================================================================")
    print("Harmonic vs Geometric Sector Collapse Comparison (Depth 1 to 4)")
    print("======================================================================")
    
    primes = [2, 3]
    # Geometric base 11 Cantor exclusions:
    cantor_sets_geom = [
        construct_generalized_cantor_set(2, 4), # Mod 4 exclusion repeated
        construct_generalized_cantor_set(3, 4)
    ]
    # Actually, construct_generalized_cantor_set handles depth based on the d argument passed.
    # To properly set up the Cantor sets for various depths, we will create them in the loop.

    max_M = 6
    depths_to_test = [1, 2, 3, 4]
    
    for d_val in depths_to_test:
        depths = [d_val, d_val]
        print(f"\n--- DEPTH d={d_val} ---")
        
        # Construct Cantor sets for this depth
        # For base 11 geometric model, standard is:
        # 2-adic: exclude odd digits (mod 4 keeps {0,1}) - wait, construct_generalized_cantor_set(2, d) handles this if default.
        cantor_sets = [
            construct_generalized_cantor_set(2, d_val),
            construct_generalized_cantor_set(3, d_val)
        ]
        
        for M in range(2, max_M + 1):
            print(f" M = {M}:")
            
            # Geometric Sequence
            scales_geom, coll_geom = analyze_valuation_sectors(
                primes=primes,
                depths=depths,
                base=11,
                M=M,
                cantor_sets=cantor_sets,
                sequence_type="geometric"
            )
            
            # Harmonic Sequence s_n = 1/(6n+1)
            scales_harm, coll_harm = analyze_valuation_sectors(
                primes=primes,
                depths=depths,
                base=11, # ignored for harmonic
                M=M,
                cantor_sets=cantor_sets,
                sequence_type="harmonic"
            )
            
            num_geom = len(scales_geom)
            num_harm = len(scales_harm)
            
            print(f"   Geometric (q=11): Allowed sectors = {num_geom:2d} | Collapsed: {coll_geom}")
            print(f"   Harmonic        : Allowed sectors = {num_harm:2d} | Collapsed: {coll_harm}")
            
            # Print explicit scales for clarity if small
            if num_harm < 5:
                print(f"      Harmonic explicit scales: {scales_harm}")
                
if __name__ == "__main__":
    main()
