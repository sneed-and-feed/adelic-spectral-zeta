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
    
    data_anti = np.where(same_sheet, 1.0, -1.0)
    anti_matrix = sp.coo_matrix((data_anti, (u_vals, v_vals)), shape=(N_half, N_half)).tocsr()
    anti_matrix = (anti_matrix + anti_matrix.T) / 2
    return anti_matrix

def main():
    for d in [5, 6, 7]:
        N_half = 1 << (d - 2)
        anti = get_schreier_blocks_sparse(d)
        
        anti_vals, anti_vecs = spla.eigsh(anti, k=1, which='LA')
        v = anti_vecs[:, 0]
        
        # Compute FFT
        v_fft = np.fft.fft(v)
        mags = np.abs(v_fft)
        
        print(f"--- d = {d} ---")
        print("FFT Magnitudes:")
        with np.printoptions(precision=4, suppress=True):
            print(mags)
            
        # Is there a single dominant frequency?
        dom_freqs = np.where(mags > 1e-2)[0]
        print(f"Dominant frequencies: {dom_freqs}")

if __name__ == '__main__':
    main()
