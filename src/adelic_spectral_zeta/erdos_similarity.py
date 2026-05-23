import numpy as np
import scipy.sparse as sp
from scipy.sparse.linalg import eigsh
from fractions import Fraction

def v_p(x, p):
    """
    Computes the p-adic valuation of a number x (integer, rational, or float).
    Returns inf if x is 0.
    """
    if x == 0:
        return float('inf')
    
    if isinstance(x, float):
        frac = Fraction(x).limit_denominator(1000000)
    else:
        try:
            frac = Fraction(x)
        except (ValueError, TypeError):
            # Fallback for floats that cannot be cleanly converted
            frac = Fraction(float(x)).limit_denominator(1000000)
    
    num = frac.numerator
    den = frac.denominator
    val = 0
    while num % p == 0:
        val += 1
        num //= p
    while den % p == 0:
        val -= 1
        den //= p
    return val

def mod_inverse(B, mod):
    """
    Computes the modular inverse of B modulo mod.
    """
    return pow(int(B), -1, int(mod))

def fraction_mod(frac, mod):
    """
    Computes the modulo of a fraction mod an integer.
    The denominator must be coprime to the mod.
    """
    frac = Fraction(frac)
    num = frac.numerator
    den = frac.denominator
    inv_den = mod_inverse(den, mod)
    return (num * inv_den) % mod

def construct_adelic_sequence(sequence_type, M, d, k):
    """
    Constructs a diagonally embedded rational sequence in the truncated adele space
    A_trunc = R/L_Z x Z/2^d Z x Z/3^k Z.
    
    Returns:
        List of tuples (s_inf, s_2, s_3) representing s_n for n = 1, ..., M.
    """
    seq = []
    for n in range(1, M + 1):
        if sequence_type == "geometric":
            # Use 11**(-n) which is coprime to 2 and 3 and cycles both mod 4 and mod 3
            val = Fraction(1, 11**n)
        elif sequence_type == "harmonic":
            # Use 1/(n + 1) if n is coprime to 2 and 3, otherwise modify
            # To ensure it is coprime to 2 and 3, we can skip multiples
            # Or use a modified harmonic sequence s_n = 1 / (6*n + 1)
            val = Fraction(1, 6*n + 1)
        else:
            raise ValueError(f"Unknown sequence type: {sequence_type}")
            
        s_inf = float(val)
        s_2 = fraction_mod(val, 2**d)
        s_3 = fraction_mod(val, 3**k)
        seq.append((s_inf, s_2, s_3))
    return seq

def construct_adelic_set(set_type, N_inf, d, k, density=0.5, L=1.0, theta=0.4):
    """
    Constructs an adèlic set indicator function of shape (N_inf, 2**d, 3**k).
    
    set_type options:
        "neighborhood": Case A, a dense neighborhood around 0.
        "porous": Case B, a Cantor-like porous set containing gaps.
        
    theta: float
        The relative width of the removed middle interval in the porous set (0 < theta < 1).
        Controls the Hausdorff/spectral dimension of the remaining set.
    """
    N2 = 2**d
    N3 = 3**k
    indicator = np.zeros((N_inf, N2, N3), dtype=bool)
    
    if set_type == "neighborhood":
        # Archimedean part: interval around 0 of width N_inf * density
        half_w = int(N_inf * density / 2)
        for i in range(N_inf):
            dist = min(i, N_inf - i)
            if dist <= half_w:
                indicator[i, :, :] = True
                
    elif set_type == "porous":
        # Case B: A highly porous, Cantor-like set
        # Keep width on each side of 0: half of (1 - theta)
        keep_w = int(N_inf * (1.0 - theta) / 2)
        for i in range(N_inf):
            dist = min(i, N_inf - i)
            if dist <= keep_w:
                indicator[i, :, :] = True
                
        # 2-adic part: exclude points congruent to 2 or 3 mod 4
        # (keeps only 0 and 1 mod 4)
        for a2 in range(N2):
            if a2 % 4 in [2, 3]:
                indicator[:, a2, :] = False
                
        # 3-adic part: exclude points congruent to 2 mod 3
        # (keeps only 0 and 1 mod 3)
        for a3 in range(N3):
            if a3 % 3 == 2:
                indicator[:, :, a3] = False
                
    else:
        raise ValueError(f"Unknown set type: {set_type}")
        
    return indicator

def compute_correlation(adelic_set, adelic_seq, b_y, b_k2, b_k3, L=1.0):
    """
    Computes the presence / correlation function Psi(b) for a scale parameter b.
    b = (b_y, b_k2, b_k3) where:
        b_y: Archimedean scale factor (float)
        b_k2: 2-adic scale exponent (int, >= 0)
        b_k3: 3-adic scale exponent (int, >= 0)
    """
    N_inf, N2, N3 = adelic_set.shape
    
    # Initialize translation intersection as the set itself
    prod = np.copy(adelic_set)
    
    # Perform component-wise translation and scale shifts
    for s_inf, s_2, s_3 in adelic_seq:
        # Archimedean shift
        shift_idx_inf = int(round(b_y * s_inf / (L / N_inf))) % N_inf
        # 2-adic shift (2**b_k2 * s_2 mod N2)
        shift_idx_2 = int((2**b_k2) * s_2) % N2
        # 3-adic shift (3**b_k3 * s_3 mod N3)
        shift_idx_3 = int((3**b_k3) * s_3) % N3
        
        # Roll the indicator array along axes
        rolled = np.roll(adelic_set, shift=-shift_idx_inf, axis=0)
        rolled = np.roll(rolled, shift=-shift_idx_2, axis=1)
        rolled = np.roll(rolled, shift=-shift_idx_3, axis=2)
        
        prod = prod & rolled
        
    return float(np.sum(prod))

def construct_idelic_laplacian(N_u, V2, V3, du):
    """
    Constructs the global free idelic Laplacian Delta_I acting on functions
    over the scale space of size N_u x (V2 + 1) x (V3 + 1).
    Uses Kronecker-sums with Dirichlet boundary conditions.
    """
    # 1. Archimedean Laplacian (Dirichlet)
    diags_inf = np.ones(N_u) * 2.0
    off_diags_inf = np.ones(N_u - 1) * -1.0
    Delta_inf = (np.diag(diags_inf) + np.diag(off_diags_inf, 1) + np.diag(off_diags_inf, -1)) / (du**2)
    
    # 2. 2-adic Laplacian (Dirichlet)
    diags_2 = np.ones(V2 + 1) * 2.0
    off_diags_2 = np.ones(V2) * -1.0
    Delta_2 = np.diag(diags_2) + np.diag(off_diags_2, 1) + np.diag(off_diags_2, -1)
    
    # 3. 3-adic Laplacian (Dirichlet)
    diags_3 = np.ones(V3 + 1) * 2.0
    off_diags_3 = np.ones(V3) * -1.0
    Delta_3 = np.diag(diags_3) + np.diag(off_diags_3, 1) + np.diag(off_diags_3, -1)
    
    # Convert to sparse matrices
    sp_Delta_inf = sp.csr_matrix(Delta_inf)
    sp_Delta_2 = sp.csr_matrix(Delta_2)
    sp_Delta_3 = sp.csr_matrix(Delta_3)
    
    # Form Kronecker sum
    Delta_I = sp.kronsum(sp.kronsum(sp_Delta_inf, sp_Delta_2), sp_Delta_3)
    return Delta_I

def solve_schrodinger_spectrum(adelic_set, adelic_seq, grid_params, lmbda=1.0):
    """
    Constructs and solves the eigenvalues of the attractive Schrödinger operator
    H = Delta_I - lambda * Psi.
    
    Returns:
        eigenvalues: Sorted list of the lowest eigenvalues.
        eigenvectors: Corresponding eigenvectors.
        Psi: The presence/correlation vector of size N_ideles.
    """
    N_u = grid_params["N_u"]
    u_min = grid_params["u_min"]
    u_max = grid_params["u_max"]
    V2 = grid_params["V2"]
    V3 = grid_params["V3"]
    L = grid_params.get("L", 1.0)
    
    u_vals = np.linspace(u_min, u_max, N_u)
    du = u_vals[1] - u_vals[0] if N_u > 1 else 1.0
    
    N_ideles = N_u * (V2 + 1) * (V3 + 1)
    Psi = np.zeros(N_ideles)
    
    # Compute correlation over the idelic grid
    for i, u in enumerate(u_vals):
        b_y = np.exp(u)
        for j in range(V2 + 1):
            for k in range(V3 + 1):
                idx = i * (V2 + 1) * (V3 + 1) + j * (V3 + 1) + k
                Psi[idx] = compute_correlation(adelic_set, adelic_seq, b_y, j, k, L=L)
                
    # Build Laplacian
    Delta_I = construct_idelic_laplacian(N_u, V2, V3, du)
    
    # Build potential: V(b) = -lambda * Psi(b)
    V_diag = -lmbda * Psi
    
    # Total Hamiltonian
    H = Delta_I + sp.diags(V_diag)
    
    # Solve for eigenvalues
    k_eigen = min(10, N_ideles - 2)
    if k_eigen <= 0:
        k_eigen = 1
        
    eigenvalues, eigenvectors = eigsh(H, k=k_eigen, which='SA')
    
    return eigenvalues, eigenvectors, Psi
