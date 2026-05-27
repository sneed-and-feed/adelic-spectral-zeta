import numpy as np

def get_Dn(n):
    N = 1 << n
    D = np.zeros((N, N))
    for x in range(N):
        y1 = (3 * x) % N
        y2 = (3 * x - 1) % N
        D[x, y1] += 1
        D[x, y2] += 1
    return D

results = []
for n in range(3, 9):
    D = get_Dn(n)
    A = D + D.T
    
    eigs_D = np.sort(np.abs(np.linalg.eigvals(D)))[::-1]
    eigs_A = np.sort(np.abs(np.linalg.eigvals(A)))[::-1]
    
    results.append(f"n={n}, N={1<<n}")
    results.append(f"  D_n top 5 eval magnitudes: {[round(x, 4) for x in eigs_D[:5]]}")
    results.append(f"  A_n top 5 eval magnitudes: {[round(x, 4) for x in eigs_A[:5]]}")

print('\n'.join(results))
