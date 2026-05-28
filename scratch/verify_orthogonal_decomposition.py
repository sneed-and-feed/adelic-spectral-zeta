import numpy as np

def get_modulation_isometry(depth):
    # U_{d} maps V_{d-1} -> W_d \subset V_d
    # depth = d
    N_d_1 = 1 << (depth - 2)
    N_d = 1 << (depth - 1)
    L = np.zeros((N_d, N_d_1))
    for x in range(N_d):
        L[x, x % N_d_1] = 1.0 / np.sqrt(2.0)
    m = np.ones(N_d)
    m[N_d_1:] = -1.0
    U = np.diag(m) @ L
    return U

def get_lift(depth):
    # L maps V_{d-1} -> V_d
    N_d_1 = 1 << (depth - 2)
    N_d = 1 << (depth - 1)
    L = np.zeros((N_d, N_d_1))
    for x in range(N_d):
        L[x, x % N_d_1] = 1.0 / np.sqrt(2.0)
    return L

def verify_decomposition(d):
    # d is the scale of the domain space.
    # W_d has dimension 2^(d-2).
    # W_{d+1} has dimension 2^(d-1).
    # We construct T_d and R_d as matrices of size 2^d x 2^(d-1) (using the full V_{d+1} coordinate representation)
    # wait, or as operators from W_d to W_{d+1}?
    # W_d is the image of U_d: V_{d-1} -> V_d.
    # So we can represent T_d and R_d as operators from V_{d-1} to V_d:
    # T_d_rep = U_{d+1} @ L_d @ U_d^T (size 2^d x 2^(d-1))
    # where L_d is the lift V_{d-1} -> V_d.
    # U_d is the modulation V_{d-1} -> V_d.
    # Wait, the domain is W_d (which is a subspace of V_d).
    # If we parameterize W_d using the V_{d-1} coordinates (via U_d), and W_{d+1} using V_d coordinates (via U_{d+1}):
    # Then T_d is represented as a matrix from V_{d-1} to V_d:
    # T_d_coord = U_{d+1}^T @ U_{d+1} @ L @ U_d^T @ U_d = L (size V_d x V_{d-1})?
    # No! Let's be precise.
    # Let's write everything in V_{d+1} and V_d:
    # W_d has basis vectors given by the columns of U_d.
    # W_{d+1} has basis vectors given by the columns of U_{d+1}.
    # We want to represent T_d and R_d as matrices of size dim(W_{d+1}) x dim(W_d), i.e., 2^(d-1) x 2^(d-2).
    # The basis for W_d is the columns of U_d.
    # The basis for W_{d+1} is the columns of U_{d+1}.
    # For any x in V_{d-1}, the corresponding vector in W_d is U_d x.
    # The image under T_d is U_{d+1} L U_d^T (U_d x) = U_{d+1} L x.
    # Since this image is in W_{d+1}, its coordinate vector in the basis of W_{d+1} is:
    # U_{d+1}^T (U_{d+1} L x) = L x.
    # So in these coordinate bases, T_d is represented simply by the lift matrix L: V_{d-1} -> V_d!
    # That is beautiful!
    # What about R_d?
    # For any x in V_{d-1}, the corresponding vector in W_d is U_d x.
    # The image under R_d is U_{d+1} U_d U_d^T (U_d x) = U_{d+1} U_d x.
    # Since this image is in W_{d+1}, its coordinate vector in the basis of W_{d+1} is:
    # U_{d+1}^T (U_{d+1} U_d x) = U_d x.
    # So in these coordinate bases, R_d is represented simply by the modulation matrix U_d: V_{d-1} -> V_d!
    # Oh my god, this is incredibly simple and elegant!
    # Let's check:
    # The coordinate representations are:
    # [T_d] = L_d : V_{d-1} -> V_d
    # [R_d] = U_d : V_{d-1} -> V_d
    # Let's check if the columns of L_d and U_d are orthonormal and mutually orthogonal.
    # We know that the unitary basis change matrix for V_d is W = [L_d, U_d]!
    # Since W is unitary, its columns are orthonormal and mutually orthogonal, which means:
    # 1. L_d^T L_d = I
    # 2. U_d^T U_d = I
    # 3. L_d^T U_d = 0
    # 4. L_d L_d^T + U_d U_d^T = I
    # This matches the properties:
    # 1. T_d^T T_d = I
    # 2. R_d^T R_d = I
    # 3. T_d^T R_d = 0
    # 4. T_d T_d^T + R_d R_d^T = I
    # perfectly!
    
    L_d = get_lift(d) # V_d x V_{d-1}
    U_d = get_modulation_isometry(d) # V_d x V_{d-1}
    
    print(f"\n================ Exploration for depth d = {d} ================")
    print("Is L_d^T @ L_d equal to Identity?", np.allclose(L_d.T @ L_d, np.eye(L_d.shape[1])))
    print("Is U_d^T @ U_d equal to Identity?", np.allclose(U_d.T @ U_d, np.eye(U_d.shape[1])))
    print("Is L_d^T @ U_d equal to Zero?", np.allclose(L_d.T @ U_d, 0))
    print("Is L_d @ L_d^T + U_d @ U_d^T equal to Identity?", np.allclose(L_d @ L_d.T + U_d @ U_d.T, np.eye(L_d.shape[0])))

if __name__ == "__main__":
    for d in [3, 4, 5, 6]:
        verify_decomposition(d)
