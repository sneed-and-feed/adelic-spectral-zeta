"""
Adelic Spectral Zeta: check_eig.py
"""

import numpy as np

def tau(x, d):
    return (x + 2**(d-2)) % (2**(d-1))

def adj(x, y, d):
    if x == y: return False
    return (y == (3*x) % (2**(d-1))) or (y == (3*x-1) % (2**(d-1))) or \
           (x == (3*y) % (2**(d-1))) or (x == (3*y-1) % (2**(d-1)))

def main():

    d = 4
    W = np.zeros((4,4))
    A = np.zeros((4,4))
    for u in range(4):
        for v in range(4):
            t_v = tau(v, d)
            w = 0
            if adj(u, v, d): w += 1
            if adj(u, t_v, d): w += 1
            W[u,v] = w
            A[u,v] = 1 if adj(u, v, d-1) else 0

    print('Eigvals W:', sorted(np.real(np.linalg.eigvals(W))))
    print('Eigvals A:', sorted(np.real(np.linalg.eigvals(A))))

if __name__ == "__main__":
    main()
