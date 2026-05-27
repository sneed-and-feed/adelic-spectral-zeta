import numpy as np
import scipy.sparse as sp
from typing import Tuple, List
import math

def padic_norm(n: int, p: int) -> float:
    """Computes the p-adic norm |n|_p"""
    if n == 0:
        return 0.0
    order = 0
    while n % p == 0:
        order += 1
        n //= p
    return p ** (-order)

def adelic_distance(x: int, y: int, primes: List[int] = [2, 3, 5, 7, 11, 13]) -> float:
    """Computes a truncated adèlic distance between two integers."""
    diff = abs(x - y)
    if diff == 0:
        return 0.0
    dist = 0.0
    for p in primes:
        dist += padic_norm(diff, p)
    # Also add the real archimedean norm (normalized)
    dist += math.log(1 + diff) 
    return dist

def build_factorization_hamiltonian(N: int, n_bits: int) -> sp.coo_matrix:
    """
    Builds the diagonal Cost Hamiltonian H_cost = (X * Y - N)^2
    The Hilbert space is of size 2^(2*n_bits).
    The basis |i> corresponds to |x, y> where x is the first n_bits, y is the second n_bits.
    """
    dim = 2 ** (2 * n_bits)
    diag = np.zeros(dim, dtype=np.float64)
    
    for i in range(dim):
        # Extract x and y from the integer i
        x = i >> n_bits
        y = i & ((1 << n_bits) - 1)
        
        # Penalize if x or y is 0 or 1 to avoid trivial factorizations (1 * N = N)
        if x <= 1 or y <= 1:
            diag[i] = 1e6
        else:
            diag[i] = (x * y - N) ** 2
            
    return sp.diags([diag], [0], shape=(dim, dim), format='coo')

def build_adelic_driver_hamiltonian(n_bits: int, sparsity_threshold: float = 2.0) -> sp.coo_matrix:
    """
    Builds the Adèlic Driver Hamiltonian.
    Instead of standard quantum transverse fields, this mixer uses the Adèlic distance
    so that quantum tunneling respects prime distributions.
    """
    dim = 2 ** (2 * n_bits)
    
    # We will build a sparse matrix to avoid OOM
    row = []
    col = []
    data = []
    
    for i in range(dim):
        # Diagonal term
        row.append(i)
        col.append(i)
        data.append(10.0) # Base energy
        
        # Connect i to a few other states based on bit flips (standard mixer)
        # BUT weight the transition by the Adèlic distance.
        for b in range(2 * n_bits):
            j = i ^ (1 << b)
            d_A = adelic_distance(i, j)
            
            # The transition amplitude is inversely proportional to the Adèlic distance
            amplitude = -1.0 / (d_A + 1e-3)
            
            row.append(i)
            col.append(j)
            data.append(amplitude)
            
    return sp.coo_matrix((data, (row, col)), shape=(dim, dim))

def bipartite_entanglement_entropy_xy(state: np.ndarray, n_bits: int) -> float:
    """
    Computes the entanglement entropy between the X register and Y register.
    State is a 1D vector of length 2^(2 * n_bits).
    """
    dim_x = 2 ** n_bits
    dim_y = 2 ** n_bits
    
    # Reshape the state into a matrix where rows are x states and cols are y states
    psi_matrix = state.reshape((dim_x, dim_y))
    
    # Compute the reduced density matrix for X
    rho_x = psi_matrix @ psi_matrix.T.conj()
    
    # Compute eigenvalues of rho_x
    eigvals = np.linalg.eigvalsh(rho_x)
    
    # Compute Von Neumann entropy S = -Tr(rho ln rho)
    entropy = 0.0
    for val in eigvals:
        if val > 1e-12:
            entropy -= val * np.log(val)
            
    return entropy
