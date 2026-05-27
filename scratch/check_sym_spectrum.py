import numpy as np

def pi(x, d):
    return x % (2**(d-2))

def tau(x, d):
    return (x + 2**(d-2)) % (2**(d-1))

def adj(x, y, d):
    if x == y: return False
    return (y == (3*x) % (2**(d-1))) or (y == (3*x-1) % (2**(d-1))) or \
           (x == (3*y) % (2**(d-1))) or (x == (3*y-1) % (2**(d-1)))

for d in range(4, 7):
    N_d = 2**(d-1)
    N_d1 = 2**(d-2)
    W = np.zeros((N_d1, N_d1))
    A = np.zeros((N_d1, N_d1))
    for u in range(N_d1):
        for v in range(N_d1):
            t_v = tau(v, d)
            w = 0
            if adj(u, v, d): w += 1
            if adj(u, t_v, d): w += 1
            W[u,v] = w
            A[u,v] = 1 if adj(u, v, d-1) else 0

    eigs_W = np.sort(np.linalg.eigvalsh(W))
    eigs_A = np.sort(np.linalg.eigvalsh(A))
    
    print(f"Depth {d}:")
    print("W spectrum:", np.round(eigs_W, 3))
    print("A spectrum:", np.round(eigs_A, 3))
    print("Equal spectrum?", np.allclose(eigs_W, eigs_A))
