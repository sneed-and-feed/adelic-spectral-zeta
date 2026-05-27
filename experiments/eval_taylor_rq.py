import numpy as np

def run_taylor_rayleigh(d):
    M = 1 << (d - 3)
    N = 1 << (d - 1)
    
    j_arr = np.arange(M)
    
    # EXACT HOPPING
    val = (3**j_arr) % N
    W_exact = 2 * np.cos(np.pi * val / N)
    
    # TAYLOR BOUND HOPPING
    W_taylor = 2 - (np.pi * val / N)**2
    
    # T_exact
    T_exact = np.zeros((M, M))
    T_taylor = np.zeros((M, M))
    
    for i in range(M - 1):
        T_exact[i, i+1] = W_exact[i]
        T_exact[i+1, i] = W_exact[i]
        
        T_taylor[i, i+1] = W_taylor[i]
        T_taylor[i+1, i] = W_taylor[i]
        
    # Test vector 1: sin(pi * (j+1) / (M+1))
    u2 = np.sin(np.pi * (j_arr + 1) / (M + 1))
    rq2_exact = (u2 @ T_exact @ u2) / (u2 @ u2)
    rq2_taylor = (u2 @ T_taylor @ u2) / (u2 @ u2)
    
    print(f"d={d}, M={M}")
    print(f"  Exact RQ:  {rq2_exact:.6f}")
    print(f"  Taylor RQ: {rq2_taylor:.6f}")
    print("-" * 40)

def main():
    for d in range(4, 10):
        run_taylor_rayleigh(d)

if __name__ == '__main__':
    main()
