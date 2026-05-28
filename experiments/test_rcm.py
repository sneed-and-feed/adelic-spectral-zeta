"""
Adelic Spectral Zeta: test_rcm.py
"""

import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla
import scipy.sparse.csgraph as csgraph
import math

def get_schreier_graph(d):
    N = 1 << (d - 1)
    inv3 = pow(3, -1, N)
    rows = np.arange(N)
    cols1 = (3 * rows) % N
    cols2 = (3 * rows - 1) % N
    cols3 = (inv3 * rows) % N
    cols4 = (inv3 * (rows + 1)) % N
    
    row_indices = np.concatenate([rows, rows, rows, rows])
    col_indices = np.concatenate([cols1, cols2, cols3, cols4])
    
    mask = row_indices != col_indices
    row_indices = row_indices[mask]
    col_indices = col_indices[mask]
    
    data_vals = np.ones(len(row_indices))
    adj = sp.coo_matrix((data_vals, (row_indices, col_indices)), shape=(N, N)).tocsr()
    adj.data = np.ones_like(adj.data)
    return adj

def get_schreier_blocks(d):
    N_half = 1 << (d - 2)
    adj = get_schreier_graph(d)
    a00 = adj[:N_half, :N_half]
    a01 = adj[:N_half, N_half:]
    weighted_matrix = a00 + a01
    sheet_diff_matrix = a00 - a01
    return weighted_matrix, sheet_diff_matrix

def rayleigh_quotient(M, v):
    v = np.array(v, dtype=float)
    if np.sum(v**2) == 0: return 0.0
    return v.dot(M.dot(v)) / v.dot(v)

def main():
    d = 7
    N_half = 1 << (d - 2)
    sym, anti = get_schreier_blocks(d)
    
    sym_vals, _ = spla.eigsh(sym, k=2, which='LA')
    lambda_sym_2 = sym_vals[0]
    
    anti_abs = np.abs(anti)
    perm = csgraph.reverse_cuthill_mckee(anti_abs)
    
    v_cos = np.zeros(N_half)
    for i in range(N_half):
        v_cos[perm[i]] = math.cos(math.pi * i / N_half)
        
    rq = rayleigh_quotient(anti, v_cos)
    
    print(f"--- d = {d} ---")
    print(f"sym_2 = {lambda_sym_2:.4f}")
    print(f"RQ(rcm_cos) = {rq:.4f}")
    
    if rq > lambda_sym_2:
        print("WINNER: RCM Ordering works!")

if __name__ == '__main__':
    main()
