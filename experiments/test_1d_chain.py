import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla
import scipy.linalg as la

def get_schreier_graph(d, remove_self_loops=False):
    N = 1 << (d - 1)
    inv3 = pow(3, -1, N)
    rows = np.arange(N)
    cols1 = (3 * rows) % N
    cols2 = (3 * rows - 1) % N
    cols3 = (inv3 * rows) % N
    cols4 = (inv3 * (rows + 1)) % N
    
    row_indices = np.concatenate([rows, rows, rows, rows])
    col_indices = np.concatenate([cols1, cols2, cols3, cols4])
    
    if remove_self_loops:
        mask = row_indices != col_indices
        row_indices = row_indices[mask]
        col_indices = col_indices[mask]
        
    data_vals = np.ones(len(row_indices))
    adj = sp.coo_matrix((data_vals, (row_indices, col_indices)), shape=(N, N)).tocsr()
    # DO NOT force adj.data to ones, allow multigraph edges to sum!
    # adj.data = np.ones_like(adj.data)
    return adj

def main():
    d = 6
    N = 1 << (d - 1)
    N_half = 1 << (d - 2)
    
    adj_with = get_schreier_graph(d, remove_self_loops=False)
    adj_without = get_schreier_graph(d, remove_self_loops=True)
    
    a00_w = adj_with[:N_half, :N_half]
    a01_w = adj_with[:N_half, N_half:]
    anti_w = a00_w - a01_w
    
    a00_wo = adj_without[:N_half, :N_half]
    a01_wo = adj_without[:N_half, N_half:]
    anti_wo = a00_wo - a01_wo
    
    anti_w_vals, _ = spla.eigsh(anti_w, k=1, which='LA')
    anti_wo_vals, _ = spla.eigsh(anti_wo, k=1, which='LA')
    
    print(f"Max eigenvalue WITH self-loops and multigraph: {anti_w_vals[0]:.4f}")
    print(f"Max eigenvalue WITHOUT self-loops and multigraph: {anti_wo_vals[0]:.4f}")

if __name__ == '__main__':
    main()
