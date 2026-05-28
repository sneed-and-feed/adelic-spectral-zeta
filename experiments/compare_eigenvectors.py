"""
Adelic Spectral Zeta: compare_eigenvectors.py
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
    sym_matrix = (sym_matrix + sym_matrix.T) / 2
    anti_matrix = (anti_matrix + anti_matrix.T) / 2
    return sym_matrix, anti_matrix

def main():
    d = 6
    N_half = 1 << (d - 2)
    sym, anti = get_schreier_blocks_sparse(d)
    
    sym_vals, sym_vecs = spla.eigsh(sym, k=2, which='LA')
    v_sym_2 = sym_vecs[:, 0] # Second largest
    
    anti_vals, anti_vecs = spla.eigsh(anti, k=1, which='LA')
    v_anti = anti_vecs[:, 0]
    
    print("v_anti:")
    print(np.round(v_anti / np.max(np.abs(v_anti)), 4))
    print("v_sym_2:")
    print(np.round(v_sym_2 / np.max(np.abs(v_sym_2)), 4))
    
    # Let's also compute the Fiedler vector of the full antisymmetric matrix
    # wait, the antisymmetric matrix isn't a Laplacian.
    
    # What if we just output the adjacency list of the antisymmetric graph to see its structure?
    print("\nAnti-symmetric edges (weight 1 or -1):")
    anti_coo = anti.tocoo()
    edges = []
    for i, j, w in zip(anti_coo.row, anti_coo.col, anti_coo.data):
        if i <= j:
            edges.append((i, j, w))
    
    # To understand the 1D structure, let's just print the degree of each node in the anti block
    degree = np.sum(np.abs(anti_coo.data)) / 2 # Total edges
    print(f"Total edges: {degree}")

if __name__ == '__main__':
    main()
