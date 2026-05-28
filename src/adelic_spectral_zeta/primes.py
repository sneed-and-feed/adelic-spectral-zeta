"""Prime number utilities: sieve, p-adic valuations, and standard prime lists."""

import numpy as np

def sieve_primes(n: int) -> np.ndarray:
    """Returns an array of all primes up to n using the Sieve of Eratosthenes.
    
    Complexity: O(n log log n) time, O(n) space.
    """
    if n < 2:
        return np.array([], dtype=int)
    is_prime = np.ones(n + 1, dtype=bool)
    is_prime[:2] = False
    for i in range(2, int(n**0.5) + 1):
        if is_prime[i]:
            is_prime[i*i::i] = False
    return np.where(is_prime)[0]

# Standard prime lists used across the project
SMALL_PRIMES = sieve_primes(151)
