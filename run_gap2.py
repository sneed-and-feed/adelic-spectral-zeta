import os
import sys
import numpy as np

sys.path.insert(0, os.path.abspath('src'))
from spectral_gap import get_schreier_blocks

prev_pf = None

for d in range(3, 13):
    weighted_matrix, sheet_diff_matrix = get_schreier_blocks(d)
    
    sym_eigs = np.linalg.eigvals(weighted_matrix).real
    anti_eigs = np.linalg.eigvals(sheet_diff_matrix).real
    
    lambda_pf = np.max(sym_eigs)
    lambda_anti = np.max(anti_eigs)
    
    gap_same_d = lambda_pf - lambda_anti
    gap_prev_d = (prev_pf - lambda_anti) if prev_pf is not None else np.nan
    
    print(f'd={d:2d}: PF(d)={lambda_pf:.5f}, Anti(d)={lambda_anti:.5f} | Gap(PF(d)-Anti(d))={gap_same_d:.5f} | Gap(PF(d-1)-Anti(d))={gap_prev_d:.5f}')
    
    prev_pf = lambda_pf
