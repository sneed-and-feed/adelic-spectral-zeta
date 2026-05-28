import numpy as np

pf_vals = np.array([1.618034, 2.851212, 3.492968, 3.814643, 3.906643, 3.956203, 3.979167, 3.989888, 3.99503, 3.99755])
anti_vals = np.array([0.618034, 1.000000, 2.000000, 2.761199, 3.097184, 3.317667, 3.469671, 3.567528, 3.63693, 3.69246])
d_vals = np.arange(3, 13)

ratios = anti_vals / pf_vals

for d, ratio in zip(d_vals, ratios):
    L = (1 - ratio) * (d**2)
    print(f"d={d:2d}: 1-rho = {1-ratio:.6f}, L = d^2 * (1-rho) = {L:.6f}")
