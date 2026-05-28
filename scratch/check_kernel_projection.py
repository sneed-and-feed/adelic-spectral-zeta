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
    N_from = 1 << d_from
    N_to = 1 << d_to
    ratio = N_from // N_to
    P = np.zeros((N_to, N_from))
    for x in range(N_to):
        for r in range(ratio):
            P[x, x + r * N_to] = 1.0 / ratio
    return P

def main():
    for d in range(3, 8):
        # Build Kd
        A_d, B_d = build_operators(d)
        K_d = A_d @ B_d - B_d @ A_d
        
        # Build Kd_prev
        A_prev, B_prev = build_operators(d-1)
        K_prev = A_prev @ B_prev - B_prev @ A_prev
        
        # Projection P
        P = get_projection_matrix(d, d-1)
        
        # Find basis of ker(Kd)
        # We can find this by SVD of K_d
        U, S, Vt = np.linalg.svd(K_d)
        # kernel corresponds to singular values close to 0
        kernel_indices = np.where(S < 1e-10)[0]
        # if Vt is V^T, then the rows of Vt starting from the right are the kernel basis
        # Wait, SVD of K_d gives K_d = U S V^T. The kernel vectors are columns of V, i.e., rows of Vt
        basis = Vt[-len(kernel_indices)-1:, :] if len(kernel_indices) < 1 << d else Vt
        # let's be precise: S is of length min(N, N). Singular values are sorted descending.
        # So the kernel basis is Vt[len(S) - kernel_dim : ]
        kernel_dim = (1 << d) - np.linalg.matrix_rank(K_d)
        basis = Vt[-kernel_dim:]
        
        # Now project the basis
        projected_basis = basis @ P.T # shape: (kernel_dim, 2^(d-1))
        
        # Check if K_prev @ projected_basis is 0
        defect = K_prev @ projected_basis.T
        norm_defect = np.linalg.norm(defect)
        
        # Check if the map is surjective onto ker(K_prev)
        rank_proj = np.linalg.matrix_rank(projected_basis)
        prev_kernel_dim = (1 << (d-1)) - np.linalg.matrix_rank(K_prev)
        
        print(f"Depth {d} -> {d-1}:")
        print(f"  Frobenius norm of K_{d-1} @ P @ ker(K_{d}): {norm_defect:.2e}")
        print(f"  Rank of projected kernel: {rank_proj} (expected surjectivity: {prev_kernel_dim})")
        print(f"  Dimension of kernel of projection on ker(K_d): {kernel_dim - rank_proj}")

if __name__ == "__main__":
    main()
