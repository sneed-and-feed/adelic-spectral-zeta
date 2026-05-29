def collatz_dir(n):
    size = 2**n
    M = [[0]*size for _ in range(size)]
    for x in range(size):
        y1 = (3*x) % size
        y2 = (3*x - 1) % size
        M[x][y1] = 1
        M[x][y2] = 1
    return M

def mat_mul_mod(A, B, m):
    n = len(A)
    C = [[0]*n for _ in range(n)]
    for i in range(n):
        for k in range(n):
            if A[i][k] != 0:
                for j in range(n):
                    C[i][j] = (C[i][j] + A[i][k] * B[k][j]) % m
    return C

def mat_pow_mod(A, p, m):
    n = len(A)
    res = [[1 if i==j else 0 for j in range(n)] for i in range(n)]
    base = A
    while p > 0:
        if p % 2 == 1:
            res = mat_mul_mod(res, base, m)
        base = mat_mul_mod(base, base, m)
        p //= 2
    return res

for n in range(2, 6):
    W = collatz_dir(n-1)
    W_pow = mat_pow_mod(W, 2**(n-1), 2)
    print(f'n={n}')
    print(all(W_pow[i][j] == 0 for i in range(len(W)) for j in range(len(W))))
