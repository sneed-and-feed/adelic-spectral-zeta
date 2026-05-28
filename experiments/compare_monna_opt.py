"""
Adelic Spectral Zeta: compare_monna_opt.py
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

def monna(x, bits):
    ans = 0.0
    for i in range(bits):
        if (x & (1 << i)):
            ans += 1.0 / (1 << (bits - i))
    return ans

def main():
    d = 6
    N_half = 1 << (d - 2)
    sym, anti = get_schreier_blocks(d)
    
    anti_vals, anti_vecs = spla.eigsh(anti, k=1, which='LA')
    v_opt = anti_vecs[:, 0]
    
    v_opt = v_opt / np.max(np.abs(v_opt))
    if v_opt[1] < 0:
        v_opt = -v_opt
        
    v_monna_cos = np.array([math.cos(math.pi * monna(x, d-2)) for x in range(N_half)])
    
    print("x  | v_opt[x] | v_monna_cos[x] | monna(x)")
    for x in range(N_half):
        print(f"{x:2d} | {v_opt[x]:8.4f} | {v_monna_cos[x]:14.4f} | {monna(x, d-2):.4f}")

if __name__ == '__main__':
    main()
