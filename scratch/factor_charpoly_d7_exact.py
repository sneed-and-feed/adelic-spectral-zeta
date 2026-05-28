import sympy as sp
import time

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
    d = 7
    print(f"Constructing exact integer adjacency matrix for Depth {d} (V={1<<(d-1)})...")
    start = time.time()
    A = build_symbolic_adjacency(d)
    print(f"Matrix built in {time.time() - start:.2f} seconds.")
    
    print("Computing exact characteristic polynomial... (this may take a minute)")
    start = time.time()
    x = sp.Symbol('x')
    charpoly = A.charpoly(x)
    poly = charpoly.as_expr()
    print(f"Charpoly computed in {time.time() - start:.2f} seconds.")
    
    print("Factoring exact characteristic polynomial...")
    start = time.time()
    factored = sp.factor(poly)
    print(f"Factored in {time.time() - start:.2f} seconds.")
    
    print("\nFactored Characteristic Polynomial of Depth 7:")
    print(sp.pretty(factored))

if __name__ == "__main__":
    main()
