"""
Adelic Spectral Zeta: derive_anti_test_vector.py
"""

import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla

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
    
    data_sym = np.ones(len(adj.data))
    data_anti = np.where(same_sheet, 1.0, -1.0)
    
    sym_matrix = sp.coo_matrix((data_sym, (u_vals, v_vals)), shape=(N_half, N_half)).tocsr()
    anti_matrix = sp.coo_matrix((data_anti, (u_vals, v_vals)), shape=(N_half, N_half)).tocsr()
    
    # Ensure perfect symmetry for eigsh
    sym_matrix = (sym_matrix + sym_matrix.T) / 2
    anti_matrix = (anti_matrix + anti_matrix.T) / 2
    
    return sym_matrix, anti_matrix

def main():
    for d in [4, 5, 6, 7]:
        sym, anti = get_schreier_blocks_sparse(d)
        
        # eigsh finds k eigenvalues/vectors
        val, vec = spla.eigsh(anti, k=1, which='LA')
        
        v = vec[:, 0]
        # Normalize the vector so the max absolute value is 1
        v = v / np.max(np.abs(v))
        
        # Make the first non-zero element positive for consistency
        idx = np.argmax(np.abs(v))
        if v[idx] < 0:
            v = -v
            
        print(f"--- d = {d} ---")
        print(f"lambda_anti = {val[0]}")
        
        # print formatted vector
        with np.printoptions(precision=4, suppress=True, linewidth=200):
            print(f"v = {v}")
            
if __name__ == '__main__':
    main()
