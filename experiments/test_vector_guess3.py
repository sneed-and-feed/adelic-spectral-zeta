import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla
import math

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

def rayleigh_quotient(M, v):
    v = np.array(v, dtype=float)
    if np.sum(v**2) == 0: return 0.0
    return v.dot(M.dot(v)) / v.dot(v)

def v2(x):
    if x == 0: return 10
    return (x & -x).bit_length() - 1

def main():
    for d in [4, 5, 6, 7]:
        N_half = 1 << (d - 2)
        sym, anti = get_schreier_blocks_sparse(d)
        
        sym_vals, _ = spla.eigsh(sym, k=2, which='LA')
        lambda_sym_2 = sym_vals[0]
        
        anti_vals, anti_vecs = spla.eigsh(anti, k=1, which='LA')
        v_opt = anti_vecs[:, 0]
        
        # Test vectors
        guesses = {}
        guesses["v2"] = np.array([v2(x) for x in range(N_half)])
        guesses["v2_even"] = np.array([1 if v2(x) % 2 == 0 else -1 for x in range(N_half)])
        guesses["x_mod_4"] = np.array([x % 4 for x in range(N_half)])
        guesses["x_mod_8"] = np.array([x % 8 for x in range(N_half)])
        
        # Look at the actual eigenvector
        print(f"--- d = {d} ---")
        print(f"sym_2 = {lambda_sym_2:.4f}, anti_max = {anti_vals[0]:.4f}")
        for name, v in guesses.items():
            rq = rayleigh_quotient(anti, v)
            if rq > lambda_sym_2:
                print(f"WINNER! RQ({name}) = {rq:.4f} > sym_2")
            else:
                print(f"RQ({name}) = {rq:.4f}")
                
        # What does v_opt look like? Let's sort it and see if it's a step function
        v_opt = v_opt / np.max(np.abs(v_opt))
        if v_opt[np.argmax(np.abs(v_opt))] < 0:
            v_opt = -v_opt
            
        print("Sorted v_opt (to see distribution of values):")
        with np.printoptions(precision=4, suppress=True):
            print(np.sort(v_opt))
            
        # Is it a function of x mod 4?
        if d == 6:
            print("v_opt values by x mod 4:")
            for m in range(4):
                vals = [v_opt[x] for x in range(N_half) if x % 4 == m]
                print(f"x % 4 == {m}: {np.round(vals, 3)}")
                
        if d == 6:
            print("v_opt values by x mod 8:")
            for m in range(8):
                vals = [v_opt[x] for x in range(N_half) if x % 8 == m]
                print(f"x % 8 == {m}: {np.round(vals, 3)}")

if __name__ == '__main__':
    main()
