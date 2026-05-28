"""
Adelic Spectral Zeta: verify_discrete_log.py
"""

import numpy as np

def main():
    d = 12
    N = 1 << (d - 1)
    
    # 3 generates the subgroup of index 2 modulo 2^(d-1)
    # The elements are exactly 3^j mod 2^(d-1)
    # We can check if all odd numbers are +- 3^j
    visited = set()
    curr = 1
    for _ in range(N // 4):
        visited.add(curr)
        visited.add((N - curr) % N)
        curr = (3 * curr) % N
        
    print(f"Total elements reached: {len(visited)}")
    print(f"Total odd numbers: {N // 2}")
    
    if len(visited) == N // 2:
        print("WINNER: All odd frequencies form exactly ONE orbit (up to sign)!")

if __name__ == '__main__':
    main()
