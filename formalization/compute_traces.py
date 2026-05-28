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
            # v,0 to u,0
            val_00 = collatz_dir(n)[v, u]
            # v,0 to u,1
            val_01 = collatz_dir(n)[v, (u + size) % (2**n)]
            M[v, u] = val_00 - val_01
    return M

for n in range(2, 6):
    T = twisted_dir(n)
    traces = []
    for k in range(1, 5):
        traces.append(np.trace(np.linalg.matrix_power(T, k)))
    print(f"n={n}: traces={traces}")
