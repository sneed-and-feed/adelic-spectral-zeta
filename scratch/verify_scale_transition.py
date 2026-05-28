import sympy as sp
import numpy as np

def build_adjacency_symbolic(depth):
    half_N = 1 << (depth - 1)
    A_G = sp.Matrix.zeros(half_N, half_N)
    inv_3 = 1
    for i in range(1, half_N):
        if (3 * i) % half_N == 1:
            inv_3 = i
            break
            
    for x in range(half_N):
        A_G[(3 * x) % half_N, x] += 1
        A_G[(3 * x - 1) % half_N, x] += 1
        A_G[(inv_3 * x) % half_N, x] += 1
        A_G[(inv_3 * (x + 1)) % half_N, x] += 1
    return A_G

def get_isometry_symbolic(depth):
    N_d = 1 << (depth - 1)
    N_d1 = 1 << depth
    L = sp.Matrix.zeros(N_d1, N_d)
    for x in range(N_d1):
        L[x, x % N_d] = 1
    m = [1]*N_d1
    for x in range(N_d, N_d1):
        m[x] = -1
    M = sp.diag(*m)
    U = M * L
    return U, sp.sqrt(sp.Rational(1, 2))

def verify_transition():
    # Let's study d = 6. H_5 has size 16x16.
    A5 = build_adjacency_symbolic(5) # 16x16
    A6 = build_adjacency_symbolic(6) # 32x32
    
    U5, scale5 = get_isometry_symbolic(4) # 16x8
    H4 = scale5**2 * (U5.T * A5 * U5) # 8x8
    
    U6, scale6 = get_isometry_symbolic(5) # 32x16
    H5 = scale6**2 * (U6.T * A6 * U6) # 16x16
    
    # Wavelet basis change W for V_5 (size 16)
    L45 = sp.Matrix.zeros(16, 8)
    for x in range(16):
        L45[x, x % 8] = 1
    L45 = L45 * sp.sqrt(sp.Rational(1, 2))
    U5_norm = U5 * scale5
    
    W = sp.Matrix.zeros(16, 16)
    W[:, 0:8] = L45
    W[:, 8:16] = U5_norm
    
    H5_w = W.T * H5 * W
    
    A_4 = H5_w[0:8, 0:8]
    B_4 = H5_w[0:8, 8:16]
    
    print("Matrix B_4 - A_4:")
    sp.pprint(B_4 - A_4)
    
    print("\nMatrix H4:")
    sp.pprint(H4)
    
    # Check if B_4 - A_4 is diagonal:
    is_diag = True
    for r in range(8):
        for c in range(8):
            if r != c and (B_4 - A_4)[r, c] != 0:
                is_diag = False
                break
    print(f"\nIs B_4 - A_4 diagonal? {is_diag}")

if __name__ == "__main__":
    verify_transition()
