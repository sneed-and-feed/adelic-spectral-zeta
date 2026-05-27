import numpy as np
import scipy.sparse.linalg as sla
from true_spectrum import get_schreier_graph

def check_lambda2():
    for d in range(4, 14):
        adj = get_schreier_graph(d).astype(np.float64)
        if d < 10:
            eig = np.linalg.eigvalsh(adj.toarray())
            l2 = eig[-2]
            print(f"d={d}, lambda_2 = {l2:.6f}")
        else:
            # compute largest 2 eigenvalues
            vals, vecs = sla.eigsh(adj, k=2, which='LA')
            l2 = vals[0]
            print(f"d={d}, lambda_2 = {l2:.6f}")

if __name__ == '__main__':
    check_lambda2()
