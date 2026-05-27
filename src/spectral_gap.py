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
    adj = get_schreier_graph(d).toarray()
    
    weighted_matrix = np.zeros((N_half, N_half))
    sheet_diff_matrix = np.zeros((N_half, N_half))
    
    for u in range(N_half):
        for v in range(N_half):
            # Lifts to the two sheets
            lift_u0 = u
            lift_v0 = v
            lift_v1 = (v + N_half) # tau(v)
            
            a00 = adj[lift_u0, lift_v0]
            a01 = adj[lift_u0, lift_v1]
            
            weighted_matrix[u, v] = a00 + a01
            sheet_diff_matrix[u, v] = a00 - a01
            
    return weighted_matrix, sheet_diff_matrix

