import numpy as np

def build_graph_adjacency(depth):
    V = 1 << (depth - 1)
    A_G = np.zeros((V, V))
    
    # Vertices are 0 to V-1
    # Edges connect:
    #   even column y=2k: k+1 <-> 3k+2 (mod V)
    #   odd column y=2k+1: k+1 <-> 3k+3 (mod V)
    # for k in 0..V-1
    for k in range(V):
        v1 = (k + 1) % V
        v2_even = (3 * k + 2) % V
        v2_odd = (3 * k + 3) % V
        
        # Undirected graph adjacency matrix
        A_G[v1, v2_even] += 1
        A_G[v2_even, v1] += 1
        A_G[v1, v2_odd] += 1
        A_G[v2_odd, v1] += 1
        
    return A_G

def main():
    for d in range(3, 7):
        A_G = build_graph_adjacency(d)
        mu = np.linalg.eigvalsh(A_G)
        
        # Calculate predicted singular values: sqrt(2 - 0.5 * mu)
        # Note: some values might be slightly negative due to precision, clip to 0
        predicted_sigma = np.sqrt(np.maximum(2.0 - 0.5 * mu, 0.0))
        # filter out the zero singular values (when 2 - 0.5 * mu = 0, which means mu = 4)
        non_zero_pred = predicted_sigma[predicted_sigma > 1e-7]
        non_zero_pred = np.sort(non_zero_pred)
        
        # Now get the actual singular values of Kd
        N = 1 << d
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
            
        Kd = A @ B_alg - B_alg @ A
        s = np.sort(np.linalg.svdvals(Kd))
        non_zero_actual = s[s > 1e-7]
        
        # Print shapes to debug
        print(f"  Predicted shape: {non_zero_pred.shape}, Actual shape: {non_zero_actual.shape}")
        matches = len(non_zero_pred) == len(non_zero_actual) and np.allclose(non_zero_pred, non_zero_actual, atol=1e-7)
        print(f"Depth {d} (N={N}): Match? {matches}")
        if not matches:
            print("  Predicted:", non_zero_pred[:5])
            print("  Actual   :", non_zero_actual[:5])
        else:
            # Let's print the eigenvalues mu of the adjacency matrix
            print("  Eigenvalues of A_G (mu):", np.round(mu, 4))
            print("  Multiplicities of mu:")
            unique_mu, counts = np.unique(np.round(mu, 6), return_counts=True)
            for m, c in zip(unique_mu, counts):
                print(f"    mu = {m:+.6f} (mult {c})")

if __name__ == "__main__":
    main()
