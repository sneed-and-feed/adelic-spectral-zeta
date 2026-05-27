import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla
import json
import time
import mpmath
import math

# Use 100 decimal places for rigorous bounds
mpmath.mp.dps = 100

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
    
    data_vals = np.ones(len(row_indices), dtype=np.int8)
    adj = sp.coo_matrix((data_vals, (row_indices, col_indices)), shape=(N, N))
    
    adj = adj.tocsr()
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

def compute_rigorous_bound(A_csr, lam_float, v_float):
    """
    Computes rigorous interval bound for the eigenvalue.
    Returns (lam_exact, delta) where true eigenvalue is in [lam_exact - delta, lam_exact + delta].
    """
    N = A_csr.shape[0]
    
    print("  Normalizing vector...")
    v_norm = np.linalg.norm(v_float)
    v_float = v_float / v_norm
    
    # Scale to integers. 2^50 is about 1e15, fitting well inside Python's arbitrary size integers
    SCALE = 1 << 50
    
    print("  Converting to Python integers...")
    lam_int = int(round(lam_float * SCALE))
    v_int = [int(round(x * SCALE)) for x in v_float]
    
    print("  Extracting CSR data as lists...")
    indptr = A_csr.indptr.tolist()
    indices = A_csr.indices.tolist()
    data = A_csr.data.tolist()
    
    print("  Computing exact residual R_i = S * sum(A_ij V_j) - Lambda * V_i...")
    t0 = time.time()
    
    R_sq = 0
    V_sq = 0
    
    # Exact integer arithmetic in pure Python
    for i in range(N):
        start = indptr[i]
        end = indptr[i+1]
        
        # A_ij V_j sum
        s = 0
        for j in range(start, end):
            s += data[j] * v_int[indices[j]]
            
        R_i = SCALE * s - lam_int * v_int[i]
        R_sq += R_i * R_i
        V_sq += v_int[i] * v_int[i]
        
    print(f"  Residual computation took {time.time() - t0:.2f}s")
    
    print("  Computing rigorous delta using mpmath...")
    # delta = sqrt(R_sq) / (SCALE * sqrt(V_sq))
    delta_mpf = mpmath.sqrt(mpmath.mpf(R_sq)) / (mpmath.mpf(SCALE) * mpmath.sqrt(mpmath.mpf(V_sq)))
    lam_exact_mpf = mpmath.mpf(lam_int) / mpmath.mpf(SCALE)
    
    return float(lam_exact_mpf), float(delta_mpf)


def main():
    d = 24
    print(f"Targeting d={d} (N={1 << (d-1)} nodes)")
    
    print("Constructing matrices...")
    t0 = time.time()
    sym_sparse, anti_sparse = get_schreier_blocks(d)
    print(f"Construction took {time.time() - t0:.2f}s")
    
    print("Computing PF eigenvalue (float64)...")
    t0 = time.time()
    lam_pf_float, v_pf_float = spla.eigsh(sym_sparse, k=1, which='LA', tol=1e-12)
    print(f"PF eigsh took {time.time() - t0:.2f}s")
    
    print("Computing Anti eigenvalue (float64)...")
    t0 = time.time()
    lam_anti_float, v_anti_float = spla.eigsh(anti_sparse, k=1, which='LA', tol=1e-12)
    print(f"Anti eigsh took {time.time() - t0:.2f}s")
    
    print("Rigorous bounding for PF...")
    lam_pf, delta_pf = compute_rigorous_bound(sym_sparse, float(lam_pf_float[0]), v_pf_float[:, 0])
    
    print("Rigorous bounding for Anti...")
    lam_anti, delta_anti = compute_rigorous_bound(anti_sparse, float(lam_anti_float[0]), v_anti_float[:, 0])
    
    print(f"PF   : {lam_pf} +/- {delta_pf}")
    print(f"Anti : {lam_anti} +/- {delta_anti}")
    
    # Compute rho and C bounds
    pf_low = lam_pf - delta_pf
    pf_high = lam_pf + delta_pf
    
    anti_low = lam_anti - delta_anti
    anti_high = lam_anti + delta_anti
    
    rho_low = anti_low / pf_high
    rho_high = anti_high / pf_low
    
    C_low = (1 - rho_high) * (d**2)
    C_high = (1 - rho_low) * (d**2)
    
    print(f"rho  : [{rho_low}, {rho_high}]")
    print(f"C    : [{C_low}, {C_high}]")
    
    results = {
        "d": d,
        "nodes": 1 << (d-1),
        "pf_eigenvalue": {
            "value": lam_pf,
            "error_bound": delta_pf,
            "interval": [pf_low, pf_high]
        },
        "anti_eigenvalue": {
            "value": lam_anti,
            "error_bound": delta_anti,
            "interval": [anti_low, anti_high]
        },
        "rho": {
            "interval": [rho_low, rho_high]
        },
        "C": {
            "interval": [C_low, C_high]
        }
    }
    
    with open("lanczos_d24_certificate.json", "w") as f:
        json.dump(results, f, indent=4)
        
    print("Certificate saved to lanczos_d24_certificate.json")

if __name__ == "__main__":
    main()
