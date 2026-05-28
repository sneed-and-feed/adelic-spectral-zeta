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
    for d in range(3, 9):
        A, B = build_operators(d)
        Kd = A @ B - B @ A
        s = svdvals(Kd)
        
        # Filter non-zero singular values
        nonzero_s = s[s > 1e-10]
        
        # Find unique singular values and their multiplicities
        unique_s = []
        multiplicities = []
        for val in nonzero_s:
            # check if close to existing
            found = False
            for idx, u in enumerate(unique_s):
                if np.isclose(u, val, atol=1e-8):
                    multiplicities[idx] += 1
                    found = True
                    break
            if not found:
                unique_s.append(val)
                multiplicities.append(1)
                
        print(f"Depth {d} (N={1<<d}):")
        print(f"  Kernel dimension: { (1<<d) - len(nonzero_s) } (expected { (1<<(d-1)) + 1 })")
        print(f"  Non-zero singular values:")
        for u, m in zip(unique_s, multiplicities):
            print(f"    {u:.10f} (multiplicity: {m})")

if __name__ == "__main__":
    main()
