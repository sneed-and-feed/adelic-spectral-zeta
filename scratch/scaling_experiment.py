import numpy as np

def to_ternary_digits(x, d):
    """
    Returns the ternary digits of x up to length d, from least to most significant.
    """
    digits = []
    temp = x
    for _ in range(d):
        digits.append(temp % 3)
        temp //= 3
    return digits

def is_in_cantor_set(x, d):
    """
    Checks if x (mod 3^d) has only 0 and 1 in its ternary representation.
    """
    digits = to_ternary_digits(x, d)
    return all(digit in [0, 1] for digit in digits)

def run_scaling_experiment(M=5, max_d=8):
    print("======================================================================")
    print(f"Valuation Sector Density Scaling on Z_3 Cantor Set (M={M})")
    print("======================================================================")
    
    # Sequence s_n = 11^-n
    # Compute sequence terms mod 3^max_d
    mod_val = 3**max_d
    s = []
    for n in range(1, M + 1):
        # 11^-n mod 3^max_d
        val = pow(11, -n, mod_val)
        s.append(val)
        
    print("Sequence terms mod 3^max_d:")
    for n, val in enumerate(s):
        print(f"  s_{n+1} = {val} (ternary: {to_ternary_digits(val, max_d)})")
        
    depths = list(range(1, max_d + 1))
    allowed_counts = []
    
    for d in depths:
        N = 3**d
        # Construct C_{3, d}
        cantor_elements = []
        for x in range(N):
            if is_in_cantor_set(x, d):
                cantor_elements.append(x)
        
        cantor_set = set(cantor_elements)
        allowed_k = []
        
        for k in range(d + 1):
            factor = 3**k
            # Check if there exists a in cantor_set such that a + 3^k * s_n mod 3^d is in cantor_set for all n
            possible = False
            for a in cantor_elements:
                match = True
                for sn in s:
                    val = (a + factor * sn) % N
                    if val not in cantor_set:
                        match = False
                        break
                if match:
                    possible = True
                    break
            if possible:
                allowed_k.append(k)
                
        allowed_counts.append(len(allowed_k))
        density = len(allowed_k) / (d + 1)
        print(f"d = {d:2d} (3^d = {N:5d}) | Allowed k: {allowed_k} | count = {len(allowed_k)} / {d+1} ({density:.2%})")
        
    # Fit scaling law |U_d| / (d+1) = C * d^-alpha
    # log(|U_d|/(d+1)) = log(C) - alpha * log(d)
    x_fit = np.log(depths[2:])  # Fit from d=3 onwards
    y_fit = np.log([allowed_counts[i] / (depths[i] + 1) for i in range(2, len(depths))])
    
    slope, intercept = np.polyfit(x_fit, y_fit, 1)
    alpha = -slope
    print("----------------------------------------------------------------------")
    print(f"Fitted Exponent alpha (density ~ d^-alpha): {alpha:.4f}")
    print(f"Fitted Constant C: {np.exp(intercept):.4f}")
    print("======================================================================")

if __name__ == "__main__":
    run_scaling_experiment(M=4, max_d=8)
    run_scaling_experiment(M=6, max_d=8)
