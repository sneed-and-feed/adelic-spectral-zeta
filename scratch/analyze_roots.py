import numpy as np

def main():
    # Coefficients of the polynomials in z = x^2
    # P4: z - 4
    # P5: z^2 - 8z + 4
    # P6: z^4 - 16z^3 + 72z^2 - 96z + 4
    # P7: z^8 - 32z^7 + 400z^6 - 2496z^5 + 8200z^4 - 13568z^3 + 9536z^2 - 1664z + 4
    
    roots4 = np.roots([1, -4])
    roots5 = np.roots([1, -8, 4])
    roots6 = np.roots([1, -16, 72, -96, 4])
    roots7 = np.roots([1, -32, 400, -2496, 8200, -13568, 9536, -1664, 4])
    
    print("Roots of P4:", np.sort(roots4))
    print("Roots of P5:", np.sort(roots5))
    print("Roots of P6:", np.sort(roots6))
    print("Roots of P7:", np.sort(roots7))
    
    # Let's check if there is a map from roots of P_d to roots of P_{d-1}
    # For example, let's see if there is a function f(z) = a * z * (b - z) or similar
    # In many dynamical systems (like Chebyshev or quadratic maps), the roots are related by a polynomial map.
    # Let's test if f(z) = z * (something - z) maps roots of P_d to roots of P_{d-1}.
    # E.g. for P5: roots are approx 0.5359 and 7.4641
    # For P4: root is 4
    # Let's see: f(0.5359) = 4, f(7.4641) = 4
    # Let's fit a quadratic function f(z) = -z^2 + B z + C such that f(r_1) = 4, f(r_2) = 4
    # Since r_1 + r_2 = 8, the vertex of the parabola is at z = 4.
    # So f(z) = - (z-4)^2 + 16 = -z^2 + 8z.
    # Let's evaluate f(z) = 8z - z^2 for the roots of P5:
    # 8 * 0.5359 - 0.5359^2 = 4.2872 - 0.2872 = 4.0!
    # 8 * 7.4641 - 7.4641^2 = 59.7128 - 55.7128 = 4.0!
    # Oh my god! It works EXACTLY! The map is f(z) = 8z - z^2 !
    
    print("\nTesting f(z) = 8z - z^2 on roots of P5:")
    print("  f(roots5) =", 8 * roots5 - roots5**2)
    
    # Now let's test if the same map f(z) = 8z - z^2 maps roots of P6 to roots of P5!
    print("\nTesting f(z) = 8z - z^2 on roots of P6:")
    sorted_f_roots6 = np.sort(8 * roots6 - roots6**2)
    print("  f(roots6) =", sorted_f_roots6)
    print("  roots5    =", np.sort(roots5))
    print("  Match?", np.allclose(sorted_f_roots6, np.sort(roots5)))
    
    # Let's test if it maps roots of P7 to roots of P6!
    print("\nTesting f(z) = 8z - z^2 on roots of P7:")
    sorted_f_roots7 = np.sort(8 * roots7 - roots7**2)
    print("  f(roots7) =", sorted_f_roots7)
    print("  roots6    =", np.sort(roots6))
    print("  Match?", np.allclose(sorted_f_roots7, np.sort(roots6)))

if __name__ == "__main__":
    main()
