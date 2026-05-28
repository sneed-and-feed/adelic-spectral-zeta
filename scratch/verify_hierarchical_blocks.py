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

def get_lift(from_depth, to_depth):
    N_from = 1 << (from_depth - 1)
    N_to = 1 << (to_depth - 1)
    ratio = N_to // N_from
    L = np.zeros((N_to, N_from))
    for x in range(N_to):
        L[x, x % N_from] = 1.0 / np.sqrt(ratio)
    return L

def get_modulation_isometry(depth):
    # U_{d+1} = M_d @ L : V_d -> V_{d+1}
    N_d = 1 << (depth - 1)
    N_d1 = 1 << depth
    L = np.zeros((N_d1, N_d))
    for x in range(N_d1):
        L[x, x % N_d] = 1.0 / np.sqrt(2.0)
    m = np.ones(N_d1)
    m[N_d:] = -1.0
    U = np.diag(m) @ L
    return U

def verify_blocks():
    # Let's test at depth d = 5 (N = 16)
    # V_5 decomposes into:
    # L^3(V_2) (dim 2)
    # L^2(W_3) (dim 2)
    # L^1(W_4) (dim 4)
    # W_5 (dim 8)
    # Total dimension: 2 + 2 + 4 + 8 = 16.
    
    # Let's get the operators:
    A_2 = build_adjacency(2) # 2x2
    A_3 = build_adjacency(3) # 4x4
    A_4 = build_adjacency(4) # 8x8
    A_5 = build_adjacency(5) # 16x16
    
    # Let's define H_k:
    # H_2 = U_3^T @ A_3 @ U_3 (2x2)
    U_3 = get_modulation_isometry(2)
    H_2 = U_3.T @ A_3 @ U_3
    
    # H_3 = U_4^T @ A_4 @ U_4 (4x4)
    U_4 = get_modulation_isometry(3)
    H_3 = U_4.T @ A_4 @ U_4
    
    # H_4 = U_5^T @ A_5 @ U_5 (8x8)
    U_5 = get_modulation_isometry(4)
    H_4 = U_5.T @ A_5 @ U_5
    
    # Now let's construct the basis vectors for each subspace in V_5:
    # Subspace 1: L^3(V_2) -> lift of V_2 all the way to V_5.
    L_2_5 = get_lift(2, 5) # 16x2
    
    # Subspace 2: L^2(W_3) -> since W_3 is image of U_3: V_2 -> V_3,
    # we map V_2 -> W_3 -> V_5 via L_3_5 @ U_3.
    L_3_5 = get_lift(3, 5) # 16x4
    W_3_in_5 = L_3_5 @ U_3 # 16x2
    
    # Subspace 3: L^1(W_4) -> L_4_5 @ U_4.
    L_4_5 = get_lift(4, 5) # 16x8
    W_4_in_5 = L_4_5 @ U_4 # 16x4
    
    # Subspace 4: W_5 -> U_5.
    W_5_in_5 = U_5 # 16x8
    
    # Let's concatenate these to form a transformation matrix W of size 16x16:
    W = np.hstack([L_2_5, W_3_in_5, W_4_in_5, W_5_in_5])
    
    # Test that W is a unitary matrix: W^T @ W = I
    is_unitary = np.allclose(W.T @ W, np.eye(16))
    print(f"Is the hierarchical wavelet transform W unitary? {is_unitary}")
    
    # Compute the matrix of A_5 in the wavelet basis: A_5_wavelet = W^T @ A_5 @ W
    A_5_w = W.T @ A_5 @ W
    
    print("\nBlock structure of A_5 in the wavelet basis:")
    # We expect 4 blocks: 2x2, 2x2, 4x4, 8x8.
    # Let's check if the off-diagonal entries are zero.
    mask = np.ones((16, 16), dtype=bool)
    mask[0:2, 0:2] = False
    mask[2:4, 2:4] = False
    mask[4:8, 4:8] = False
    mask[8:16, 8:16] = False
    
    off_diagonal_max = np.max(np.abs(A_5_w[mask]))
    print(f"Max absolute off-diagonal value between blocks: {off_diagonal_max}")
    
    # Let's compare the diagonal blocks with the expected operators:
    block1 = A_5_w[0:2, 0:2]
    block2 = A_5_w[2:4, 2:4]
    block3 = A_5_w[4:8, 4:8]
    block4 = A_5_w[8:16, 8:16]
    
    print("\nCompare block 1 with A_2:")
    print("Close?", np.allclose(block1, A_2))
    
    print("Compare block 2 with H_2:")
    print("Close?", np.allclose(block2, H_2))
    
    print("Compare block 3 with H_3:")
    print("Close?", np.allclose(block3, H_3))
    
    print("Compare block 4 with H_4:")
    print("Close?", np.allclose(block4, H_4))

if __name__ == "__main__":
    verify_blocks()
