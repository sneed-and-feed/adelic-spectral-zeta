import numpy as np

def pi(x, d):
    return x % (2**(d-2))

def tau(x, d):
    return (x + 2**(d-2)) % (2**(d-1))

def adj(x, y, d):
    if x == y: return False
    return (y == (3*x) % (2**(d-1))) or (y == (3*x-1) % (2**(d-1))) or \
           (x == (3*y) % (2**(d-1))) or (x == (3*y-1) % (2**(d-1)))

def get_weighted_matrix(d):
    n = 2**(d-2)
    W = np.zeros((n, n))
    for u in range(n):
        for v in range(n):
            w = 0
            if adj(u, v, d): w += 1
            if adj(u, tau(v, d), d): w += 1
            W[u, v] = w
    return W

def get_antisym_matrix(d):
    n = 2**(d-2)
    D = np.zeros((n, n))
    for u in range(n):
        for v in range(n):
            w1 = 1 if adj(u, v, d) else 0
            w2 = 1 if adj(u, tau(v, d), d) else 0
            D[u, v] = w1 - w2
    return D

for d in range(4, 9):
    W = get_weighted_matrix(d)
    D = get_antisym_matrix(d)
    
    # Eigenvalues of Symmetric block
    eigs_W = np.linalg.eigvalsh(W)
    eigs_W = np.sort(eigs_W)
    sym_max_eigenvalue = eigs_W[-1]
    sym_second_eigenvalue = eigs_W[-2]
    
    # Eigenvalues of Antisymmetric block
    eigs_D = np.linalg.eigvalsh(D)
    eigs_D = np.sort(eigs_D)
    anti_max_eigenvalue = eigs_D[-1]
    
    print(f"d={d}: sym_1 = {sym_max_eigenvalue:.4f}, sym_2 = {sym_second_eigenvalue:.4f}, anti_1 = {anti_max_eigenvalue:.4f}")
    if sym_second_eigenvalue >= anti_max_eigenvalue:
        print(f"  WARNING: bound fails at d={d}!")
