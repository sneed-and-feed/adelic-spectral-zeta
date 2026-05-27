import numpy as np
import scipy.sparse as sp

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
    adj = sp.coo_matrix((data_vals, (row_indices, col_indices)), shape=(N, N)).toarray()
    return adj

def main():
    d = 6
    adj_d = get_schreier_graph(d)
    N_half = 1 << (d - 2)
    sym_d = adj_d[:N_half, :N_half] + adj_d[:N_half, N_half:]
    
    adj_d_prev = get_schreier_graph(d - 1)
    
    diff = np.abs(sym_d - adj_d_prev).max()
    print(f"Max difference between sym_d and adj_{d-1}: {diff}")
    
    if diff == 0:
        print("THE MATRICES ARE EXACTLY EQUAL ENTRY-WISE!!!")

if __name__ == '__main__':
    main()
