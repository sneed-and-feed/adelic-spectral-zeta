"""
Task 2.1: GL(3) Satake Parameters & Symmetric Square L-function
===============================================================
Computes the Satake parameters and local Euler factors for the 
Symmetric Square lift of the Ramanujan Delta function: L(s, Sym^2 Delta).

For Delta (weight 12 cusp form), the GL(2) Satake parameters are 
alpha_p, beta_p where:
  alpha_p * beta_p = 1
  alpha_p + beta_p = tilde_tau(p) = tau(p) p^{-11/2}

The Symmetric Square lift is a GL(3) automorphic form. Its local 
Euler factor at prime p is:
  L_p(s, Sym^2 Delta)^{-1} = (1 - alpha_p^2 p^{-s})(1 - p^{-s})(1 - beta_p^2 p^{-s})
                           = 1 - A_p p^{-s} + A_p p^{-2s} - p^{-3s}
where A_p = alpha_p^2 + 1 + beta_p^2 = tilde_tau(p)^2 - 1.
"""

import numpy as np

print("=" * 70)
print("TASK 2.1: GL(3) SATAKE PARAMETERS (Sym^2 Delta)")
print("=" * 70)

P_MAX = 43

# Sieve for primes
def sieve(n):
    is_prime = np.ones(n + 1, dtype=bool)
    is_prime[:2] = False
    for i in range(2, int(n**0.5) + 1):
        if is_prime[i]:
            is_prime[i*i::i] = False
    return np.where(is_prime)[0]

primes = sieve(P_MAX)

# Compute tau(n) via eta product
M = P_MAX
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

print(f"{'p':<5} | {'tau(p)':<12} | {'tilde_tau(p)':<12} | {'A_p (Sym^2 trace)':<12} | {'Satake roots (GL3)'}")
print("-" * 70)

for p in primes:
    tp = float(tau[p])
    ttp = tp * (p ** -5.5)
    
    # Sym^2 trace: A_p = tilde_tau(p)^2 - 1
    Ap = ttp**2 - 1.0
    
    # Satake roots
    # ttp = 2 cos(theta), so theta = acos(ttp / 2)
    if abs(ttp) <= 2.0:
        theta = np.arccos(ttp / 2.0)
        root1 = np.exp(2j * theta)
        root2 = 1.0
        root3 = np.exp(-2j * theta)
        roots_str = f"({root1.real:+.3f}{root1.imag:+.3f}j, 1.0, {root3.real:+.3f}{root3.imag:+.3f}j)"
    else:
        roots_str = "Ramanujan bound violated!"
        
    print(f"{p:<5} | {int(tp):<12} | {ttp:<12.5f} | {Ap:<17.5f} | {roots_str}")

print("=" * 70)
print("TASK 2.1 COMPLETE")
print("=" * 70)
