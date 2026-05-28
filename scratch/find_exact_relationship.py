import numpy as np

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

def find_relation(d):
    N = 1 << (d - 2)
    A_d = build_adjacency(d)
    U_d = get_modulation_isometry(d-1)
    H_d_1 = U_d.T @ A_d @ U_d # N x N
    
    A_d1 = build_adjacency(d+1)
    U_d1 = get_modulation_isometry(d)
    H_d = U_d1.T @ A_d1 @ U_d1 # 2N x 2N
    
    L = np.zeros((2*N, N))
    for x in range(2*N):
        L[x, x % N] = 1.0 / np.sqrt(2.0)
    U = get_modulation_isometry(d-1) # 2N x N
    W = np.hstack([L, U]) # 2N x 2N
    
    H_d_w = W.T @ H_d @ W
    A = H_d_w[0:N, 0:N]
    B = H_d_w[0:N, N:2*N]
    
    print(f"\n================ Depth d = {d} (N = {N}) ================")
    # Let's check: is B - A equal to some similarity transform of H_{d-1}?
    # We check if they have the same eigenvalues.
    vals_H_prev = np.linalg.eigvalsh(H_d_1)
    vals_B_minus_A = np.linalg.eigvalsh(B - A)
    print("Eigenvalues of H_{d-1}:")
    print(np.round(vals_H_prev, 6))
    print("Eigenvalues of B - A:")
    print(np.round(vals_B_minus_A, 6))
    print("Do they have the same eigenvalues?", np.allclose(vals_H_prev, vals_B_minus_A))
    
    # What about B + A?
    vals_B_plus_A = np.linalg.eigvalsh(B + A)
    print("Eigenvalues of B + A:")
    print(np.round(vals_B_plus_A, 6))

if __name__ == "__main__":
    for d in [3, 4, 5]:
        find_relation(d)
