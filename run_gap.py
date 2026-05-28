import os
import sys
import numpy as np

sys.path.insert(0, os.path.abspath('src'))
from spectral_gap import get_schreier_blocks

for d in range(3, 11):
    weighted_matrix, sheet_diff_matrix = get_schreier_blocks(d)
    
    # We want to find the top eigenvalue of each block.
    # The symmetric block (weighted_matrix) contains the PF eigenvalue of G_d
    # Wait, weighted_matrix is the symmetric block.
    sym_eigs = np.linalg.eigvals(weighted_matrix).real
    anti_eigs = np.linalg.eigvals(sheet_diff_matrix).real
    
    lambda_pf = np.max(sym_eigs)
    lambda_anti = np.max(anti_eigs)
    
    gap = lambda_pf - lambda_anti
    print(f'd={d}: lambda_PF = {lambda_pf:.6f}, lambda_anti = {lambda_anti:.6f}, gap = {gap:.6f}')
