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

def get_projection_matrix(d_from, d_to):
    # Matrix of size 2^d_to x 2^d_from representing the conditional expectation projection
    N_from = 1 << d_from
    N_to = 1 << d_to
    ratio = N_from // N_to
    P = np.zeros((N_to, N_from))
    for x in range(N_to):
        for r in range(ratio):
            P[x, x + r * N_to] = 1.0 / ratio
    return P

def main():
    # We will compute the dimension of the compatible kernel at depth d
    # A vector psi_d is in the compatible kernel if:
    # 1. K_d psi_d = 0
    # 2. K_{d-1} P_{d \to d-1} psi_d = 0
    # ...
    # 3. K_2 P_{d \to 2} psi_d = 0
    
    for d in range(2, 9):
        N = 1 << d
        constraints = []
        
        # Build constraints for each level j from 2 to d
        for j in range(2, d + 1):
            A_j, B_j = build_operators(j)
            K_j = A_j @ B_j - B_j @ A_j
            
            if j == d:
                constraints.append(K_j)
            else:
                P = get_projection_matrix(d, j)
                constraints.append(K_j @ P)
                
        # Stack all constraints vertically
        all_constraints = np.vstack(constraints)
        
        # Find the rank and nullity of the stacked constraint matrix
        rank = np.linalg.matrix_rank(all_constraints)
        nullity = N - rank
        
        print(f"Depth {d} (N={N}):")
        print(f"  Dimension of ker(K_d) alone: {N - np.linalg.matrix_rank(constraints[-1])}")
        print(f"  Dimension of compatible kernel: {nullity}")

if __name__ == "__main__":
    main()
