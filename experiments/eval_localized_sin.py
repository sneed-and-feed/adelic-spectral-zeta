import numpy as np

def run_localized_sin(d):
    M = 1 << (d - 3)
    N = 1 << (d - 1)
    j_arr = np.arange(M)
    val = (3**j_arr) % N
    
    # EXACT HOPPING
    W_exact = 2 * np.cos(np.pi * val / N)
    
    # TAYLOR BOUND HOPPING (this is what Lean will use)
    W_taylor = 2 - (np.pi * val / N)**2
    
    T_exact = np.zeros((M, M))
    T_taylor = np.zeros((M, M))
    for i in range(M - 1):
        T_exact[i, i+1] = W_exact[i]
        T_exact[i+1, i] = W_exact[i]
        T_taylor[i, i+1] = W_taylor[i]
        T_taylor[i+1, i] = W_taylor[i]
        
    from true_spectrum import get_schreier_graph
    adj_prev = get_schreier_graph(d-1).toarray()
    eig_prev = np.linalg.eigvalsh(adj_prev)
    lambda_2_prev = eig_prev[-2]
    
    print(f"d={d}, lambda_sym,2 = {lambda_2_prev:.4f}")
    
    # Try different support lengths L
    found = False
    for L in range(2, M+1):
        u = np.zeros(M)
        for j in range(L):
            u[j] = np.sin(np.pi * (j + 1) / (L + 1))
            
        rq_exact = (u @ T_exact @ u) / (u @ u)
        rq_taylor = (u @ T_taylor @ u) / (u @ u)
        
        if rq_taylor > lambda_2_prev:
            print(f"  SUCCESS! L={L} gives Taylor RQ = {rq_taylor:.4f} > {lambda_2_prev:.4f}")
            found = True
            break
            
    if not found:
        print(f"  FAIL for all L")
    print("-" * 50)

if __name__ == '__main__':
    for d in range(4, 10):
        run_localized_sin(d)
