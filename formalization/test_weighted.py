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

def weighted_dir(n):
    size = 2**(n-1)
    M = np.zeros((size, size), dtype=int)
    for v in range(size):
        for u in range(size):
            val_00 = collatz_dir(n)[v, u]
            val_01 = collatz_dir(n)[v, (u + size) % (2**n)]
            M[v, u] = val_00 + val_01
    return M

def adjacency(n):
    size = 2**(n-1)
    M = np.zeros((size, size), dtype=int)
    for x in range(size):
        y1 = (3 * x) % size
        y2 = (3 * x - 1) % size
        M[x, y1] = 1
        M[x, y2] = 1
    # Actually adjacency of G_d is symmetric? No, G_d is SimpleGraph, so it's symm closure.
    # Wait, in SchreierSpectral, G_d is defined using collatzDirMatrix. Let's assume it's symm.
    pass

for n in range(3, 5):
    W = weighted_dir(n)
    C = collatz_dir(n-1)
    print(f"n={n}")
    for i in range(W.shape[0]):
        for j in range(W.shape[1]):
            if W[i,j] != C[i,j]:
                print(f"Mismatch at {i},{j}: W={W[i,j]}, C={C[i,j]}")
