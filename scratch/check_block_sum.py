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

def check_block_sum(d):
    N = 1 << (d - 2)
    A_d = build_adjacency(d)
    U_d = get_modulation_isometry(d-1)
    H_d_1 = U_d.T @ A_d @ U_d
    
    # Lower scale twisted operator H_{d-2} (dimension N/2 x N/2)
    A_d_1 = build_adjacency(d-1)
    U_d_1 = get_modulation_isometry(d-2)
    H_d_2 = U_d_1.T @ A_d_1 @ U_d_1
    
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
    
    A = B_plus.T @ H_d_1 @ B_plus
    B = B_plus.T @ H_d_1 @ B_minus
    
    print(f"\n--- Depth d = {d} ---")
    print(f"H_{d-2} eigenvalues: ", np.round(np.linalg.eigvalsh(H_d_2), 6))
    print(f"A + B eigenvalues:   ", np.round(np.linalg.eigvalsh(A + B), 6))
    print(f"A - B eigenvalues:   ", np.round(np.linalg.eigvalsh(A - B), 6))
    print(f"Is A + B equal to H_{d-2}? {np.allclose(A + B, H_d_2)}")
    
    # Check if they are related by a diagonal sign change (gauge equivalence)
    # A gauge twist on V_{d-2} is a diagonal matrix of signs S = diag(s_1, ..., s_k) where s_i \in {+1, -1}.
    # We want to check if there exists S such that S @ (A + B) @ S = H_{d-2}.
    # Since the size is small, we can check all 2^(N/2) possible sign combinations.
    found = False
    for bits in range(1 << N_half):
        s = np.array([1.0 if (bits & (1 << i)) else -1.0 for i in range(N_half)])
        S = np.diag(s)
        if np.allclose(S @ (A + B) @ S, H_d_2):
            print(f"Found gauge equivalence S @ (A + B) @ S = H_{d-2} with s = {s}")
            found = True
            break
    if not found:
        print("No simple diagonal gauge equivalence found for A + B.")
        
    found_minus = False
    for bits in range(1 << N_half):
        s = np.array([1.0 if (bits & (1 << i)) else -1.0 for i in range(N_half)])
        S = np.diag(s)
        if np.allclose(S @ (A - B) @ S, H_d_2):
            print(f"Found gauge equivalence S @ (A - B) @ S = H_{d-2} with s = {s}")
            found_minus = True
            break
    if not found_minus:
        print("No simple diagonal gauge equivalence found for A - B.")

if __name__ == "__main__":
    for d in [4, 5, 6]:
        check_block_sum(d)
