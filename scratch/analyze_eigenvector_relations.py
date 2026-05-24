import numpy as np
from scipy.linalg import eigh

def build_adjacency(depth):
    half_N = 1 << (depth - 1)
    A_G = np.zeros((half_N, half_N))
    inv_3 = 1
    for i in range(1, half_N):
        if (3 * i) % half_N == 1:
            inv_3 = i
            break
            
    for x in range(half_N):
        A_G[(3 * x) % half_N, x] += 1.0
        A_G[(3 * x - 1) % half_N, x] += 1.0
        A_G[(inv_3 * x) % half_N, x] += 1.0
        A_G[(inv_3 * (x + 1)) % half_N, x] += 1.0
    return A_G

def get_modulation_isometry(depth):
    N_d = 1 << (depth - 1)
    N_d1 = 1 << depth
    L = np.zeros((N_d1, N_d))
    for x in range(N_d1):
        L[x, x % N_d] = 1.0 / np.sqrt(2.0)
    m = np.ones(N_d1)
    m[N_d:] = -1.0
    U = np.diag(m) @ L
    return U

def analyze_depth(d):
    # Operator H_{d-1} is of size N = 2^(d-2)
    # Operator H_d is of size 2*N = 2^(d-1)
    N = 1 << (d - 2)
    A_d = build_adjacency(d)
    U_d = get_modulation_isometry(d-1)
    H_d_1 = U_d.T @ A_d @ U_d # N x N
    
    A_d1 = build_adjacency(d+1)
    U_d1 = get_modulation_isometry(d)
    H_d = U_d1.T @ A_d1 @ U_d1 # 2N x 2N
    
    # Unitary wavelet basis change W for V_d (size 2N)
    L = np.zeros((2*N, N))
    for x in range(2*N):
        L[x, x % N] = 1.0 / np.sqrt(2.0)
    U = get_modulation_isometry(d-1) # 2N x N
    W = np.hstack([L, U]) # 2N x 2N
    
    H_d_w = W.T @ H_d @ W
    A = H_d_w[0:N, 0:N]
    B = H_d_w[0:N, N:2*N]
    
    # Transform A and B to the eigenvector basis of H_{d-1}
    vals_prev, vecs_prev = eigh(H_d_1)
    A_prime = vecs_prev.T @ A @ vecs_prev
    B_prime = vecs_prev.T @ B @ vecs_prev
    
    print(f"\n================ Depth d = {d} ================")
    print("Is A + B equal to 2*I?")
    print(np.allclose(A + B, 2 * np.eye(N)))
    print("Is B - A related to H_{d-1}?")
    # Let's check if B - A is equal to H_{d-1} or a permutation thereof
    print("Norm of (B - A) - H_{d-1}:", np.linalg.norm((B - A) - H_d_1))
    print("Norm of (B - A) + H_{d-1}:", np.linalg.norm((B - A) + H_d_1))
    
    print("\nMatrix A in H_{d-1} eigenvector basis:")
    print(np.round(A_prime, 6))
    print("Matrix B in H_{d-1} eigenvector basis:")
    print(np.round(B_prime, 6))
    
    print(f"\nH_{d-1} eigenvalues:")
    for idx, val in enumerate(vals_prev):
        print(f"  {idx}: {val:.6f}")
        
    print(f"\nH_d eigenvalues:")
    vals_curr, vecs_curr = eigh(H_d)
    for idx, val in enumerate(vals_curr):
        print(f"  {idx}: {val:.6f}")
        
    # Let's project the eigenvectors of H_d (represented in split basis)
    # onto the eigenvectors of H_{d-1}
    # For an eigenvector Psi of H_d, it has split form [u, v]^T where u, v in V_{d-1}.
    # We can write u and v in the basis of eigenvectors of H_{d-1}.
    print("\nDecomposition of H_d eigenvectors in terms of H_{d-1} eigenvectors:")
    for j in range(2*N):
        psi = W.T @ vecs_curr[:, j] # psi in split basis: [u, v]^T
        u = psi[0:N]
        v = psi[N:2*N]
        
        # Project u and v onto H_{d-1} eigenvectors:
        u_proj = vecs_prev.T @ u
        v_proj = vecs_prev.T @ v
        
        val = vals_curr[j]
        print(f"\nEigenvector {j} (eigenval {val:.6f}):")
        
        # Print non-zero projections:
        print("  Symmetric part (u) projections:")
        for idx in range(N):
            if abs(u_proj[idx]) > 1e-5:
                print(f"    H_{d-1} eig {idx} (val {vals_prev[idx]:.6f}): {u_proj[idx]:.6f}")
        print("  Anti-symmetric part (v) projections:")
        for idx in range(N):
            if abs(v_proj[idx]) > 1e-5:
                print(f"    H_{d-1} eig {idx} (val {vals_prev[idx]:.6f}): {v_proj[idx]:.6f}")

if __name__ == "__main__":
    analyze_depth(3)
    analyze_depth(4)


