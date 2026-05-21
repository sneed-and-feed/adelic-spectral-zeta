import numpy as np
exact_zeros = np.array([5.128673, 5.646348, 6.115696, 6.685053, 7.101472])
C_mag_vals = np.array([40.61956482, 144.58622488, 347.18448309, 4922.07467512, 16875.10445576])
ratio = C_mag_vals * np.exp(-np.pi * exact_zeros / 2)
print("C_mag:", C_mag_vals)
print("Ratio C_mag / e^(pi*t/2):", ratio)
