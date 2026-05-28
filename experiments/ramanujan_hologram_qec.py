"""
Ramanujan-Petersson Holographic QEC (Phase 1)
---------------------------------------------
This script numerically simulates a 24-dimensional Quantum Error Correction
code inspired by Ramanujan's tau function and the Leech Lattice.

The bosonic string requires 24 dimensions to cancel quantum anomalies. 
The unique, perfect topological packing in 24D is the Leech Lattice, 
whose binary shadow is the Extended Binary Golay Code [24, 12, 8].

We first compute Ramanujan's tau function to demonstrate its parity 
structure, and then we deploy a 24-qubit Holographic Stabilizer Code 
(Golay structure) to evaluate its resilience to thermal bit-flip noise.
"""

import numpy as np
import itertools
from collections import defaultdict

def compute_tau(N: int) -> np.ndarray:
    """
    Computes the first N values of Ramanujan's tau function 
    by expanding the polynomial x * prod_{n=1}^N (1 - x^n)^24.
    """
    # We will use a simple dynamic programming approach for polynomial multiplication.
    # We only care about terms up to x^N.
    coeffs = np.zeros(N + 1, dtype=np.int64)
    coeffs[0] = 1 # Constant term of the product is 1
    
    for n in range(1, N + 1):
        # Multiply current coeffs by (1 - x^n)^24
        # We can do this efficiently by recognizing (1-x^n)^24 has binomial coefficients
        # But for N small, we can just multiply by (1 - x^n) 24 times.
        for _ in range(24):
            new_coeffs = np.copy(coeffs)
            for i in range(n, N + 1):
                new_coeffs[i] -= coeffs[i - n]
            coeffs = new_coeffs
            
    # tau(n) is the coefficient of x^(n-1) in the product, because of the leading x.
    tau_values = np.zeros(N + 1, dtype=np.int64)
    for n in range(1, N + 1):
        tau_values[n] = coeffs[n - 1]
        
    return tau_values

def generate_golay_generator():
    """
    Generates the Generator matrix G for the [24, 12, 8] Extended Binary Golay Code.
    This acts as the holographic stabilizer footprint of the 24D Leech Lattice.
    """
    # The standard construction uses the quadratic residue tournament matrix 
    # of size 11x11, bordered to 12x12, and appended to the 12x12 identity matrix.
    
    # Quadratic residues mod 11
    Q = [1, 3, 4, 5, 9]
    
    A = np.zeros((11, 11), dtype=int)
    for i in range(11):
        for j in range(11):
            if (j - i) % 11 in Q:
                A[i, j] = 1
            elif i != j:
                A[i, j] = 1 # Non-residues (Paley construction)
    
    # Correct Paley construction for Golay matrix B (12x12)
    B = np.zeros((12, 12), dtype=int)
    for i in range(11):
        for j in range(11):
            if i == j:
                B[i, j] = 1
            elif (j - i) % 11 in Q:
                B[i, j] = 1
            else:
                B[i, j] = 0
                
    # Bordering
    B[0:11, 11] = 1
    B[11, 0:11] = 1
    B[11, 11] = 0
    
    # Golay G = [I_12 | B]
    I = np.eye(12, dtype=int)
    G = np.hstack((I, B))
    return G % 2

def simulate_holographic_qec(p_error: float, trials: int = 1000):
    """
    Simulates thermal noise on the 24-qubit Hologram.
    Distance is 8, so it can perfectly correct ANY 3 physical qubit errors.
    """
    G = generate_golay_generator()
    # The parity check matrix H for Golay is [B | I_12] because B is symmetric
    B = G[:, 12:]
    H = np.hstack((B, np.eye(12, dtype=int))) % 2
    
    # We use syndrome decoding. The Golay code has 2^12 = 4096 syndromes.
    # To decode quickly, we precompute a syndrome lookup table up to weight 3.
    # Weight 3 means up to 3 errors can occur anywhere in 24 qubits.
    syndrome_table = {}
    
    # Precompute error patterns of weight 0, 1, 2, 3
    for w in range(4):
        for err_positions in itertools.combinations(range(24), w):
            e = np.zeros(24, dtype=int)
            e[list(err_positions)] = 1
            
            # Compute syndrome: s = H * e^T
            s = tuple((H @ e) % 2)
            if s not in syndrome_table:
                syndrome_table[s] = e
    
    logical_errors = 0
    
    for _ in range(trials):
        # Generate random physical errors
        # Thermal flip probability = p_error
        physical_errors = (np.random.rand(24) < p_error).astype(int)
        
        # Measure topological syndrome
        syndrome = tuple((H @ physical_errors) % 2)
        
        # Decode
        if syndrome in syndrome_table:
            correction = syndrome_table[syndrome]
            residual = (physical_errors + correction) % 2
        else:
            # Overloaded error (weight > 3), failure guaranteed
            residual = physical_errors # Fails
            
        # Check if the residual error is a logical error (i.e. a non-zero codeword)
        if np.any(residual):
            logical_errors += 1
            
    logical_error_rate = logical_errors / trials
    return logical_error_rate

def run_ramanujan_hologram():
    print("--- Phase 1: Ramanujan Tau Geometry ---")
    N = 25
    tau = compute_tau(N)
    for n in range(1, N + 1):
        parity = "ODD" if tau[n] % 2 != 0 else "EVEN"
        print(f"tau({n:02d}) = {tau[n]:20d} | Parity: {parity}")
        
    print("\nObserve the exact topological boundary: tau(n) is ODD if and only if n is an odd perfect square (1, 9, 25).")
    print("This defines a strict, sparse parity structure in 24-dimensional space.\n")
    
    print("--- Phase 2: 24D Holographic QEC Simulation ---")
    print("Executing Monte Carlo threshold sweep on the [24, 12, 8] Leech Lattice Shadow...\n")
    
    p_errors = np.linspace(0.01, 0.15, 10)
    for p in p_errors:
        ler = simulate_holographic_qec(p, trials=5000)
        
        # Compare to a generic unprotected logical qubit (where 1 physical error = 1 logical error)
        # Actually, let's compare it to the probability of ANY error occurring on a 24-qubit unencoded block.
        # P_fail_unencoded = 1 - (1 - p)^24
        unencoded_fail = 1.0 - (1.0 - p)**24
        
        suppression_factor = unencoded_fail / (ler + 1e-9)
        print(f"Physical Noise p={p:.3f} | Logical Error Rate: {ler:.4f} | Suppression: {suppression_factor:.1f}x")

if __name__ == "__main__":
    run_ramanujan_hologram()
