import numpy as np
import pytest

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
    N_d = 1 << (depth - 1)
    N_d1 = 1 << depth
    L = np.zeros((N_d1, N_d))
    for x in range(N_d1):
        L[x, x % N_d] = 1.0 / np.sqrt(2.0)
    m = np.ones(N_d1)
    m[N_d:] = -1.0
    U = np.diag(m) @ L
    return U

def test_wavelet_block_diagonalization():
    r"""Test that A_G_d is unitarily equivalent to A_G_2 \oplus H_2 \oplus ... \oplus H_{d-1}"""
    for d in range(3, 8):
        N = 1 << (d - 1)
        A_d = build_adjacency(d)
        
        # Construct the wavelet basis change matrix W
        # Subspace 1: L^(d-2)(V_2)
        W_parts = [get_lift(2, d)]
        
        # Subspaces 2 to d: L^(d-k)(W_k) for k = 3 to d
        # W_k is the image of U_k: V_{k-1} -> V_k
        for k in range(3, d + 1):
            U_k = get_modulation_isometry(k - 1)
            L_k_d = get_lift(k, d)
            W_parts.append(L_k_d @ U_k)
            
        W = np.hstack(W_parts)
        
        # Check that W is unitary
        assert np.allclose(W.T @ W, np.eye(N), atol=1e-12)
        
        # Transform A_d to the wavelet basis
        A_w = W.T @ A_d @ W
        
        # Test the block-diagonal structure
        # Block dimensions: 2, 2, 4, 8, ..., 2^(d-2)
        block_dims = [2] + [1 << (k - 2) for k in range(3, d + 1)]
        
        # Create a mask for the block-diagonal entries
        mask = np.ones((N, N), dtype=bool)
        start = 0
        for dim in block_dims:
            mask[start:start+dim, start:start+dim] = False
            start += dim
            
        # Assert that all off-diagonal block entries are close to zero
        assert np.max(np.abs(A_w[mask])) < 1e-12
        
        # Test that the blocks match A_2 and H_{k-1}
        start = 0
        A_2 = build_adjacency(2)
        assert np.allclose(A_w[start:start+2, start:start+2], A_2, atol=1e-12)
        start += 2
        
        for k in range(3, d + 1):
            dim = 1 << (k - 2)
            # Expected block is H_{k-1} = U_k^T @ A_k @ U_k
            A_k = build_adjacency(k)
            U_k = get_modulation_isometry(k - 1)
            H_k_1 = U_k.T @ A_k @ U_k
            assert np.allclose(A_w[start:start+dim, start:start+dim], H_k_1, atol=1e-12)
            start += dim

def test_chiral_symmetry():
    """Test that H_{d-1} satisfies J H + H J = 0 in the split basis"""
    for d in range(4, 8):
        N = 1 << (d - 2)
        A_d = build_adjacency(d)
        U_d = get_modulation_isometry(d - 1)
        H_d_1 = U_d.T @ A_d @ U_d
        
        # Split basis transformation for V_{d-1}: L_{d-2->d-1} and U_{d-1}
        L = get_lift(d - 2, d - 1)
        U = get_modulation_isometry(d - 2)
        W = np.hstack([L, U])
        
        # Transform H_{d-1} to the split basis
        H_split = W.T @ H_d_1 @ W
        
        # Check that H_split has the block form [[A, B], [B, -A]]
        N_half = N // 2
        A = H_split[0:N_half, 0:N_half]
        B1 = H_split[0:N_half, N_half:N]
        B2 = H_split[N_half:N, 0:N_half]
        C = H_split[N_half:N, N_half:N]
        
        # Assert symmetry of A and B
        assert np.allclose(A, A.T, atol=1e-12)
        assert np.allclose(B1, B1.T, atol=1e-12)
        
        # Assert C = -A and B2 = B1
        assert np.allclose(C, -A, atol=1e-12)
        assert np.allclose(B1, B2, atol=1e-12)
        
        # Assert J @ H_split + H_split @ J = 0
        J = np.zeros((N, N))
        J[0:N_half, N_half:N] = -np.eye(N_half)
        J[N_half:N, 0:N_half] = np.eye(N_half)
        
        anti_comm = J @ H_split + H_split @ J
        assert np.allclose(anti_comm, 0, atol=1e-12)

def test_scale_crossing_isometries():
    """Test the isometric and orthogonal properties of T_d and R_d"""
    for d in range(3, 7):
        N_prev = 1 << (d - 2)
        N_curr = 1 << (d - 1)
        
        # Coordinate-free representations of T_d and R_d as maps V_d -> V_{d+1}
        # T_d = U_{d+1} @ L_d @ U_d^T
        # R_d = U_{d+1} @ U_d @ U_d^T
        # We check their action on the detail space W_d.
        # W_d is the image of U_d: V_{d-1} -> V_d.
        U_d = get_modulation_isometry(d - 1) # V_d x V_{d-1}
        L_d = get_lift(d - 1, d) # V_d x V_{d-1}
        U_d1 = get_modulation_isometry(d) # V_{d+1} x V_d
        
        # We can construct T_d and R_d as matrices of size 2^d x 2^(d-2)
        # mapping the coordinate space V_{d-1} (representing W_d)
        # to V_{d+1} (representing W_{d+1}):
        T_d = U_d1 @ L_d # V_{d+1} x V_{d-1}
        R_d = U_d1 @ U_d # V_{d+1} x V_{d-1}
        
        # Test that T_d and R_d are isometries
        assert np.allclose(T_d.T @ T_d, np.eye(N_prev), atol=1e-12)
        assert np.allclose(R_d.T @ R_d, np.eye(N_prev), atol=1e-12)
        
        # Test that they have orthogonal ranges
        assert np.allclose(T_d.T @ R_d, 0, atol=1e-12)
        
        # Test that their ranges span the detail space W_{d+1} (columns of U_{d+1})
        # i.e., T_d @ T_d^T + R_d @ R_d^T = U_{d+1} @ U_{d+1}^T
        P_T = T_d @ T_d.T
        P_R = R_d @ R_d.T
        P_W = U_d1 @ U_d1.T
        assert np.allclose(P_T + P_R, P_W, atol=1e-12)

def test_eigenvector_alignment_recursion():
    """Test that the anti-symmetric eigenvectors at scale d+1 are reconstructed
    exactly from the anti-symmetric eigenvectors at scale d via T_d and R_d."""
    for d in range(3, 6):
        # Scale d detail eigenvectors
        A_d = build_adjacency(d)
        U_d = get_modulation_isometry(d-1)
        H_d_1 = U_d.T @ A_d @ U_d
        vals_prev, vecs_prev = np.linalg.eigh(H_d_1)
        
        # Scale d+1 detail eigenvectors
        A_d1 = build_adjacency(d+1)
        U_d1 = get_modulation_isometry(d)
        H_d = U_d1.T @ A_d1 @ U_d1
        vals_curr, vecs_curr = np.linalg.eigh(H_d)
        
        N_prev = 1 << (d - 2)
        N_curr = 1 << (d - 1)
        
        # Wavelet change of basis matrix for V_d
        L_d = get_lift(d-1, d)
        U_d_prev = get_modulation_isometry(d-1)
        W_d = np.hstack([L_d, U_d_prev])
        
        # Transition operators
        T_d = U_d1 @ L_d
        R_d = U_d1 @ U_d_prev
        
        for k in range(N_curr):
            psi_k = vecs_curr[:, k]
            w_curr = U_d1 @ psi_k
            
            split_coords = W_d.T @ psi_k
            u_k = split_coords[0:N_prev]
            v_k = split_coords[N_prev:2*N_prev]
            
            c = vecs_prev.T @ u_k
            d_coeff = vecs_prev.T @ v_k
            
            reconstructed = np.zeros_like(w_curr)
            for j in range(N_prev):
                reconstructed += c[j] * (T_d @ vecs_prev[:, j]) + d_coeff[j] * (R_d @ vecs_prev[:, j])
                
            assert np.allclose(w_curr, reconstructed, atol=1e-12)
