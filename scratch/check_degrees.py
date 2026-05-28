import numpy as np

def tau(x, d):
    return (x + 2**(d-2)) % (2**(d-1))

def adj(x, y, d):
    if x == y: return False
    return (y == (3*x) % (2**(d-1))) or (y == (3*x-1) % (2**(d-1))) or \
           (x == (3*y) % (2**(d-1))) or (x == (3*y-1) % (2**(d-1)))

d = 5
N_d1 = 2**(d-2)
W_sym = np.zeros((N_d1, N_d1))
for u in range(N_d1):
    row_sum = 0
    for v in range(N_d1):
        t_v = tau(v, d)
        w_u_v = 1 if adj(u, v, d) else 0
        w_u_tv = 1 if adj(u, t_v, d) else 0
        W_sym[u,v] = w_u_v + w_u_tv
        row_sum += w_u_v + w_u_tv
    print(f"Row {u} sum: {row_sum}")
