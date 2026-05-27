import numpy as np

def tau(x, d):
    return (x + 2**(d-2)) % (2**(d-1))

def adj(x, y, d):
    if x == y: return False
    return (y == (3*x) % (2**(d-1))) or (y == (3*x-1) % (2**(d-1))) or \
           (x == (3*y) % (2**(d-1))) or (x == (3*y-1) % (2**(d-1)))

for d in range(4, 8):
    N_d = 2**(d-1)
    N_d1 = 2**(d-2)
    W_sym = np.zeros((N_d1, N_d1))
    W_anti = np.zeros((N_d1, N_d1))
    for u in range(N_d1):
        for v in range(N_d1):
            t_v = tau(v, d)
            w_u_v = 1 if adj(u, v, d) else 0
            w_u_tv = 1 if adj(u, t_v, d) else 0
            W_sym[u,v] = w_u_v + w_u_tv
            W_anti[u,v] = w_u_v - w_u_tv

    eigs_sym = np.sort(np.linalg.eigvalsh(W_sym))
    eigs_anti = np.sort(np.linalg.eigvalsh(W_anti))
    
    print(f"Depth {d}:")
    print("max(Sym_d)   :", np.round(np.max(eigs_sym), 3))
    print("max(Anti_d)  :", np.round(np.max(eigs_anti), 3))
    
    if d > 4:
        # Check if max(Sym_d) == max(Anti_{d-1})
        pass
    
print("Checking max(Sym_d) vs max(Anti_{d-1})")
prev_max_anti = None
for d in range(4, 9):
    N_d = 2**(d-1)
    N_d1 = 2**(d-2)
    W_sym = np.zeros((N_d1, N_d1))
    W_anti = np.zeros((N_d1, N_d1))
    for u in range(N_d1):
        for v in range(N_d1):
            t_v = tau(v, d)
            w_u_v = 1 if adj(u, v, d) else 0
            w_u_tv = 1 if adj(u, t_v, d) else 0
            W_sym[u,v] = w_u_v + w_u_tv
            W_anti[u,v] = w_u_v - w_u_tv

    max_sym = np.max(np.linalg.eigvalsh(W_sym))
    max_anti = np.max(np.linalg.eigvalsh(W_anti))
    
    if prev_max_anti is not None:
        print(f"Depth {d}: max(Sym_d)={max_sym:.4f}, max(Anti_{d-1})={prev_max_anti:.4f}")
    prev_max_anti = max_anti
