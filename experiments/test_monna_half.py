"""
Adelic Spectral Zeta: test_monna_half.py
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

def monna(x, bits):
    ans = 0.0
    for i in range(bits):
        if (x & (1 << i)):
            ans += 1.0 / (1 << (bits - i))
    return ans

def main():
    for d in [4, 5, 6, 7, 8]:
        N_half = 1 << (d - 2)
        sym, anti = get_schreier_blocks(d)
        
        # symmetric eigenvalue 2
        sym_vals, _ = spla.eigsh(sym, k=2, which='LA')
        lambda_sym_2 = sym_vals[0]
        
        # max antisymmetric
        anti_vals, _ = spla.eigsh(anti, k=1, which='LA')
        anti_max = anti_vals[0]
        
        print(f"--- d = {d} ---")
        print(f"sym_2 = {lambda_sym_2:.4f}, anti_max = {anti_max:.4f}")
        
        guesses = {}
        guesses["monna_sin_pi"] = np.array([math.sin(math.pi * monna(x, d-2)) for x in range(N_half)])
        guesses["monna_cos_pi"] = np.array([math.cos(math.pi * monna(x, d-2)) for x in range(N_half)])
        
        for name, v in guesses.items():
            rq = rayleigh_quotient(anti, v)
            if rq > lambda_sym_2:
                print(f"WINNER: {name} (RQ = {rq:.4f}) > {lambda_sym_2:.4f}")
            else:
                print(f"{name} RQ = {rq:.4f}")

if __name__ == '__main__':
    main()
