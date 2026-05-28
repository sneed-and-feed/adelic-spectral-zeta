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

def check_structure(d):
    # Operator H_{d-1} is on V_{d-1} of dimension N = 2^(d-2)
    N = 1 << (d - 2)
    A_d = build_adjacency(d)
    U_d = get_modulation_isometry(d-1)
    H_d_1 = U_d.T @ A_d @ U_d
    
    # We want to decompose V_{d-1} under S_{d-1} (shift by N/2)
    N_half = N // 2
    basis_plus = []
    basis_minus = []
    for x in range(N_half):
        v_plus = np.zeros(N)
        v_plus[x] = 1.0 / np.sqrt(2.0)
        v_plus[x + N_half] = 1.0 / np.sqrt(2.0)
        basis_plus.append(v_plus)
        
        v_minus = np.zeros(N)
        v_minus[x] = 1.0 / np.sqrt(2.0)
        v_minus[x + N_half] = -1.0 / np.sqrt(2.0)
        basis_minus.append(v_minus)
        
    B_plus = np.array(basis_plus).T
    B_minus = np.array(basis_minus).T
    
    H_plus_plus = B_plus.T @ H_d_1 @ B_plus
    H_minus_minus = B_minus.T @ H_d_1 @ B_minus
    H_plus_minus = B_plus.T @ H_d_1 @ B_minus
    H_minus_plus = B_minus.T @ H_d_1 @ B_plus
    
    print(f"\n--- Depth d = {d} (H_{d-1} matrix size {N}x{N}) ---")
    print(f"Is H_plus_plus + H_minus_minus close to 0? {np.allclose(H_plus_plus + H_minus_minus, 0)}")
    print(f"Is H_plus_minus - H_minus_plus close to 0? {np.allclose(H_plus_minus - H_minus_plus, 0)}")
    
    # Let's print the max absolute values:
    print(f"Max abs(H_plus_plus + H_minus_minus): {np.max(np.abs(H_plus_plus + H_minus_minus))}")
    print(f"Max abs(H_plus_minus - H_minus_plus): {np.max(np.abs(H_plus_minus - H_minus_plus))}")

if __name__ == "__main__":
    for d in [4, 5, 6, 7]:
        check_structure(d)
