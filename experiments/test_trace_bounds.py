import numpy as np

def tau(x, d):
    return (x + 2**(d-2)) % (2**(d-1))

def adj(x, y, d):
    if x == y: return False
    return (y == (3*x) % (2**(d-1))) or (y == (3*x-1) % (2**(d-1))) or \
           (x == (3*y) % (2**(d-1))) or (x == (3*y-1) % (2**(d-1)))

def get_antisym_matrix(d):
    M = 2**(d-2)
    S = np.zeros((M, M))
    for u in range(M):
        for v in range(M):
            w = 0
            if adj(u, v, d): w += 1
            if adj(u, tau(v, d), d): w -= 1
            S[u,v] = w
    return S

def get_chain_rayleigh(d):
    L = 5 if d >= 7 else 0
    if L == 0: return 0
    N = 2**(d-1)
    M = 2**(d-3)
    def hopping(j):
        return 2 * np.cos(np.pi * (3**j) / N)
    T = np.zeros((M, M))
    for i in range(M-1):
        T[i, i+1] = hopping(i)
        T[i+1, i] = hopping(i)
    u = np.zeros(M)
    for j in range(L):
        u[j] = np.sin(np.pi * (j + 1) / (L + 1))
    return np.dot(u, T @ u) / np.dot(u, u)

for d in range(7, 10):
    prev_d = d - 1
    S = get_antisym_matrix(prev_d)
    tr_A2 = np.trace(S @ S)
    max_eig = np.max(np.real(np.linalg.eigvals(S)))
    rq = get_chain_rayleigh(d)
    
    print(f"--- d={d} ---")
    print(f"Max Eig of A_{prev_d}: {max_eig:.4f}")
    print(f"Rayleigh Quotient: {rq:.4f}")
    print(f"Tr(A^2): {tr_A2}")
    print(f"sqrt(Tr(A^2)): {np.sqrt(tr_A2):.4f}")
    
    # Let's also check max row sum
    max_row_sum = np.max(np.sum(np.abs(S), axis=1))
    print(f"Max Absolute Row Sum (Gershgorin): {max_row_sum}")
