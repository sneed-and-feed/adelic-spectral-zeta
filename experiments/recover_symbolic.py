"""
Adelic Spectral Zeta: recover_symbolic.py
"""

import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla
import sympy

def get_schreier_graph_sparse(d):
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

def get_schreier_blocks_sparse(d):
    N = 1 << (d - 1)
    N_half = 1 << (d - 2)
    adj = get_schreier_graph_sparse(d).tocoo()
    
    u_vals = adj.row % N_half
    v_vals = adj.col % N_half
    same_sheet = (adj.row // N_half) == (adj.col // N_half)
    
    data_anti = np.where(same_sheet, 1.0, -1.0)
    anti_matrix = sp.coo_matrix((data_anti, (u_vals, v_vals)), shape=(N_half, N_half)).tocsr()
    anti_matrix = (anti_matrix + anti_matrix.T) / 2
    return anti_matrix

def main():
    d = 6
    anti = get_schreier_blocks_sparse(d)
    val, vec = spla.eigsh(anti, k=1, which='LA')
    v = vec[:, 0]
    v = v / np.max(np.abs(v))
    
    print("Trying to identify fractional values for d=6...")
    for val in np.unique(np.round(np.abs(v), 4)):
        if val == 0: continue
        # try to match val^2
        sq = val**2
        frac = sympy.nsimplify(sq, tolerance=1e-3)
        print(f"val = {val:.4f}, val^2 = {sq:.4f} -> {frac}")
        
    print("\nAlso let's do d=5...")
    anti5 = get_schreier_blocks_sparse(5)
    val5, vec5 = spla.eigsh(anti5, k=1, which='LA')
    v5 = vec5[:, 0]
    v5 = v5 / np.max(np.abs(v5))
    for val in np.unique(np.round(np.abs(v5), 4)):
        if val == 0: continue
        sq = val**2
        frac = sympy.nsimplify(sq, tolerance=1e-3)
        print(f"val = {val:.4f}, val^2 = {sq:.4f} -> {frac}")

if __name__ == '__main__':
    main()
