import numpy as np
import sys

def compute_ratio(d, alpha):
    N = 2**(d-2)
    L = int(alpha * N)
    if L == 0:
        return 0
    k = np.arange(1, L + 1)
    num = np.sum((1 - np.cos(2 * np.pi * k / N))**2)
    den = L
    return num / den

def main():
    alphas = [0.1, 0.25, 0.5, 0.75, 1.0]
    ds = [10, 15, 20, 24]
    
    for alpha in alphas:
        print(f"Alpha: {alpha}")
        for d in ds:
            ratio = compute_ratio(d, alpha)
            print(f"  d={d}: ratio = {ratio:.6f}")
        print()

if __name__ == "__main__":
    main()
