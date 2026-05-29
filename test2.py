import numpy as np

def collatz_dir(n):
    size = 2**n
    M = np.zeros((size, size), dtype=int)
    for x in range(size):
        y1 = (3*x) % size
        y2 = (3*x - 1) % size
        M[x, y1] = 1
        M[x, y2] = 1
    return M

def twisted_block(n):
    size = 2**(n-1)
    T = np.zeros((size, size), dtype=int)
    Dn = collatz_dir(n)
    for v in range(size):
        for u in range(size):
            T[v, u] = Dn[v, u] - Dn[v, u + size]
    return T

for n in range(3, 5):
    T = twisted_block(n)
    poly = np.poly(T)
    print(f'n={n}')
    print(np.round(poly))
