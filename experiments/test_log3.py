import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla
import math

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
    
    mask = row_indices != col_indices
    row_indices = row_indices[mask]
    col_indices = col_indices[mask]
    
    data_vals = np.ones(len(row_indices))
    adj = sp.coo_matrix((data_vals, (row_indices, col_indices)), shape=(N, N)).tocsr()
    adj.data = np.ones_like(adj.data)
    return adj

def get_schreier_blocks(d):
    N_half = 1 << (d - 2)
    adj = get_schreier_graph(d)
    a00 = adj[:N_half, :N_half]
    a01 = adj[:N_half, N_half:]
    weighted_matrix = a00 + a01
    sheet_diff_matrix = a00 - a01
    return weighted_matrix, sheet_diff_matrix

def rayleigh_quotient(M, v):
    v = np.array(v, dtype=float)
    if np.sum(v**2) == 0: return 0.0
    return v.dot(M.dot(v)) / v.dot(v)

def get_log3(x, d):
    # Returns k such that x = 2^j * (-1)^s * 3^k mod N_half
    if x == 0: return 0
    N_half = 1 << (d - 2)
    
    # remove powers of 2
    x_odd = x
    while x_odd % 2 == 0:
        x_odd //= 2
        
    # check powers of 3
    val = 1
    for k in range(N_half):
        if val == x_odd or val == (N_half - x_odd):
            return k
        val = (val * 3) % N_half
    return 0

def main():
    for d in [6, 7, 8]:
        N_half = 1 << (d - 2)
        sym, anti = get_schreier_blocks(d)
        
        sym_vals, _ = spla.eigsh(sym, k=2, which='LA')
        lambda_sym_2 = sym_vals[0]
        
        L = 1 << (d - 4) # Number of powers of 3
        
        # Test vector: cos(pi * k / L) where k = log3(x)
        v_cos1 = np.zeros(N_half)
        v_cos2 = np.zeros(N_half)
        for x in range(N_half):
            k = get_log3(x, d)
            v_cos1[x] = math.cos(math.pi * k / L)
            v_cos2[x] = math.cos(2 * math.pi * k / L)
            
        rq1 = rayleigh_quotient(anti, v_cos1)
        rq2 = rayleigh_quotient(anti, v_cos2)
        
        print(f"--- d = {d} ---")
        print(f"sym_2 = {lambda_sym_2:.4f}")
        print(f"RQ(cos_pi_k/L) = {rq1:.4f}")
        print(f"RQ(cos_2pi_k/L) = {rq2:.4f}")
        
        if rq1 > lambda_sym_2: print("WINNER: cos(pi*k/L)")
        if rq2 > lambda_sym_2: print("WINNER: cos(2pi*k/L)")

if __name__ == '__main__':
    main()
