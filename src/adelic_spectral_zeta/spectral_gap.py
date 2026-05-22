import numpy as np
import scipy.sparse as sp

def construct_B3(k):
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

def construct_B2(d):
    """
    Constructs the algebraic 2-adic transfer operator B_2 on C^(2^d).
    Returns a dense complex numpy array of shape (2^d, 2^d).
    """
    N = 1 << d
    B2 = np.zeros((N, N), dtype=complex)
    inv3 = pow(3, -1, N)
    for x in range(N):
        c0 = (2 * x) % N
        c1 = ((2 * x - 1) * inv3) % N
        B2[x, c0] += 0.5
        B2[x, c1] += 0.5
    return B2

def get_diagonal_indices(d, k, M):
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

def construct_diagonal_vectors(d, k, M):
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

def construct_restricted_operator(d, k, M):
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

def compute_restricted_spectral_gap(d, k, M):
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

def construct_gauge_twisted_B(d, theta):
    """
    Constructs the gauge-twisted transfer operator B(theta) = B * exp(i * theta * omega_2) on C^(2^d).
    Returns a dense complex numpy array of shape (2^d, 2^d).
    """
    N = 1 << d
    B2 = construct_B2(d)
    
    # Construct omega_2:
    # (omega_2)_{x, y} = 2**(-d) if x % 2 != y % 2 else 0
    x_coords = np.arange(N)
    parity = x_coords % 2
    omega_2 = np.zeros((N, N))
    omega_2[parity[:, None] != parity[None, :]] = 1.0 / N
    
    # Compute exp(i * theta * omega_2) using scipy.linalg.expm
    from scipy.linalg import expm
    U_theta = expm(1j * theta * omega_2)
    
    B_theta = B2 @ U_theta
    return B_theta

def compute_gauge_twisted_gap(d, theta):
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
