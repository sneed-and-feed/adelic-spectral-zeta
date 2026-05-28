"""
Adelic Spectral Zeta: check_large_d.py
"""

import numpy as np

def test_large_d():
    # As d -> infinity, W_j -> 2 for any fixed j.
    # The limit of the Rayleigh quotient for a given L is the RQ on a path graph of length L with weight 2.
    
    for L in range(2, 10):
        # max eigenvalue of path graph length L is 2 * cos(pi / (L + 1))
        # but our hopping is W=2, so it's 4 * cos(pi / (L + 1))
        lim_rq = 4 * np.cos(np.pi / (L + 1))
        print(f"L={L}, Limiting RQ = {lim_rq:.4f}")
        
if __name__ == '__main__':
    test_large_d()
