import numpy as np
from typing import List, Tuple

def get_primes_up_to(n: int) -> List[int]:
    """Returns a list of primes up to n using a simple sieve."""
    if n < 2: return []
    sieve = [True] * (n + 1)
    for p in range(2, int(n**0.5) + 1):
        if sieve[p]:
            for i in range(p * p, n + 1, p):
                sieve[i] = False
    return [p for p in range(2, n + 1) if sieve[p]]

class AdelicStabilizerCode:
    def __init__(self, N: int):
        """
        Initializes an Adèlic Stabilizer Code.
        Qubits are indexed from 2 to N. Total qubits = N - 1.
        Stabilizers are indexed by primes p <= N.
        """
        self.N = N
        self.primes = get_primes_up_to(N)
        self.num_qubits = N - 1
        self.num_stabilizers = len(self.primes)
        
        # Build Parity Check Matrix H (num_stabilizers x num_qubits)
        # H[p_idx, k_idx] = 1 if prime p divides (k_idx + 2)
        self.H = np.zeros((self.num_stabilizers, self.num_qubits), dtype=np.int8)
        for p_idx, p in enumerate(self.primes):
            for k in range(2, N + 1):
                if k % p == 0:
                    self.H[p_idx, k - 2] = 1

    def generate_thermal_noise(self, p_error: float) -> np.ndarray:
        """Generates a random bit-flip error vector based on thermal probability."""
        return (np.random.random(self.num_qubits) < p_error).astype(np.int8)

    def measure_syndrome(self, error_vector: np.ndarray) -> np.ndarray:
        """Returns the Adèlic syndrome: H * e mod 2"""
        return (self.H @ error_vector) % 2

    def decode_greedy(self, syndrome: np.ndarray, max_iter: int = 50) -> np.ndarray:
        """
        A greedy Bit-Flip (Gallager) decoder utilizing the Adèlic topology.
        It iteratively flips the qubit that participates in the highest number of 
        unsatisfied prime stabilizers.
        """
        current_syndrome = syndrome.copy()
        estimated_error = np.zeros(self.num_qubits, dtype=np.int8)
        
        for _ in range(max_iter):
            if np.all(current_syndrome == 0):
                break
                
            # Compute unsatisfied checks for each qubit
            # H.T is (num_qubits x num_stabilizers)
            # Multiplying by current_syndrome (which is 1 for unsatisfied) 
            # gives the count of unsatisfied checks each qubit is involved in.
            unsatisfied_counts = self.H.T @ current_syndrome
            
            # Find the qubit with the maximum unsatisfied checks
            max_unsatisfied = np.max(unsatisfied_counts)
            if max_unsatisfied == 0:
                break
                
            # Flip the best candidate (if tie, pick the first or random)
            best_qubit = np.argmax(unsatisfied_counts)
            
            # Apply flip
            estimated_error[best_qubit] ^= 1
            
            # Update syndrome
            current_syndrome = (current_syndrome + self.H[:, best_qubit]) % 2
            
        return estimated_error

    def is_logical_failure(self, true_error: np.ndarray, estimated_error: np.ndarray) -> bool:
        """
        Determines if the decoding failed.
        In standard repetition-like codes, failure means the residual error has high weight.
        Here we simply check if true_error == estimated_error.
        Since H might have a non-trivial kernel (logical operators), 
        we check if the residual error is in the kernel.
        """
        residual = (true_error + estimated_error) % 2
        # If residual is exactly 0, perfect decode.
        if np.all(residual == 0):
            return False
            
        # If residual has 0 syndrome, it's a logical error (undetectable slip)
        # or a failed decode.
        res_syndrome = (self.H @ residual) % 2
        if np.all(res_syndrome == 0):
            # It's in the kernel -> silent logical error!
            return True
        else:
            # The decoder just gave up / failed to converge
            return True
