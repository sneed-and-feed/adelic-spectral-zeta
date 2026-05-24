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

def study_alignment():
    # Let's study depths d=4 and d=5
    # G_4 has 8 vertices, G_5 has 16 vertices.
    A_4 = build_adjacency(4) # 8x8
    A_5 = build_adjacency(5) # 16x16
    
    # Compute eigenvalues and eigenvectors
    val_4, vec_4 = eigh(A_4)
    val_5, vec_5 = eigh(A_5)
    
    print("Depth d=4 eigenvalues:")
    for idx, val in enumerate(val_4):
        print(f"  {idx}: {val:.6f}")
        
    print("\nDepth d=5 eigenvalues:")
    for idx, val in enumerate(val_5):
        print(f"  {idx}: {val:.6f}")

    # Let's check which eigenvectors are anti-symmetric.
    # For G_4, the deck transformation is shift by 2^(d-2) = 4.
    # So v(x+4) = -v(x) for anti-symmetric eigenvectors.
    print("\nDepth d=4 anti-symmetric eigenvectors:")
    anti_4_indices = []
    for idx in range(8):
        v = vec_4[:, idx]
        diff = v[4:] + v[:4]
        if np.allclose(diff, 0):
            print(f"  Eigenvalue {val_4[idx]:.6f} (index {idx}) is anti-symmetric")
            anti_4_indices.append(idx)
            
    # For G_5, the deck transformation is shift by 8.
    print("\nDepth d=5 anti-symmetric eigenvectors:")
    anti_5_indices = []
    for idx in range(16):
        v = vec_5[:, idx]
        diff = v[8:] + v[:8]
        if np.allclose(diff, 0):
            print(f"  Eigenvalue {val_5[idx]:.6f} (index {idx}) is anti-symmetric")
            anti_5_indices.append(idx)
            
    # Let's define the lift operator L: V_4 -> V_5 (periodic extension map)
    # L is a 16x8 matrix.
    L = np.zeros((16, 8))
    for x in range(16):
        L[x, x % 8] = 1.0 / np.sqrt(2.0) # normalized lift
        
    # Let's check the action of L on the anti-symmetric eigenvectors of G_4.
    # We want to see where L v maps them in V_5.
    print("\nChecking lift of G_4 anti-symmetric eigenvectors into V_5:")
    for idx in anti_4_indices:
        v = vec_4[:, idx]
        Lv = L @ v
        # Let's project Lv onto all eigenvectors of G_5:
        projections = [np.dot(Lv, vec_5[:, j]) for j in range(16)]
        print(f"  Lift of eigenvalue {val_4[idx]:.6f}:")
        for j, proj in enumerate(projections):
            if abs(proj) > 1e-5:
                print(f"    Component along G_5 eigenvector {j} (eigenval {val_5[j]:.6f}): {proj:.6f}")

if __name__ == "__main__":
    study_alignment()
