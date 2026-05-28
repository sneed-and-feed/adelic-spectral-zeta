import numpy as np

def tau(x, d):
    return (x + 2**(d-2)) % (2**(d-1))

def adj(x, y, d):
    if x == y: return False
    return (y == (3*x) % (2**(d-1))) or (y == (3*x-1) % (2**(d-1))) or \
           (x == (3*y) % (2**(d-1))) or (x == (3*y-1) % (2**(d-1)))

spectra = {}
for d in range(3, 8):
    N_d = 2**(d-1)
    A = np.zeros((N_d, N_d))
    for u in range(N_d):
        for v in range(N_d):
            A[u,v] = 1 if adj(u, v, d) else 0
    spectra[d] = np.sort(np.linalg.eigvalsh(A))

sym_spectra = {}
for d in range(4, 8):
    N_d = 2**(d-1)
    N_d1 = 2**(d-2)
    W_sym = np.zeros((N_d1, N_d1))
    for u in range(N_d1):
        for v in range(N_d1):
            t_v = tau(v, d)
            w_u_v = 1 if adj(u, v, d) else 0
            w_u_tv = 1 if adj(u, t_v, d) else 0
            W_sym[u,v] = w_u_v + w_u_tv
    sym_spectra[d] = np.sort(np.linalg.eigvalsh(W_sym))

for d in range(4, 8):
    eigs_Gd_minus_1 = spectra[d-1]
    eigs_Sym_d = sym_spectra[d]
    diff = np.max(np.abs(eigs_Gd_minus_1 - eigs_Sym_d))
    print(f"Depth {d}: Max diff between Sym_d and G_{d-1}: {diff:.6f}")
