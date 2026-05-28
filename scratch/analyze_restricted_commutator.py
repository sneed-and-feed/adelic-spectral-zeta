import numpy as np

def build_operators(depth):
    N = 1 << depth
    A = np.zeros((N, N))
    for x in range(N):
        A[(x + 1) % N, x] = 1.0
        
    B_alg = np.zeros((N, N))
    inv_3 = 1
    for i in range(1, N):
        if (3 * i) % N == 1:
            inv_3 = i
            break
    for x in range(N):
        y1 = (2 * x) % N
        B_alg[x, y1] += 0.5
        y2 = ((2 * x - 1) * inv_3) % N
        B_alg[x, y2] += 0.5
        
    return A, B_alg

def build_graph_adjacency(depth):
    V = 1 << (depth - 1)
    A_G = np.zeros((V, V))
    for k in range(V):
        v1 = (k + 1) % V
        v2_even = (3 * k + 2) % V
        v2_odd = (3 * k + 3) % V
        A_G[v1, v2_even] += 1
        A_G[v2_even, v1] += 1
        A_G[v1, v2_odd] += 1
        A_G[v2_odd, v1] += 1
    return A_G

def main():
    d = 4
    N = 1 << d
    V = 1 << (d - 1)
    
    A, B = build_operators(d)
    Kd = A @ B - B @ A
    Kd2 = Kd @ Kd.T # Kd Kd^\dagger
    
    # We want to project Kd2 onto V_+ (periodic functions with period V)
    # A basis for V_+ is v_j = 1/sqrt(2) * (e_j + e_{j+V}) for j = 0..V-1
    basis_plus = np.zeros((V, N))
    for j in range(V):
        basis_plus[j, j] = 1.0 / np.sqrt(2)
        basis_plus[j, j + V] = 1.0 / np.sqrt(2)
        
    Kd2_plus = basis_plus @ Kd2 @ basis_plus.T
    
    print("Kd2_plus:")
    print(np.round(Kd2_plus, 4))
    
    A_G = build_graph_adjacency(d)
    print("\nAdjacency matrix A_G:")
    print(A_G)
    
    # Let's check relation: Kd2_plus and A_G
    # We predicted singular values are sqrt(2 - 0.5 * mu)
    # This means eigenvalues of Kd2 are 2 - 0.5 * mu
    # Let's check if Kd2_plus is exactly 2 * I - 0.5 * A_G (or similar)
    predicted_Kd2_plus = 2.0 * np.eye(V) - 0.5 * A_G
    print("\n2 * I - 0.5 * A_G:")
    print(predicted_Kd2_plus)
    
    print("\nDifference norm:", np.linalg.norm(Kd2_plus - predicted_Kd2_plus))

if __name__ == "__main__":
    main()
