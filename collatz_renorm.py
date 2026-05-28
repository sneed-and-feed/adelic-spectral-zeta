import numpy as np

def build_Pn(depth):
    """Transfer operator (Perron-Frobenius) for Collatz on Z/2^n Z"""
    N = 1 << depth
    P = np.zeros((N, N))
    inv_3 = pow(3, -1, N) if depth > 0 else 1
    
    for x in range(N):
        y1 = (2 * x) % N
        y2 = ((2 * x - 1) * inv_3) % N
        P[x, y1] += 0.5
        P[x, y2] += 0.5
    return P

def fwht_1d(a):
    """Fast Walsh-Hadamard Transform of a 1D array"""
    h = 1
    a = a.copy()
    while h < len(a):
        for i in range(0, len(a), h * 2):
            for j in range(i, i + h):
                x = a[j]
                y = a[j + h]
                a[j] = x + y
                a[j + h] = x - y
        h *= 2
    return a

def wht_2d(M):
    """2D Walsh-Hadamard Transform"""
    res = np.zeros_like(M)
    for c in range(M.shape[1]):
        res[:, c] = fwht_1d(M[:, c])
    for r in range(res.shape[0]):
        res[r, :] = fwht_1d(res[r, :])
    return res / M.shape[0]

def analyze_decay(W, depth):
    decay_rates = np.zeros((depth+1, depth+1))
    for u in range(depth + 1):
        for v in range(depth + 1):
            row_start = 0 if u == 0 else 1 << (u-1)
            row_end = 1 if u == 0 else 1 << u
            col_start = 0 if v == 0 else 1 << (v-1)
            col_end = 1 if v == 0 else 1 << v
            
            block = W[row_start:row_end, col_start:col_end]
            norm = np.linalg.norm(block, ord='fro') / np.sqrt(max(1, block.size))
            decay_rates[u, v] = norm
    return decay_rates

def main():
    depth = 8
    print(f"Building Transfer Operator P_{depth} (Size {1<<depth}x{1<<depth})...")
    P = build_Pn(depth)
    print("Computing 2D Walsh-Hadamard Transform...")
    W = wht_2d(P)
    print("Analyzing Block Decay Rates in Walsh Basis...")
    decay_rates = analyze_decay(W, depth)
    np.set_printoptions(precision=4, suppress=True, linewidth=120)
    print("\nBlock Normalized Frobenius Norms:")
    print(decay_rates)

if __name__ == '__main__':
    main()
