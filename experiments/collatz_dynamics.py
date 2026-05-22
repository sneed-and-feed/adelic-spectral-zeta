import numpy as np
import matplotlib.pyplot as plt

def collatz_2adic_step(x, bits=64):
    """
    Computes a single Collatz step in the 2-adic integers of given bit precision.
    T(x) = x / 2       if x is even
    T(x) = (3x + 1)/2  if x is odd
    """
    mask = (1 << bits) - 1
    if (x & 1) == 0:
        return (x >> 1) & mask
    else:
        return ((3 * x + 1) >> 1) & mask

def compute_parity_sequence(x, n_steps=64, bits=64):
    """
    Computes the parity sequence (s_0, s_1, ..., s_{n-1}) where s_i = T^i(x) mod 2.
    """
    seq = []
    curr = x
    for _ in range(n_steps):
        seq.append(curr & 1)
        curr = collatz_2adic_step(curr, bits=bits)
    return seq

def lagarias_conjugacy(x, n_steps=64, bits=64):
    """
    Computes the Lagarias conjugacy map \Phi(x) = \sum_{i=0}^{n-1} s_i(x) 2^i.
    This maps the Collatz map to the standard 2-adic shift map.
    """
    seq = compute_parity_sequence(x, n_steps=n_steps, bits=bits)
    val = 0
    for i, s in enumerate(seq):
        val |= (s << i)
    return val

def build_transfer_operator(depth=4):
    """
    Builds the transition/transfer matrix for the Collatz map T on the 2-adic integers
    at a finite depth (approximation of L^2(Z_2)).
    The state space is {0, 1, ..., 2^depth - 1}.
    We map each state x to its two preimages under T (since T is 2-to-1).
    For T(y) = x:
      If y is even: y = 2x
      If y is odd: y = (2x - 1)/3 (if this is an integer mod 2^depth)
    The transfer operator P acts on functions by:
      (P f)(x) = 1/2 * \sum_{T(y) = x} f(y)
    """
    N = 1 << depth
    P = np.zeros((N, N))
    
    # 3 is invertible modulo 2^depth. Find its modular inverse.
    # For depth=0, it's just 1.
    inv_3 = 1
    if depth > 0:
        for i in range(1, N):
            if (3 * i) % N == 1:
                inv_3 = i
                break
                
    for x in range(N):
        # Preimage 1: y_even = 2x mod 2^depth
        y1 = (2 * x) % N
        P[x, y1] += 0.5
        
        # Preimage 2: y_odd = (2x - 1) * 3^{-1} mod 2^depth
        y2 = ((2 * x - 1) * inv_3) % N
        P[x, y2] += 0.5
        
    return P

def main():
    print("--- Collatz 2-Adic Dynamics & Conjugacy Verification ---")
    bits = 32
    
    # Choose a test number
    test_x = 27
    seq = compute_parity_sequence(test_x, n_steps=10, bits=bits)
    print(f"Parity sequence for x={test_x}: {seq}")
    
    phi_x = lagarias_conjugacy(test_x, n_steps=bits, bits=bits)
    print(f"Lagarias Conjugacy \Phi({test_x}) = {phi_x} (binary: {bin(phi_x)})")
    
    # Verify the conjugacy relation: \Phi(T(x)) = \sigma(\Phi(x))
    # where \sigma is the 2-adic shift (division by 2 of the parity vector)
    tx = collatz_2adic_step(test_x, bits=bits)
    phi_tx = lagarias_conjugacy(tx, n_steps=bits-1, bits=bits)
    sigma_phi_x = phi_x >> 1
    
    print(f"Checking conjugacy:")
    print(f"  \Phi(T(x))      = {phi_tx}")
    print(f"  \sigma(\Phi(x)) = {sigma_phi_x}")
    print(f"  Difference      = {phi_tx - sigma_phi_x} (Should be 0)")
    
    # Verify bijectivity of \Phi on Z/2^N Z for a small depth
    depth = 8
    N = 1 << depth
    images = []
    for x in range(N):
        images.append(lagarias_conjugacy(x, n_steps=depth, bits=depth))
    
    unique_images = len(set(images))
    print(f"\nBijectivity Check at depth {depth}:")
    print(f"  Total states: {N}")
    print(f"  Unique images under \Phi: {unique_images}")
    print(f"  Is bijective: {unique_images == N}")
    
    # Compute transfer operator eigenvalues
    print(f"\nBuilding Collatz transfer operator P at depth {depth}...")
    P = build_transfer_operator(depth=depth)
    
    # Check that it is stochastic (rows sum to 1)
    row_sums = P.sum(axis=1)
    print(f"  Max row sum deviation: {np.abs(row_sums - 1.0).max():.2e}")
    
    # Compute eigenvalues
    eigs = np.linalg.eigvals(P)
    # Sort by magnitude
    eigs = eigs[np.argsort(np.abs(eigs))[::-1]]
    
    print("\nTop 10 eigenvalues of the Collatz transfer operator:")
    for i in range(min(10, len(eigs))):
        print(f"  \lambda_{i}: {eigs[i]:.6f} (magnitude: {np.abs(eigs[i]):.6f})")
        
    # Plot eigenvalues on the complex unit circle
    plt.figure(figsize=(6, 6))
    theta = np.linspace(0, 2*np.pi, 200)
    plt.plot(np.cos(theta), np.sin(theta), 'k--', alpha=0.5, label="Unit Circle")
    plt.scatter(eigs.real, eigs.imag, color='crimson', alpha=0.8, edgecolors='k', s=40, label="Eigenvalues")
    plt.title(f"Collatz Transfer Operator Eigenvalues (Depth {depth})")
    plt.xlabel("Re")
    plt.ylabel("Im")
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.tight_layout()
    
    # Save the plot
    plot_path = "c:/Users/x/.gemini/antigravity/scratch/collatz_transfer_eigs.png"
    plt.savefig(plot_path)
    print(f"\nSaved eigenvalue plot to {plot_path}")

if __name__ == "__main__":
    main()
