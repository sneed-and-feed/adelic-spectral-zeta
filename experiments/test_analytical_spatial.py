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
    
    # Keep multigraph edges and self-loops!
    data_vals = np.ones(len(row_indices))
    adj = sp.coo_matrix((data_vals, (row_indices, col_indices)), shape=(N, N)).tocsr()
    return adj

def rayleigh_quotient(M, v):
    v = np.array(v, dtype=float)
    if np.sum(v**2) == 0: return 0.0
    return v.dot(M.dot(v)) / v.dot(v)

def main():
    for d in [6, 8, 10, 12]:
        N = 1 << (d - 1)
        N_half = 1 << (d - 2)
        adj = get_schreier_graph(d)
        
        a00 = adj[:N_half, :N_half]
        a01 = adj[:N_half, N_half:]
        sym = a00 + a01
        anti = a00 - a01
        
        sym_vals, _ = spla.eigsh(sym, k=2, which='LA')
        lambda_sym_2 = sym_vals[0]
        
        # Test vector
        # Determine the length of the 'regular' path where W_j = 2 cos(pi 3^j / N) is approx 2
        M = int(math.log(N_half, 3)) + 1
        
        v_test = np.zeros(N_half)
        for x in range(N_half):
            val = 0
            for j in range(M):
                u_j = math.sin(math.pi * (j + 1) / (M + 1))
                freq = pow(3, j, N)
                # We know the phase is theta_j = - (pi / 2N) * (3^j - 1)
                phase = (2 * math.pi * freq * x / N) - (math.pi / (2 * N)) * (freq - 1)
                val += u_j * math.cos(phase)
            v_test[x] = val
            
        rq = rayleigh_quotient(anti, v_test)
        
        print(f"--- d = {d} ---")
        print(f"sym_2 = {lambda_sym_2:.4f}")
        print(f"RQ(v_test) = {rq:.4f}")
        if rq > lambda_sym_2:
            print("WINNER!")

if __name__ == '__main__':
    main()
