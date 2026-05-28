import numpy as np
import sympy as sp

def analyze_roots():
    # Let's define the symbolic polynomials:
    z = sp.symbols('z')
    
    P4 = z - 4
    P5 = z**2 - 8*z + 4
    P6 = z**4 - 16*z**3 + 72*z**2 - 96*z + 4
    P7 = z**8 - 32*z**7 + 400*z**6 - 2496*z**5 + 8200*z**4 - 13568*z**3 + 9536*z**2 - 1664*z + 4
    
    # Let's solve them and print the numerical roots:
    roots4 = [float(sp.re(r.evalf())) for r in sp.solve(P4, z)]
    roots5 = [float(sp.re(r.evalf())) for r in sp.solve(P5, z)]
    roots6 = [float(sp.re(r.evalf())) for r in sp.solve(P6, z)]
    roots7 = [float(sp.re(r.evalf())) for r in sp.solve(P7, z)]
    
    print("Roots of P4:", roots4)
    print("Roots of P5:", sorted(roots5))
    print("Roots of P6:", sorted(roots6))
    print("Roots of P7:", sorted(roots7))
    
    # Let's check if the roots of P_d are of the form 8 - something or if there is a nested radical structure.
    # For example, roots of P5 are 4 +/- sqrt(12) = 4 +/- 2*sqrt(3).
    # What are the roots of P6? Let's check their algebraic representation:
    sol6 = sp.solve(P6, z)
    print("\nAlgebraic roots of P6:")
    for r in sol6:
        print(sp.simplify(r))
        
    # Let's see if there is a quadratic recurrence.
    # For example, does a root w of P_d relate to a root v of P_{d-1}?
    # Let's check if (w - 4)^2 or (w - 8)^2 is related to the roots of P_{d-1}.
    # Let's check:
    # For d=5, roots are z_5 = 4 +/- 2*sqrt(3).
    # (z_5 - 4)^2 = 12.
    # For d=6, let's check the roots z_6:
    # Let's compute (z_6 - 8)^2.
    print("\nLet's test (z_d - 2**(d-3))**2 for d=5, 6, 7:")
    # For d=5, 2**(d-3) = 4. (z_5 - 4)^2 = 12.
    # For d=6, 2**(d-3) = 8. Let's print (z_6 - 8)^2:
    for r in roots6:
        val = (float(r) - 8.0)**2
        print(f"  (root6 - 8)^2 = {val:.6f}")
        
    # For d=7, 2**(d-3) = 16. Let's print (z_7 - 16)^2:
    for r in roots7:
        val = (float(r) - 16.0)**2
        print(f"  (root7 - 16)^2 = {val:.6f}")

if __name__ == "__main__":
    analyze_roots()
