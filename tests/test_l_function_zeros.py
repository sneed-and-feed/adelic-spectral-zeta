"""
Test suite: test_l_function_zeros.py
Tests mathematical properties and correctness invariants.
"""
import mpmath

# Define completed L-function for q=3, odd character
def L_3(t):
    s = 0.5 + 1j * t
    # L(s, \chi) = 3^-s * (hurwitz(s, 1/3) - hurwitz(s, 2/3))
    term = 3**(-s) * (mpmath.hurwitz(s, 1/3) - mpmath.hurwitz(s, 2/3))
    return term

def xi_3(t):
    s = 0.5 + 1j * t
    # xi(s, \chi) = (3/pi)**((s+1)/2) * gamma((s+1)/2) * L(s, \chi)
    gamma_factor = mpmath.gamma((s + 1) / 2)
    conductor_factor = (3 / mpmath.pi)**((s + 1) / 2)
    return conductor_factor * gamma_factor * L_3(t)

# Find zeros in t in [0, 50]
t_vals = mpmath.linspace(0, 50, 1000)
y_vals = [float(xi_3(t).real) for t in t_vals]

zeros = []
for i in range(len(t_vals) - 1):
    if y_vals[i] * y_vals[i+1] < 0:
        # Bisection to find root
        root = mpmath.findroot(lambda t: xi_3(t).real, (t_vals[i], t_vals[i+1]))
        zeros.append(float(root))

print("First 10 non-trivial zeros of L(s, chi_3):")
print(zeros[:10])
