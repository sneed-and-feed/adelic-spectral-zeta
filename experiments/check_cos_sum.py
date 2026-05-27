import numpy as np

for L in range(4, 10):
    s = 0
    for j in range(L - 1):
        s += np.cos(np.pi * (2 * j + 3) / (L + 1))
    print(f"L={L}, sum = {s:.4f}")
