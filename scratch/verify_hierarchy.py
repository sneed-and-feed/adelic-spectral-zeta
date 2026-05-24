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

def study_hierarchical_decomposition():
    A_4 = build_adjacency(4) # 8x8
    A_5 = build_adjacency(5) # 16x16
    
    L = np.zeros((16, 8))
    for x in range(16):
        L[x, x % 8] = 1.0 / np.sqrt(2.0)
        
    m5 = np.ones(16)
    m5[8:] = -1.0
    U_5 = np.diag(m5) @ L # 16x8
    
    # H_4 is the twisted operator on V_4: H_4 = U_5^T @ A_5 @ U_5
    H_4 = U_5.T @ A_5 @ U_5
    
    # Let's check if H_4 commutes with the deck transformation of V_4, which is shift by 4:
    # S_4 is the shift-by-4 matrix (8x8)
    S_4 = np.zeros((8, 8))
    for x in range(8):
        S_4[(x + 4) % 8, x] = 1.0
        
    comm = H_4 @ S_4 - S_4 @ H_4
    print(f"Does H_4 commute with shift-by-4? {np.allclose(comm, 0)}")
    
    # Since it commutes, we can decompose H_4 into symmetric and anti-symmetric sectors:
    # P_sym = 0.5 * (I + S_4), P_anti = 0.5 * (I - S_4)
    # Let's check eigenvalues of H_4 on symmetric and anti-symmetric sectors of V_4:
    # We can project H_4 onto V_4^+ and V_4^-:
    # Let's construct a basis for V_4^+ (dimension 4) and V_4^- (dimension 4):
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
    
    H_plus = B_plus.T @ H_4 @ B_plus # 4x4
    H_minus = B_minus.T @ H_4 @ B_minus # 4x4
    
    print("\nMatrix H_plus (symmetric sector of H_4):")
    print(np.round(H_plus, 4))
    print("\nMatrix H_minus (anti-symmetric sector of H_4):")
    print(np.round(H_minus, 4))
    
    val_plus, _ = eigh(H_plus)
    val_minus, _ = eigh(H_minus)
    print(f"\nEigenvalues of H_plus:  {np.round(val_plus, 6)}")
    print(f"Eigenvalues of H_minus: {np.round(val_minus, 6)}")

if __name__ == "__main__":
    study_hierarchical_decomposition()
