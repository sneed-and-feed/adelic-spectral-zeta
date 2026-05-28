import numpy as np
import sympy as sp

def build_adjacency(depth):
    V = 1 << (depth - 1)
    A = np.zeros((V, V))
    for k in range(V):
        v1 = (k + 1) % V
        v2_even = (3 * k + 2) % V
        v2_odd = (3 * k + 3) % V
        
        A[v1, v2_even] += 1
        A[v2_even, v1] += 1
        A[v1, v2_odd] += 1
        A[v2_odd, v1] += 1
    return A

def main():
    d = 7
    print(f"Computing charpoly for Depth {d} (V={1<<(d-1)})...")
    A = build_adjacency(d)
    
    # Compute characteristic polynomial coefficients using numpy.poly
    poly_coeffs = np.poly(A)
    
    # Round to nearest integers
    int_coeffs = np.round(poly_coeffs).astype(object)
    
    # Convert to sympy polynomial
    x = sp.Symbol('x')
    poly_expr = sum(c * x**(len(int_coeffs) - 1 - i) for i, c in enumerate(int_coeffs))
    
    print("Factoring the polynomial in SymPy...")
    factored = sp.factor(poly_expr)
    print("\nFactored Characteristic Polynomial of Depth 7:")
    print(sp.pretty(factored))

if __name__ == "__main__":
    main()
