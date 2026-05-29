import jax
import jax.numpy as jnp
import flax.linen as nn
import math
from typing import Optional, Tuple, Any

from .layer import UltrametricAttention

class UltrametricTransformerBlock(nn.Module):
    """
    Flax implementation of a transformer block with sparse p-adic UltrametricAttention.
    """
    embed_dim: int
    num_heads: int
    p: int = 2
    mlp_ratio: float = 4.0

    @nn.compact
    def __call__(self, x: jnp.ndarray, routing_paths: jnp.ndarray, interior_nodes: Optional[jnp.ndarray] = None, return_interior: bool = False) -> Any:
        batch_size, seq_len, _ = x.shape
        
        # routing_paths should have shape (batch_size, seq_len, levels)
        levels = routing_paths.shape[2] if routing_paths is not None else int(math.ceil(math.log(seq_len, self.p))) if seq_len > 0 else 0
        
        # Allocate capacity for the interior nodes of the Bruhat-Tits tree
        interior_token = self.param('interior_token', nn.initializers.normal(stddev=1.0), (1, 1, self.embed_dim))
        
        if interior_nodes is None:
            pad_len = self.p ** levels if levels > 0 else 0
            num_interior = (pad_len - 1) // (self.p - 1) if levels > 0 else 0
            
            # Broadcast interior_token to (batch_size, num_interior, embed_dim)
            interior_nodes = jnp.broadcast_to(interior_token, (batch_size, num_interior, self.embed_dim))
            
        num_interior = interior_nodes.shape[1]
        
        # Concatenate interior nodes and boundary tokens
        x_full = jnp.concatenate([interior_nodes, x], axis=1)
        
        # Pre-LN and Attention
        ln_1 = nn.LayerNorm()
        h = ln_1(x_full)
        
        attn = UltrametricAttention(embed_dim=self.embed_dim, num_heads=self.num_heads, p=self.p)
        attn_out = attn(h, num_interior=num_interior, routing_paths=routing_paths)
        
        x_full = x_full + attn_out
        
        # MLP
        ln_2 = nn.LayerNorm()
        h2 = ln_2(x_full)
        
        mlp_dim = int(self.embed_dim * self.mlp_ratio)
        h2 = nn.Dense(mlp_dim)(h2)
        h2 = nn.gelu(h2)
        mlp_out = nn.Dense(self.embed_dim)(h2)
        
        x_full = x_full + mlp_out
        
        # Extract the updated components
        out_interior = x_full[:, :num_interior, :]
        out_leaves = x_full[:, num_interior:, :]
        
        if return_interior:
            return out_leaves, out_interior
        return out_leaves
