import numpy as np

def extract_eigenvector(d):
    M = 1 << (d - 3)
    N = 1 << (d - 1)
    j_arr = np.arange(M)
    val = (3**j_arr) % N
    W_exact = 2 * np.cos(np.pi * val / N)
    
    T = np.zeros((M, M))
    for i in range(M - 1):
        T[i, i+1] = W_exact[i]
        T[i+1, i] = W_exact[i]
        
    vals, vecs = np.linalg.eigh(T)
    max_idx = np.argmax(vals)
    max_val = vals[max_idx]
    max_vec = vecs[:, max_idx]
    
    # Normalize max_vec so the first element is 1
    if abs(max_vec[0]) > 1e-10:
        max_vec = max_vec / max_vec[0]
        
    print(f"d = {d}, M = {M}, Max Eig = {max_val:.6f}")
    print("W_exact:", np.round(W_exact, 3))
    print("Dominant Vec:", np.round(max_vec, 3))
    print("-" * 50)

if __name__ == '__main__':
    for d in range(4, 10):
        extract_eigenvector(d)
