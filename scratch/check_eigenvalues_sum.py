import numpy as np
A = np.array([[2, -1/np.sqrt(2), 1/np.sqrt(2), 0],
              [-1/np.sqrt(2), 0, 0, 1/np.sqrt(2)],
              [1/np.sqrt(2), 0, 0, 1/np.sqrt(2)],
              [0, 1/np.sqrt(2), 1/np.sqrt(2), 0]])
B = np.array([[0, -1/np.sqrt(2), 1/np.sqrt(2), 0],
              [-1/np.sqrt(2), 0, 0, 1/np.sqrt(2)],
              [1/np.sqrt(2), 0, 0, 1/np.sqrt(2)],
              [0, 1/np.sqrt(2), 1/np.sqrt(2), 2]])
print('Eigs of A+B:', np.round(np.linalg.eigvalsh(A+B), 6))
print('Eigs of A-B:', np.round(np.linalg.eigvalsh(A-B), 6))
