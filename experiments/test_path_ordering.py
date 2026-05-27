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

def main():
    d = 6
    sym, anti = get_schreier_blocks(d)
    anti_vals, anti_vecs = spla.eigsh(anti, k=1, which='LA')
    v = anti_vecs[:, 0]
    
    order = np.argsort(v)
    print("Sorted nodes by eigenvector value:")
    print(order)
    
    print("\nEigenvector values in sorted order:")
    print(v[order])
    
    print("\nAdjacency matrix (anti) in sorted order:")
    anti_dense = anti.toarray()
    anti_sorted = anti_dense[np.ix_(order, order)]
    for row in anti_sorted:
        print("".join(["+" if x > 0 else "-" if x < 0 else "." for x in row]))

if __name__ == '__main__':
    main()
