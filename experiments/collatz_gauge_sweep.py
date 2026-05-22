import numpy as np
import matplotlib.pyplot as plt
from scipy.linalg import norm

def build_operators(depth):
    N = 1 << depth
    
    # 1. Translation operator A
    A = np.zeros((N, N))
    for x in range(N):
        A[(x + 1) % N, x] = 1.0
        
    # 2. Parity Projections
    P0 = np.zeros((N, N))
    P1 = np.zeros((N, N))
    for x in range(N):
        if x % 2 == 0:
            P0[x, x] = 1.0
        else:
            P1[x, x] = 1.0
            
    # 3. Algebraic modular transfer operator B_alg
    B_alg = np.zeros((N, N))
    inv_3 = 1
    if depth > 0:
        for i in range(1, N):
            if (3 * i) % N == 1:
                inv_3 = i
                break
    for x in range(N):
        y1 = (2 * x) % N
        B_alg[x, y1] += 0.5
        y2 = ((2 * x - 1) * inv_3) % N
        B_alg[x, y2] += 0.5
        
    # 4. Numerical integer-division transfer operator B_num
    B_num = np.zeros((N, N))
    for x in range(N):
        if x % 2 == 0:
            Tx = (x // 2) % N
        else:
            Tx = ((3 * x + 1) // 2) % N
        B_num[Tx, x] = 1.0
    # Normalize B_num columns to make it a Perron-Frobenius transition matrix
    col_sums = B_num.sum(axis=0)
    for c in range(N):
        if col_sums[c] > 0:
            B_num[:, c] /= col_sums[c]
            
    return A, P0, P1, B_alg, B_num

def main():
    print("--- Running Collatz Gauge and Spectral Sweep ---")
    
    depths = list(range(3, 11))
    
    comm_norms_alg = []
    comm_norms_num = []
    defect_norms_alg = []
    defect_norms_num = []
    spectral_gaps = []
    
    for d in depths:
        N = 1 << d
        A, P0, P1, B_alg, B_num = build_operators(d)
        
        # 1. Commutator [A, B] representing gauge curvature
        comm_alg = A @ B_alg - B_alg @ A
        comm_num = A @ B_num - B_num @ A
        
        # Normalize Frobenius norm by sqrt(N) to account for dimensionality growth
        comm_norms_alg.append(norm(comm_alg, 'fro') / np.sqrt(N))
        comm_norms_num.append(norm(comm_num, 'fro') / np.sqrt(N))
        
        # 2. Defect of the gauge relation: B A^2 - (A B P0 + A^3 B P1)
        defect_alg = B_alg @ (A @ A) - (A @ B_alg @ P0 + (A @ A @ A) @ B_alg @ P1)
        defect_num = B_num @ (A @ A) - (A @ B_num @ P0 + (A @ A @ A) @ B_num @ P1)
        
        defect_norms_alg.append(norm(defect_alg, 'fro'))
        defect_norms_num.append(norm(defect_num, 'fro'))
        
        # 3. Spectral gap of B_alg
        eigs = np.linalg.eigvals(B_alg)
        eigs_sorted = sorted(np.abs(eigs), reverse=True)
        # The secondary eigenvalue lambda_1
        lambda_1 = eigs_sorted[1] if len(eigs_sorted) > 1 else 0.0
        spectral_gaps.append(1.0 - lambda_1)
        
        print(f"Depth {d:2d} (N={N:4d}) | Defect (Alg): {norm(defect_alg, 'fro'):.2e} | Defect (Num): {norm(defect_num, 'fro'):.2f} | Normalized [A, B]_alg: {comm_norms_alg[-1]:.4f} | Gap: {spectral_gaps[-1]:.4f}")
        
    # Plot 1: Commutator scaling
    plt.figure(figsize=(12, 5))
    
    plt.subplot(1, 2, 1)
    plt.plot(depths, comm_norms_alg, 'o-', color='royalblue', label='Algebraic (Modular)')
    plt.plot(depths, comm_norms_num, 's--', color='darkorange', label='Numerical (Integer Div)')
    plt.xlabel('Tree Depth (d)')
    plt.ylabel('Normalized Commutator Norm ||[A, B]||_F / sqrt(N)')
    plt.title('Non-Abelian Gauge Curvature Scaling')
    plt.grid(True, alpha=0.3)
    plt.legend()
    
    # Plot 2: Spectral Gap Decay
    plt.subplot(1, 2, 2)
    plt.plot(depths, spectral_gaps, 'o-', color='crimson')
    plt.xlabel('Tree Depth (d)')
    plt.ylabel('Spectral Gap (1 - |lambda_1|)')
    plt.title('Spectral Gap vs Tree Depth')
    plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plot_path = "c:/Users/x/.gemini/antigravity/scratch/collatz_gauge_sweep.png"
    plt.savefig(plot_path)
    print(f"\nSaved sweep plots to {plot_path}")

if __name__ == "__main__":
    main()
