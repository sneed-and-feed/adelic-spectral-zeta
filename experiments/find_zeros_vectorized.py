"""
Adelic Spectral Zeta: find_zeros_vectorized.py
"""

import numpy as np
import mpmath
from scipy.optimize import bisect
import time

def sieve(n):
    is_prime = np.ones(n + 1, dtype=bool)
    is_prime[:2] = False
    for i in range(2, int(n**0.5) + 1):
        if is_prime[i]:
            is_prime[i*i::i] = False
    return np.where(is_prime)[0]

def main():

    M = 10000
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

    # Compute coefficients for Sym^3(Delta) (GL(4))
    b3 = np.zeros(M + 1)
    b3[1] = 1.0
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
            if b3[i] == 0: continue
            k = 1
            while True:
                pk = p**k
                if i * pk > M:
                    break
                b3[i * pk] = b3[i] * pk_coeffs[k]
                k += 1

    # Compute coefficients for Sym^4(Delta) (GL(5))
    b4 = np.zeros(M + 1)
    b4[1] = 1.0
    for p in primes:
        tp = float(tau[p] * (p ** -5.5))
        if abs(tp) <= 2.0:
            theta = np.arccos(tp / 2.0)
        else:
            theta = 0.0

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

    # Precompute arrays for fast evaluation
    n_arr = np.arange(1, M + 1)
    log_n = np.log(n_arr)
    sqrt_n = np.sqrt(n_arr)

    # Setup mpmath for gamma
    mpmath.mp.dps = 20

    def get_phase_sym3(t):
        s = 0.5 + 1j * t
        g1 = complex(mpmath.loggamma(s + 16.5))
        g2 = complex(mpmath.loggamma(s + 5.5))
        # phase = exp(i * Im(g1 + g2 - 2s log(2pi)))
        # Im(-2 * (0.5+it) * log(2pi)) = -2t log(2pi)
        phase_val = np.exp(1j * (g1.imag + g2.imag - 2.0 * t * np.log(2.0 * np.pi)))
        return phase_val

    def Z_sym3_fast(t, W=800.0):
        phase = get_phase_sym3(t)
        # L(1/2+it) = sum b3[n] * e^{-n/W} / (n**0.5 * n**it)
        # n**it = exp(1j * t * log_n)
        terms = b3[1:] * np.exp(-n_arr / W) / sqrt_n * np.exp(-1j * t * log_n)
        total = np.sum(terms)
        return (phase * total).real

    def get_phase_sym4(t):
        s = 0.5 + 1j * t
        g_R = complex(mpmath.loggamma((s + 22)/2.0)) - 0.5*(s+22)*np.log(np.pi)
        g_C1 = complex(mpmath.loggamma(s + 11)) - (s+11)*np.log(2.0*np.pi)
        g_C2 = complex(mpmath.loggamma(s + 22)) - (s+22)*np.log(2.0*np.pi)
        phase_val = np.exp(1j * (g_R.imag + g_C1.imag + g_C2.imag))
        return phase_val

    def Z_sym4_fast(t, W=800.0):
        phase = get_phase_sym4(t)
        terms = b4[1:] * np.exp(-n_arr / W) / sqrt_n * np.exp(-1j * t * log_n)
        total = np.sum(terms)
        return (phase * total).real

    def Z_sym3_batch(t_arr, W=800.0):
        phases = np.array([get_phase_sym3(t) for t in t_arr])
        weights = b3[1:] * np.exp(-n_arr / W) / sqrt_n
        exps = np.exp(-1j * np.outer(t_arr, log_n))
        return (phases * (exps @ weights)).real

    def Z_sym4_batch(t_arr, W=800.0):
        phases = np.array([get_phase_sym4(t) for t in t_arr])
        weights = b4[1:] * np.exp(-n_arr / W) / sqrt_n
        exps = np.exp(-1j * np.outer(t_arr, log_n))
        return (phases * (exps @ weights)).real

    # Scan and find zeros
    print("Scanning Sym^3(Delta) (GL(4)) zeros...")
    start = time.time()
    t_vals = np.linspace(5.0, 30.0, 1000)
    z_vals3 = Z_sym3_batch(t_vals)
    zeros3 = []
    for i in range(len(t_vals) - 1):
        if z_vals3[i] * z_vals3[i+1] < 0:
            root = bisect(lambda t: Z_sym3_fast(t), t_vals[i], t_vals[i+1], xtol=1e-8)
            zeros3.append(root)
    print(f"Sym^3 zeros found in {time.time() - start:.2f}s: {zeros3[:6]}")

    print("Scanning Sym^4(Delta) (GL(5)) zeros...")
    start = time.time()
    z_vals4 = Z_sym4_batch(t_vals)
    zeros4 = []
    for i in range(len(t_vals) - 1):
        if z_vals4[i] * z_vals4[i+1] < 0:
            root = bisect(lambda t: Z_sym4_fast(t), t_vals[i], t_vals[i+1], xtol=1e-8)
            zeros4.append(root)
    print(f"Sym^4 zeros found in {time.time() - start:.2f}s: {zeros4[:6]}")

if __name__ == "__main__":
    main()
