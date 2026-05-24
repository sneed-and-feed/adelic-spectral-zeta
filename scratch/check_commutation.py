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

def check_comm(d):
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
    
    comm = A @ B - B @ A
    print(f"Depth d={d} (N={N}):")
    print("  Is A @ B == B @ A?", np.allclose(comm, 0))
    print("  Max absolute entry of [A, B]:", np.max(np.abs(comm)))

if __name__ == "__main__":
    check_comm(3)
    check_comm(4)
    check_comm(5)
