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

def check_chiral(d):
    N = 1 << (d - 2)
    A_d = build_adjacency(d)
    U_d = get_modulation_isometry(d-1)
    H_d_1 = U_d.T @ A_d @ U_d
    
    # Construct J_twist in the V_{d-1} basis = V_{d-2} \oplus V_{d-2}
    # J_twist = [[0, -I], [I, 0]]
    # Since H_d_1 is in the standard basis, let's represent J_twist in the standard basis.
    # The basis change is W = [B_plus, B_minus]
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
    W = np.hstack([B_plus, B_minus]) # N x N
    
    # J_twist in block basis:
    J_block = np.zeros((N, N))
    J_block[0:N_half, N_half:N] = -np.eye(N_half)
    J_block[N_half:N, 0:N_half] = np.eye(N_half)
    
    # J_twist in standard basis:
    J_standard = W @ J_block @ W.T
    
    # Check if J_standard anti-commutes with H_d_1:
    anti_comm = J_standard @ H_d_1 + H_d_1 @ J_standard
    print(f"Depth d = {d} (N = {N}):")
    print(f"  Is J @ H + H @ J close to 0? {np.allclose(anti_comm, 0)}")
    print(f"  Max absolute entry of J @ H + H @ J: {np.max(np.abs(anti_comm))}")

if __name__ == "__main__":
    for d in [4, 5, 6, 7]:
        check_chiral(d)
