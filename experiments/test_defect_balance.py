import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import linregress

def generate_fat_cantor(N_points, depth, removal_fraction=0.2):
    """
    Generates a 1D indicator array for a Fat Cantor set on [0, 1].
    N_points: Resolution of the grid.
    depth: Number of Cantor iterations.
    removal_fraction: Fraction of the middle segment to remove at each step.
    """
    grid = np.ones(N_points)
    
    def remove_middle(start, end, current_depth):
        if current_depth == 0:
            return
        
        length = end - start
        remove_len = int(length * removal_fraction)
        
        # Calculate center bounds
        mid = start + length // 2
        r_start = mid - remove_len // 2
        r_end = r_start + remove_len
        
        # Remove middle
        grid[r_start:r_end] = 0
        
        # Recurse on left and right
        remove_middle(start, r_start, current_depth - 1)
        remove_middle(r_end, end, current_depth - 1)
        
    remove_middle(0, N_points, depth)
    return grid

def main():
    print("==================================================")
    print("Testing Hypothesis 11.H.2: The Defect-Balance")
    print("==================================================")

    # 1. Setup Grid and Geometry for E
    N_E = 2**16
    x = np.linspace(0, 1, N_E, endpoint=False)
    dx = 1.0 / N_E
    
    print(f"[*] Generating Fat Cantor Set (Resolution: {N_E} points)...")
    indicator_E = generate_fat_cantor(N_E, depth=6, removal_fraction=0.1)
    vol_E = np.sum(indicator_E) * dx
    print(f"[*] Set Measure |E|: {vol_E:.4f}")
    
    # Precompute the coordinates of the set E for fast FT
    x_E = x[indicator_E == 1]
    
    def compute_FT(xi_array):
        # xi_array: shape (M,)
        # x_E: shape (K,)
        # Output: shape (M,)
        # FT = sum_x exp(-2 pi i xi x) dx
        phase = -2j * np.pi * np.outer(xi_array, x_E)
        return np.sum(np.exp(phase), axis=1) * dx

    # 3. Test Scale Coupling
    p = 3
    K_max = 8
    
    ks = np.arange(1, K_max + 1)
    eps_inf_vals = []
    eps_p_vals = []
    
    print("\n[*] Evaluating Defect Balance across scales...")
    print(f"{'k':<4} | {'delta(k)':<12} | {'eps_inf':<12} | {'eps_p':<12} | {'Ratio':<10}")
    print("-" * 60)
    
    for k in ks:
        # Physical scale coupling: delta(k) = p^{-k/2}
        delta_k = float(p)**(-k / 2.0)
        
        # We integrate from -delta_k to delta_k
        # Due to symmetry, we can integrate 0 to delta_k and multiply by 2
        M_freqs = 2000
        xi_vals = np.linspace(0, delta_k, M_freqs)
        dxi = delta_k / (M_freqs - 1)
        
        ft_vals = compute_FT(xi_vals)
        power_vals = np.abs(ft_vals)**2
        
        # Trapezoidal rule for integration over [0, delta_k]
        integral_half = np.trapezoid(power_vals, dx=dxi)
        integral_mass = 2 * integral_half
        
        # Archimedean Concentration Ratio
        A_inf = integral_mass / (2 * delta_k * vol_E**2)
        
        # Fix minor floating point overshoots due to integration discrete error
        if A_inf > 1.0:
            A_inf = 1.0
            
        eps_inf = 1.0 - A_inf
        eps_p = float(p)**(-k)
        
        eps_inf_vals.append(eps_inf)
        eps_p_vals.append(eps_p)
        
        ratio = eps_inf / eps_p if eps_p > 0 else 0
        print(f"{k:<4} | {delta_k:<12.6f} | {eps_inf:<12.6e} | {eps_p:<12.6e} | {ratio:<10.4f}")
        
    eps_inf_vals = np.array(eps_inf_vals)
    eps_p_vals = np.array(eps_p_vals)
    
    # Filter out exact zeros to avoid log issues
    valid = eps_inf_vals > 0
    k_valid = ks[valid]
    eps_inf_valid = eps_inf_vals[valid]
    
    if len(k_valid) > 2:
        # 4. Perform Linear Regression
        # We plot log(eps_inf) against k * log(p)
        x_data = k_valid * np.log(p)
        y_data = np.log(eps_inf_valid)
        
        slope, intercept, r_value, p_value, std_err = linregress(x_data, y_data)
        
        print("\n==================================================")
        print(f"Log-Log Slope: {slope:.6f} (Expected: -1.0)")
        print(f"R-squared:     {r_value**2:.6f}")
        print("==================================================")
        
        # 5. Plotting
        plt.figure(figsize=(8, 6))
        plt.scatter(x_data, y_data, color='blue', label='Data: $\\log \\epsilon_\\infty(k)$ vs $k \\log p$')
        plt.plot(x_data, intercept + slope * x_data, color='red', linestyle='--', 
                 label=f'Fit (slope={slope:.3f})')
        
        plt.title('Defect-Balance Scaling: Archimedean vs p-adic')
        plt.xlabel('Adèlic Depth: $k \\log p$')
        plt.ylabel('Log Archimedean Defect: $\\log \\epsilon_\\infty$')
        plt.legend()
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig('defect_balance_scaling.png')
        print("[*] Plot saved to defect_balance_scaling.png")
        
    else:
        print("\n[!] Not enough non-zero defect values to perform regression. Try increasing integration resolution.")

if __name__ == "__main__":
    main()
