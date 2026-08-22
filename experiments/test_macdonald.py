import numpy as np
import itertools

def c_func(z, q):
    z1, z2, z3 = z
    res = 1.0 + 0j
    pairs = [(z1, z2), (z1, z3), (z2, z3)]
    for za, zb in pairs:
        res *= (1.0 - (1.0/q) * zb / za) / (1.0 - zb / za)
    return res

def spherical_phi(m, n, z, q):
    z1, z2, z3 = z
    perms = list(itertools.permutations([z1, z2, z3]))
    W_q = 1.0 + 2.0/q + 2.0/(q**2) + 1.0/(q**3)
    val = 0.0 + 0j
    for p in perms:
        w_z = p
        cw = c_func(w_z, q)
        term = cw * (w_z[0]**(m + n)) * (w_z[1]**n)
        val += term
    val = val / W_q
    return val * (q ** (-(m + n)))

q = 3
theta1 = 0.7
theta2 = 1.2
theta3 = -theta1 - theta2
z = (np.exp(1j*theta1), np.exp(1j*theta2), np.exp(1j*theta3))

print("Phi(0,0) =", spherical_phi(0, 0, z, q))
print("Phi(1,0) =", spherical_phi(1, 0, z, q))
print("Phi(0,1) =", spherical_phi(0, 1, z, q))
print("Phi(1,1) =", spherical_phi(1, 1, z, q))
print("Phi(2,0) =", spherical_phi(2, 0, z, q))

# Let's find the exact radial Hecke coefficients by solving linear systems across random z
def solve_radial_T1(m, n, q):
    # Candidate neighbors for type 1 transition from (m,n):
    # In the weight lattice A2, the 3 fundamental steps are:
    # +varpi_1: (m+1, n)
    # -varpi_1 + varpi_2: (m-1, n+1)
    # -varpi_2: (m, n-1)
    # In addition, due to folding/boundary or double coset geometry, check:
    candidates = []
    for dm in [-2, -1, 0, 1, 2]:
        for dn in [-2, -1, 0, 1, 2]:
            if m + dm >= 0 and n + dn >= 0:
                candidates.append((m + dm, n + dn))
    
    # Generate random z on T^2
    np.random.seed(42)
    A = []
    b = []
    for _ in range(50):
        t1, t2 = np.random.uniform(0, 2*np.pi, 2)
        t3 = -t1 - t2
        z_sample = (np.exp(1j*t1), np.exp(1j*t2), np.exp(1j*t3))
        e1_sample = sum(z_sample)
        phi_mn = spherical_phi(m, n, z_sample, q)
        row = [spherical_phi(cm, cn, z_sample, q) for cm, cn in candidates]
        A.append(row)
        b.append(q * e1_sample * phi_mn)
    
    A = np.array(A)
    b = np.array(b)
    # Solve least squares (real & imag)
    A_real = np.vstack([A.real, A.imag])
    b_real = np.concatenate([b.real, b.imag])
    x, residuals, rank, s = np.linalg.lstsq(A_real, b_real, rcond=1e-10)
    
    nonzeros = {}
    for (cm, cn), coeff in zip(candidates, x):
        if abs(coeff) > 1e-4:
            nonzeros[(cm, cn)] = round(coeff, 6)
    return nonzeros

def solve_radial_T2(m, n, q):
    candidates = []
    for dm in [-2, -1, 0, 1, 2]:
        for dn in [-2, -1, 0, 1, 2]:
            if m + dm >= 0 and n + dn >= 0:
                candidates.append((m + dm, n + dn))
    
    np.random.seed(42)
    A = []
    b = []
    for _ in range(50):
        t1, t2 = np.random.uniform(0, 2*np.pi, 2)
        t3 = -t1 - t2
        z_sample = (np.exp(1j*t1), np.exp(1j*t2), np.exp(1j*t3))
        e2_sample = z_sample[0]*z_sample[1] + z_sample[1]*z_sample[2] + z_sample[2]*z_sample[0]
        phi_mn = spherical_phi(m, n, z_sample, q)
        row = [spherical_phi(cm, cn, z_sample, q) for cm, cn in candidates]
        A.append(row)
        b.append(q * e2_sample * phi_mn)
    
    A = np.array(A)
    b = np.array(b)
    A_real = np.vstack([A.real, A.imag])
    b_real = np.concatenate([b.real, b.imag])
    x, residuals, rank, s = np.linalg.lstsq(A_real, b_real, rcond=1e-10)
    
    nonzeros = {}
    for (cm, cn), coeff in zip(candidates, x):
        if abs(coeff) > 1e-4:
            nonzeros[(cm, cn)] = round(coeff, 6)
    return nonzeros

print("\n--- T2 Coefficients ---")
print("T2 at (0,0):", solve_radial_T2(0, 0, q=3))
print("T2 at (1,0):", solve_radial_T2(1, 0, q=3))
print("T2 at (0,1):", solve_radial_T2(0, 1, q=3))
print("T2 at (1,1):", solve_radial_T2(1, 1, q=3))
print("T2 at (0,2):", solve_radial_T2(0, 2, q=3))
print("T2 at (1,2):", solve_radial_T2(1, 2, q=3))




