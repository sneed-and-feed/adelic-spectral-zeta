"""
Adèlic Topological Coherent QEC (TPU / JAX Version)
Designed to run on Google Colab with TPU acceleration.

Instead of classical bit-flips, this simulates a full quantum wave function
under continuous coherent errors (e.g. thermal phase drift) and evaluates 
the Adèlic Syndrome continuously using JAX XLA operations.

Usage in Colab:
1. Runtime -> Change runtime type -> TPU
2. `!pip install --upgrade jax jaxlib`
3. Run this script.
"""

import jax
import jax.numpy as jnp
import numpy as np
import time

# We simulate N = 10 physical qubits.
# Qubits are integers 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
N_QUBITS = 10
DIM = 2 ** N_QUBITS

def build_stabilizer_matrices():
    """
    Build the Z-parity stabilizer matrices for primes p <= 11.
    Stabilizers: S_p = Prod_{k: p|k} Z_k
    """
    primes = [2, 3, 5, 7, 11]
    
    # We will build dense 1024x1024 diagonal matrices for JAX.
    S_matrices = []
    
    for p in primes:
        diag = np.ones(DIM, dtype=np.float32)
        # Find which qubits (indices 0 to 9) correspond to multiples of p
        qubit_indices = [k - 2 for k in range(2, 12) if k % p == 0]
        
        for i in range(DIM):
            # Check the parity of the bitstring for these qubits
            parity = 0
            for q in qubit_indices:
                if (i & (1 << q)):
                    parity ^= 1
            if parity == 1:
                diag[i] = -1.0
                
        S_matrices.append(jax.device_put(jnp.array(diag)))
        
    return primes, S_matrices

@jax.jit
def apply_coherent_error(psi: jnp.ndarray, theta: float) -> jnp.ndarray:
    """
    Applies a continuous coherent error U = exp(-i * theta * X) to all qubits.
    Since X flips bits, this mixes the state vector.
    """
    # For a global X rotation on all qubits, we can do a batched 
    # tensor product, but an easier way for exact simulation in JAX
    # is to apply the matrix globally or loop over qubits.
    
    # Convert theta to float32
    theta = jnp.float32(theta)
    cos_t = jnp.cos(theta)
    sin_t = -1j * jnp.sin(theta)
    
    # We reshape psi into a 2x2x...x2 tensor
    psi_tensor = jnp.reshape(psi, (2,) * N_QUBITS)
    
    for q in range(N_QUBITS):
        # Apply [cos_t, sin_t \\ sin_t, cos_t] to axis q
        # JAX tensor contraction (vdot / tensordot is tricky to write generalized)
        # Using swapaxes and simple matrix mult:
        psi_tensor = jnp.swapaxes(psi_tensor, q, -1)
        # shape is now (..., 2)
        # multiply by [[cos_t, sin_t], [sin_t, cos_t]]
        
        # out[..., 0] = cos_t * psi[..., 0] + sin_t * psi[..., 1]
        # out[..., 1] = sin_t * psi[..., 0] + cos_t * psi[..., 1]
        psi_0 = psi_tensor[..., 0]
        psi_1 = psi_tensor[..., 1]
        
        new_0 = cos_t * psi_0 + sin_t * psi_1
        new_1 = sin_t * psi_0 + cos_t * psi_1
        
        psi_tensor = jnp.stack([new_0, new_1], axis=-1)
        psi_tensor = jnp.swapaxes(psi_tensor, q, -1)
        
    return jnp.reshape(psi_tensor, (DIM,))

@jax.jit
def measure_syndromes(psi: jnp.ndarray, S_diags: list) -> list:
    """
    Computes the expectation value <psi | S_p | psi> for each Adèlic stabilizer.
    """
    # psi is complex, S_diags are real
    expectations = []
    for S_diag in S_diags:
        # <psi | S | psi> = sum(|psi|^2 * S_diag)
        val = jnp.sum(jnp.abs(psi)**2 * S_diag)
        expectations.append(val)
    return expectations

def run_tpu_coherent_qec():
    print(f"Hardware backend: {jax.devices()}")
    print("Initializing Logical |0> state...")
    
    # State |0...0>
    psi = jnp.zeros(DIM, dtype=jnp.complex64)
    psi = psi.at[0].set(1.0 + 0.0j)
    
    print("Building Adèlic TPU Stabilizers...")
    primes, S_diags = build_stabilizer_matrices()
    
    # We sweep the coherent error drift (theta) from 0 to pi/4
    thetas = np.linspace(0.0, np.pi / 4, 15)
    
    # JIT Compile warmup
    print("JIT Compiling continuous XLA tensors...")
    _ = apply_coherent_error(psi, 0.01)
    _ = measure_syndromes(psi, S_diags)
    
    print("\nTracking Continuous Adèlic Syndrome Drift...")
    for theta in thetas:
        # Apply coherent error
        t_start = time.time()
        psi_err = apply_coherent_error(psi, theta)
        
        # Measure
        syndromes = measure_syndromes(psi_err, S_diags)
        t_end = time.time()
        
        # Format output
        print(f"Theta={theta:.3f} rad | XLA_Time={(t_end - t_start)*1000:.1f}ms")
        for p, syn in zip(primes, syndromes):
            # 1.0 means perfect parity, 0.0 means completely destroyed
            print(f"  Stabilizer S_{p:02d} Expectation: {float(syn):.4f}")
        print("-" * 50)

if __name__ == "__main__":
    run_tpu_coherent_qec()
