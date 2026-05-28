"""
Test suite: test_convergence.py
Tests mathematical properties and correctness invariants.
"""
import numpy as np
import mpmath
from scipy.optimize import bisect

def sieve(n):
    is_prime = np.ones(n + 1, dtype=bool)
    is_prime[:2] = False
    for i in range(2, int(n**0.5) + 1):
        if is_prime[i]:
            is_prime[i*i::i] = False
    return np.where(is_prime)[0]

M = 8000
primes = sieve(M)

# Compute tau(n)
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
b = np.zeros(M + 1)
b[1] = 1.0
for p in primes:
    tp = float(tau[p] * (p ** -5.5))
    B1 = tp**3 - 2.0 * tp
    B2 = tp**4 - 3.0 * tp**2 + 2.0
    B3 = B1
    B4 = 1.0
    
    pk_coeffs = [1.0, B1]
    pk_coeffs.append(B1 * pk_coeffs[1] - B2 * pk_coeffs[0])
    pk_coeffs.append(B1 * pk_coeffs[2] - B2 * pk_coeffs[1] + B3 * pk_coeffs[0])
    k = 4
    while p**k <= M:
        pk_coeffs.append(B1 * pk_coeffs[k-1] - B2 * pk_coeffs[k-2] + B3 * pk_coeffs[k-3] - B4 * pk_coeffs[k-4])
        k += 1
        
    for i in range(M, 0, -1):
        if b[i] == 0: continue
        k = 1
        while True:
            pk = p**k
            if i * pk > M:
                break
            b[i * pk] = b[i] * pk_coeffs[k]
            k += 1

mpmath.mp.dps = 30

def Z_sym3(t, W):
    s = mpmath.mpc(0.5, t)
    g1 = mpmath.gamma(s + 16.5)
    g2 = mpmath.gamma(s + 5.5)
    phase = mpmath.exp(mpmath.arg(g1) * 1j + mpmath.arg(g2) * 1j - 2j * t * mpmath.log(2 * mpmath.pi))
    
    total = mpmath.mpc(0.0)
    for n in range(1, M + 1):
        if b[n] == 0: continue
        term = b[n] * mpmath.exp(-n/W) / (n**s)
        total += term
        
    return float((phase * total).real)

for W in [400.0, 1000.0, 2000.0]:
    zeros = []
    # Find first 3 zeros
    t_vals = np.linspace(5.0, 15.0, 100)
    z_vals = [Z_sym3(t, W) for t in t_vals]
    for i in range(len(t_vals) - 1):
        if z_vals[i] * z_vals[i+1] < 0:
            root = bisect(lambda t: Z_sym3(t, W), t_vals[i], t_vals[i+1], xtol=1e-8)
            zeros.append(root)
    print(f"W = {W:.1f}, first 3 zeros: {zeros}")
