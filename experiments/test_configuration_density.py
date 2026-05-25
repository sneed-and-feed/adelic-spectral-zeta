import numpy as np
import matplotlib.pyplot as plt

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
        
        mid = start + length // 2
        r_start = mid - remove_len // 2
        r_end = r_start + remove_len
        
        grid[r_start:r_end] = 0
        
        remove_middle(start, r_start, current_depth - 1)
        remove_middle(r_end, end, current_depth - 1)
        
    remove_middle(0, N_points, depth)
    return grid

def generate_random_set(N_points, measure):
    """
    Generates a random uniform set of a given measure.
    """
    grid = np.zeros(N_points)
    num_ones = int(N_points * measure)
    indices = np.random.choice(N_points, num_ones, replace=False)
    grid[indices] = 1
    return grid

def compute_configuration_density(indicator, shift_pixels):
    """
    Computes the empirical density of finding the pair (x, x + D).
    """
    N = len(indicator)
    if shift_pixels >= N or shift_pixels < 0:
        return 0.0
    if shift_pixels == 0:
        return np.mean(indicator)
        
    # Overlap count
    overlap = np.sum(indicator[:N - shift_pixels] * indicator[shift_pixels:])
    # Normalize by valid domain size
    density = overlap / (N - shift_pixels)
    return density

def main():
    print("==================================================")
    print("Testing Hypothesis 11.H.3: Configuration Density")
    print("==================================================")

    # 1. Setup Space
    N_grid = 2**20  # ~1 million points
    L = 1.0
    dx = L / N_grid
    
    print(f"[*] Generating Structured Set (Fat Cantor, depth=6)...")
    indicator_structured = generate_fat_cantor(N_grid, depth=6, removal_fraction=0.1)
    measure_E = np.mean(indicator_structured)
    print(f"    Measure |E| = {measure_E:.4f}")
    
    print(f"[*] Generating Random Uniform Set (same measure)...")
    indicator_random = generate_random_set(N_grid, measure_E)
    
    # Expected density for independent points
    expected_density = measure_E**2
    print(f"[*] Expected Baseline Density |E|^2 = {expected_density:.4f}")

    # 2. Evaluate sequence distances D_n = 3^{-n}
    p = 3
    n_max = 10
    n_vals = np.arange(1, n_max + 1)
    
    densities_structured = []
    densities_random = []
    
    print("\n[*] Evaluating Configuration Densities...")
    print(f"{'n':<4} | {'D_n (3^-n)':<12} | {'Struct. Dens':<15} | {'Random Dens':<15}")
    print("-" * 55)
    
    for n in n_vals:
        D_n = float(p)**(-n)
        shift_pixels = int(np.round(D_n / dx))
        
        # Calculate densities
        dens_struct = compute_configuration_density(indicator_structured, shift_pixels)
        dens_rand = compute_configuration_density(indicator_random, shift_pixels)
        
        densities_structured.append(dens_struct)
        densities_random.append(dens_rand)
        
        print(f"{n:<4} | {D_n:<12.6f} | {dens_struct:<15.6f} | {dens_rand:<15.6f}")

    # 3. Plotting
    plt.figure(figsize=(10, 6))
    
    # Plot baseline
    plt.axhline(expected_density, color='green', linestyle='--', linewidth=2, 
                label=f'Expected Baseline ($|E|^2 = {expected_density:.3f}$)')
    
    # Plot random set
    plt.plot(n_vals, densities_random, marker='o', color='gray', alpha=0.7, 
             label='Random Uniform Set')
             
    # Plot structured set
    plt.plot(n_vals, densities_structured, marker='s', color='red', linewidth=2, 
             label='Structured Set (Fat Cantor)')
             
    plt.title('Configuration Density: Structural Geometric Resonance vs Randomness')
    plt.xlabel('Sequence Index $n$ (Distance $D_n = 3^{-n}$)')
    plt.ylabel('Empirical Density of Pairs $(x, x + D_n)$')
    plt.xticks(n_vals)
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    
    plt.savefig('configuration_density.png')
    print("\n[*] Plot saved to configuration_density.png")

if __name__ == "__main__":
    main()
