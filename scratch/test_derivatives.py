import json
import math
import numpy as np
import mpmath
import sympy as sp

mpmath.mp.dps = 35

# Load complex ap from step 1334
filepath = r"C:\Users\x\.gemini\antigravity\brain\f1ebe7a5-1121-4865-9a68-9e435b87c778\.system_generated\steps\1334\content.md"
with open(filepath, "r", encoding="utf-8") as f:
    text = f.read()
json_text = text.split("---")[1].strip()
data_hecke = json.loads(json_text)
entry = data_hecke["data"][0]
ap_raw = entry["ap"]
N = 800

zeta20 = np.exp(2j * np.pi / 20.0)
def parse_coeff(terms):
    if not terms: return 0.0 + 0.0j
    return sum(c * (zeta20 ** k) for c, k in terms)

primes_list = list(sp.primerange(2, 2001))
a_p_complex = {}
for idx, p in enumerate(primes_list):
    if idx < len(ap_raw):
        a_p_complex[p] = parse_coeff(ap_raw[idx])

# Build character chi
lut_32 = {}
for x1 in [0, 1]:
    for x2 in range(8):
        lut_32[((-1)**x1 * 5**x2) % 32] = (x1, x2)
lut_25 = {}
for x3 in range(20):
    lut_25[(2**x3) % 25] = x3

def chi(n):
    n = int(n)
    if math.gcd(n, 800) > 1: return 0.0 + 0.0j
    x1, _ = lut_32[n % 32]
    x3 = lut_25[n % 25]
    val = (5*x1 + 4*x3) % 10
    return np.exp(2j * np.pi * val / 10)

M = 1500
primes = [p for p in primes_list if p <= M]
a = np.zeros(M+1, dtype=complex)
a[1] = 1.0

for p in primes:
    ap = a_p_complex.get(p, 0.0+0j)
    chip = chi(p)
    pk_coeffs = [1.0+0j, ap]
    k = 2
    while p**k <= M:
        pk_coeffs.append(ap * pk_coeffs[k-1] - chip * pk_coeffs[k-2])
        k += 1
    for k in range(1, len(pk_coeffs)):
        if p**k <= M:
            a[p**k] = pk_coeffs[k]

for i in range(2, M+1):
    if abs(a[i]) < 1e-14:
        continue
    for p in primes:
        if i * p > M:
            break
        if math.gcd(i, p) > 1:
            continue
        ap = a_p_complex.get(p, 0.0+0j)
        chip = chi(p)
        pk_coeffs = [1.0+0j, ap]
        kk = 2
        while i * p**kk <= M:
            pk_coeffs.append(ap * pk_coeffs[kk-1] - chip * pk_coeffs[kk-2])
            kk += 1
        for k in range(1, len(pk_coeffs)):
            pk = p**k
            if i * pk > M:
                break
            a[i*pk] = a[i] * pk_coeffs[k]

log_n = np.log(np.arange(1, M+1))
a_arr = a[1:]

def eval_L(t, w_val, max_n=1200):
    s = 0.5 + 1j*t
    powers = np.exp(-s * log_n[:max_n])
    S1 = np.dot(a_arr[:max_n], powers)
    
    s2 = 0.5 - 1j*t
    powers2 = np.exp(-s2 * log_n[:max_n])
    S2 = np.dot(np.conj(a_arr[:max_n]), powers2)
    
    gamma_s = mpmath.gamma(mpmath.mpc(0.5, t))
    gamma_1ms = mpmath.gamma(mpmath.mpc(0.5, -t))
    cond = mpmath.mpf(N) / (4 * mpmath.pi**2)
    cond_factor = mpmath.power(cond, mpmath.mpc(0, t))
    P = gamma_1ms / gamma_s * cond_factor
    P_c = complex(float(P.real), float(P.imag))
    
    return S1 + w_val * P_c * S2

buhler_zeros = [5.1015, 5.5613, 6.0244, 6.4910, 6.9613]
w_vals = [-1j, -1j, -1j, 1j, 1j]

eps = 1e-4
for idx, (t, w) in enumerate(zip(buhler_zeros, w_vals)):
    L_val = eval_L(t, w)
    L_plus = eval_L(t + eps, w)
    L_minus = eval_L(t - eps, w)
    
    # Derivative with respect to t
    dL_dt = (L_plus - L_minus) / (2 * eps)
    
    # Derivative with respect to s = 1/2 + it: dL_ds = -i * dL_dt
    dL_ds = -1j * dL_dt
    
    print(f"Zero t_{idx+1}={t:.4f}: |L|={abs(L_val):.6f}, dL/ds={dL_ds:.4f}, |dL/ds|={abs(dL_ds):.4f}")
