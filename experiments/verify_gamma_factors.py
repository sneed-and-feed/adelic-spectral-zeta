import numpy as np
import mpmath
from scipy.signal import fftconvolve

# 1. Compute tau using FFT
M = 5000

def trunc_conv(a, b, maxdeg):
    return fftconvolve(a, b)[:maxdeg + 1]

def poly_pow(p, n, maxdeg):
    result = np.zeros(maxdeg + 1); result[0] = 1.0
    base = p[:maxdeg + 1].copy()
    while n:
        if n & 1:
            result = trunc_conv(result, base, maxdeg)
        base = trunc_conv(base, base, maxdeg)
        n >>= 1
    return result

eta = np.zeros(M + 1); eta[0] = 1.0
for n in range(1, M + 1):
    eta[n:] -= eta[:M + 1 - n]

delta = poly_pow(eta, 24, M)
tau = np.zeros(M + 2)
tau[1:M + 2] = delta[:M + 1]

# 2. Compute Sym^4(Delta) coefficients
primes = []
is_prime = np.ones(M + 1, dtype=bool)
is_prime[:2] = False
for i in range(2, int(M**0.5) + 1):
    if is_prime[i]:
        is_prime[i*i::i] = False
primes = np.where(is_prime)[0]

b4 = np.zeros(M + 1)
b4[1] = 1.0
for p in primes:
    tp = float(tau[p] * (p ** -5.5))
    if abs(tp) > 2.0:
        theta = 0.0
    else:
        theta = np.arccos(tp / 2.0)
    
    alphas = [np.exp(1j * (4 - 2*j) * theta) for j in range(5)]
    
    max_k = 1
    while p**(max_k + 1) <= M:
        max_k += 1
        
    denom = np.array([1.0], dtype=complex)
    for alpha in alphas:
        denom = np.convolve(denom, [1.0, -alpha])
        
    coeffs = [1.0]
    for n in range(1, max_k + 1):
        val = 0.0
        for i in range(1, min(n + 1, len(denom))):
            val -= denom[i] * coeffs[n - i]
        coeffs.append(val)
        
    for i in range(M, 0, -1):
        if b4[i] == 0: continue
        k = 1
        while True:
            pk = p**k
            if i * pk > M:
                break
            b4[i * pk] = b4[i] * coeffs[k].real
            k += 1

# 3. Vectorized L-function evaluation
n_arr = np.arange(1, M + 1)
log_n = np.log(n_arr)
sqrt_n = np.sqrt(n_arr)

# Test candidate gamma factors
mpmath.mp.dps = 30

def test_gamma(t, a_val):
    s = 0.5 + 1j * t
    # Gamma factors:
    g_R = complex(mpmath.loggamma((s + a_val)/2.0)) - 0.5*(s+a_val)*np.log(np.pi)
    g_C1 = complex(mpmath.loggamma(s + 11)) - (s+11)*np.log(2.0*np.pi)
    g_C2 = complex(mpmath.loggamma(s + 22)) - (s+22)*np.log(2.0*np.pi)
    
    total_g = g_R + g_C1 + g_C2
    # The completed L-function value is L(s) * exp(total_g)
    # Let's compute L(1/2+it) using a smoothed sum
    W = 1000.0
    terms = b4[1:] * np.exp(-n_arr / W) / sqrt_n * np.exp(-1j * t * log_n)
    L_val = np.sum(terms)
    
    completed_L = L_val * np.exp(total_g)
    return completed_L

# Let's evaluate at t = 10.0 and t = 15.0 for a_val = 22 and a_val = 23
for a_val in [22.0, 23.0, 24.0]:
    print(f"Testing a_val = {a_val}:")
    for t in [10.0, 15.0]:
        val = test_gamma(t, a_val)
        print(f"  t = {t}: completed L = {val.real:.8e} + i * {val.imag:.8e}")
