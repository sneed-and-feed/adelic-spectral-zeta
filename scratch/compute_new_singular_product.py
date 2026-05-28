import numpy as np
from numpy.linalg import norm

def compute_products():
    # Let's compute for d=5:
    # new eigenvalues of A_G_5 are the roots of (z - (4 + 2*sqrt(3))) * (z - (4 - 2*sqrt(3))) = z^2 - 8z + 4 = 0 (each with multiplicity 2)
    # The roots in z = mu^2 are z_1 = 4 + 2*sqrt(3), z_2 = 4 - 2*sqrt(3).
    # Since mu = +/- sqrt(z), the new eigenvalues are:
    # mu_1, mu_2 = sqrt(4 + 2*sqrt(3)) = 1 + sqrt(3)  and -(1 + sqrt(3))
    # mu_3, mu_4 = sqrt(4 - 2*sqrt(3)) = sqrt(3) - 1 and -(sqrt(3) - 1)
    # Each has multiplicity 2.
    # Let's test these are indeed the eigenvalues of the new sector at d=5.
    
    # Let's write the values and compute the product of new singular values:
    # sigma_i = sqrt(2 - mu_i / 2)
    # Let's compute for all 8 new eigenvalues at d=5:
    # mu values:
    # 1+sqrt(3) (mult 2)
    # -1-sqrt(3) (mult 2)
    # sqrt(3)-1 (mult 2)
    # 1-sqrt(3) (mult 2)
    
    r3 = np.sqrt(3.0)
    mus = np.array([
        1.0 + r3, 1.0 + r3,
        -1.0 - r3, -1.0 - r3,
        r3 - 1.0, r3 - 1.0,
        1.0 - r3, 1.0 - r3
    ])
    
    sigmas = np.sqrt(2.0 - 0.5 * mus)
    prod_sigmas = np.prod(sigmas)
    print(f"d=5:")
    print(f"  mus: {mus}")
    print(f"  sigmas: {sigmas}")
    print(f"  Product of new singular values: {prod_sigmas:.15f}")
    
    # Let's check algebraically:
    # The product of sigmas is prod_{i=1}^8 sqrt(2 - mu_i / 2) = sqrt( prod_{i=1}^8 (2 - mu_i / 2) )
    # Let's evaluate prod_{i} (2 - mu_i / 2)
    # The mu_i values are:
    # lambda_1 = 1 + sqrt(3)
    # lambda_2 = -1 - sqrt(3)
    # lambda_3 = sqrt(3) - 1
    # lambda_4 = 1 - sqrt(3)
    # each with multiplicity 2.
    # (2 - lambda_1/2)(2 - lambda_2/2) = (2 - (1+sqrt(3))/2)(2 - (-1-sqrt(3))/2)
    # = (3/2 - sqrt(3)/2)(5/2 + sqrt(3)/2) = 15/4 + 3*sqrt(3)/4 - 5*sqrt(3)/4 - 3/4 = 12/4 - 2*sqrt(3)/4 = 3 - sqrt(3)/2
    # (2 - lambda_3/2)(2 - lambda_4/2) = (2 - (sqrt(3)-1)/2)(2 - (1-sqrt(3))/2)
    # = (5/2 - sqrt(3)/2)(3/2 + sqrt(3)/2) = 15/4 + 5*sqrt(3)/4 - 3*sqrt(3)/4 - 3/4 = 12/4 + 2*sqrt(3)/4 = 3 + sqrt(3)/2
    # Multiplying these two:
    # (3 - sqrt(3)/2)(3 + sqrt(3)/2) = 9 - 3/4 = 33/4 = 8.25
    # Since each has multiplicity 2, the product of (2 - mu_i/2) is (33/4)^2 = 1089/16 = 68.0625.
    # The product of sigmas is the square root of this:
    # prod_sigmas = sqrt(68.0625) = 8.25 (which is 33/4).
    # Let's test this!
    print(f"  Analytical product: {33.0 / 4.0}")

    # Let's do d=6:
    # The minimal polynomial in z = mu^2 is z^4 - 16z^3 + 72z^2 - 96z + 4 = 0 (each with multiplicity 2)
    # The roots in z are z_1, z_2, z_3, z_4.
    # For each z_k, the eigenvalues are +/- sqrt(z_k).
    # So the product of (2 - mu/2) for all 16 new eigenvalues (each z_k gives two mus, and each has multiplicity 2)
    # is:
    # prod_{k=1}^4 [ (2 - sqrt(z_k)/2) (2 + sqrt(z_k)/2) ]^2
    # = prod_{k=1}^4 [ 4 - z_k / 4 ]^2
    # = [ prod_{k=1}^4 (4 - z_k / 4) ]^2
    # = [ (1/256) * prod_{k=1}^4 (16 - z_k) ]^2
    # Let's note that prod_{k=1}^4 (16 - z_k) is the value of the characteristic polynomial Q_6(z) = prod (z - z_k) at z = 16.
    # Since Q_6(z) = z^4 - 16z^3 + 72z^2 - 96z + 4:
    # Q_6(16) = 16^4 - 16^4 + 72 * 16^2 - 96 * 16 + 4
    #         = 72 * 256 - 96 * 16 + 4
    #         = 18432 - 1536 + 4
    #         = 16900
    # Thus, the product inside the square is (1/256) * 16900 = 16900 / 256 = 4225 / 64
    # And we square it because of multiplicity 2: (4225 / 64)^2
    # The product of the singular values is the square root:
    # prod_sigmas = 4225 / 64 = 66.015625
    # Let's print and check!
    print(f"\nd=6:")
    # We can get the roots of z^4 - 16z^3 + 72z^2 - 96z + 4 = 0
    coeffs = [1.0, -16.0, 72.0, -96.0, 4.0]
    zs = np.roots(coeffs)
    mus_d6 = []
    for z in zs:
        mus_d6.extend([np.sqrt(z), -np.sqrt(z), np.sqrt(z), -np.sqrt(z)]) # mult 2
    mus_d6 = np.array(mus_d6)
    sigmas_d6 = np.sqrt(2.0 - 0.5 * mus_d6)
    prod_sigmas_d6 = np.prod(sigmas_d6)
    print(f"  Product of new singular values: {prod_sigmas_d6:.15f}")
    print(f"  Analytical product: {4225.0 / 64.0}")

if __name__ == "__main__":
    compute_products()
