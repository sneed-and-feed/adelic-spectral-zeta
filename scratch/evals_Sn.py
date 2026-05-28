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

def get_Sn(n):
    # D_n is size 2^n. S_n is the twisted block at scale n, size 2^{n-1}.
    # The twisted block is D_n(v, u) - D_n(v, u + 2^{n-1})
    D = get_Dn(n)
    half = 1 << (n - 1)
    S = D[:half, :half] - D[:half, half:]
    return S

results = []
for n in range(2, 10):
    S = get_Sn(n)
    eigs = np.linalg.eigvals(S)
    mags = np.abs(eigs)
    sort_idx = np.argsort(mags)[::-1]
    eigs_sorted = eigs[sort_idx]
    mags_sorted = mags[sort_idx]
    
    unique_mags = np.unique(np.round(mags_sorted, 4))[::-1]
    results.append(f"n={n}, dim={1<<(n-1)}")
    results.append(f"  Top 5 magnitudes: {unique_mags[:5]}")
    if len(eigs_sorted) > 0:
        results.append(f"  Top eigenvalue (complex): {np.round(eigs_sorted[0], 4)}")

print('\n'.join(results))
