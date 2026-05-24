import numpy as np
import scipy.linalg as la
import sympy as sp
import time

print("Benchmarking factorization...")
x = sp.Symbol('x')
f = x**5 + 10*x**3 - 10*x**2 + 35*x - 18
primes = list(sp.primerange(2, 200))
t0 = time.time()
a_p = {}
for p in primes:
    if p in [2, 5]:
        a_p[p] = 0.0
    else:
        try:
            factors = sp.factor_list(f, modulus=p)[1]
            degrees = sorted([sp.degree(poly) for poly, mult in factors])
            a_p[p] = 1.0
        except Exception as e:
            a_p[p] = 0.0
print(f"Factorization of {len(primes)} primes took {time.time() - t0:.4f}s")

print("Benchmarking 1001x1001 la.eigvalsh...")
dim = 1001
H = np.random.randn(dim, dim)
H = H + H.T  # make symmetric
t1 = time.time()
evs = la.eigvalsh(H)
print(f"Single 1001x1001 la.eigvalsh took {time.time() - t1:.4f}s")
