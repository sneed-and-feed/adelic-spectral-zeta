import numpy as np
import itertools

def search_d8():
    d = 8
    M = 1 << (d - 3)
    N = 1 << (d - 1)
    j_arr = np.arange(M)
    val = (3**j_arr) % N
    W_exact = 2 * np.cos(np.pi * val / N)
    
    T = np.zeros((M, M))
    for i in range(M - 1):
        T[i, i+1] = W_exact[i]
        T[i+1, i] = W_exact[i]
        
    lambda_2_prev = 3.25073367
    
    best_rq = 0
    best_v = None
    
    # Try all integer vectors of length up to 8 with max element 10
    # To reduce search space, only consider unimodal symmetric vectors
    for L in range(4, 9):
        half_L = L // 2
        for p in itertools.product(range(1, 10), repeat=half_L):
            if list(p) != sorted(list(p)):
                continue # only non-decreasing first half
            if L % 2 == 0:
                v = list(p) + list(reversed(p))
            else:
                for mid in range(p[-1], 10):
                    v = list(p) + [mid] + list(reversed(p))
                    u = np.zeros(M)
                    u[:len(v)] = v
                    rq = (u @ T @ u) / (u @ u)
                    if rq > best_rq:
                        best_rq = rq
                        best_v = v
            if L % 2 == 0:
                u = np.zeros(M)
                u[:len(v)] = v
                rq = (u @ T @ u) / (u @ u)
                if rq > best_rq:
                    best_rq = rq
                    best_v = v
                    
    print(f"d=8: Best RQ = {best_rq:.4f} > {lambda_2_prev:.4f} ? {best_rq > lambda_2_prev}")
    print(f"Best Vec: {best_v}")

if __name__ == '__main__':
    search_d8()
