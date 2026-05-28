"""
Adelic Spectral Zeta: test_sgn.py
"""

import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla
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
    for d in [6, 7, 8, 9]:
        N_half = 1 << (d - 2)
        sym, anti = get_schreier_blocks(d)
        
        sym_vals, _ = spla.eigsh(sym, k=2, which='LA')
        lambda_sym_2 = sym_vals[0]
        
        anti_vals, anti_vecs = spla.eigsh(anti, k=1, which='LA')
        anti_max = anti_vals[0]
        v_opt = anti_vecs[:, 0]
        
        v_sgn = np.sign(v_opt)
        rq_sgn = rayleigh_quotient(anti, v_sgn)
        
        print(f"--- d = {d} ---")
        print(f"sym_2 = {lambda_sym_2:.4f}, anti_max = {anti_max:.4f}")
        print(f"RQ(sgn(v_opt)) = {rq_sgn:.4f}")
        
        if rq_sgn > lambda_sym_2:
            print("WINNER: sgn(v_opt)!")

if __name__ == '__main__':
    main()
