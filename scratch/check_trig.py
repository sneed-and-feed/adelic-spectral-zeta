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
        nonzero_s = s[s > 1e-10]
        nonzero_s = np.sort(nonzero_s)
        
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
        # Let's extract the offsets x = sigma^2 - 2
        offsets = [u**2 - 2 for u in unique_s]
        for u, m, off in zip(unique_s, multiplicities, offsets):
            # check if off / 2 is cos of some rational multiple of pi
            # cos(theta) = off / 2
            cos_val = off / 2.0
            theta_pi = np.arccos(np.clip(cos_val, -1.0, 1.0)) / np.pi
            print(f"  sigma^2 = 2 + {off:+.6f} (mult {m}) | cos(theta) = {cos_val:+.6f} | theta = {theta_pi:.6f} * pi")

if __name__ == "__main__":
    main()
