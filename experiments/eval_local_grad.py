"""
Adelic Spectral Zeta: eval_local_grad.py
"""

import numpy as np

def run_local_gradient(d):
    M = 1 << (d - 3)
    N = 1 << (d - 1)
    j_arr = np.arange(M)
    val = (3**j_arr) % N
    W_exact = 2 * np.cos(np.pi * val / N)
    
    T = np.zeros((M, M))
    for i in range(M - 1):
        T[i, i+1] = W_exact[i]
        T[i+1, i] = W_exact[i]
        
    from true_spectrum import get_schreier_graph
    adj_prev = get_schreier_graph(d-1).toarray()
    eig_prev = np.linalg.eigvalsh(adj_prev)
    lambda_2_prev = eig_prev[-2]
    
    print(f"d={d}, lambda_sym,2 = {lambda_2_prev:.4f}")
    
    # Try local gradient vectors u_j = k - j for j < k
    for k in range(2, M+1):
        u = np.zeros(M)
        for j in range(k):
            u[j] = k - j
        
        rq = (u @ T @ u) / (u @ u)
        if rq > lambda_2_prev:
            print(f"  SUCCESS! k={k} gives RQ = {rq:.4f} > {lambda_2_prev:.4f}")
            break
    print("-" * 50)

if __name__ == '__main__':
    for d in range(4, 10):
        run_local_gradient(d)
