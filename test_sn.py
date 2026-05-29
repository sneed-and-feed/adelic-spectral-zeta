import numpy as np
def S(n):
    N = 2**(n-1)
    mat = np.zeros((N, N), dtype=int)
    for v in range(N):
        t1 = (3*v) % (2**n)
        t2 = (3*v - 1) % (2**n)
        u1 = t1 % N
        u2 = t2 % N
        sign1 = 1 if t1 < N else -1
        sign2 = 1 if t2 < N else -1
        mat[v, u1] += sign1
        mat[v, u2] += sign2
    return mat

print('S_2:')
print(S(2))
print('S_3:')
print(S(3))
print('S_4:')
print(S(4))
