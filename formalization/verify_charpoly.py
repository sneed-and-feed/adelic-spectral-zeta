import sympy as sp

A3 = sp.Matrix([
 [0, 0, 0, 1],
 [0, 0, 1, 1],
 [0, 1, 0, 0],
 [1, 1, 0, 0]
])

x = sp.Symbol('x')
print("A3 charpoly:", A3.charpoly(x))
