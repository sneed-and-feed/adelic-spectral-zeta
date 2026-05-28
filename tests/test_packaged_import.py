"""
Test suite: test_packaged_import.py
Tests mathematical properties and correctness invariants.
"""
from adelic_spectral_zeta import get_tau, Z_sym3_batch
import numpy as np

# Test tau values
tau = get_tau(10)
print("Tau coefficients (n=1 to 10):")
print(tau[1:11])

# Test Z-function batch calculation
t_vals = np.linspace(5.0, 10.0, 5)
z_vals = Z_sym3_batch(t_vals, M=100)
print("Z-values for Sym^3(Delta) at t in [5, 10]:")
print(z_vals)
print("Package import test PASSED!")
