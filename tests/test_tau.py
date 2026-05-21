import numpy as np
import mpmath

# Calculate Ramanujan tau coefficients using modular discriminant expansion
# Delta(q) = q * prod_{n=1}^inf (1 - q^n)^24
# We compute coefficients up to degree 100
M = 100
coeffs = np.zeros(M + 1)
coeffs[1] = 1.0

# Using prod(1 - q^n)^24
# Let's represent the product expansion in python.
# We can do this by using the pentagonal number theorem for (1-q)^3 or just polynomial multiplication.
# A simple way to compute it:
# Delta(q) = q * (prod (1-q^n))^24.
# We can compute the series for prod(1-q^n) first:
poly = np.zeros(M + 1)
poly[0] = 1.0
for n in range(1, M + 1):
    # Multiply by (1 - q^n)
    next_poly = poly.copy()
    for i in range(M + 1 - n):
        next_poly[i + n] -= poly[i]
    poly = next_poly

# Now raise to power 24
delta_poly = np.zeros(M + 1)
delta_poly[0] = 1.0
for power in range(24):
    next_delta = np.zeros(M + 1)
    for i in range(M + 1):
        for j in range(M + 1 - i):
            next_delta[i + j] += delta_poly[i] * poly[j]
    delta_poly = next_delta

# Shift by 1 (multiply by q)
tau = np.zeros(M + 1)
for i in range(M):
    tau[i + 1] = delta_poly[i]

# Test printing tau for first few primes
primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43]
print("Primes and tau values:")
for p in primes:
    print(f"p = {p}: tau = {tau[p]}")

# Normalized tau values: \tilde{\tau}(n) = \tau(n) * n**(-11/2)
def tau_tilde(n):
    return float(tau[n] * (n**(-5.5)))

# Completed normalized L-function using approximate functional equation
# \Xi(1/2 + it) = 2 * Re( (2*pi)**(-s) * \sum_{n=1}^50 \tilde{\tau}(n)/n^s * gamma(s + 5.5, 2*pi*n) )
# where s = 1/2 + it
def Xi_delta(t):
    s = mpmath.mpc(0.5, t)
    total = mpmath.mpc(0.0)
    for n in range(1, 50):
        coeff = float(tau[n] * (n**(-5.5)))
        val = coeff / (n**s) * mpmath.gammainc(s + 5.5, 2 * mpmath.pi * n)
        total += val
    xi_val = 2 * ( (2 * mpmath.pi)**(-s) * total ).real
    return float(xi_val)

# Find zeros in range [0, 20]
t_vals = np.linspace(0, 20, 200)
y_vals = [Xi_delta(t) for t in t_vals]

zeros = []
for i in range(len(t_vals) - 1):
    if y_vals[i] * y_vals[i+1] < 0:
        root = mpmath.findroot(Xi_delta, (t_vals[i], t_vals[i+1]))
        zeros.append(float(root))

print("\nFirst non-trivial zeros of the Ramanujan L-function on the critical line:")
print(zeros)
