import numpy as np

def adj(x, y, d):
    if x == y: return False
    return (y == (3*x) % (2**(d-1))) or (y == (3*x-1) % (2**(d-1))) or \
           (x == (3*y) % (2**(d-1))) or (x == (3*y-1) % (2**(d-1)))

spectra = {}
for d in range(3, 7):
    N_d = 2**(d-1)
    A = np.zeros((N_d, N_d))
    for u in range(N_d):
        for v in range(N_d):
            A[u,v] = 1 if adj(u, v, d) else 0
    spectra[d] = np.sort(np.linalg.eigvalsh(A))

for d in range(4, 7):
    eigs_Gd_minus_1 = spectra[d-1]
    eigs_Gd = spectra[d]
    
    # Check if every element in Gd_minus_1 is in Gd
    missing = []
    for eig in eigs_Gd_minus_1:
        if np.min(np.abs(eigs_Gd - eig)) > 1e-3:
            missing.append(eig)
    
    print(f"Depth {d}: Is G_{d-1} spectrum a subset of G_d? {len(missing) == 0}")
    if len(missing) > 0:
        print(f"  Missing eigs: {missing}")
