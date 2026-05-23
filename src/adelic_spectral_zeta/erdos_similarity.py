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

def construct_adelic_sequence(sequence_type, M, d=None, k=None, primes=None, depths=None, base=11):
    """
    Constructs a diagonally embedded rational sequence in the truncated adele space
    A_trunc = R/L_Z x Z/p_1^d_1 Z x ... x Z/p_r^d_r Z.
    
    Returns:
        List of tuples (s_inf, s_p1, ..., s_pr) representing s_n for n = 1, ..., M.
    """
    if M < 2:
        raise ValueError("Sequence length M must be at least 2 for similarity analysis.")
        
    if primes is None:
        if d is None or k is None:
            raise ValueError("Must provide either 'primes' and 'depths', or 'd' and 'k'.")
        primes = [2, 3]
        depths = [d, k]
        
    if len(primes) == 0:
        raise ValueError("The set of prime places must not be empty.")
        
    if isinstance(base, (int, float)):
        base_frac = Fraction(base).limit_denominator(1000000)
    else:
        base_frac = Fraction(base)
        
    num = base_frac.numerator
    den = base_frac.denominator
    
    for p in primes:
        if num % p == 0:
            raise ValueError(f"Base numerator {num} is not coprime to prime {p}.")
        if den % p == 0:
            raise ValueError(f"Base denominator {den} is not coprime to prime {p}.")
            
    seq = []
    for n in range(1, M + 1):
        if sequence_type == "geometric":
            val = Fraction(1, base_frac**n)
        elif sequence_type == "harmonic":
            # For harmonic, use a modified form coprime to all primes in primes.
            k_mult = 1
            for p in primes:
                k_mult *= p
            val = Fraction(1, k_mult*n + 1)
        else:
            raise ValueError(f"Unknown sequence type: {sequence_type}")
            
        s_inf = float(val)
        coords = [s_inf]
        for p, dp in zip(primes, depths):
            coords.append(fraction_mod(val, p**dp))
        seq.append(tuple(coords))
    return seq

def construct_generalized_cantor_set(p, d, allowed_residues=None, base_level=1, allowed_digits=None):
    """
    Constructs a boolean array of shape (p**d,) where True elements represent
    the allowed points in the Cantor-like set.
    """
    size = p**d
    indicator = np.ones(size, dtype=bool)
    
    if allowed_digits is not None:
        for x in range(size):
            temp = x
            for j in range(d):
                digit = temp % p
                if j in allowed_digits and digit not in allowed_digits[j]:
                    indicator[x] = False
                    break
                temp //= p
    else:
        if allowed_residues is None:
            # Default behavior:
            if p == 2:
                # Mod 4 residues {0, 1}
                allowed_residues = [0, 1]
                base_level = min(2, d)
            elif p == 3:
                # Mod 3 residues {0, 1}
                allowed_residues = [0, 1]
                base_level = min(1, d)
            else:
                # General p: keep all but the last residue mod p
                allowed_residues = list(range(p - 1))
                base_level = 1
                
        mod = p**base_level
        allowed_set = set(allowed_residues)
        for x in range(size):
            if (x % mod) not in allowed_set:
                indicator[x] = False
                
    return indicator

def construct_adelic_set(set_type, N_inf, d=None, k=None, primes=None, depths=None, density=0.5, L=1.0, theta=0.4, cantor_sets=None):
    """
    Constructs an adèlic set indicator function of shape (N_inf, p_1**d_1, ..., p_r**d_r).
    
    set_type options:
        "neighborhood": Case A, a dense neighborhood around 0.
        "porous": Case B, a Cantor-like porous set containing gaps.
        
    theta: float
        The relative width of the removed middle interval in the porous set (0 < theta < 1).
    """
    if primes is None:
        if d is None or k is None:
            raise ValueError("Must provide either 'primes' and 'depths', or 'd' and 'k'.")
        primes = [2, 3]
        depths = [d, k]
        
    shape = (N_inf,) + tuple(p**dp for p, dp in zip(primes, depths))
    indicator = np.zeros(shape, dtype=bool)
    
    if set_type == "neighborhood":
        # Archimedean part: interval around 0 of width N_inf * density
        half_w = int(N_inf * density / 2)
        for i in range(N_inf):
            dist = min(i, N_inf - i)
            if dist <= half_w:
                indicator[i, ...] = True
                
    elif set_type == "porous":
        # Case B: A highly porous, Cantor-like set
        keep_w = int(N_inf * (1.0 - theta) / 2)
        for i in range(N_inf):
            dist = min(i, N_inf - i)
            if dist <= keep_w:
                indicator[i, ...] = True
                
        # Build default or use provided Cantor sets
        if cantor_sets is None:
            cantor_sets = []
            for p, dp in zip(primes, depths):
                cantor_sets.append(construct_generalized_cantor_set(p, dp))
                
        # Apply Cantor constraints along each prime axis
        for i, C_i in enumerate(cantor_sets):
            new_shape = [1] * len(shape)
            new_shape[i + 1] = len(C_i)
            C_i_reshaped = C_i.reshape(new_shape)
            indicator = indicator & C_i_reshaped
            
    else:
        raise ValueError(f"Unknown set type: {set_type}")
        
    return indicator

def compute_correlation(adelic_set, adelic_seq, b_y, b_k2=None, b_k3=None, k_vals=None, primes=None, L=1.0):
    """
    Computes the presence / correlation function Psi(b) for a scale parameter b.
    """
    if k_vals is None:
        if b_k2 is None or b_k3 is None:
            raise ValueError("Must provide either 'k_vals' or 'b_k2' and 'b_k3'.")
        k_vals = [b_k2, b_k3]
        
    if primes is None:
        primes = [2, 3]
        
    N_dims = list(adelic_set.shape)
    N_inf = N_dims[0]
    
    # Initialize translation intersection as the set itself
    prod = np.copy(adelic_set)
    
    for s_tuple in adelic_seq:
        s_inf = s_tuple[0]
        shift_idx_inf = int(round(b_y * s_inf / (L / N_inf))) % N_inf
        
        rolled = np.roll(prod, shift=-shift_idx_inf, axis=0)
        
        for i, (k_val, s_p) in enumerate(zip(k_vals, s_tuple[1:])):
            p = primes[i]
            N_p = N_dims[i + 1]
            shift_p = int((p**k_val) * s_p) % N_p
            rolled = np.roll(rolled, shift=-shift_p, axis=i + 1)
            
        prod = prod & rolled
        
    return float(np.sum(prod))

def analyze_valuation_sectors(primes, depths, base, M, cantor_sets, sequence_type="geometric"):
    """
    Performs algebraic cycle analysis for sequence base over prime places.
    Determines the set of admissible non-Archimedean scale factors (k_1, ..., k_r).
    
    Returns:
        admissible_scales: list of tuples (k_1, ..., k_r) that are allowed.
        collapsed: bool, True if the allowed non-Archimedean scales are empty or strictly restricted to the boundary.
    """
    if isinstance(base, (int, float)):
        base_frac = Fraction(base).limit_denominator(1000000)
    else:
        base_frac = Fraction(base)
        
    num = base_frac.numerator
    den = base_frac.denominator
    for p in primes:
        if num % p == 0 or den % p == 0:
            raise ValueError(f"Base {base} is not coprime to prime {p}.")
            
    seq_mod = []
    for p, d in zip(primes, depths):
        p_pow = p**d
        if sequence_type == "geometric":
            terms = [fraction_mod(Fraction(1, base_frac**n), p_pow) for n in range(1, M + 1)]
        elif sequence_type == "harmonic":
            k_mult = 1
            for prime in primes:
                k_mult *= prime
            terms = [fraction_mod(Fraction(1, k_mult*n + 1), p_pow) for n in range(1, M + 1)]
        else:
            raise ValueError(f"Unknown sequence type: {sequence_type}")
        seq_mod.append(terms)
        
    allowed_translations = []
    for i, (p, d) in enumerate(zip(primes, depths)):
        p_pow = p**d
        C_i_set = set(np.where(cantor_sets[i])[0])
        place_allowed = []
        for k_i in range(d + 1):
            scale_factor = p**k_i
            valid_a = []
            for a in range(p_pow):
                if a not in C_i_set:
                    continue
                is_valid = True
                for n in range(M):
                    shifted = (a + scale_factor * seq_mod[i][n]) % p_pow
                    if shifted not in C_i_set:
                        is_valid = False
                        break
                if is_valid:
                    valid_a.append(a)
            place_allowed.append(set(valid_a))
        allowed_translations.append(place_allowed)
        
    allowed_k_by_place = []
    for i, (p, d) in enumerate(zip(primes, depths)):
        allowed_k = [k for k in range(d + 1) if len(allowed_translations[i][k]) > 0]
        allowed_k_by_place.append(allowed_k)
        
    import itertools
    admissible_scales = list(itertools.product(*allowed_k_by_place))
    
    boundary_scale = tuple(depths)
    if len(admissible_scales) == 0:
        collapsed = True
    elif len(admissible_scales) == 1 and admissible_scales[0] == boundary_scale:
        collapsed = True
    else:
        collapsed = False
        
    return admissible_scales, collapsed

def construct_idelic_laplacian(N_u, *args, **kwargs):
    """
    Constructs the global free idelic Laplacian Delta_I acting on functions
    over the joint scale space.
    Supports:
        construct_idelic_laplacian(N_u, V2, V3, du) -- Old positional signature
        construct_idelic_laplacian(N_u, du, V_list=[V1, V2, ...]) -- New generalized signature
    """
    if len(args) == 3:
        V2, V3, du = args
        V_list = [V2, V3]
    elif len(args) == 1:
        du = args[0]
        V_list = kwargs.get("V_list", None)
        if V_list is None:
            V2 = kwargs.get("V2")
            V3 = kwargs.get("V3")
            V_list = [V2, V3]
    else:
        du = kwargs.get("du")
        V_list = kwargs.get("V_list", None)
        if V_list is None:
            V2 = kwargs.get("V2")
            V3 = kwargs.get("V3")
            V_list = [V2, V3]
            
    diags_inf = np.ones(N_u) * 2.0
    off_diags_inf = np.ones(N_u - 1) * -1.0
    Delta_inf = (np.diag(diags_inf) + np.diag(off_diags_inf, 1) + np.diag(off_diags_inf, -1)) / (du**2)
    sp_Delta_inf = sp.csr_matrix(Delta_inf)
    
    Delta_I = sp_Delta_inf
    for V in V_list:
        diags_p = np.ones(V + 1) * 2.0
        off_diags_p = np.ones(V) * -1.0
        Delta_p = np.diag(diags_p) + np.diag(off_diags_p, 1) + np.diag(off_diags_p, -1)
        sp_Delta_p = sp.csr_matrix(Delta_p)
        Delta_I = sp.kronsum(Delta_I, sp_Delta_p)
        
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
    import itertools
    
    N_u = grid_params["N_u"]
    u_min = grid_params["u_min"]
    u_max = grid_params["u_max"]
    L = grid_params.get("L", 1.0)
    
    if "V_list" in grid_params:
        V_list = grid_params["V_list"]
    else:
        V_list = [grid_params["V2"], grid_params["V3"]]
        
    primes = grid_params.get("primes", [2, 3])
    
    u_vals = np.linspace(u_min, u_max, N_u)
    du = u_vals[1] - u_vals[0] if N_u > 1 else 1.0
    
    V_dims = [V + 1 for V in V_list]
    strides = []
    current_stride = 1
    for dim in reversed(V_dims):
        strides.append(current_stride)
        current_stride *= dim
    strides.reverse()
    stride_inf = current_stride
    
    N_ideles = N_u * stride_inf
    Psi = np.zeros(N_ideles)
    
    non_arch_coords = [list(range(dim)) for dim in V_dims]
    
    # Compute correlation over the idelic grid
    for i, u in enumerate(u_vals):
        b_y = np.exp(u)
        for k_tuple in itertools.product(*non_arch_coords):
            idx = i * stride_inf + sum(k_m * s_m for k_m, s_m in zip(k_tuple, strides))
            Psi[idx] = compute_correlation(
                adelic_set, 
                adelic_seq, 
                b_y=b_y, 
                k_vals=k_tuple, 
                primes=primes, 
                L=L
            )
            
    # Build Laplacian
    Delta_I = construct_idelic_laplacian(N_u, du, V_list=V_list)
    
    # Build potential: V(b) = -lambda * Psi(b)
    V_diag = -lmbda * Psi
    
    # Total Hamiltonian
    H = Delta_I + sp.diags(V_diag)
    
    # Solve for eigenvalues
    k_eigen = min(10, N_ideles - 2)
    if k_eigen <= 0:
        k_eigen = 1
        
    if N_ideles <= 500:
        import scipy.linalg as la
        H_dense = H.toarray()
        eigenvalues, eigenvectors = la.eigh(H_dense)
        eigenvalues = eigenvalues[:k_eigen]
        eigenvectors = eigenvectors[:, :k_eigen]
    else:
        from scipy.sparse.linalg import ArpackNoConvergence
        try:
            eigenvalues, eigenvectors = eigsh(H, k=k_eigen, which='SA')
        except ArpackNoConvergence:
            import scipy.linalg as la
            H_dense = H.toarray()
            eigenvalues, eigenvectors = la.eigh(H_dense)
            eigenvalues = eigenvalues[:k_eigen]
            eigenvectors = eigenvectors[:, :k_eigen]
            
    return eigenvalues, eigenvectors, Psi

def fit_confinement_scaling(primes, depths, base, M, grid_params, theta_vals=[0.2, 0.3, 0.4, 0.5], lmbda=100.0):
    """
    Solves ground-state energy for a range of theta values and performs linear regression
    against 1/(1 - theta)**2.
    
    Returns:
        beta_0: float, intercept of the scaling relation
        beta_1: float, slope of the scaling relation
        r_squared: float, coefficient of determination of the fit
    """
    energies = []
    x_vals = []
    
    N_inf = grid_params.get("N_inf", 32)
    L = grid_params.get("L", 1.0)
    
    # Pre-construct sequence
    seq = construct_adelic_sequence("geometric", M, primes=primes, depths=depths, base=base)
    
    for theta in theta_vals:
        # Construct porous set with specific theta
        set_porous = construct_adelic_set(
            "porous", 
            N_inf=N_inf, 
            primes=primes, 
            depths=depths, 
            theta=theta, 
            L=L
        )
        
        # Build local grid_params with depths
        local_params = grid_params.copy()
        local_params["V_list"] = depths
        local_params["primes"] = primes
        
        # Solve
        eigs, _, _ = solve_schrodinger_spectrum(set_porous, seq, local_params, lmbda=lmbda)
        E0 = eigs[0]
        
        energies.append(E0)
        x_vals.append(1.0 / ((1.0 - theta) ** 2))
        
    # Perform linear regression: y = beta_0 + beta_1 * x
    x = np.array(x_vals)
    y = np.array(energies)
    
    mean_x = np.mean(x)
    mean_y = np.mean(y)
    
    num = np.sum((x - mean_x) * (y - mean_y))
    den = np.sum((x - mean_x) ** 2)
    
    if den == 0:
        beta_1 = 0.0
    else:
        beta_1 = num / den
        
    beta_0 = mean_y - beta_1 * mean_x
    
    # Calculate R^2
    ss_tot = np.sum((y - mean_y) ** 2)
    ss_res = np.sum((y - (beta_0 + beta_1 * x)) ** 2)
    
    r_squared = 1.0 - (ss_res / ss_tot) if ss_tot > 0 else 1.0
    
    return float(beta_0), float(beta_1), float(r_squared)

def predict_projective_limit(primes, base, M, grid_params, target_theta, sample_depths=[1, 2, 3], gamma=0.5, lmbda=100.0):
    """
    Computes beta_0(d) and beta_1(d) for a range of small depths d,
    extrapolates their values as d -> infinity using an exponential decay basis,
    and predicts E0 for the target_theta.
    
    Returns:
        prediction: float, predicted ground-state energy E0 at d -> infinity
        extrapolated_beta0: float
        extrapolated_beta1: float
        fits_metadata: dict containing the fit parameters and R^2 values
    """
    if len(sample_depths) < 2:
        raise ValueError("Need at least 2 depths to perform d -> infinity extrapolation.")
        
    beta_0s = []
    beta_1s = []
    
    for d in sample_depths:
        current_depths = [d] * len(primes)
        b0, b1, _ = fit_confinement_scaling(
            primes=primes, 
            depths=current_depths, 
            base=base, 
            M=M, 
            grid_params=grid_params, 
            lmbda=lmbda
        )
        beta_0s.append(b0)
        beta_1s.append(b1)
        
    # Extrapolate beta_0 and beta_1 against z = exp(-gamma * d) -> 0
    z = np.exp(-gamma * np.array(sample_depths))
    
    # Fit beta_0 = a_0 + b_0 * z
    mean_z = np.mean(z)
    mean_b0 = np.mean(beta_0s)
    num_b0 = np.sum((z - mean_z) * (beta_0s - mean_b0))
    den_z = np.sum((z - mean_z) ** 2)
    
    b_coef0 = num_b0 / den_z if den_z != 0 else 0.0
    a_coef0 = mean_b0 - b_coef0 * mean_z  # Intercept representing z -> 0 (d -> inf)
    
    # Fit beta_1 = a_1 + b_1 * z
    mean_b1 = np.mean(beta_1s)
    num_b1 = np.sum((z - mean_z) * (beta_1s - mean_b1))
    
    b_coef1 = num_b1 / den_z if den_z != 0 else 0.0
    a_coef1 = mean_b1 - b_coef1 * mean_z  # Intercept representing z -> 0 (d -> inf)
    
    # Predict E0 at target_theta
    x_target = 1.0 / ((1.0 - target_theta) ** 2)
    prediction = a_coef0 + a_coef1 * x_target
    
    fits_metadata = {
        "depths": list(sample_depths),
        "beta_0s": [float(val) for val in beta_0s],
        "beta_1s": [float(val) for val in beta_1s],
        "beta_0_extrapolated": float(a_coef0),
        "beta_1_extrapolated": float(a_coef1)
    }
    
    return float(prediction), float(a_coef0), float(a_coef1), fits_metadata
