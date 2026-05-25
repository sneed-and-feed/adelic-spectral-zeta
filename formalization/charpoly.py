import sympy as sp

M3 = sp.Matrix([[0, -1], [-1, -1]])
M4 = sp.Matrix([
 [0, 0, 0, 0],
 [0, 0, 0, 1],
 [0, 0, -1, 0],
 [0, 1, 0, 0]
])
M5 = sp.Matrix([
 [0, 0, 0, -1, 0, 0, 0, -1],
 [0, 0, 1, 0, 0, 0, 1, 0],
 [0, 1, 0, 0, 0, 1, 1, 0],
 [-1, 0, 0, 0, -1, 0, 0, 0],
 [0, 0, 0, -1, -1, 0, 0, 1],
 [0, 0, 1, 0, 0, 0, -1, 0],
 [0, 1, 1, 0, 0, -1, 0, 0],
 [-1, 0, 0, 0, 1, 0, 0, 0]
])

x = sp.Symbol('x')
print("d=3:", M3.charpoly(x))
print("d=3 roots:", M3.eigenvals())

print("d=4:", M4.charpoly(x))
print("d=4 roots:", M4.eigenvals())

print("d=5:", M5.charpoly(x))
print("d=5 roots:", M5.eigenvals())
