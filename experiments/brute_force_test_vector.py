import numpy as np
import scipy.sparse as sp
import itertools

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
    
    anti_matrix = sp.coo_matrix((data_anti, (u_vals, v_vals)), shape=(N_half, N_half)).tocsr()
    anti_matrix = (anti_matrix + anti_matrix.T) / 2
    return anti_matrix

def main():
    d = 6
    N_half = 1 << (d - 2) # 16
    anti = get_schreier_blocks_sparse(d).toarray()
    
    print(f"Brute forcing all 2^{N_half} vectors for d={d}...")
    
    # We can fix the first bit to 1 by symmetry
    best_val = -1000
    best_v = None
    
    # pre-generate vectors
    for bits in itertools.product([-1, 1], repeat=N_half - 1):
        v = np.array((1,) + bits)
        val = v.dot(anti.dot(v))
        if val > best_val:
            best_val = val
            best_v = v
            
    print(f"Max v^T A v = {best_val}")
    print(f"Max Rayleigh Quotient = {best_val / N_half}")
    print(f"Best vector: {best_v}")
    
    print("\nLooking for any vectors that beat sym_2 (RQ > 5.4641)...")
    target_val = 5.4641 * N_half
    winners = []
    for bits in itertools.product([-1, 1], repeat=N_half - 1):
        v = np.array((1,) + bits)
        val = v.dot(anti.dot(v))
        if val > target_val:
            winners.append((val, v))
            
    winners.sort(key=lambda x: x[0], reverse=True)
    for val, v in winners[:10]:
        print(f"RQ = {val/N_half:.4f}, v = {v}")

if __name__ == '__main__':
    main()
