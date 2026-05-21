# Adèlic Spectral Zeta

A Python library to package and simulate the **Adèlic Spectral Triple** framework for automorphic $L$-functions. This project implements:
1. Fast, exact arithmetic coefficients (using divisor-sum recurrences).
2. Vectorized $Z$-function scanning for zeros on the critical line.
3. Compressed Dirac operators and Rank-1 Universality sweeps.
4. Many-body interacting fermion ground states under Coulomb-like repulsion.
5. von Neumann entanglement entropy bipartite sweeps.

## Installation

To build and install the package locally:

```bash
pip install -e .
```

## Structure

- `adelic_spectral_zeta/core.py`: Exact coefficient generation and vectorized $Z$-function calculators.
- `adelic_spectral_zeta/universality.py`: Operators simulation and Rank-1 vs Rank-N sweeps.
- `adelic_spectral_zeta/quantum.py`: Many-body Fock basis, Hamiltonian builder, and entanglement calculation.

## Quick Start

```python
from adelic_spectral_zeta.core import get_tau, Z_sym3_batch
import numpy as np

# Compute exact Ramanujan tau values
tau = get_tau(100)
print("Tau(5):", tau[5])

# Compute Z-function for Sym^3(Delta)
t_vals = np.linspace(5.0, 25.0, 10)
z_vals = Z_sym3_batch(t_vals)
print("Z-values:", z_vals)
```

## Authors
Pair-programmed by Antigravity (AI) & the User. May 2026.
