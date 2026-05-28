"""
Topological QEC
=================
Thermal Noise Simulation.
"""


import numpy as np
import matplotlib.pyplot as plt
from tqdm import tqdm

from adelic_spectral_zeta.error_correction import AdelicStabilizerCode

def main():
    print("--- Adèlic Topological QEC: Thermal Noise Simulation ---")
    
    # We set a physical lattice of size N=1000.
    N = 1000
    code = AdelicStabilizerCode(N)
    
    print(f"Lattice Size: {code.num_qubits} Qubits")
    print(f"Number of Prime Stabilizers: {code.num_stabilizers}")
    
    # We sweep thermal physical error rates from 0% to 25%
    p_errors = np.linspace(0.00, 0.25, 20)
    shots_per_p = 500
    
    logical_error_rates = []
    
    print("\nRunning Monte Carlo Thermal Noise Simulation...")
    for p in tqdm(p_errors):
        failures = 0
        for _ in range(shots_per_p):
            # 1. Generate Thermal Noise
            true_error = code.generate_thermal_noise(p)
            
            # 2. Measure Adèlic Syndrome
            syndrome = code.measure_syndrome(true_error)
            
            # 3. Decode
            estimated_error = code.decode_greedy(syndrome)
            
            # 4. Check for Logical Failure
            if code.is_logical_failure(true_error, estimated_error):
                failures += 1
                
        logical_error_rates.append(failures / shots_per_p)
        
    print("\nSimulation Complete.")
    
    # Plot the Threshold Graph
    plt.figure(figsize=(10, 6))
    
    # Plot the break-even line (Physical Error Rate = Logical Error Rate)
    plt.plot(p_errors, p_errors, '--', color='#888888', label="Unprotected Qubit Baseline")
    
    # Plot the Adèlic Code performance
    plt.plot(p_errors, logical_error_rates, 'o-', color='#C4A6D1', linewidth=2.5, markersize=6, label="Adèlic Stabilizer Code")
    plt.fill_between(p_errors, logical_error_rates, color='#C4A6D1', alpha=0.1)
    
    # Modern dark theme
    plt.style.use('dark_background')
    ax = plt.gca()
    ax.set_facecolor('#121212')
    plt.gcf().patch.set_facecolor('#121212')
    ax.grid(color='#333333', linestyle='--', alpha=0.5)
    
    plt.title(f"Adèlic Topological QEC Threshold (N={N})", color="white", fontsize=14)
    plt.xlabel(r"Physical Error Rate ($P_{error}$)", color="white", fontsize=12)
    plt.ylabel(r"Logical Error Rate ($P_{logical}$)", color="white", fontsize=12)
    plt.legend(facecolor='#121212', edgecolor='#333333')
    
    # Set y-axis to log scale for better threshold visualization
    plt.yscale('log')
    plt.ylim(max(1e-4, min(logical_error_rates + [1e-4])), 1.0)
    
    out_path = os.path.join(os.path.dirname(__file__), 'topological_qec_threshold.png')
    plt.savefig(out_path, dpi=300, bbox_inches='tight')
    print(f"Threshold graph saved to {out_path}")

if __name__ == "__main__":
    main()