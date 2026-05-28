import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla
import os
import sys
import time

sys.path.insert(0, os.path.abspath('src'))
from spectral_gap import get_schreier_blocks

print("d | PF | Anti | L_d | Is_Anti_2nd")
print("-" * 50)

for d in range(6, 21):
    t0 = time.time()
    weighted_matrix, sheet_diff_matrix = get_schreier_blocks(d)
    
    # We only need the top 2 eigenvalues for the symmetric block 
    # to see if the second eigenvalue of sym is > or < top of anti
    sym_sparse = sp.csr_matrix(weighted_matrix)
    anti_sparse = sp.csr_matrix(sheet_diff_matrix)
    
    # get top 2 eigenvalues
    # we use 'LA' (Largest Algebraic)
    sym_eigs, _ = spla.eigsh(sym_sparse, k=2, which='LA')
    anti_eigs, _ = spla.eigsh(anti_sparse, k=1, which='LA')
    
    lambda_pf = np.max(sym_eigs)
    sym_second = np.min(sym_eigs) # since k=2, min is the 2nd largest
    lambda_anti = anti_eigs[0]
    
    rho = lambda_anti / lambda_pf
    L = (1 - rho) * (d**2)
    
    # Is lambda_anti the 2nd largest eigenvalue of the entire graph?
    # It is if lambda_anti > sym_second
    is_anti_2nd = lambda_anti > sym_second
    
    print(f"{d:2d} | {lambda_pf:.6f} | {lambda_anti:.6f} | {L:.6f} | {is_anti_2nd} (t={time.time()-t0:.2f}s)")
