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
    # We normalize U by 1/sqrt(2)
    return U, sp.sqrt(sp.Rational(1, 2))

def study_symbolic():
    # Build G_3, G_4, G_5:
    A3 = build_adjacency_symbolic(3) # 4x4
    A4 = build_adjacency_symbolic(4) # 8x8
    A5 = build_adjacency_symbolic(5) # 16x16
    
    U3, scale3 = get_isometry_symbolic(2) # 4x2
    H2 = scale3**2 * (U3.T * A3 * U3) # 2x2
    
    U4, scale4 = get_isometry_symbolic(3) # 8x4
    H3 = scale4**2 * (U4.T * A4 * U4) # 4x4
    
    U5, scale5 = get_isometry_symbolic(4) # 16x8
    H4 = scale5**2 * (U5.T * A5 * U5) # 8x8
    
    # H_5 = U_6^T @ A_6 @ U_6 (16x16)
    A6 = build_adjacency_symbolic(6)
    U6, scale6 = get_isometry_symbolic(5)
    H5 = scale6**2 * (U6.T * A6 * U6) # 16x16
    
    print("Exact symbolic H_2 (size 2x2):")
    sp.pprint(H2)
    
    print("\nExact symbolic H_3 (size 4x4):")
    sp.pprint(H3)
    
    print("\nExact symbolic H_4 (size 8x8):")
    sp.pprint(H4)
    
    # Let's find the eigenvalues and eigenvectors of H_3:
    print("\nEigenvalues of H_3:")
    sp.pprint(H3.eigenvals())
    
    # Let's find eigenvalues and eigenvectors of H_4:
    lam = sp.symbols('lam')
    cp4 = H4.charpoly(lam)
    print("\nCharacteristic polynomial of H_4 in lambda:")
    sp.pprint(sp.factor(cp4.as_expr()))
    
    # Let's factor characteristic polynomial of H_5:
    cp5 = H5.charpoly(lam)
    print("\nCharacteristic polynomial of H_5 in lambda:")
    sp.pprint(sp.factor(cp5.as_expr()))

if __name__ == "__main__":
    study_symbolic()
