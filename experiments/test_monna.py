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

def rayleigh_quotient(M, v):
    v = np.array(v, dtype=float)
    if np.sum(v**2) == 0: return 0.0
    return v.dot(M.dot(v)) / v.dot(v)

def monna(x, bits):
    # reverse the `bits` lowest bits of x and treat as a fraction
    ans = 0.0
    for i in range(bits):
        if (x & (1 << i)):
            ans += 1.0 / (1 << (bits - i))
    return ans

def main():
    d = 8
    N_half = 1 << (d - 2)
    sym, anti = get_schreier_blocks_sparse(d)
    
    anti_vals, anti_vecs = spla.eigsh(anti, k=1, which='LA')
    v = anti_vecs[:, 0]
    
    import math
    
    # Try different test vectors using the Monna map
    guesses = {}
    guesses["monna_lin"] = np.array([monna(x, d-2) - 0.5 for x in range(N_half)])
    guesses["monna_sin"] = np.array([math.sin(2 * math.pi * monna(x, d-2)) for x in range(N_half)])
    guesses["monna_cos"] = np.array([math.cos(2 * math.pi * monna(x, d-2)) for x in range(N_half)])
    
    # Let's print out the actual values of v vs monna
    coords = [(monna(x, d-2), v[x]) for x in range(N_half)]
    coords.sort()
    
    print("Monna(x) vs v[x] (first 20 sorted by Monna):")
    for val_monna, val_v in coords[:20]:
        print(f"Monna: {val_monna:.4f}, v: {val_v:.4f}")
        
    print("\nRayleigh Quotients:")
    sym_vals, _ = spla.eigsh(sym, k=2, which='LA')
    lambda_sym_2 = sym_vals[0]
    print(f"sym_2 = {lambda_sym_2:.4f}, anti_max = {anti_vals[0]:.4f}")
    
    for name, guess in guesses.items():
        rq = rayleigh_quotient(anti, guess)
        if rq > lambda_sym_2:
            print(f"WINNER! RQ({name}) = {rq:.4f} > sym_2")
        else:
            print(f"RQ({name}) = {rq:.4f}")

if __name__ == '__main__':
    main()
