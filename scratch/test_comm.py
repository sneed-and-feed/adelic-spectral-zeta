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

def audit():
    A_4 = build_adjacency(4) # 8x8
    A_5 = build_adjacency(5) # 16x16
    
    L = np.zeros((16, 8))
    for x in range(16):
        L[x, x % 8] = 1.0 / np.sqrt(2.0)
        
    m5 = np.ones(16)
    m5[8:] = -1.0
    U_5 = np.diag(m5) @ L # 16x8
    
    H_4 = U_5.T @ A_5 @ U_5
    
    # S_4 is the shift-by-4 matrix (8x8)
    S_4 = np.zeros((8, 8))
    for x in range(8):
        S_4[(x + 4) % 8, x] = 1.0
        
    comm = H_4 @ S_4 - S_4 @ H_4
    print("Max absolute difference in H_4 @ S_4 - S_4 @ H_4:", np.max(np.abs(comm)))
    print("Commutator matrix:")
    print(np.round(comm, 4))
    
    # Let's check off-diagonal blocks
    basis_plus = []
    basis_minus = []
    for x in range(4):
        v_plus = np.zeros(8)
        v_plus[x] = 1.0 / np.sqrt(2.0)
        v_plus[x+4] = 1.0 / np.sqrt(2.0)
        basis_plus.append(v_plus)
        
        v_minus = np.zeros(8)
        v_minus[x] = 1.0 / np.sqrt(2.0)
        v_minus[x+4] = -1.0 / np.sqrt(2.0)
        basis_minus.append(v_minus)
        
    B_plus = np.array(basis_plus).T # 8x4
    B_minus = np.array(basis_minus).T # 8x4
    
    H_plus_minus = B_plus.T @ H_4 @ B_minus # 4x4
    print("\nCross-term block (B_plus^T @ H_4 @ B_minus):")
    print(np.round(H_plus_minus, 4))
    
    H_minus_plus = B_minus.T @ H_4 @ B_plus # 4x4
    print("\nCross-term block (B_minus^T @ H_4 @ B_plus):")
    print(np.round(H_minus_plus, 4))

if __name__ == "__main__":
    audit()
