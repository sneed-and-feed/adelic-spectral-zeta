import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla
import mpmath
import time

mpmath.mp.dps = 30
iv = mpmath.iv
iv.dps = 30

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

def test_iv_residual(d):
    weighted, sheet_diff = get_schreier_blocks(d)
    A = sp.csr_matrix(weighted)
    
    print("Computing eigsh...")
    t0 = time.time()
    lam_float, v_float = spla.eigsh(A, k=1, which='LA', tol=1e-12)
    print("Eigsh took", time.time() - t0)
    
    lam = lam_float[0]
    v = v_float[:, 0]
    
    print("Converting to iv.mpf...")
    lam_iv = iv.mpf(str(lam))
    v_iv = [iv.mpf(str(x)) for x in v]
    
    print("Computing interval residual...")
    t0 = time.time()
    
    indptr = A.indptr
    indices = A.indices
    data = A.data
    
    r_norm2 = iv.mpf(0)
    v_norm2 = iv.mpf(0)
    
    for i in range(len(v_iv)):
        start = indptr[i]
        end = indptr[i+1]
        s = iv.mpf(0)
        for j in range(start, end):
            col = indices[j]
            val = data[j]
            if val == 1:
                s += v_iv[col]
            elif val == -1:
                s -= v_iv[col]
            else:
                s += int(val) * v_iv[col]
        
        vi = v_iv[i]
        ri = s - lam_iv * vi
        r_norm2 += ri * ri
        v_norm2 += vi * vi
        
    delta = mpmath.sqrt(r_norm2) / mpmath.sqrt(v_norm2)
    print("Interval residual calculation took", time.time() - t0)
    print("delta bound:", delta)

if __name__ == "__main__":
    test_iv_residual(20)
