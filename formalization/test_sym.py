import numpy as np

def collatz_dir(n):
    size = 2**n
    M = np.zeros((size, size), dtype=int)
    for x in range(size):
        y1 = (3 * x) % size
        y2 = (3 * x - 1) % size
        M[x, y1] = 1
        M[x, y2] = 1
    return M

def sym_closure(M):
    size = M.shape[0]
    S = np.zeros((size, size), dtype=int)
    for i in range(size):
        for j in range(size):
            if M[i,j] > 0 or M[j,i] > 0:
                S[i,j] = 1
    return S

def weighted_matrix(n):
    size = 2**(n-1)
    S = sym_closure(collatz_dir(n))
    M = np.zeros((size, size), dtype=int)
    for v in range(size):
        for u in range(size):
            val_00 = S[v, u]
            val_01 = S[v, (u + size) % (2**n)]
            M[v, u] = val_00 + val_01
    return M

for n in range(3, 5):
    W = weighted_matrix(n)
    C = sym_closure(collatz_dir(n-1))
    print(f"n={n}")
    for i in range(W.shape[0]):
        for j in range(W.shape[1]):
            if W[i,j] != C[i,j]:
                print(f"Mismatch at {i},{j}: W={W[i,j]}, C={C[i,j]}")
