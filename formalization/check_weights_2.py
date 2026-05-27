import sys
def pi(x, d):
    return x % (2**(d-2))

def tau(x, d):
    return (x + 2**(d-2)) % (2**(d-1))

def adj(x, y, d):
    if x == y: return False
    return (y == (3*x) % (2**(d-1))) or (y == (3*x-1) % (2**(d-1))) or \
           (x == (3*y) % (2**(d-1))) or (x == (3*y-1) % (2**(d-1)))

d = 4
for u in range(4):
    for v in range(4):
        t_v = tau(v, d)
        w = 0
        if adj(u, v, d): w += 1
        if adj(u, t_v, d): w += 1
        a = 1 if adj(u, v, d-1) else 0
        sys.stdout.write(f"W[{u},{v}]={w}  A[{u},{v}]={a}\n")
sys.stdout.flush()
