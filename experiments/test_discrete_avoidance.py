# GUARDRAILS — DO NOT VIOLATE
# 1. This code computes the DISCRETE analog of the Erdős Similarity Conjecture.
# 2. It does NOT prove the continuous ESC. Discrete density → 0 is Szemerédi's theorem.
# 3. Any continuous claim must be prefixed with "heuristic" or "motivation."
# 4. The output is a finite combinatorial optimization result, not a contradiction or "structural wall."
# 5. Do not invoke Fourier analysis, adèlic geometry, or "defect balance" in the interpretation.

import numpy as np
import matplotlib.pyplot as plt
from ortools.sat.python import cp_model

def optimize_pattern_avoidance(N, pattern):
    """
    Finds the maximum density subset of {1..N} avoiding the given pattern using ILP.
    pattern: A list of integers representing the configuration, e.g., [0, 1, 2, 3] for 4-AP.
    Returns: The maximum size r(N) of the avoiding set.
    """
    model = cp_model.CpModel()
    
    # Variables: x[i] = 1 if i is in the set, 0 otherwise
    # We use 1-based indexing conceptually, but 0-based for the array, so size is N.
    x = [model.NewBoolVar(f'x_{i}') for i in range(N)]
    
    # Add constraints: No affine copies of the pattern
    # For every starting point 'a' and step size 'd' > 0
    k = len(pattern)
    max_p = max(pattern)
    
    for a in range(N):
        for d in range(1, N):
            if a + max_p * d < N:
                # The sum of elements in this affine copy cannot be equal to k
                model.Add(sum(x[a + p * d] for p in pattern) <= k - 1)
            else:
                break
                
    # Objective: Maximize the size of the set
    model.Maximize(sum(x))
    
    # Solve
    solver = cp_model.CpSolver()
    # Time limit for difficult cases (though small N should be fast)
    solver.parameters.max_time_in_seconds = 15.0
    status = solver.Solve(model)
    
    if status == cp_model.OPTIMAL:
        return int(solver.ObjectiveValue()), True
    elif status == cp_model.FEASIBLE:
        return int(solver.ObjectiveValue()), False
    else:
        return 0, False

def plot_asymptotic_bounds(N_vals, r4_vals, r_nonAP_vals):
    N_arr = np.array(N_vals)
    density_4ap = np.array(r4_vals) / N_arr
    density_nonAP = np.array(r_nonAP_vals) / N_arr
    
    plt.figure(figsize=(12, 8))
    
    # Plot our ILP exact data
    plt.plot(N_arr, density_4ap, 'o-', color='blue', linewidth=2, label='ILP: 4-AP {0,1,2,3}')
    plt.plot(N_arr, density_nonAP, 's-', color='red', linewidth=2, label='ILP: {0,1,3,4}')
    
    # Asymptotic bounds (Heuristic scalings for visual reference)
    # Behrend-Rankin lower bound: ~exp(-c * sqrt(log N))
    c_behrend = 0.5 # rough scaling constant for visual
    behrend = np.exp(-c_behrend * np.sqrt(np.log(N_arr)))
    # Normalize to match scale roughly at N_arr[0]
    behrend = behrend * (density_4ap[0] / behrend[0])
    
    # Gowers upper bound: ~(log log N)^{-c}
    # Since log log for small N is problematic, we use an offset
    c_gowers = 0.1
    gowers = (np.log(np.log(N_arr + 3))) ** (-c_gowers)
    gowers = gowers * (density_4ap[0] / gowers[0])
    
    # Random baseline: expected density avoiding 4-AP goes roughly as N^{-1/2} or similar
    random_base = 2.0 * N_arr**(-0.5)
    
    plt.plot(N_arr, behrend, '--', color='green', label=r'Behrend-Rankin Lower Bound ($\sim \exp(-c\sqrt{\log N})$)')
    plt.plot(N_arr, gowers, '--', color='purple', label=r'Gowers Upper Bound ($\sim (\log\log N)^{-c}$)')
    plt.plot(N_arr, random_base, ':', color='gray', label=r'Random Baseline ($N^{-1/2}$)')
    
    plt.xscale('log')
    plt.yscale('log')
    plt.title('Discrete Density Survey: 4-Point Pattern Avoidance\n(Note: Asymptotic bounds are artificially rescaled for visual alignment at small N)')
    plt.xlabel('Grid Size N')
    plt.ylabel('Maximum Density $\delta(N) = r(N)/N$')
    plt.legend()
    plt.grid(True, which="both", ls="-", alpha=0.2)
    
    plt.tight_layout()
    plt.savefig('discrete_density_bounds.png')
    print("\n[*] Plot saved to discrete_density_bounds.png")

def main():
    print("=====================================================")
    print("Discrete Density Survey: Szemerédi's Theorem (Finite N)")
    print("=====================================================")
    
    # Test range: up to N=150 to keep execution time reasonable for exact ILP
    N_vals = [10, 20, 30, 40, 50, 60, 80, 100, 120, 150]
    
    pattern_4ap = [0, 1, 2, 3]
    pattern_nonAP = [0, 1, 3, 4]
    
    r4_vals = []
    r_nonAP_vals = []
    
    print(f"{'N':<5} | {'r_4(N) {0,1,2,3}':<20} | {'r_P(N) {0,1,3,4}':<20}")
    print("-" * 55)
    
    for N in N_vals:
        r4, r4_opt = optimize_pattern_avoidance(N, pattern_4ap)
        rP, rP_opt = optimize_pattern_avoidance(N, pattern_nonAP)
        
        r4_vals.append(r4)
        r_nonAP_vals.append(rP)
        
        d4 = r4 / N
        dP = rP / N
        
        s4 = " " if r4_opt else "*"
        sP = " " if rP_opt else "*"
        print(f"{N:<5} | {r4:<5} (dens {d4:.3f}) {s4}   | {rP:<5} (dens {dP:.3f}) {sP}")
        
    print("\n* indicates lower bound (optimality not proven within time limit)")
        
    plot_asymptotic_bounds(N_vals, r4_vals, r_nonAP_vals)

if __name__ == "__main__":
    main()
