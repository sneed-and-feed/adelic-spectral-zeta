import numpy as np
import mpmath
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from scipy.optimize import bisect

# 1. Sieve primes
def sieve(n):
    is_prime = np.ones(n + 1, dtype=bool)
    is_prime[:2] = False
    for i in range(2, int(n**0.5) + 1):
        if is_prime[i]:
            is_prime[i*i::i] = False
    return np.where(is_prime)[0]

primes = sieve(1000)

# 2. Compute tau(n)
M = 1000
poly = np.zeros(M + 1)
poly[0] = 1.0
for n in range(1, M + 1):
    nxt = poly.copy()
    for i in range(M + 1 - n):
        nxt[i + n] -= poly[i]
    poly = nxt

delta_poly = np.zeros(M + 1)
delta_poly[0] = 1.0
for _ in range(24):
    nxt = np.zeros(M + 1)
    for i in range(M + 1):
        if delta_poly[i] == 0: continue
        for j in range(min(M + 1 - i, len(poly))):
            nxt[i + j] += delta_poly[i] * poly[j]
    delta_poly = nxt

tau = np.zeros(M + 1)
for i in range(M):
    tau[i + 1] = delta_poly[i]

# Compute b_n for Sym^3(Delta)
# For prime p, Satake parameters have roots e^{i theta_p}, e^{-i theta_p}
# where 2 cos(theta_p) = tau(p) * p^{-5.5}
# The Sym^3 coefficients at prime p are: b_p = tau(p)^3 * p^{-16.5} - 2 * tau(p) * p^{-5.5}
# Let's compute local factors up to p^k
b = np.zeros(M + 1)
b[1] = 1.0

# Multiplicative construction:
# For each prime, compute b_{p^k}
# For Sym^3, the recurrence is:
# b_{p^k} = B1 * b_{p^{k-1}} - B2 * b_{p^{k-2}} + B3 * b_{p^{k-3}} - B4 * b_{p^{k-4}}
# where B1 = a_p^3 - 2a_p
# B2 = a_p^4 - 3a_p^2 + 2
# B3 = a_p^3 - 2a_p
# B4 = 1
for p in primes:
    tp = float(tau[p] * (p ** -5.5))
    B1 = tp**3 - 2.0 * tp
    B2 = tp**4 - 3.0 * tp**2 + 2.0
    B3 = B1
    B4 = 1.0
    
    # We can compute b_{p^k} for k such that p^k <= M
    pk_vals = [1.0] # p^0
    pk_vals.append(B1) # p^1
    
    # p^2: B1*b_p - B2*b_1
    pk_vals.append(B1 * pk_vals[1] - B2 * pk_vals[0])
    
    # p^3: B1*b_{p^2} - B2*b_p + B3*b_1
    pk_vals.append(B1 * pk_vals[2] - B2 * pk_vals[1] + B3 * pk_vals[0])
    
    k = 4
    while True:
        val = p**k
        if val > M:
            break
        pk_val = B1 * pk_vals[k-1] - B2 * pk_vals[k-2] + B3 * pk_vals[k-3] - B4 * pk_vals[k-4]
        pk_vals.append(pk_val)
        k += 1
        
    # Now fill in b for prime powers using multiplicativity
    # To do this safely, we can do a sieve-like multiplication
    # (Since we want to do this for all n, we can do it by induction or prime-by-prime)

# A standard prime-by-prime multiplicative sieve:
b = np.zeros(M + 1)
b[1] = 1.0
for p in primes:
    tp = float(tau[p] * (p ** -5.5))
    B1 = tp**3 - 2.0 * tp
    B2 = tp**4 - 3.0 * tp**2 + 2.0
    B3 = B1
    B4 = 1.0
    
    # Compute prime power coefficients
    pk_coeffs = [1.0, B1]
    pk_coeffs.append(B1 * pk_coeffs[1] - B2 * pk_coeffs[0])
    pk_coeffs.append(B1 * pk_coeffs[2] - B2 * pk_coeffs[1] + B3 * pk_coeffs[0])
    k = 4
    while p**k <= M:
        pk_coeffs.append(B1 * pk_coeffs[k-1] - B2 * pk_coeffs[k-2] + B3 * pk_coeffs[k-3] - B4 * pk_coeffs[k-4])
        k += 1
        
    # Multiply into b
    for i in range(M, 0, -1):
        if b[i] == 0: continue
        k = 1
        while True:
            pk = p**k
            if i * pk > M:
                break
            b[i * pk] = b[i] * pk_coeffs[k]
            k += 1

print("First few b_n coefficients for Sym^3(Delta):")
for i in range(1, 15):
    print(f"  b_{i} = {b[i]:.6f}")
