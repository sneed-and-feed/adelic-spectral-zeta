import numpy as np

def pi(x, d):
    return x % (2**(d-2))

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
            # u and v are in 0..2^{d-2}-1
            w = 0
            if adj(u, v, d): w += 1
            if adj(u, tau(v, d), d): w -= 1
            S[u,v] = w
    return S

for d in range(4, 9):
    S = get_antisym_matrix(d)
    eigvals = np.real(np.linalg.eigvals(S))
    print(f"d={d}, max_antisym_eig={np.max(eigvals)}")
