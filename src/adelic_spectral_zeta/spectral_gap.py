"""Spectral gap computation for 2-adic and 3-adic transfer operators and their gauge-twisted variants."""

import numpy as np
import scipy.sparse as sp
from scipy.linalg import expm
from typing import Tuple

def construct_B3(k: int) -> np.ndarray:
    """
    Constructs the 3-adic transfer operator B_3 on C^(3^k) representing 3-adic tree transitions.
    B_3 is represented as a dense complex numpy array of shape (3^k, 3^k).
    """
    N = 3**k
    B3 = np.zeros((N, N), dtype=complex)
    for x in range(N):
        # The preimages of x under 3-adic transitions are 3x, 3x+1, 3x+2 mod N
        c0 = (3 * x) % N
        c1 = (3 * x + 1) % N
        c2 = (3 * x + 2) % N
        B3[x, c0] += 1.0 / 3.0
        B3[x, c1] += 1.0 / 3.0
        B3[x, c2] += 1.0 / 3.0
    return B3

def construct_B2(d: int) -> np.ndarray:
    """
    Constructs the algebraic 2-adic transfer operator B_2 on C^(2^d).
    Returns a dense complex numpy array of shape (2^d, 2^d).
    """
    N = 1 << d
    B2 = np.zeros((N, N), dtype=complex)
    # Modular inverse of 3 mod 2^d
    inv3 = pow(3, -1, N)
    for x in range(N):
        c0 = (2 * x) % N
        c1 = ((2 * x - 1) * inv3) % N
        B2[x, c0] += 0.5
        B2[x, c1] += 0.5
    return B2

def get_diagonal_indices(d: int, k: int, M: int) -> np.ndarray:
    """
    Returns the indices in the joint space of dimension 2^d * 3^k corresponding
    to the physical integers 1, ..., M.
    """
    N2 = 2**d
    N3 = 3**k
    indices = []
    for n in range(1, M + 1):
        n2 = n % N2
        n3 = n % N3
        idx = n2 * N3 + n3
        indices.append(idx)
    return np.array(indices, dtype=int)

def construct_diagonal_vectors(d: int, k: int, M: int) -> np.ndarray:
    """
    Constructs the M diagonal embedding vectors |e_n> in C^(2^d * 3^k)
    for n = 1, ..., M.
    Returns a numpy array of shape (M, 2^d * 3^k).
    """
    N2 = 2**d
    N3 = 3**k
    dim = N2 * N3
    vectors = np.zeros((M, dim), dtype=complex)
    indices = get_diagonal_indices(d, k, M)
    for j, idx in enumerate(indices):
        vectors[j, idx] = 1.0
    return vectors

def construct_restricted_operator(d: int, k: int, M: int) -> np.ndarray:
    r"""
    Constructs the restricted joint operator P_{Z, M} (B_2 \otimes B_3) P_{Z, M}
    projected onto the subspace of dimension M.
    Returns a dense complex numpy array of shape (M, M).
    """
    N2 = 2**d
    B2 = construct_B2(d)
    B3 = construct_B3(k)
    
    n_vals = np.arange(1, M + 1)
    n2 = n_vals % N2
    n3 = n_vals % 3**k
    
    B2_sub = B2[n2[:, None], n2[None, :]]
    B3_sub = B3[n3[:, None], n3[None, :]]
    
    return B2_sub * B3_sub

def compute_restricted_spectral_gap(d: int, k: int, M: int) -> Tuple[np.ndarray, float]:
    """
    Computes the eigenvalues and the spectral gap of the restricted joint operator.
    Returns:
        eigenvalues: Sorted in descending order of magnitude.
        gap: 1.0 - abs(eigenvalues[1]) (if M >= 2, else 0.0).
    """
    B_rest = construct_restricted_operator(d, k, M)
    eigenvalues = np.linalg.eigvals(B_rest)
    idx = np.argsort(np.abs(eigenvalues))[::-1]
    eigenvalues_sorted = eigenvalues[idx]
    if len(eigenvalues_sorted) >= 2:
        gap = 1.0 - np.abs(eigenvalues_sorted[1])
    else:
        gap = 0.0
    return eigenvalues_sorted, gap

def construct_gauge_twisted_B(d: int, theta: float) -> np.ndarray:
    """
    Constructs the gauge-twisted transfer operator B(theta) = B * exp(i * theta * omega_2) on C^(2^d).
    Returns a dense complex numpy array of shape (2^d, 2^d).
    """
    N = 1 << d
    B2 = construct_B2(d)
    
    # Construct omega_2:
    # (omega_2)_{x, y} = 2**(-d) if x % 2 != y % 2 else 0
    # The gauge connection is given by U(theta) = exp(i * theta * omega_2)
    x_coords = np.arange(N)
    parity = x_coords % 2
    omega_2 = np.zeros((N, N))
    omega_2[parity[:, None] != parity[None, :]] = 1.0 / N
    
    # Compute exp(i * theta * omega_2) using scipy.linalg.expm
    U_theta = expm(1j * theta * omega_2)
    
    B_theta = B2 @ U_theta
    return B_theta

def compute_gauge_twisted_gap(d: int, theta: float) -> Tuple[np.ndarray, float]:
    """
    Computes the eigenvalues of B(theta) and its spectral gap.
    Returns:
        eigenvalues: Sorted in descending order of magnitude.
        gap: 1.0 - abs(eigenvalues[1]) (second largest).
    """
    B_theta = construct_gauge_twisted_B(d, theta)
    eigenvalues = np.linalg.eigvals(B_theta)
    idx = np.argsort(np.abs(eigenvalues))[::-1]
    eigenvalues_sorted = eigenvalues[idx]
    if len(eigenvalues_sorted) >= 2:
        gap = 1.0 - np.abs(eigenvalues_sorted[1])
    else:
        gap = 0.0
    return eigenvalues_sorted, gap

def v2(x: float, N: int) -> float:
    """
    Computes the 2-adic valuation of x modulo N.
    If x % N == 0, returns np.inf.
    """
    x_int = int(x) % int(N)
    if x_int == 0:
        return np.inf
    # Extract lowest set bit to count trailing zeros
    return float((x_int & -x_int).bit_length() - 1)

def padic_distance_matrix(N: int) -> np.ndarray:
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

def holder_seminorm(psi: np.ndarray, alpha: float, dists: np.ndarray = None) -> float:
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
    
    return float(np.max(ratios))

def holder_norm(psi: np.ndarray, alpha: float, dists: np.ndarray = None) -> float:
    """
    Computes the full alpha-Hölder norm of a vector psi:
    ||psi||_alpha = ||psi||_inf + v_alpha(psi)
    """
    sup_norm = np.max(np.abs(psi))
    seminorm = holder_seminorm(psi, alpha, dists)
    return float(sup_norm + seminorm)

def get_operators(d: int) -> Tuple[sp.csr_matrix, sp.csr_matrix]:
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

def simulate_decay(psi_0: np.ndarray, B: sp.csr_matrix, steps: int, alpha: float, dists: np.ndarray = None) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
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

def get_schreier_graph(d: int) -> sp.csr_matrix:
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

def get_schreier_blocks(d: int) -> Tuple[sp.csr_matrix, sp.csr_matrix]:
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

