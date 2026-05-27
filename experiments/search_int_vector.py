import numpy as np
import scipy.sparse as sp

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
    N_half = 1 << (d - 2)
    anti = get_schreier_blocks_sparse(d).toarray()
    
    # We want RQ > 5.4641
    # Random search over vectors with entries in {-3, -2, -1, 0, 1, 2, 3}
    np.random.seed(42)
    best_rq = -100
    
    for i in range(100000):
        v = np.random.randint(-3, 4, size=N_half)
        if np.all(v == 0): continue
        rq = v.dot(anti.dot(v)) / v.dot(v)
        if rq > best_rq:
            best_rq = rq
            if best_rq > 5.4641:
                print(f"WINNER FOUND! RQ = {rq:.4f}")
                print(f"v = {v}")
                break

    print(f"Best RQ from random search: {best_rq:.4f}")

if __name__ == '__main__':
    main()
