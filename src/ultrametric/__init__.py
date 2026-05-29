"""
Ultrametric AI — PyTorch / Triton Stack

True Fractal attention with dynamic Gumbel-Softmax routing,
Triton block-sparse GPU kernels, and Holographic Reasoning Tokens.
"""

from .topology import (
    DynamicTopologyRouter,
    get_ultrametric_mask,
    get_dynamic_ultrametric_mask,
    compute_p_adic_distance,
)
from .layer import (
    UltrametricAttention,
    RotaryPositionEmbedding,
    apply_rotary_pos_emb,
    get_tree_adjacency_mask,
)
from .model import (
    UltrametricTransformerBlock,
    UltrametricTransformer,
)
from .kernel import HAS_TRITON, routing_to_block_indices

# Conditional export for Triton
if HAS_TRITON:
    from .kernel import ultrametric_attention_triton

__all__ = [
    # Topology & Routing
    "DynamicTopologyRouter",
    "get_ultrametric_mask",
    "get_dynamic_ultrametric_mask",
    "compute_p_adic_distance",
    # Attention Layer
    "UltrametricAttention",
    "RotaryPositionEmbedding",
    "apply_rotary_pos_emb",
    "get_tree_adjacency_mask",
    # Model
    "UltrametricTransformerBlock",
    "UltrametricTransformer",
    # Kernel utilities
    "HAS_TRITON",
    "routing_to_block_indices",
]
