def collatz_dir(n):
    size = 2**n
    M = [[0]*size for _ in range(size)]
    for x in range(size):
        y1 = (3*x) % size
        y2 = (3*x - 1) % size
        M[x][y1] = 1
        M[x][y2] = 1
    return M

def twisted_block(n):
    size = 2**(n-1)
    T = [[0]*size for _ in range(size)]
    Dn = collatz_dir(n)
    for v in range(size):
        for u in range(size):
            T[v][u] = Dn[v][u] - Dn[v][u + size]
    return T

def mat_mul(A, B):
    n = len(A)
    C = [[0]*n for _ in range(n)]
    for i in range(n):
        for k in range(n):
            if A[i][k] != 0:
                for j in range(n):
                    C[i][j] += A[i][k] * B[k][j]
    return C

def mat_pow(A, p):
    n = len(A)
    res = [[1 if i==j else 0 for j in range(n)] for i in range(n)]
    base = A
    while p > 0:
        if p % 2 == 1:
            res = mat_mul(res, base)
        base = mat_mul(base, base)
        p //= 2
    return res

for n in range(6, 9):
    T = twisted_block(n)
    T_pow = mat_pow(T, 2**(n-1))
    print(f'n={n}')
    diag = [T_pow[i][i] for i in range(len(T))]
    print(set(diag))
    print(all(T_pow[i][j] == 0 for i in range(len(T)) for j in range(len(T)) if i != j))
