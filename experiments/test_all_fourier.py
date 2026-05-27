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
    
    sym_matrix = sp.coo_matrix((np.ones(len(adj.data)), (u_vals, v_vals)), shape=(N_half, N_half)).tocsr()
    anti_matrix = sp.coo_matrix((np.where(same_sheet, 1.0, -1.0), (u_vals, v_vals)), shape=(N_half, N_half)).tocsr()
    
    sym_matrix = (sym_matrix + sym_matrix.T) / 2
    anti_matrix = (anti_matrix + anti_matrix.T) / 2
    
    return sym_matrix, anti_matrix

def rayleigh_quotient(M, v):
    v = np.array(v, dtype=float)
    if np.sum(v**2) == 0: return 0.0
    return v.dot(M.dot(v)) / v.dot(v)

def main():
    for d in [5, 6, 7]:
        N_half = 1 << (d - 2)
        sym, anti = get_schreier_blocks_sparse(d)
        
        sym_vals, _ = spla.eigsh(sym, k=2, which='LA')
        lambda_sym_2 = sym_vals[0]
        anti_vals, _ = spla.eigsh(anti, k=1, which='LA')
        anti_max = anti_vals[0]
        
        print(f"--- d = {d} ---")
        print(f"sym_2 = {lambda_sym_2:.4f}, anti_max = {anti_max:.4f}")
        
        for k in range(N_half // 2 + 1):
            v_cos = np.array([math.cos(2 * math.pi * k * x / N_half) for x in range(N_half)])
            v_sin = np.array([math.sin(2 * math.pi * k * x / N_half) for x in range(N_half)])
            
            rq_cos = rayleigh_quotient(anti, v_cos)
            rq_sin = rayleigh_quotient(anti, v_sin)
            
            if rq_cos > lambda_sym_2: print(f"WINNER: cos(2pi*{k}x/{N_half}), RQ={rq_cos:.4f}")
            if rq_sin > lambda_sym_2: print(f"WINNER: sin(2pi*{k}x/{N_half}), RQ={rq_sin:.4f}")
            
if __name__ == '__main__':
    main()
