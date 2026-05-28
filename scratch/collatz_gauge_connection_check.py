import numpy as np

def two_adic_val(n):
    if n == 0:
        return float('inf')
    val = 0
    while n % 2 == 0:
        val += 1
        n //= 2
    return val

def two_adic_dist(x, y, N):
    diff = (x - y) % N
    val = two_adic_val(diff)
    if val == float('inf'):
        return 0.0
    return 2.0**(-val)

def build_tv_dirac(depth):
    N = 1 << depth
    D = np.zeros((N, N))
    
    # Haar measure of each point in Z/2^d Z is 1/N
    measure = 1.0 / N
    
    for x in range(N):
        diag_val = 0.0
        for y in range(N):
            if x != y:
                d = two_adic_dist(x, y, N)
                weight = measure / (d**2)
                D[x, y] = -weight
                diag_val += weight
        D[x, x] = diag_val
    return D

def build_parity_projections(depth):
    N = 1 << depth
    P0 = np.zeros((N, N))
    P1 = np.zeros((N, N))
    for x in range(N):
        if x % 2 == 0:
            P0[x, x] = 1.0
        else:
            P1[x, x] = 1.0
    return P0, P1

def build_collatz_operator(depth):
    N = 1 << depth
    B = np.zeros((N, N))
    
    # Find modular inverse of 3 mod N
    inv_3 = 1
    for i in range(1, N):
        if (3 * i) % N == 1:
            inv_3 = i
            break
            
    for x in range(N):
        # Even preimage: y = 2x
        y1 = (2 * x) % N
        B[x, y1] += 0.5
        
        # Odd preimage: y = (2x - 1) * 3^{-1}
        y2 = ((2 * x - 1) * inv_3) % N
        B[x, y2] += 0.5
        
    return B

def main():
    print("--- Testing Noncommutative Connection 1-form ---")
    depth = 5
    N = 1 << depth
    
    D = build_tv_dirac(depth)
    P0, P1 = build_parity_projections(depth)
    B = build_collatz_operator(depth)
    
    # Connection 1-form omega = P0 D P0 + P1 D P1 - D
    omega = P0 @ D @ P0 + P1 @ D @ P1 - D
    
    # Formula omega_formula = 1/N for x != y mod 2, else 0
    omega_formula = np.zeros((N, N))
    for x in range(N):
        for y in range(N):
            if (x % 2) != (y % 2):
                omega_formula[x, y] = 1.0 / N
                
    diff_omega = omega - omega_formula
    norm_diff_omega = np.linalg.norm(diff_omega, ord='fro')
    print(f"Connection 1-form Frobenius Difference: {norm_diff_omega:.10e}")
    
    # Now test commutator [B, omega]
    comm = B @ omega - omega @ B
    
    # Rank-1 formula: [B, omega] = 0.5 * |u><v|
    # u is parity: u[x] = (-1)^(x mod 2)
    # v is coarse parity: v[y] = 1 if y mod 4 in (0, 1) else -1
    u = np.zeros(N)
    v = np.zeros(N)
    for x in range(N):
        u[x] = 1.0 if x % 2 == 0 else -1.0
        v[x] = 1.0 if (x % 4) in (0, 1) else -1.0
        
    # Scale by L^2 normalization / integration weights:
    # In L^2(Z/2^d Z), the inner product has 1/N weight.
    # So the operator |u><v| acting on f is (1/N) * u * (v^T f).
    # Thus, as a matrix, (|u><v|)_{x, y} = (1/N) * u[x] * v[y].
    comm_formula = np.zeros((N, N))
    for x in range(N):
        for y in range(N):
            comm_formula[x, y] = 0.5 * (1.0 / N) * u[x] * v[y]
            
    diff_comm = comm - comm_formula
    norm_diff_comm = np.linalg.norm(diff_comm, ord='fro')
    print(f"Commutator [B, omega] Frobenius Difference: {norm_diff_comm:.10e}")

if __name__ == "__main__":
    main()
