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

def verify_modulation_mapping():
    # Let's study d=4 to d=5
    # V_4 has dimension 8.
    # W_5 has dimension 8 (anti-symmetric sector of V_5 which has dimension 16).
    A_4 = build_adjacency(4) # 8x8
    A_5 = build_adjacency(5) # 16x16
    
    val_4, vec_4 = eigh(A_4)
    val_5, vec_5 = eigh(A_5)
    
    # Normalized lift L: V_4 -> V_5 (16x8)
    L = np.zeros((16, 8))
    for x in range(16):
        L[x, x % 8] = 1.0 / np.sqrt(2.0)
        
    # Modulation operator m: 16x16 diagonal matrix
    # m(x) = 1 for x < 8, -1 for x >= 8
    m = np.ones(16)
    m[8:] = -1.0
    M = np.diag(m)
    
    # Combined operator U = M @ L (16x8)
    U = M @ L
    
    # Test that U is an isometry: U^T @ U = I_8
    is_isometry = np.allclose(U.T @ U, np.eye(8))
    print(f"Is U = M @ L an isometry? {is_isometry}")
    
    # Let's project the image of U @ vec_4 onto the anti-symmetric sector of V_5.
    # The anti-symmetric sector of V_5 is spanned by eigenvectors with indices in [1, 2, 5, 6, 8, 9, 12, 13]
    anti_5_indices = []
    for idx in range(16):
        v = vec_5[:, idx]
        diff = v[8:] + v[:8]
        if np.allclose(diff, 0):
            anti_5_indices.append(idx)
            
    P_anti = np.zeros((16, 16))
    for idx in anti_5_indices:
        v = vec_5[:, idx]
        P_anti += np.outer(v, v)
        
    # Check if U maps V_4 entirely into the anti-symmetric sector of V_5:
    # This means P_anti @ U @ v = U @ v for all v, or P_anti @ U = U
    into_anti = np.allclose(P_anti @ U, U)
    print(f"Does U map V_4 entirely into the anti-symmetric sector of V_5? {into_anti}")
    
    # Let's see how the operator A_5 acts on the modulated lifts.
    # Specifically, we want to know if U intertwines A_4 and A_5.
    # Since A_5 acts on the anti-symmetric sector W_5, let's look at the matrix U^T @ A_5 @ U (which is 8x8)
    # and compare it to A_4.
    A_5_red = U.T @ A_5 @ U
    print("\nMatrix U^T @ A_5 @ U:")
    print(np.round(A_5_red, 4))
    
    print("\nMatrix A_4:")
    print(np.round(A_4, 4))
    
    # Let's compute the eigenvalues of U^T @ A_5 @ U
    val_red, _ = eigh(A_5_red)
    print(f"\nEigenvalues of U^T @ A_5 @ U: {np.round(val_red, 6)}")
    print(f"Eigenvalues of A_4:           {np.round(val_4, 6)}")

if __name__ == "__main__":
    verify_modulation_mapping()
