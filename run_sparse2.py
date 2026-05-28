import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla
import time

def v2(x, N):
    x = int(x) % int(N)
    if x == 0: return np.inf
    return (x & -x).bit_length() - 1

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
    adj.data = np.ones_like(adj.data) # binarize multi-edges if any
    return adj

def get_schreier_blocks_sparse(d):
    N = 1 << (d - 1)
    N_half = 1 << (d - 2)
    adj = get_schreier_graph_sparse(d).tocoo()
    
    # We map edges (i, j) down to (i mod N_half, j mod N_half)
    u_vals = adj.row % N_half
    v_vals = adj.col % N_half
    
    # an edge (i, j) is 'same sheet' if i//N_half == j//N_half
    same_sheet = (adj.row // N_half) == (adj.col // N_half)
    
    # weights: +1 for same sheet, +1 for diff sheet in sym_matrix
    # +1 for same sheet, -1 for diff sheet in anti_matrix
    data_sym = np.ones(len(adj.data))
    data_anti = np.where(same_sheet, 1.0, -1.0)
    
    sym_matrix = sp.coo_matrix((data_sym, (u_vals, v_vals)), shape=(N_half, N_half)).tocsr()
    anti_matrix = sp.coo_matrix((data_anti, (u_vals, v_vals)), shape=(N_half, N_half)).tocsr()
    
    return sym_matrix, anti_matrix

print("d | Trace(Anti) | 4*dim | dim")
for d in range(3, 10):
    N_half = 1 << (d - 2)
    sym, anti = get_schreier_blocks_sparse(d)
    trace_anti = anti.diagonal().sum()
    print(f"{d:2d} | {trace_anti:11.1f} | {4*N_half:5d} | {N_half:3d}")

print("\nComputing L(d) up to d=20:")
print("d | PF       | Anti     | L(d)")
print("-" * 40)
for d in range(6, 21):
    sym, anti = get_schreier_blocks_sparse(d)
    
    sym_eigs, _ = spla.eigsh(sym, k=1, which='LA')
    anti_eigs, _ = spla.eigsh(anti, k=1, which='LA')
    
    lambda_pf = sym_eigs[0]
    lambda_anti = anti_eigs[0]
    
    rho = lambda_anti / lambda_pf
    L = (1 - rho) * (d**2)
    
    print(f"{d:2d}| {lambda_pf:.6f} | {lambda_anti:.6f} | {L:.6f}")

