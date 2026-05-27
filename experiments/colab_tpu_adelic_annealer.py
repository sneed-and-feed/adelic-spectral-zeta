"""
Adèlic Cryptographic Annealer (TPU / JAX Version)
Designed to run on Google Colab with TPU acceleration.

Usage in Colab:
1. Runtime -> Change runtime type -> TPU
2. `!pip install --upgrade jax jaxlib`
3. Run this script.
"""

import jax
import jax.numpy as jnp
from jax.experimental import sparse
import numpy as np
import time

def generate_padic_distance_matrix(n_bits: int):
    """
    Precomputes the Adèlic distance driver Hamiltonian.
    We do this in standard NumPy to construct the connectivity, 
    then push to JAX Device Memory.
    """
    dim = 2 ** (2 * n_bits)
    primes = [2, 3, 5, 7, 11, 13, 17, 19]
    
    # We construct a dense matrix for JAX/TPU, because TPUs are extremely 
    # efficient at dense matrix multiplication (bfloat16/float32) up to 8192x8192.
    driver = np.zeros((dim, dim), dtype=np.float32)
    
    # Fill diagonal
    np.fill_diagonal(driver, 10.0)
    
    # We only connect states that are 1 bit flip apart
    for i in range(dim):
        for b in range(2 * n_bits):
            j = i ^ (1 << b)
            
            diff = abs(i - j)
            dist = 0.0
            
            # Adelic metric logic
            for p in primes:
                n = diff
                if n == 0: continue
                order = 0
                while n % p == 0:
                    order += 1
                    n //= p
                dist += p ** (-order)
                
            dist += np.log(1 + diff)
            
            amplitude = -1.0 / (dist + 1e-3)
            driver[i, j] = amplitude
            
    return driver

def generate_cost_diagonal(N: int, n_bits: int):
    """
    Constructs the diagonal cost H = (XY - N)^2
    """
    dim = 2 ** (2 * n_bits)
    diag = np.zeros(dim, dtype=np.float32)
    
    for i in range(dim):
        x = i >> n_bits
        y = i & ((1 << n_bits) - 1)
        if x <= 1 or y <= 1:
            diag[i] = 1e6
        else:
            diag[i] = (x * y - N) ** 2
            
    return diag

# JAX Compiled solver for the ground state
@jax.jit
def tpu_solve_ground_state(H_dense: jnp.ndarray):
    """
    Uses JAX's XLA-compiled exact eigensolver.
    On TPU, this is computed using parallelized systolic arrays.
    """
    # eigh returns eigenvalues and eigenvectors for Hermitian matrices
    evals, evecs = jnp.linalg.eigh(H_dense)
    # The ground state is the eigenvector corresponding to the lowest eigenvalue
    return evals[0], evecs[:, 0]

def run_tpu_cryptographic_annealer():
    print(f"Hardware backend: {jax.devices()}")
    
    # We push n_bits to 5, giving a 10-qubit Hilbert space (1024 x 1024 matrix).
    # For a TPU, the eigh eigensolver can sometimes OOM on 4096x4096 due to XLA 
    # buffer bloat, so 1024 is extremely safe and solves in milliseconds.
    # N = 437 (which is 19 * 23, fitting into 5 bits per factor)
    N = 437
    n_bits = 5
    dim = 2 ** (2 * n_bits)
    print(f"Target Semiprime: {N}")
    print(f"Hilbert Space: {dim} x {dim} (10 Qubits)")
    
    print("Generating H_driver and H_cost on CPU...")
    t0 = time.time()
    driver_np = generate_padic_distance_matrix(n_bits)
    cost_diag_np = generate_cost_diagonal(N, n_bits)
    print(f"Matrices generated in {time.time() - t0:.2f}s")
    
    print("Pushing to TPU Device Memory...")
    driver_jnp = jax.device_put(jnp.array(driver_np))
    cost_diag_jnp = jax.device_put(jnp.array(cost_diag_np))
    
    taus = np.linspace(0.0, 1.0, 20)
    
    # Warmup JIT compiler
    print("JIT Compiling eigensolver...")
    H_warmup = driver_jnp + jnp.diag(cost_diag_jnp) * 0.5
    _ = tpu_solve_ground_state(H_warmup)
    
    print("Running Rigorous Annealing Sweep on TPU...")
    for tau in taus:
        # Construct H_tau locally on the device
        H_tau = (1.0 - tau) * driver_jnp + tau * jnp.diag(cost_diag_jnp)
        
        t_solve = time.time()
        # Compute ground state via XLA
        gs_energy, gs_state = tpu_solve_ground_state(H_tau)
        solve_time = time.time() - t_solve
        
        # Pull state back to CPU to find max probability
        gs_state_np = np.array(gs_state)
        max_idx = np.argmax(np.abs(gs_state_np)**2)
        
        x = max_idx >> n_bits
        y = max_idx & ((1 << n_bits) - 1)
        
        print(f"tau={tau:.2f} | SolveTime={solve_time*1000:.1f}ms | Most Probable: |{x}, {y}> (Cost: {(x*y - N)**2})")

if __name__ == "__main__":
    run_tpu_cryptographic_annealer()
