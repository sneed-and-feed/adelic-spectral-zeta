import numpy as np

def analyze_columns(depth):
    N = 1 << depth
    A = np.zeros((N, N))
    for x in range(N):
        A[(x + 1) % N, x] = 1.0
        
    B_alg = np.zeros((N, N))
    inv_3 = 1
    for i in range(1, N):
        if (3 * i) % N == 1:
            inv_3 = i
            break
    for x in range(N):
        y1 = (2 * x) % N
        B_alg[x, y1] += 0.5
        y2 = ((2 * x - 1) * inv_3) % N
        B_alg[x, y2] += 0.5
        
    comm = A @ B_alg - B_alg @ A
    
    # comm is N x N
    # Let's split it into even columns and odd columns
    even_cols = comm[:, 0::2]
    odd_cols = comm[:, 1::2]
    
    print(f"Depth {depth:2d} (N={N:4d})")
    print(f"  Rank of even columns submatrix: {np.linalg.matrix_rank(even_cols)}")
    print(f"  Rank of odd columns submatrix:  {np.linalg.matrix_rank(odd_cols)}")
    print(f"  Rank of total commutator:       {np.linalg.matrix_rank(comm)}")
    
    # Let's check row relations.
    # Are there rows that are identical or opposite?
    # Let's print the unique rows of comm
    unique_rows = np.unique(comm, axis=0)
    print(f"  Number of unique rows:          {len(unique_rows)}")
    
    # Let's see if we can find the exact row relationships.
    # For example, what is the relation between row x and row (x + N/2) % N?
    # Let's test this!
    half = N // 2
    all_same = True
    all_opposite = True
    for x in range(N):
        row1 = comm[x, :]
        row2 = comm[(x + half) % N, :]
        if not np.allclose(row1, row2):
            all_same = False
        if not np.allclose(row1, -row2):
            all_opposite = False
            
    print(f"  Are row x and row x+N/2 identical? {all_same}")
    print(f"  Are row x and row x+N/2 opposite?  {all_opposite}")

analyze_columns(3)
analyze_columns(4)
analyze_columns(5)
