import numpy as np
from scipy.optimize import bisect
from adelic_spectral_zeta.erdos_similarity import (
    construct_adelic_sequence,
    construct_adelic_set,
    solve_schrodinger_spectrum
)

primes = [2, 3]
depths = [2, 1]
M = 3
base = 11

seq = construct_adelic_sequence("geometric", M, primes=primes, depths=depths, base=base)
N_inf = 16
set_b = construct_adelic_set("porous", N_inf=N_inf, primes=primes, depths=depths)

grid_params = {
    "N_u": 2,
    "u_min": -0.5,
    "u_max": 0.5,
    "V_list": depths,
    "primes": primes,
    "L": 1.0
}

def f(lmb):
    e, _, _ = solve_schrodinger_spectrum(set_b, seq, grid_params, lmbda=lmb)
    return e[0]

# Find lambda_c using bisection
lambda_c = bisect(f, 0.0, 1.0)
print(f"Critical coupling lambda_c: {lambda_c:.6f}")
