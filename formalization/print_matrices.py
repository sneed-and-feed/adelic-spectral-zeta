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

def twisted_dir(n):
    size = 2**(n-1)
    M = np.zeros((size, size), dtype=int)
    for v in range(size):
        for u in range(size):
            val_00 = collatz_dir(n)[v, u]
            val_01 = collatz_dir(n)[v, (u + size) % (2**n)]
            M[v, u] = val_00 - val_01
    return M

print("n=2 matrix:")
M2 = twisted_dir(2)
print(M2)
print("n=3 matrix:")
M3 = twisted_dir(3)
print(M3)
