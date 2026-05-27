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
    
    # We only take rows in the first sheet (0 to N_half - 1)
    mask = adj.row < N_half
    row_vals = adj.row[mask]
    col_vals = adj.col[mask]
    
    u_vals = row_vals
    v_vals = col_vals % N_half
    same_sheet = (col_vals < N_half)
    
    data_sym = np.ones(len(u_vals))
    data_anti = np.where(same_sheet, 1.0, -1.0)
    
    sym_matrix = sp.coo_matrix((data_sym, (u_vals, v_vals)), shape=(N_half, N_half)).tocsr()
    anti_matrix = sp.coo_matrix((data_anti, (u_vals, v_vals)), shape=(N_half, N_half)).tocsr()
    
    return sym_matrix, anti_matrix

def rayleigh_quotient(M, v):
    v = np.array(v, dtype=float)
    if np.sum(v**2) == 0: return 0.0
    return v.dot(M.dot(v)) / v.dot(v)

def monna(x, bits):
    ans = 0.0
    for i in range(bits):
        if (x & (1 << i)):
            ans += 1.0 / (1 << (bits - i))
    return ans

def main():
    for d in [4, 5, 6, 7]:
        N_half = 1 << (d - 2)
        sym, anti = get_schreier_blocks_sparse(d)
        
        sym_vals, _ = spla.eigsh(sym, k=2, which='LA')
        lambda_sym_1 = sym_vals[1]
        lambda_sym_2 = sym_vals[0]
        
        anti_vals, _ = spla.eigsh(anti, k=1, which='LA')
        lambda_anti_1 = anti_vals[0]
        
        print(f"--- d = {d} ---")
        print(f"sym_1 = {lambda_sym_1:.4f}, sym_2 = {lambda_sym_2:.4f}, anti_1 = {lambda_anti_1:.4f}")
        
        # Test 1: Monna sin
        v_monna_sin = np.array([math.sin(2 * math.pi * monna(x, d-2)) for x in range(N_half)])
        # Test 2: Monna cos
        v_monna_cos = np.array([math.cos(2 * math.pi * monna(x, d-2)) for x in range(N_half)])
        # Test 3: Monna lin
        v_monna_lin = np.array([monna(x, d-2) - 0.5 for x in range(N_half)])
        
        # Test 4: regular sin
        v_sin = np.array([math.sin(2 * math.pi * x / N_half) for x in range(N_half)])
        # Test 5: period-4 sin
        v_sin4 = np.array([math.sin(math.pi * x / 2) for x in range(N_half)])
        # Test 6: period-4 cos
        v_cos4 = np.array([math.cos(math.pi * x / 2) for x in range(N_half)])
        
        guesses = {
            "monna_sin": v_monna_sin,
            "monna_cos": v_monna_cos,
            "monna_lin": v_monna_lin,
            "sin(2pi*x/N_half)": v_sin,
            "sin(pi*x/2)": v_sin4,
            "cos(pi*x/2)": v_cos4
        }
        
        for name, v in guesses.items():
            rq = rayleigh_quotient(anti, v)
            if rq > lambda_sym_2:
                print(f"WINNER: {name} (RQ = {rq:.4f})")
            else:
                pass

if __name__ == '__main__':
    main()
