import numpy as np
import matplotlib.pyplot as plt

def compute_Sn(n):
    N = 2**(n-1)
    Sn = np.zeros((N, N))
    for v in range(N):
        y1 = (3 * v) % (2**n)
        Sn[v, y1 % N] += 1 if y1 < N else -1
        
        y2 = (3 * v - 1) % (2**n)
        Sn[v, y2 % N] += 1 if y2 < N else -1
    return Sn

def main():
    plt.figure(figsize=(15, 10))
    for i, n in enumerate(range(3, 10)):
        Sn = compute_Sn(n)
        evs = np.linalg.eigvals(Sn)
        mags = np.abs(evs)
        N = 2**(n-1)
        r_exact = 2**(1/N)
        print(f"n={n:2d} | N={N:3d} | Max|λ|={np.max(mags):.6f} | Min|λ|={np.min(mags):.6f} | Exact 2^(1/N)={r_exact:.6f}")
        
        plt.subplot(3, 3, i+1)
        plt.scatter(evs.real, evs.imag, s=10, alpha=0.7)
        circle = plt.Circle((0, 0), r_exact, fill=False, color='red', linestyle='--')
        plt.gca().add_patch(circle)
        plt.title(f"n={n} (N={N})")
        plt.grid(True)
        plt.axis('equal')

    plt.tight_layout()
    plt.savefig('twisted_spectrum.png')
    print("Saved plot to twisted_spectrum.png")

if __name__ == "__main__":
    main()
