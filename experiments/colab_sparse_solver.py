import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as sla
import time
import argparse

def compute_max_antisym_eig(d):
    """
    Computes the maximum eigenvalue of the Antisymmetric block of the 
    Collatz Schreier graph at depth d using a sparse matrix formulation.
    """
    start_time = time.time()
    
    N = 2**(d-1)
    M = 2**(d-2)
    
    # 1. Generate all unique undirected edges in G_{d-1}
    # The edges are defined by the forward maps y = 3x and y = 3x-1 mod N
    edge_set = set()
    for x in range(N):
        y1 = (3*x) % N
        y2 = (3*x - 1) % N
        if x != y1:
            edge_set.add((min(x, y1), max(x, y1)))
        if x != y2:
            edge_set.add((min(x, y2), max(x, y2)))
            
    # 2. Map edges to the Antisymmetric block S
    # S[u,v] = A[u,v] - A[u, v+M]
    # where A is the adjacency matrix of G_{d-1}.
    rows = []
    cols = []
    data = []
    
    for (a, b) in edge_set:
        for (src, dst) in [(a, b), (b, a)]:
            if src < M:
                u = src
                if dst < M:
                    v = dst
                    rows.append(u)
                    cols.append(v)
                    data.append(1.0)
                else:
                    v = dst - M
                    rows.append(u)
                    cols.append(v)
                    data.append(-1.0)
                    
    # 3. Construct sparse matrix
    S = sp.coo_matrix((data, (rows, cols)), shape=(M, M)).tocsr()
    
    build_time = time.time() - start_time
    
    # 4. Compute largest eigenvalue using Lanczos algorithm
    solve_start = time.time()
    if M <= 2:
        evals = np.linalg.eigvalsh(S.toarray())
        max_eig = np.max(evals)
    else:
        # Use eigsh to find the algebraically largest eigenvalue ('LA')
        # We compute k=1 eigenvalues. tol=1e-6 is standard for Arnoldi iteration.
        evals, evecs = sla.eigsh(S, k=1, which='LA')
        max_eig = evals[0]
        
    solve_time = time.time() - solve_start
    
    return max_eig, build_time, solve_time

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Compute max eigenvalue of Antisymmetric Collatz block.")
    parser.add_argument("--max-d", type=int, default=15, help="Maximum depth to compute.")
    parser.add_argument("--start-d", type=int, default=4, help="Starting depth.")
    args = parser.parse_args()
    
    print(f"{'Depth (d)':<10} | {'Max Eig (λ)':<20} | {'Build Time (s)':<15} | {'Solve Time (s)':<15}")
    print("-" * 65)
    
    for d in range(args.start_d, args.max_d + 1):
        max_eig, build_time, solve_time = compute_max_antisym_eig(d)
        print(f"{d:<10} | {max_eig:<20.8f} | {build_time:<15.4f} | {solve_time:<15.4f}")
