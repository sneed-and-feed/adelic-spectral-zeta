import jax
import jax.numpy as jnp
import flax.linen as nn
import math
from typing import Optional, Any

def get_tree_adjacency_mask(routing_paths: jnp.ndarray, num_interior: int, seq_len: int, p: int = 2) -> jnp.ndarray:
    """
    Generates a boolean adjacency mask for a tree topology.
    routing_paths: (batch, seq_len, levels) containing integer branch IDs at each level.
    Returns: mask of shape (batch, num_interior + seq_len, num_interior + seq_len)
    """
    batch_size, _, levels = routing_paths.shape
    total_len = num_interior + seq_len
    
    # 1. Static interior edges
    i_idx = jnp.arange(1, num_interior)
    parent_idx = (i_idx - 1) // p
    
    # 2. Dynamic leaf edges
    current_node_offset = 0
    current_path_val = jnp.zeros((batch_size, seq_len), dtype=jnp.int32)
    
    # We only need the parent interior node of the sequence tokens, which is at level `levels-1`.
    for l in range(1, levels):
        current_node_offset += p**(l-1)
        current_path_val = current_path_val * p + routing_paths[:, :, l-1]
        
    leaf_parents = current_node_offset + current_path_val # (batch, seq_len)
    
    # Build mask
    mask = jnp.zeros((batch_size, total_len, total_len), dtype=bool)
    
    # Self loops
    idx = jnp.arange(total_len)
    mask = mask.at[:, idx, idx].set(True)
    
    # Interior to interior
    if num_interior > 1:
        mask = mask.at[:, i_idx, parent_idx].set(True)
        mask = mask.at[:, parent_idx, i_idx].set(True)
    
    # Sequence tokens to their leaf parents
    seq_idx = num_interior + jnp.arange(seq_len)
    batch_idx = jnp.arange(batch_size)[:, None]
    seq_idx_broadcast = jnp.broadcast_to(seq_idx[None, :], (batch_size, seq_len))
    
    mask = mask.at[batch_idx, seq_idx_broadcast, leaf_parents].set(True)
    mask = mask.at[batch_idx, leaf_parents, seq_idx_broadcast].set(True)
    
    return mask

class UltrametricAttention(nn.Module):
    """
    JAX/Flax implementation of Ultrametric (p-adic) Attention over a fractal tree.
    """
    embed_dim: int
    num_heads: int
    p: int = 2

    def setup(self):
        assert self.embed_dim % self.num_heads == 0, "embed_dim must be divisible by num_heads"
        self.head_dim = self.embed_dim // self.num_heads
        
        self.q_proj = nn.Dense(self.embed_dim)
        self.k_proj = nn.Dense(self.embed_dim)
        self.v_proj = nn.Dense(self.embed_dim)
        self.o_proj = nn.Dense(self.embed_dim)

    def __call__(self, x: jnp.ndarray, num_interior: int, routing_paths: Optional[jnp.ndarray] = None) -> jnp.ndarray:
        batch_size, total_len, _ = x.shape
        seq_len = total_len - num_interior
        
        # Project Q, K, V
        q = self.q_proj(x).reshape((batch_size, total_len, self.num_heads, self.head_dim)).transpose((0, 2, 1, 3))
        k = self.k_proj(x).reshape((batch_size, total_len, self.num_heads, self.head_dim)).transpose((0, 2, 1, 3))
        v = self.v_proj(x).reshape((batch_size, total_len, self.num_heads, self.head_dim)).transpose((0, 2, 1, 3))
        
        # Scaled dot-product attention
        scores = jnp.matmul(q, k.transpose((0, 1, 3, 2))) / math.sqrt(self.head_dim)
        
        if routing_paths is not None:
            # Mask shape: (batch_size, total_len, total_len) -> Broadcast to (batch_size, num_heads, total_len, total_len)
            mask = get_tree_adjacency_mask(routing_paths, num_interior, seq_len, self.p)
            mask = jnp.expand_dims(mask, axis=1)
        else:
            # Fallback to fully dense if no routing provided
            mask = jnp.ones((batch_size, 1, total_len, total_len), dtype=bool)
            
        # Invert mask: True means keep, False means drop (-inf)
        scores = jnp.where(mask, scores, jnp.full_like(scores, -jnp.inf))
        
        attn_weights = jax.nn.softmax(scores, axis=-1)
            
        # Apply weights to values
        out = jnp.matmul(attn_weights, v)
        
        # Reshape and project out
        out = out.transpose((0, 2, 1, 3)).reshape((batch_size, total_len, self.embed_dim))
        return self.o_proj(out)
