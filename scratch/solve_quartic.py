import sympy as sp

def main():
    y = sp.Symbol('y')
    poly = y**4 - 16*y**3 + 72*y**2 - 96*y + 4
    
    print("Solving y^4 - 16*y^3 + 72*y^2 - 96*y + 4 = 0...")
    roots = sp.solve(poly, y)
    for i, r in enumerate(roots):
        print(f"Root {i+1}:")
        print(sp.pretty(sp.simplify(r)))

if __name__ == "__main__":
    main()
