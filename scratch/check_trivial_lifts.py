import numpy as np

def build_operators(depth):
    N = 1 << depth
    A = np.zeros((N, N))
    for x in range(N):
        A[(x + 1) % N, x] = 1.0
        
    B_alg = np.zeros((N, N))
    inv_3 = 1
    for i in range(1, N):
        if (3 * i) % N == 1:
            inv_3 = i
            break
    for x in range(N):
        y1 = (2 * x) % N
        B_alg[x, y1] += 0.5
        y2 = ((2 * x - 1) * inv_3) % N
        B_alg[x, y2] += 0.5
        
    return A, B_alg

def main():
    for d in range(3, 7):
        # Build Kd_prev
        A_prev, B_prev = build_operators(d-1)
        K_prev = A_prev @ B_prev - B_prev @ A_prev
        
        # Get basis of ker(K_prev)
        U, S, Vt = np.linalg.svd(K_prev)
        kernel_dim_prev = (1 << (d-1)) - np.linalg.matrix_rank(K_prev)
        basis_prev = Vt[-kernel_dim_prev:] # shape: (kernel_dim_prev, 2^(d-1))
        
        # Build Kd
        A_d, B_d = build_operators(d)
        K_d = A_d @ B_d - B_d @ A_d
        
        # Trivial lift of the basis: repeat each element twice (or tile)
        # Since psi_d(x) = psi_prev(x mod 2^(d-1)), the vector is just duplicated: [v, v]
        trivial_lifts = np.hstack([basis_prev, basis_prev]) # shape: (kernel_dim_prev, 2^d)
        
        # Check if Kd @ trivial_lifts.T is 0
        defect = K_d @ trivial_lifts.T
        norm_defect = np.linalg.norm(defect, axis=0) # norm of defect for each basis vector
        
        print(f"Depth {d-1} -> {d}:")
        print(f"  For each of the {kernel_dim_prev} basis vectors, the Kd defect of its trivial lift is:")
        print("  ", np.round(norm_defect, 6))

if __name__ == "__main__":
    main()
