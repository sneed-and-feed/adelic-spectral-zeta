import numpy as np
from scipy.linalg import svdvals

def build_operators(depth):
    N = 1 << depth
    A = np.zeros((N, N))
    for x in range(N):
        A[(x + 1) % N, x] = 1.0
        
    B_alg = np.zeros((N, N))
    inv_3 = 1
    for i in range(1, N):
        if (3 * i) % N == 1:
            inv_3 = i
            break
    for x in range(N):
        y1 = (2 * x) % N
        B_alg[x, y1] += 0.5
        y2 = ((2 * x - 1) * inv_3) % N
        B_alg[x, y2] += 0.5
        
    return A, B_alg

def main():
    for d in range(3, 7):
        A, B = build_operators(d)
        Kd = A @ B - B @ A
        s = svdvals(Kd)
        nonzero_s = s[s > 1e-10]
        
        # Sort ascending
        nonzero_s = np.sort(nonzero_s)
        
        # Find unique singular values and their multiplicities
        unique_s = []
        multiplicities = []
        for val in nonzero_s:
            found = False
            for idx, u in enumerate(unique_s):
                if np.isclose(u, val, atol=1e-8):
                    multiplicities[idx] += 1
                    found = True
                    break
            if not found:
                unique_s.append(val)
                multiplicities.append(1)
                
        print(f"\nDepth {d} (N={1<<d}):")
        for u, m in zip(unique_s, multiplicities):
            sq = u**2
            # Let's see if we can identify it in terms of sqrt
            # E.g. test if it's of the form a + b * sqrt(c)
            # or try to print it as a float first
            print(f"  sigma = {u:.10f}, sigma^2 = {sq:.10f} (mult {m})")

if __name__ == "__main__":
    main()
