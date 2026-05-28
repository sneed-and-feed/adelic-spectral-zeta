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

def analyze_algebra():
    A4 = build_adjacency_symbolic(4) # 8x8
    A5 = build_adjacency_symbolic(5) # 16x16
    
    U4, scale4 = get_isometry_symbolic(3) # 8x4
    H3 = scale4**2 * (U4.T * A4 * U4) # 4x4
    
    U5, scale5 = get_isometry_symbolic(4) # 16x8
    H4 = scale5**2 * (U5.T * A5 * U5) # 8x8
    
    # We construct the basis transformation W for V_4 (size 8):
    # W = [B_plus, B_minus]
    # B_plus is the normalized lift L_{3,4} (8x4)
    # B_minus is U_4 (8x4)
    L34 = sp.Matrix.zeros(8, 4)
    for x in range(8):
        L34[x, x % 4] = 1
    L34 = L34 * sp.sqrt(sp.Rational(1, 2))
    
    # U4 is scaled by scale4 = 1/sqrt(2)
    U4_norm = U4 * scale4
    
    W = sp.Matrix.zeros(8, 8)
    W[:, 0:4] = L34
    W[:, 4:8] = U4_norm
    
    # Check if W is orthogonal: W.T * W
    print("Is W orthogonal? (W.T * W):")
    sp.pprint(W.T * W)
    
    # Now let's transform H4: H4_w = W.T * H4 * W
    H4_w = W.T * H4 * W
    
    A = H4_w[0:4, 0:4]
    B = H4_w[0:4, 4:8]
    
    print("\nMatrix A (symmetric block of H4 in wavelet basis):")
    sp.pprint(A)
    
    print("\nMatrix B (cross block of H4 in wavelet basis):")
    sp.pprint(B)
    
    print("\nMatrix H3 (twisted operator at scale 3):")
    sp.pprint(H3)
    
    print("\nMatrix A_G_3 (adjacency of G_3):")
    A_G_3 = build_adjacency_symbolic(3)
    sp.pprint(A_G_3)
    
    # Let's check relation of A and B with H3 and A_G_3:
    # We want to see if we can write A and B as linear combinations of H3 and other matrices.
    # Note that A and B have size 4x4.
    # Let's check:
    # A_G_3 is:
    # [2  0  0  2]
    # [0  0  2  0]
    # [0  2  0  2]
    # [2  0  2  0]
    # And H3 is:
    # [2  0   0  0]
    # [0  0   0  2]
    # [0  0  -2  0]
    # [0  2   0  0]
    
    # Let's check if A is a gauge-twisted version of H3 or A_G_3.
    # Let's print the entries of A and B side-by-side with A_G_3 and H3:
    print("\nLet's compare elements:")
    print("A:")
    sp.pprint(A)
    print("B:")
    sp.pprint(B)

if __name__ == "__main__":
    analyze_algebra()
