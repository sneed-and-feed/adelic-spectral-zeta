import numpy as np
from scipy.linalg import eigh
import sympy as sp

def build_adjacency(depth):
    half_N = 1 << (depth - 1)
    A_G = np.zeros((half_N, half_N))
    inv_3 = 1
    for i in range(1, half_N):
        if (3 * i) % half_N == 1:
            inv_3 = i
            break
            
    for x in range(half_N):
        A_G[(3 * x) % half_N, x] += 1.0
        A_G[(3 * x - 1) % half_N, x] += 1.0
        A_G[(inv_3 * x) % half_N, x] += 1.0
        A_G[(inv_3 * (x + 1)) % half_N, x] += 1.0
    return A_G

def get_modulation_isometry(depth):
    N_d = 1 << (depth - 1)
    N_d1 = 1 << depth
    L = np.zeros((N_d1, N_d))
    for x in range(N_d1):
        L[x, x % N_d] = 1.0 / np.sqrt(2.0)
    m = np.ones(N_d1)
    m[N_d:] = -1.0
    U = np.diag(m) @ L
    return U

def find_algebraic():
    # Let's find the exact representations of the unique values:
    vals = [0.627963, -0.325058, -0.229850, -0.888074, -0.459701, -0.444037, 0.999944]
    
    # We want to check if they match roots of simple polynomials, or nested radicals of sqrt(3), sqrt(2), etc.
    # Let's check some guesses:
    print("Guessed expressions and their values:")
    
    guesses = {
        "sqrt((3 - sqrt(3))/6)": np.sqrt((3.0 - np.sqrt(3.0)) / 6.0),
        "sqrt((3 + sqrt(3))/6)": np.sqrt((3.0 + np.sqrt(3.0)) / 6.0),
        "sqrt((3 - sqrt(3))/12)": np.sqrt((3.0 - np.sqrt(3.0)) / 12.0),
        "sqrt((3 + sqrt(3))/12)": np.sqrt((3.0 + np.sqrt(3.0)) / 12.0),
        "sqrt((3 - sqrt(3))/24)": np.sqrt((3.0 - np.sqrt(3.0)) / 24.0),
        "sqrt((3 + sqrt(3))/24)": np.sqrt((3.0 + np.sqrt(3.0)) / 24.0),
        "sqrt((2 - sqrt(3))/4)": np.sqrt((2.0 - np.sqrt(3.0)) / 4.0),
        "sqrt((2 + sqrt(3))/4)": np.sqrt((2.0 + np.sqrt(3.0)) / 4.0),
        "sqrt((2 - sqrt(2))/4)": np.sqrt((2.0 - np.sqrt(2.0)) / 4.0),
        "sqrt((2 + sqrt(2))/4)": np.sqrt((2.0 + np.sqrt(2.0)) / 4.0),
    }
    
    for name, val in guesses.items():
        print(f"  {name:30} = {val:.8f}")
        
    print("\nMatching the computed values:")
    for v in vals:
        matched = False
        for name, val in guesses.items():
            if abs(abs(v) - val) < 1e-5:
                print(f"  {v:+.6f} matches {name} (diff {abs(abs(v) - val):.2e})")
                matched = True
                break
        if not matched:
            print(f"  {v:+.6f} could not be matched with simple guesses.")

if __name__ == "__main__":
    find_algebraic()
