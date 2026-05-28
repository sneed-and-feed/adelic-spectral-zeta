import numpy as np
from scipy.optimize import curve_fit
import scipy.sparse as sp
import scipy.sparse.linalg as spla
import os
import sys

sys.path.insert(0, os.path.abspath('src'))
from spectral_gap import get_schreier_blocks

d_vals = []
sym2_vals = []
pf_vals = []
anti_vals = []

for d in range(6, 15):
    weighted_matrix, sheet_diff_matrix = get_schreier_blocks(d)
    
    sym_eigs, _ = spla.eigsh(sp.csr_matrix(weighted_matrix), k=2, which='LA')
    anti_eigs, _ = spla.eigsh(sp.csr_matrix(sheet_diff_matrix), k=1, which='LA')
    
    lambda_pf = np.max(sym_eigs)
    sym_second = np.min(sym_eigs)
    lambda_anti = anti_eigs[0]
    
    d_vals.append(d)
    pf_vals.append(lambda_pf)
    sym2_vals.append(sym_second)
    anti_vals.append(lambda_anti)

d_vals = np.array(d_vals)
pf_vals = np.array(pf_vals)
sym2_vals = np.array(sym2_vals)
anti_vals = np.array(anti_vals)

ratios = anti_vals / pf_vals
L_vals = (1 - ratios) * (d_vals**2)

print("d | PF       | Anti     | Sym_2    | L(d)")
print("-" * 50)
for i in range(len(d_vals)):
    print(f"{d_vals[i]:2d}| {pf_vals[i]:.6f} | {anti_vals[i]:.6f} | {sym2_vals[i]:.6f} | {L_vals[i]:.6f}")

def fit_func(d, A, B):
    return A - B / d

def fit_func2(d, A, B, c):
    return A - B / (d**c)

popt, _ = curve_fit(fit_func, d_vals, L_vals)
print(f"\nFit L(d) = A - B/d: A (asymptote) = {popt[0]:.4f}, B = {popt[1]:.4f}")

try:
    popt2, _ = curve_fit(fit_func2, d_vals, L_vals)
    print(f"Fit L(d) = A - B/d^c: A = {popt2[0]:.4f}, B = {popt2[1]:.4f}, c = {popt2[2]:.4f}")
except:
    pass

