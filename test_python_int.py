import numpy as np
import scipy.sparse as sp
import time

N = 4194304
print("Creating sparse matrix...")
data = np.ones(N * 4, dtype=np.int8)
row = np.repeat(np.arange(N), 4)
col = np.random.randint(0, N, size=N * 4)
A = sp.csr_matrix((data, (row, col)), shape=(N, N))

indptr = A.indptr
indices = A.indices
adata = A.data.tolist()

print("Creating object array...")
# large Python integers
V = [12345678901234567890] * N

print("Computing dot product...")
t0 = time.time()
out = [0] * N
for i in range(N):
    start = indptr[i]
    end = indptr[i+1]
    s = 0
    for j in range(start, end):
        s += adata[j] * V[indices[j]]
    out[i] = s

print("Dot product took", time.time() - t0)
