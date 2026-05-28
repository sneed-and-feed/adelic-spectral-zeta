import sympy as sp

def build_symbolic_adjacency(depth):
    V = 1 << (depth - 1)
    A = sp.Matrix.zeros(V, V)
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
    d = 6
    print(f"--- Depth {d} (V={1<<(d-1)}) ---")
    A = build_symbolic_adjacency(d)
    x = sp.Symbol('x')
    charpoly = A.charpoly(x)
    poly = charpoly.as_expr()
    factored = sp.factor(poly)
    print(sp.pretty(factored))

if __name__ == "__main__":
    main()
