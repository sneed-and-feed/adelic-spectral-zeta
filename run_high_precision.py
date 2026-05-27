import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla
import os
import sys
import time

def get_schreier_graph(d):
    """
    Constructs the unweighted sparse adjacency matrix for the Schreier graph G_d
    on Z/2^(d-1)Z, as formalized in SchreierConnectivity.lean.
    Generators: x -> 3x, x -> 3x - 1, and their inverses mod 2^(d-1).
    """
    N = 1 << (d - 1)
    inv3 = pow(3, -1, N)
    
    rows = np.arange(N)
    
    # 1. y = 3 * x mod N
    cols1 = (3 * rows) % N
    # 2. y = 3 * x - 1 mod N
    cols2 = (3 * rows - 1) % N
    # 3. x = 3 * y => y = inv3 * x mod N
    cols3 = (inv3 * rows) % N
    # 4. x = 3 * y - 1 => y = inv3 * (x + 1) mod N
    cols4 = (inv3 * (rows + 1)) % N
    
    row_indices = np.concatenate([rows, rows, rows, rows])
    col_indices = np.concatenate([cols1, cols2, cols3, cols4])
    
    # Remove self-loops (loopless graph)
    mask = row_indices != col_indices
    row_indices = row_indices[mask]
    col_indices = col_indices[mask]
    
    # Build sparse adjacency matrix (summing duplicates to 1)
    data_vals = np.ones(len(row_indices))
    adj = sp.coo_matrix((data_vals, (row_indices, col_indices)), shape=(N, N))
    
    # Binarize to make it an unweighted simple graph (handling multi-edges)
    adj = adj.tocsr()
    adj.data = np.ones_like(adj.data)
    
    return adj

def get_schreier_blocks(d):
    """
    Computes the symmetric and antisymmetric block matrices from the canonical
    sheet decomposition of G_d, as formalized in SchreierSpectral.lean.
    Returns: (weighted_matrix, sheet_diff_matrix)
    Both are (N/2) x (N/2) matrices, where N/2 = 2^(d-2).
    """
    N_half = 1 << (d - 2)
    adj = get_schreier_graph(d) # keep as sparse CSR
    
    # Slice the top-left and top-right blocks
    a00 = adj[:N_half, :N_half]
    a01 = adj[:N_half, N_half:]
    
    weighted_matrix = a00 + a01
    sheet_diff_matrix = a00 - a01
    
    return weighted_matrix, sheet_diff_matrix



def run_high_precision():
    print("d  | PF         | Anti       | rho        | C = (1-rho)*d^2 | Time (s)")
    print("-" * 75)
    
    # We will test specific large d values to avoid OOM but get high precision limits
    d_values = [16, 18, 20]
    
    results = []
    
    for d in d_values:
        t0 = time.time()
        weighted_matrix, sheet_diff_matrix = get_schreier_blocks(d)
        
        sym_sparse = sp.csr_matrix(weighted_matrix)
        anti_sparse = sp.csr_matrix(sheet_diff_matrix)
        
        # High precision eigensolver using tol=1e-12
        # Use return_eigenvectors=False if we just need the values (saves memory/time)
        try:
            sym_eigs, _ = spla.eigsh(sym_sparse, k=1, which='LA', tol=1e-12)
            anti_eigs, _ = spla.eigsh(anti_sparse, k=1, which='LA', tol=1e-12)
            
            lambda_pf = sym_eigs[0]
            lambda_anti = anti_eigs[0]
            
            rho = lambda_anti / lambda_pf
            C = (1 - rho) * (d**2)
            
            elapsed = time.time() - t0
            print(f"{d:2d} | {lambda_pf:.8f} | {lambda_anti:.8f} | {rho:.8f} | {C:.8f}      | {elapsed:.2f}")
            results.append((d, rho, C))
        except Exception as e:
            print(f"Error at d={d}: {e}")
            print("Note: If this is an OOM error, you may want to run this script on Google Colab with higher RAM.")
            
    print("\nVerification Complete.")
    print("Expected asymptotic limit for C is 12.")

if __name__ == "__main__":
    run_high_precision()
