import os
import sys
import numpy as np
import matplotlib.pyplot as plt

# Ensure src directory is in the import path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from src.spectral_gap import get_schreier_graph, get_schreier_blocks

def run_experiment():
    print("=== Running Schreier Graph Canonical Sheet Decomposition Experiment ===")
    
    d = 7
    N = 1 << (d - 1)
    N_half = 1 << (d - 2)
    
    print(f"Tree Depth d={d}, Graph size N={N}")
    
    # 1. Full Schreier Graph
    adj = get_schreier_graph(d).toarray()
    eigenvalues_full = np.sort(np.linalg.eigvals(adj).real)
    
    # 2. Block Decomposition
    weighted_matrix, sheet_diff_matrix = get_schreier_blocks(d)
    
    eigenvalues_sym = np.sort(np.linalg.eigvals(weighted_matrix).real)
    eigenvalues_anti = np.sort(np.linalg.eigvals(sheet_diff_matrix).real)
    
    # Combine block eigenvalues
    eigenvalues_combined = np.sort(np.concatenate([eigenvalues_sym, eigenvalues_anti]))
    
    # Verify the decomposition holds exactly
    max_diff = np.max(np.abs(eigenvalues_full - eigenvalues_combined))
    
    print(f"\nMax difference between full spectrum and decomposed blocks: {max_diff:.3e}")
    if max_diff < 1e-10:
        print("=> SUCCESS: The spectrum of the full graph perfectly decomposes into the symmetric and antisymmetric blocks, validating the Lean formalization.")
    else:
        print("=> FAILURE: The spectral decomposition does not match.")
        
    print("\nTop 5 Eigenvalues (Full):  ", eigenvalues_full[-5:][::-1])
    print("Top 5 Eigenvalues (Sym):   ", eigenvalues_sym[-5:][::-1])
    print("Top 5 Eigenvalues (Anti):  ", eigenvalues_anti[-5:][::-1])
    
    # Create plot
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # Plot histograms of the spectra
    ax.hist(eigenvalues_sym, bins=50, alpha=0.5, color='royalblue', label=f'Symmetric Block (N={N_half})', density=True)
    ax.hist(eigenvalues_anti, bins=50, alpha=0.5, color='crimson', label=f'Antisymmetric Block (N={N_half})', density=True)
    
    ax.set_title(f"Spectral Decomposition of Schreier Graph $G_{{{d}}}$ (N={N})")
    ax.set_xlabel("Eigenvalue")
    ax.set_ylabel("Density")
    ax.legend()
    ax.grid(True, linestyle=':', alpha=0.6)
    
    plt.tight_layout()
    
    figures_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'figures'))
    os.makedirs(figures_dir, exist_ok=True)
    plot_path = os.path.join(figures_dir, 'schreier_spectrum_decomposition.png')
    plt.savefig(plot_path, dpi=150)
    print(f"\nSuccessfully generated and saved plot to: {plot_path}")

if __name__ == "__main__":
    run_experiment()
