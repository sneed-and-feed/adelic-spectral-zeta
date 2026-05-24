import sympy as sp

def main():
    u = sp.Symbol('u')
    poly = u**3 - 48*u**2 + 560*u - 1024
    print("Factoring u^3 - 48*u^2 + 560*u - 1024...")
    print(sp.factor(poly))
    
    print("\nRoots of the cubic:")
    roots = sp.solve(poly, u)
    for r in roots:
        print(sp.simplify(r))

if __name__ == "__main__":
    main()
