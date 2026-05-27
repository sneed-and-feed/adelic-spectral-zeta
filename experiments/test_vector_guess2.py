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
    for d in [4, 5, 6, 7]:
        sym, anti = get_schreier_blocks_sparse(d)
        val, vec = spla.eigsh(anti, k=1, which='LA')
        v = vec[:, 0]
        v = v / np.max(np.abs(v))
        idx = np.argmax(np.abs(v))
        if v[idx] < 0:
            v = -v
            
        print(f"--- d = {d} ---")
        
        # multiply by various integers to see if it's rational
        for mult in [1, 2, 3, 4, 8, 16, 32]:
            v_int = v * mult
            # check if v_int is close to integer
            if np.allclose(v_int, np.round(v_int), atol=1e-3):
                print(f"Integer vector found with multiplier {mult}:")
                print(np.round(v_int).astype(int))
                break
        else:
            print("No simple integer multiplier found. Values:")
            with np.printoptions(precision=4, suppress=True):
                print(v)

if __name__ == '__main__':
    main()
