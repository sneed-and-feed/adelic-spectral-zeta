import numpy as np

def build_adjacency(depth):
    V = 1 << (depth - 1)
    A = np.zeros((V, V))
    for k in range(V):
        v1 = (k + 1) % V
        v2_even = (3 * k + 2) % V
        v2_odd = (3 * k + 3) % V
        
        A[v1, v2_even] += 1
        A[v2_even, v1] += 1
        A[v1, v2_odd] += 1
        A[v2_odd, v1] += 1
    return A

def main():
    for d in range(3, 8):
        A = build_adjacency(d)
        eigenvalues = np.linalg.eigvalsh(A)
        eigenvalues = np.sort(eigenvalues)
        
        # We want to check the unique eigenvalues
        unique_eigs = []
        multiplicities = []
        for val in eigenvalues:
            found = False
            for idx, u in enumerate(unique_eigs):
                if np.isclose(u, val, atol=1e-8):
                    multiplicities[idx] += 1
                    found = True
                    break
            if not found:
                unique_eigs.append(val)
                multiplicities.append(1)
                
        print(f"\nDepth {d} (V={1<<(d-1)}):")
        for u, m in zip(unique_eigs, multiplicities):
            # Write as 4 * cos(phi)
            cos_val = u / 4.0
            phi_pi = np.arccos(np.clip(cos_val, -1.0, 1.0)) / np.pi
            print(f"  mu = {u:+.8f} (mult {m}) | cos(phi) = {cos_val:+.8f} | phi = {phi_pi:.8f} * pi")

if __name__ == "__main__":
    main()
