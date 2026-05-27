import numpy as np

def check_W(d):
    M = 1 << (d - 3)
    N = 1 << (d - 1)
    print(f"d={d}, N={N}, M={M}")
    for j in range(M):
        val = (3**j) % N
        W = 2 * np.cos(np.pi * val / N)
        taylor = 2 - (np.pi * val / N)**2
        print(f"  j={j}: 3^j mod N = {val}, W = {W:.4f}, taylor = {taylor:.4f}")

if __name__ == '__main__':
    check_W(6)
