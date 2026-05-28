import numpy as np
import scipy.sparse as sp
import time

N = 4000000
print("Creating sparse matrix...")
data = np.ones(N, dtype=object)
row = np.arange(N)
col = np.arange(N)
A = sp.csr_matrix((data, (row, col)), shape=(N, N))

print("Creating object array...")
V = np.random.randint(-1000000, 1000000, size=N).astype(object)

print("Computing dot product...")
t0 = time.time()
AV = A.dot(V)
print("Dot product took", time.time() - t0)
