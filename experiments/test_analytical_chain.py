import numpy as np

def main():
    d = 12
    N = 1 << (d - 1)
    
    # Generate the orbit starting at k=1
    visited = set()
    orbit = []
    curr = 1
    while curr not in visited:
        orbit.append(curr)
        visited.add(curr)
        curr = (3 * curr) % N
        
    L = len(orbit)
    W = np.zeros(L)
    for j in range(L):
        # W_j is the hopping between j and j+1
        W[j] = abs(2 * np.cos(np.pi * orbit[j] / N))
        
    # Let's compute the exact max eigenvalue of this 1D chain
    A = np.zeros((L, L))
    for j in range(L):
        A[j, (j+1)%L] = W[j]
        A[(j+1)%L, j] = W[j]
        
    vals, vecs = np.linalg.eigh(A)
    max_val = np.max(vals)
    max_vec = vecs[:, np.argmax(vals)]
    
    print(f"d={d}, Chain length L={L}")
    print(f"Max eigenvalue of 1D chain = {max_val:.4f}")
    
    # Test analytical vectors
    def test_u(u_name, u):
        u = np.array(u)
        rq = 2 * np.sum(W * u * np.roll(u, -1)) / np.sum(u**2)
        print(f"RQ({u_name}) = {rq:.4f}")
        
    test_u("u=1", np.ones(L))
    test_u("u=W", W)
    test_u("u=W^2", W**2)
    test_u("u=W*W_prev", W * np.roll(W, 1))
    
    # Print the top 10 elements of the true eigenvector to look for patterns
    print("Top 10 values of max eigenvector:")
    for j in range(10):
        print(f"j={j}, W[j]={W[j]:.4f}, u_opt[j]={max_vec[j]:.4f}")

if __name__ == '__main__':
    main()
