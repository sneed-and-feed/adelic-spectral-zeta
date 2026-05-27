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

def main():
    for d in [4, 5, 6, 7, 8, 9, 10]:
        N_half = 1 << (d - 2)
        sym, anti = get_schreier_blocks_sparse(d)
        
        # Get top 2 symmetric eigenvalues
        sym_vals, _ = spla.eigsh(sym, k=2, which='LA')
        lambda_sym_1 = sym_vals[1] # Largest
        lambda_sym_2 = sym_vals[0] # Second largest
        
        # Get top antisymmetric eigenvalue
        anti_vals, _ = spla.eigsh(anti, k=1, which='LA')
        lambda_anti_max = anti_vals[0]
        
        # Guess 1: parity (x % 2)
        v_parity = np.array([x % 2 for x in range(N_half)])
        # Guess 2: step function
        v_step = np.array([1 if x < N_half//2 else -1 for x in range(N_half)])
        # Guess 3: linear
        v_lin = np.array([x - N_half/2 for x in range(N_half)])
        # Guess 4: fourier
        v_sin = np.array([math.sin(2 * math.pi * x / N_half) for x in range(N_half)])
        # Guess 5: alternating step
        v_alt_step = np.array([1 if (x // 2) % 2 == 0 else -1 for x in range(N_half)])
        # Guess 6: indicator of odd numbers
        v_odd = np.array([1 if x % 2 == 1 else 0 for x in range(N_half)])
        # Guess 7: indicator of x=1 mod 3?
        v_3 = np.array([1 if x % 3 == 1 else 0 for x in range(N_half)])

        print(f"--- d = {d} ---")
        print(f"sym_1 = {lambda_sym_1:.4f}, sym_2 = {lambda_sym_2:.4f}, anti_max = {lambda_anti_max:.4f}")
        
        rq_parity = rayleigh_quotient(anti, v_parity)
        rq_step = rayleigh_quotient(anti, v_step)
        rq_lin = rayleigh_quotient(anti, v_lin)
        rq_sin = rayleigh_quotient(anti, v_sin)
        rq_alt_step = rayleigh_quotient(anti, v_alt_step)
        rq_odd = rayleigh_quotient(anti, v_odd)
        
        print(f"RQ(parity) = {rq_parity:.4f}")
        print(f"RQ(step) = {rq_step:.4f}")
        print(f"RQ(lin) = {rq_lin:.4f}")
        print(f"RQ(sin) = {rq_sin:.4f}")
        print(f"RQ(alt_step) = {rq_alt_step:.4f}")
        print(f"RQ(odd) = {rq_odd:.4f}")
        
        # Which one beats sym_2?
        guesses = {
            "parity": rq_parity, "step": rq_step, "lin": rq_lin, "sin": rq_sin, "alt_step": rq_alt_step, "odd": rq_odd
        }
        winners = [name for name, val in guesses.items() if val > lambda_sym_2]
        print(f"Winners beating sym_2: {winners}")
        
if __name__ == '__main__':
    main()
