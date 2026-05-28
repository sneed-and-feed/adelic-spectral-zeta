"""
Adelic Spectral Zeta: test_sym_upper_bound.py
"""

import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla

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
    
    data_vals = np.ones(len(row_indices))
    adj = sp.coo_matrix((data_vals, (row_indices, col_indices)), shape=(N, N)).tocsr()
    return adj

def main():
    for d in range(4, 9):
        adj_d = get_schreier_graph(d)
        N_half = 1 << (d - 2)
        sym_d = adj_d[:N_half, :N_half] + adj_d[:N_half, N_half:]
        anti_d = adj_d[:N_half, :N_half] - adj_d[:N_half, N_half:]
        
        # Eigenvalues
        sym_vals, _ = spla.eigsh(sym_d, k=2, which='LA')
        anti_vals, _ = spla.eigsh(anti_d, k=1, which='LA')
        
        lambda_sym_2_d = sym_vals[0]
        lambda_anti_d = anti_vals[0]
        
        print(f"--- d = {d} ---")
        print(f"lambda_anti(G_{d}) = {lambda_anti_d:.4f}")
        print(f"lambda_sym_2(G_{d}) = {lambda_sym_2_d:.4f}")
        
        if d > 4:
            print(f"Is lambda_sym_2(G_{d}) == lambda_anti(G_{d-1})? {abs(lambda_sym_2_d - prev_anti) < 1e-4}")
            
        prev_anti = lambda_anti_d

if __name__ == '__main__':
    main()
