import numpy as np
from true_spectrum import get_schreier_graph
import scipy.sparse.linalg as sla

def run_large_d():
    for d in range(7, 15):
        M = 1 << (d - 3)
        N = 1 << (d - 1)
        j_arr = np.arange(M)
        val = (3**j_arr) % N
        
        W_taylor = 2 - (np.pi * val / N)**2
        T_taylor = np.zeros((M, M))
        for i in range(M - 1):
            T_taylor[i, i+1] = W_taylor[i]
            T_taylor[i+1, i] = W_taylor[i]
            
        adj_prev = get_schreier_graph(d-1).astype(np.float64)
        if d - 1 < 10:
            eig_prev = np.linalg.eigvalsh(adj_prev.toarray())
            lambda_2_prev = eig_prev[-2]
        else:
            vals, _ = sla.eigsh(adj_prev, k=2, which='LA')
            lambda_2_prev = vals[0]
            
        print(f"d={d}, lambda_sym,2 = {lambda_2_prev:.6f}")
        
        found = False
        for L in range(4, 25):
            if L > M:
                break
            u = np.zeros(M)
            for j in range(L):
                u[j] = np.sin(np.pi * (j + 1) / (L + 1))
            rq_taylor = (u @ T_taylor @ u) / (u @ u)
            
            if rq_taylor > lambda_2_prev:
                print(f"  SUCCESS! L={L} gives Taylor RQ = {rq_taylor:.6f} > {lambda_2_prev:.6f}")
                found = True
                break
                
        if not found:
            print(f"  FAIL for all L up to 24")
        print("-" * 50)

if __name__ == '__main__':
    run_large_d()
