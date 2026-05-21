import numpy as np
import mpmath
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from scipy.optimize import bisect

# Sieve primes
def sieve(n):
    is_prime = np.ones(n + 1, dtype=bool)
    is_prime[:2] = False
    for i in range(2, int(n**0.5) + 1):
        if is_prime[i]:
            is_prime[i*i::i] = False
    return np.where(is_prime)[0]

M = 5000
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

# Compute b_n for Sym^4(Delta) (GL(5))
# Using generating function: 1 / prod_{j=0}^4 (1 - alpha_j * z)
b = np.zeros(M + 1)
b[1] = 1.0

for p in primes:
    tp = float(tau[p] * (p ** -5.5))
    if abs(tp) <= 2.0:
        theta = np.arccos(tp / 2.0)
    else:
        theta = 0.0
    
    # Satake parameters
    alphas = [np.exp(1j * (4 - 2*j) * theta) for j in range(5)]
    
    # Find max power k such that p^k <= M
    max_k = 1
    while p**(max_k + 1) <= M:
        max_k += 1
        
    # We want Taylor coefficients of 1 / prod(1 - alpha_j * z) up to z^{max_k}
    # Let's do polynomial multiplication for the denominator: prod (1 - alpha_j * z)
    denom = np.array([1.0], dtype=complex)
    for alpha in alphas:
        denom = np.convolve(denom, [1.0, -alpha])
        
    # Now invert denom to get Taylor coefficients:
    # 1 / (1 + d1 z + d2 z^2 + ...) = c0 + c1 z + c2 z^2 + ...
    # c0 = 1
    # cn = - sum_{i=1}^n di * c_{n-i}
    coeffs = [1.0]
    for n in range(1, max_k + 1):
        val = 0.0
        for i in range(1, min(n + 1, len(denom))):
            val -= denom[i] * coeffs[n - i]
        coeffs.append(val)
        
    # Multiply into b
    for i in range(M, 0, -1):
        if b[i] == 0: continue
        k = 1
        while True:
            pk = p**k
            if i * pk > M:
                break
            b[i * pk] = b[i] * coeffs[k].real
            k += 1

print("First few Sym^4(Delta) coefficients:")
for i in range(1, 15):
    print(f"  b_{i} = {b[i]:.6f}")

# Z-function for Sym^4(Delta)
# Hodge weights: 22, 11, 0, -11, -22
# Gamma factors: Gamma_R(s+22) Gamma_C(s+11) Gamma_C(s+22) ...
# Let's write the completed L-function phase:
# For GL(5), completed L-function has 5 Gamma factors.
mpmath.mp.dps = 30

def Z_sym4(t):
    s = mpmath.mpc(0.5, t)
    # Gamma factors:
    # Gamma_R(s + 22) = pi^{-(s+22)/2} Gamma((s+22)/2)
    # Gamma_C(s + 11) = 2(2pi)^{-(s+11)} Gamma(s+11)
    # Gamma_C(s + 22) = 2(2pi)^{-(s+22)} Gamma(s+22)
    # Log-gamma values:
    g_R = mpmath.loggamma((s + 22)/2) - ((s + 22)/2) * mpmath.log(mpmath.pi)
    g_C1 = mpmath.loggamma(s + 11) - (s + 11) * mpmath.log(2*mpmath.pi)
    g_C2 = mpmath.loggamma(s + 22) - (s + 22) * mpmath.log(2*mpmath.pi)
    
    total_g = g_R + g_C1 + g_C2
    phase = mpmath.exp(1j * total_g.imag)
    
    W = 400.0
    total = mpmath.mpc(0.0)
    for n in range(1, M + 1):
        if b[n] == 0: continue
        total += b[n] * mpmath.exp(-n/W) / (n**s)
        
    return float((phase * total).real)

print("\nScanning for zeros of Sym^4(Delta)...")
t_vals = np.linspace(5.0, 30.0, 500)
z_vals = [Z_sym4(t) for t in t_vals]

zeros = []
for i in range(len(t_vals) - 1):
    if z_vals[i] * z_vals[i+1] < 0:
        root = bisect(Z_sym4, t_vals[i], t_vals[i+1], xtol=1e-8)
        zeros.append(root)

print("Found zeros:", zeros)
