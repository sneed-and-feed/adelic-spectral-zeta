import sympy as sp

u = sp.Symbol('u', commutative=True)

# We use symbols for the non-commutative matrices
# Note: sympy matrices with non-commutative symbols can be tricky.
# We'll just define 2x2 block matrices whose entries are symbols, and assume they commute if they are scalars.

class MatrixSymbol(sp.Expr):
    def __new__(cls, name):
        return sp.Symbol(name, commutative=False)

I_V = sp.Symbol('I_V', commutative=False)
I_E = sp.Symbol('I_E', commutative=False)
S = sp.Symbol('S', commutative=False)
T_t = sp.Symbol('T_t', commutative=False)
J = sp.Symbol('J', commutative=False)
S_t = sp.Symbol('S_t', commutative=False)
T_M = sp.Symbol('T_M', commutative=False)
A = sp.Symbol('A', commutative=False)
D = sp.Symbol('D', commutative=False)

def mul(a, b):
    # Handle scalar multiplication manually
    if a == 0 or b == 0: return 0
    if a == 1: return b
    if b == 1: return a
    if isinstance(a, sp.Mul):
        args = list(a.args)
        # extract scalars
        scalars = [x for x in args if x.is_commutative]
        noncom = [x for x in args if not x.is_commutative]
        if not noncom:
            return sp.Mul(*scalars) * b
        else:
            return sp.Mul(*scalars) * mul(noncom[0], b) # Assuming 1 noncom
    if isinstance(a, sp.Add):
        return sp.Add(*[mul(x, b) for x in a.args])
    if isinstance(b, sp.Add):
        return sp.Add(*[mul(a, x) for x in b.args])
    if a == u or a == 1-u**2:
        return a * b
    if b == u or b == 1-u**2:
        return b * a
    return a * b

# Rules:
# S * T_t = A
# S * S_t = D
# J * T_t = S_t
# J * S_t = T_t
# S * J = T_M
# T_t * S = T_hash + J
T_hash = T_t * S - J

M = sp.Matrix([[I_V, u*S], [u*T_t, I_E + u*J]])
print("M:")
sp.pprint(M)

# Evaluate det M using Schur complement from top-left block
# det(M) = det(I_V) * det(I_E + u*J - u*T_t * I_V * u*S)
det_M_1 = I_E + u*J - u**2 * T_t * S
print("det_M Schur 1:", det_M_1)

# What if we want det(I_E - u*T_hash) ?
print("I_E - u*T_hash:", I_E - u*T_hash)
# I_E - u*(T_t * S - J) = I_E - u*T_t*S + u*J
