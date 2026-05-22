import numpy as np
import scipy.sparse as sp

def v2(x, N):
    """
    Computes the 2-adic valuation of x modulo N.
    If x % N == 0, returns np.inf.
    """
    x = int(x) % int(N)
    if x == 0:
        return np.inf
    # Extract lowest set bit to count trailing zeros
    return (x & -x).bit_length() - 1

def padic_distance_matrix(N):
    """
    Computes the N x N pairwise 2-adic distance matrix.
    N must be a power of 2.
    """
    dists = np.zeros((N, N))
    for i in range(N):
        for j in range(N):
            diff = (i - j) % N
            val = v2(diff, N)
            if val == np.inf:
                dists[i, j] = 0.0
            else:
                dists[i, j] = 2.0 ** (-val)
    return dists

def holder_seminorm(psi, alpha, dists=None):
    """
    Computes the discrete alpha-Hölder seminorm of a vector psi.
    dists is an optional precomputed pairwise distance matrix.
    """
    N = len(psi)
    if dists is None:
        dists = padic_distance_matrix(N)
        
    # Vectorized computation of pairwise differences
    diffs = np.abs(psi[:, None] - psi[None, :])
    
    # Avoid division by zero on diagonal by masking
    mask = dists > 0
    ratios = np.zeros_like(diffs)
    ratios[mask] = diffs[mask] / (dists[mask] ** alpha)
    
    return np.max(ratios)

def holder_norm(psi, alpha, dists=None):
    """
    Computes the full alpha-Hölder norm of a vector psi:
    ||psi||_alpha = ||psi||_inf + v_alpha(psi)
    """
    sup_norm = np.max(np.abs(psi))
    seminorm = holder_seminorm(psi, alpha, dists)
    return sup_norm + seminorm

def get_operators(d):
    """
    Constructs sparse matrix representations of the translation operator A
    and the algebraic modular transfer operator B_alg on C^(2^d).
    """
    N = 1 << d
    rows = np.arange(N)
    
    # 1. Translation Operator A
    cols_A = (rows - 1) % N
    data_A = np.ones(N)
    A = sp.coo_matrix((data_A, (rows, cols_A)), shape=(N, N)).tocsr()
    
    # 2. Algebraic Transfer Operator B_alg
    inv3 = pow(3, -1, N)
    cols1 = (2 * rows) % N
    cols2 = ((2 * rows - 1) * inv3) % N
    
    row_indices = np.concatenate([rows, rows])
    col_indices = np.concatenate([cols1, cols2])
    data_vals = np.concatenate([np.full(N, 0.5), np.full(N, 0.5)])
    
    B = sp.coo_matrix((data_vals, (row_indices, col_indices)), shape=(N, N)).tocsr()
    
    return A, B

def simulate_decay(psi_0, B, steps, alpha, dists=None):
    """
    Simulates the decay of the Hölder norm of psi_0 under repeated applications of B.
    B is the transfer operator (sparse or dense).
    """
    N = len(psi_0)
    if dists is None:
        dists = padic_distance_matrix(N)
        
    norms = []
    seminorms = []
    sup_norms = []
    
    psi = np.copy(psi_0)
    for _ in range(steps):
        psi = B.dot(psi)
        
        # Enforce zero mean to track decay (orthogonal to the constant state 1)
        psi = psi - np.mean(psi)
        
        sup_norm = np.max(np.abs(psi))
        seminorm = holder_seminorm(psi, alpha, dists)
        
        sup_norms.append(sup_norm)
        seminorms.append(seminorm)
        norms.append(sup_norm + seminorm)
        
    return np.array(norms), np.array(seminorms), np.array(sup_norms)
