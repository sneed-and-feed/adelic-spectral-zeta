import numpy as np
import matplotlib.pyplot as plt

def build_translation_operator(depth=8):
    """
    Builds the translation operator A on L^2(Z/2^d Z)
    (A \psi)(x) = \psi(x - 1 mod 2^d)
    """
    N = 1 << depth
    A = np.zeros((N, N))
    for x in range(N):
        A[(x + 1) % N, x] = 1.0
    return A

def build_collatz_operator(depth=8):
    """
    Builds the Collatz transfer operator B on L^2(Z/2^d Z).
    T(x) = x/2 if x is even, (3x+1)/2 if x is odd.
    """
    N = 1 << depth
    B = np.zeros((N, N))
    
    # Find modular inverse of 3 mod 2^depth
    inv_3 = 1
    if depth > 0:
        for i in range(1, N):
            if (3 * i) % N == 1:
                inv_3 = i
                break
                
    for x in range(N):
        # Even preimage: y = 2x
        y1 = (2 * x) % N
        B[x, y1] += 0.5
        
        # Odd preimage: y = (2x - 1) * 3^{-1}
        y2 = ((2 * x - 1) * inv_3) % N
        B[x, y2] += 0.5
        
    return B

def build_parity_projections(depth=8):
    """
    Builds the projections P0 (even) and P1 (odd) on L^2(Z/2^d Z).
    """
    N = 1 << depth
    P0 = np.zeros((N, N))
    P1 = np.zeros((N, N))
    for x in range(N):
        if x % 2 == 0:
            P0[x, x] = 1.0
        else:
            P1[x, x] = 1.0
    return P0, P1

def main():
    print("--- Collatz Gauge-Covariant Relation Exploration ---")
    depth = 8
    N = 1 << depth
    
    A = build_translation_operator(depth=depth)
    B = build_collatz_operator(depth=depth)
    P0, P1 = build_parity_projections(depth=depth)
    
    # Gauge-covariant relation: B A^2 = A B P0 + A^3 B P1
    lhs = B @ (A @ A)
    rhs = A @ B @ P0 + (A @ A @ A) @ B @ P1
    
    diff = lhs - rhs
    norm_diff = np.linalg.norm(diff, ord='fro')
    print(f"Dimension: {N} x {N}")
    print(f"Frobenius Norm of Gauge Defect (B A^2 - [A B P0 + A^3 B P1]): {norm_diff:.6f}")
    
    # Find non-zero indices of the defect to show they are only at the boundary
    non_zero_rows, non_zero_cols = np.where(np.abs(diff) > 1e-9)
    print(f"Number of non-zero entries in the defect matrix: {len(non_zero_rows)}")
    
    # Let's test that these occur only at boundary states that wrap around
    print("\nDefect details (first 10):")
    for r, c in zip(non_zero_rows[:10], non_zero_cols[:10]):
        # The preimage state c wraps around under translation by 2
        # c and c+1 mod N
        print(f"  Row {r}, Col {c} has defect value: {diff[r, c]:.4f}")
        
    # Plot the gauge-covariant defect matrix
    plt.figure(figsize=(8, 6))
    plt.imshow(np.abs(diff), cmap='inferno', interpolation='nearest')
    plt.colorbar(label='Absolute Defect')
    plt.title(f"Gauge-Covariant Defect |B A^2 - (A B P0 + A^3 B P1)| (Depth {depth})")
    plt.xlabel("Preimage Index (y)")
    plt.ylabel("Image Index (x)")
    plt.tight_layout()
    
    plot_path = "c:/Users/x/.gemini/antigravity/scratch/collatz_gauge_defect.png"
    plt.savefig(plot_path)
    print(f"\nSaved gauge defect plot to {plot_path}")

if __name__ == "__main__":
    main()
