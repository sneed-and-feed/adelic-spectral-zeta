"""
Ultrametric AI v3.0 — Google Native (JAX / Flax / Pallas)

True Fractal attention with dynamic Gumbel-Softmax routing,
Pallas TPU kernels, deterministic PRNG routing, and
XLA-compiled fractal attention.
"""

from .topology import (
    DynamicTopologyRouter,
    compute_load_balance_loss,
    get_tau_schedule,
    get_ultrametric_mask,
    compute_p_adic_distance,
)
from .layer import (
    UltrametricAttention,
    build_rope_cache,
    apply_rotary_pos_emb,
    get_tree_adjacency_mask,
)
from .model import (
    UltrametricTransformerBlock,
    UltrametricTransformer,
)

__all__ = [
    # Topology & Routing
    "DynamicTopologyRouter",
    "compute_load_balance_loss",
    "get_tau_schedule",
    "get_ultrametric_mask",
    "compute_p_adic_distance",
    # Attention Layer
    "UltrametricAttention",
    "build_rope_cache",
    "apply_rotary_pos_emb",
    "get_tree_adjacency_mask",
    # Model
    "UltrametricTransformerBlock",
    "UltrametricTransformer",
]
