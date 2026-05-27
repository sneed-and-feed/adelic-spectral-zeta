import numpy as np

def run_compact_test_vector(d):
    M = 1 << (d - 3)
    N = 1 << (d - 1)
    j_arr = np.arange(M)
    val = (3**j_arr) % N
    W_exact = 2 * np.cos(np.pi * val / N)
    
    T = np.zeros((M, M))
    for i in range(M - 1):
        T[i, i+1] = W_exact[i]
        T[i+1, i] = W_exact[i]
        
    # Get lambda_2 of symmetric block (which is max eig of G_{d-1})
    from true_spectrum import get_schreier_graph
    adj_prev = get_schreier_graph(d-1).toarray()
    eig_prev = np.linalg.eigvalsh(adj_prev)
    lambda_2_prev = eig_prev[-2]
    
    print(f"d={d}, lambda_sym,2 = {lambda_2_prev:.4f}")
    
    u_lin = np.zeros(M)
    for j in range(M):
        u_lin[j] = M - j
    
    rq_lin = (u_lin @ T @ u_lin) / (u_lin @ u_lin)
    if rq_lin > lambda_2_prev:
        print(f"  SUCCESS! Linear Gradient gives RQ = {rq_lin:.4f} > {lambda_2_prev:.4f}")
    else:
        print(f"  Fail: Linear Gradient gives RQ = {rq_lin:.4f} <= {lambda_2_prev:.4f}")
        
    u_step = np.ones(M)
    rq_step = (u_step @ T @ u_step) / (u_step @ u_step)
    if rq_step > lambda_2_prev:
        print(f"  SUCCESS! Step function gives RQ = {rq_step:.4f} > {lambda_2_prev:.4f}")
    else:
        print(f"  Fail: Step function gives RQ = {rq_step:.4f} <= {lambda_2_prev:.4f}")
        
    u_sin = np.sin(np.pi * np.arange(M) / M)
    if np.sum(u_sin**2) > 0:
        rq_sin = (u_sin @ T @ u_sin) / (u_sin @ u_sin)
        if rq_sin > lambda_2_prev:
            print(f"  SUCCESS! Sin(pi j / M) gives RQ = {rq_sin:.4f} > {lambda_2_prev:.4f}")
        else:
            print(f"  Fail: Sin(pi j / M) gives RQ = {rq_sin:.4f} <= {lambda_2_prev:.4f}")
    print("-" * 50)

if __name__ == '__main__':
    for d in range(4, 10):
        run_compact_test_vector(d)
