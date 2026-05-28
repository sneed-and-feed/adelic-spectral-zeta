"""
Adelic Spectral Zeta: test_subspace.py
"""

import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla
import scipy.linalg as la
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
    for d in [6, 7, 8]:
        N_half = 1 << (d - 2)
        sym, anti = get_schreier_blocks(d)
        
        sym_vals, _ = spla.eigsh(sym, k=2, which='LA')
        lambda_sym_2 = sym_vals[0]
        
        v_list = []
        # Monna
        v_list.append(np.array([math.sin(math.pi * monna(x, d-2)) for x in range(N_half)]))
        v_list.append(np.array([math.cos(math.pi * monna(x, d-2)) for x in range(N_half)]))
        v_list.append(np.array([math.sin(2 * math.pi * monna(x, d-2)) for x in range(N_half)]))
        v_list.append(np.array([math.cos(2 * math.pi * monna(x, d-2)) for x in range(N_half)]))
        
        # Euclidean
        v_list.append(np.array([math.sin(math.pi * x / N_half) for x in range(N_half)]))
        v_list.append(np.array([math.cos(math.pi * x / N_half) for x in range(N_half)]))
        v_list.append(np.array([math.sin(2 * math.pi * x / N_half) for x in range(N_half)]))
        v_list.append(np.array([math.cos(2 * math.pi * x / N_half) for x in range(N_half)]))
        v_list.append(np.array([x - N_half/2 for x in range(N_half)]))
        v_list.append(np.ones(N_half))
        
        V = np.column_stack(v_list)
        # Orthogonalize V
        Q, R = np.linalg.qr(V)
        
        # Compute Q^T A Q
        anti_dense = anti.toarray()
        A_sub = Q.T @ anti_dense @ Q
        
        sub_vals, _ = la.eigh(A_sub)
        max_sub = np.max(sub_vals)
        
        print(f"--- d = {d} ---")
        print(f"sym_2 = {lambda_sym_2:.4f}, max in subspace = {max_sub:.4f}")
        
        if max_sub > lambda_sym_2:
            print("WINNER: A linear combination works!")

if __name__ == '__main__':
    main()
