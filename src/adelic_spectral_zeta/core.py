"""Ramanujan tau computation and symmetric-power L-function Z-functions (Sym³, Sym⁴)."""

import numpy as np
import mpmath
from scipy.signal import fftconvolve

from .primes import sieve_primes

def get_tau(M: int) -> np.ndarray:
    """Compute Ramanujan tau values up to M in O(M log M) time via Pentagonal shifts & FFT.
    
    Uses the Euler pentagonal number theorem: eta(q) = sum_{k in Z} (-1)^k q^{k(3k-1)/2}.
    """
    # Build Euler eta(q) = prod(1 - q^k) up to degree M
    eta = np.zeros(M + 1)
    eta[0] = 1.0
    k = 1
    while True:
        p1 = k * (3 * k - 1) // 2
        p2 = k * (3 * k + 1) // 2
        # Euler function sign based on the parity of k
        sign = -1 if k % 2 == 1 else 1
        if p1 > M and p2 > M:
            break
        if p1 <= M:
            eta[p1] = sign
        if p2 <= M:
            eta[p2] = sign
        k += 1

    # Compute eta(q)^24 via O(log N) FFT repeated squaring
    result = np.zeros(M + 1)
    result[0] = 1.0
    base = eta.copy()
    n = 24
    while n > 0:
        if n & 1:
            result = fftconvolve(result, base)[:M + 1]
        base = fftconvolve(base, base)[:M + 1]
        n >>= 1

    # Shift by 1 since Delta(q) = q * eta(q)^24
    tau = np.zeros(M + 1)
    tau[1:] = result[:M]
    return tau

def get_phase_sym3(t: float | np.ndarray) -> complex | np.ndarray:
    """Computes the gamma factor phase for the degree-3 symmetric power L-function.
    
    The shifts 16.5 and 5.5 arise from (k-1)/2 + degree_shift for weight k=12.
    """
    s = 0.5 + 1j * t
    g1 = complex(mpmath.loggamma(s + 16.5))
    g2 = complex(mpmath.loggamma(s + 5.5))
    return np.exp(1j * (g1.imag + g2.imag - 2.0 * t * np.log(2.0 * np.pi)))

def Z_sym3_batch(t_arr: np.ndarray, M: int = 8000, W: float = 1000.0) -> np.ndarray:
    """Computes the Hardy Z-function for Sym³(Δ) using a truncated Dirichlet series.
    
    Uses Ramanujan-Petersson normalized coefficients. The W=1000.0 parameter
    is a smooth cutoff window. The b3 array stores the Sym³ Dirichlet coefficients.
    """
    tau = get_tau(M)
    
    primes = sieve_primes(M)

    b3 = np.zeros(M + 1)
    b3[1] = 1.0
    for p in primes:
        tp = float(tau[p] * (p ** -5.5))
        # Clamp at 2.0 to enforce the Ramanujan-Petersson bound
        if abs(tp) > 2.0:
            tp = 2.0 * np.sign(tp)
            
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

    n_arr = np.arange(1, M + 1)
    log_n = np.log(n_arr)
    sqrt_n = np.sqrt(n_arr)
    
    phases = np.array([get_phase_sym3(t) for t in t_arr])
    weights = b3[1:] * np.exp(-n_arr / W) / sqrt_n
    exps = np.exp(-1j * np.outer(t_arr, log_n))
    return (phases * (exps @ weights)).real

def get_phase_sym4(t: float | np.ndarray) -> complex | np.ndarray:
    """Computes the gamma factor phase for the degree-4 symmetric power L-function.
    
    The parameters 22.0 and 11.0 come from the Langlands parameters of Sym⁴ for weight 12.
    """
    s = 0.5 + 1j * t
    g_R = complex(mpmath.loggamma((s + 22.0)/2.0)) - 0.5*(s+22.0)*np.log(np.pi)
    g_C1 = complex(mpmath.loggamma(s + 11.0)) - (s+11.0)*np.log(2.0*np.pi)
    g_C2 = complex(mpmath.loggamma(s + 22.0)) - (s+22.0)*np.log(2.0*np.pi)
    return np.exp(1j * (g_R.imag + g_C1.imag + g_C2.imag))

def Z_sym4_batch(t_arr: np.ndarray, M: int = 8000, W: float = 1000.0) -> np.ndarray:
    """Computes the Hardy Z-function for Sym⁴(Δ) using a truncated Dirichlet series.
    
    The b4 array stores the Sym⁴ Dirichlet coefficients. The W=1000.0 parameter
    is a smooth cutoff window.
    """
    tau = get_tau(M)
    
    primes = sieve_primes(M)

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

    n_arr = np.arange(1, M + 1)
    log_n = np.log(n_arr)
    sqrt_n = np.sqrt(n_arr)
    
    phases = np.array([get_phase_sym4(t) for t in t_arr])
    weights = b4[1:] * np.exp(-n_arr / W) / sqrt_n
    exps = np.exp(-1j * np.outer(t_arr, log_n))
    return (phases * (exps @ weights)).real
