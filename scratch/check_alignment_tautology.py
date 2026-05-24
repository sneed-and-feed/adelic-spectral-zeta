import numpy as np
import sys
sys.path.append(".")
from tests.test_eigenvector_alignment import build_adjacency, get_lift, get_modulation_isometry

def check_alignment():
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
                
            diff = np.max(np.abs(w_curr - reconstructed))
            print(f"Depth d={d}, Eigenvector k={k}: Max difference = {diff:.2e}")
            assert np.allclose(w_curr, reconstructed, atol=1e-12)

if __name__ == "__main__":
    check_alignment()
