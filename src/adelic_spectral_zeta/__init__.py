__version__ = "1.0.0"

from .core import get_tau, Z_sym3_batch, Z_sym4_batch
from .universality import simulate_universality, compute_resolvent_trace_diff
from .quantum import build_many_body_H, get_entanglement_entropy, solve_ground_state_entanglement
from .determinant import weierstrass_determinant, compute_eigenvalues
from .spectral_gap import (
    construct_B3,
    construct_B2,
    get_diagonal_indices,
    construct_diagonal_vectors,
    construct_restricted_operator,
    compute_restricted_spectral_gap,
    construct_gauge_twisted_B,
    compute_gauge_twisted_gap,
)
from .adelic_dirac import (
    construct_D0,
    construct_omega2,
    construct_D_cov,
    construct_D_artin,
    construct_xi_and_P,
    sweep_eigenvalues,
)


