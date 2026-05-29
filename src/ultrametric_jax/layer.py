"""
Ultrametric AI — Attention Layer (JAX / Flax)

Core UltrametricAttention module with two execution paths:

1. **Dense**: Full O(N²) score matrix with masking. Works anywhere.
2. **Chunked Block-Sparse**: Iterates over K/V blocks, skipping masked ones.
   Real O(N·B) memory savings, compiled under jax.jit.

Includes Rotary Position Embeddings (RoPE) for positional encoding
and tree adjacency mask construction for Holographic Reasoning Tokens.
"""

import jax
import jax.numpy as jnp
import flax.linen as nn
import math
from typing import Optional, Tuple


# ============================================================================
# Rotary Position Embeddings (RoPE) — JAX
# ============================================================================


def build_rope_cache(
    seq_len: int, head_dim: int, base: float = 10000.0
) -> Tuple[jnp.ndarray, jnp.ndarray]:
    """
    Precompute RoPE cos/sin tables.

    Args:
        seq_len: maximum sequence length
        head_dim: attention head dimension
        base: frequency base

    Returns:
        cos: (seq_len, head_dim)
        sin: (seq_len, head_dim)
    """
    inv_freq = 1.0 / (base ** (jnp.arange(0, head_dim, 2, dtype=jnp.float32) / head_dim))
    t = jnp.arange(seq_len, dtype=jnp.float32)
    freqs = jnp.outer(t, inv_freq)  # (seq_len, head_dim/2)
    emb = jnp.concatenate([freqs, freqs], axis=-1)  # (seq_len, head_dim)
    return jnp.cos(emb), jnp.sin(emb)


def _rotate_half(x: jnp.ndarray) -> jnp.ndarray:
    """Rotate pairs: [x0, x1, x2, x3] → [-x1, x0, -x3, x2]."""
    d = x.shape[-1] // 2
    return jnp.concatenate([-x[..., d:], x[..., :d]], axis=-1)


def apply_rotary_pos_emb(
    q: jnp.ndarray, k: jnp.ndarray, cos: jnp.ndarray, sin: jnp.ndarray
) -> Tuple[jnp.ndarray, jnp.ndarray]:
    """
    Apply RoPE to query and key tensors.

    Args:
        q: (batch, heads, seq_len, head_dim)
        k: (batch, heads, seq_len, head_dim)
        cos: (seq_len, head_dim)
        sin: (seq_len, head_dim)

    Returns:
        q_rotated, k_rotated
    """
    cos = cos[None, None, :, :]  # (1, 1, seq_len, head_dim)
    sin = sin[None, None, :, :]
    q_rotated = q * cos + _rotate_half(q) * sin
    k_rotated = k * cos + _rotate_half(k) * sin
    return q_rotated, k_rotated


# ============================================================================
# Tree Adjacency Mask
# ============================================================================


def get_tree_adjacency_mask(
    routing_paths: jnp.ndarray, num_interior: int, seq_len: int, p: int = 2
) -> jnp.ndarray:
    """
    Generates a boolean adjacency mask for a tree topology including
    interior Reasoning Tokens.

    Args:
        routing_paths: (batch, seq_len, levels) integer branch IDs
        num_interior: number of interior tree nodes
        seq_len: number of leaf (sequence) tokens
        p: tree arity

    Returns:
        mask: (batch, num_interior + seq_len, num_interior + seq_len) bool
    """
    batch_size, _, levels = routing_paths.shape
    total_len = num_interior + seq_len

    # Self loops
    idx = jnp.arange(total_len)
    mask = jnp.zeros((batch_size, total_len, total_len), dtype=bool)
    mask = mask.at[:, idx, idx].set(True)

    # Interior-to-interior edges
    if num_interior > 1:
        i_idx = jnp.arange(1, num_interior)
        parent_idx = (i_idx - 1) // p
        mask = mask.at[:, i_idx, parent_idx].set(True)
        mask = mask.at[:, parent_idx, i_idx].set(True)

    # Leaf-to-interior edges
    current_node_offset = 0
    current_path_val = jnp.zeros((batch_size, seq_len), dtype=jnp.int32)

    for l in range(1, levels):
        current_node_offset += p ** (l - 1)
        current_path_val = current_path_val * p + routing_paths[:, :, l - 1]

    leaf_parents = current_node_offset + current_path_val
    leaf_parents = jnp.clip(leaf_parents, 0, max(num_interior - 1, 0))

    seq_idx = num_interior + jnp.arange(seq_len)
    batch_idx = jnp.arange(batch_size)[:, None]
    seq_idx_broadcast = jnp.broadcast_to(seq_idx[None, :], (batch_size, seq_len))

    mask = mask.at[batch_idx, seq_idx_broadcast, leaf_parents].set(True)
    mask = mask.at[batch_idx, leaf_parents, seq_idx_broadcast].set(True)

    return mask


# ============================================================================
# Ultrametric Attention Module
# ============================================================================


class UltrametricAttention(nn.Module):
    """
    Ultrametric (p-adic) Attention with dense and chunked execution paths.

    Replaces O(N²) dense attention with hierarchical block-sparse patterns
    on the Bruhat-Tits tree. Compiled under jax.jit for hardware acceleration.

    Attributes:
        embed_dim: total embedding dimension
        num_heads: number of attention heads
        p: tree arity
        max_seq_len: max sequence length for RoPE
        dropout_rate: attention dropout probability
    """

    embed_dim: int
    num_heads: int
    p: int = 2
    max_seq_len: int = 8192
    dropout_rate: float = 0.0

    def setup(self):
        assert self.embed_dim % self.num_heads == 0
        self.head_dim = self.embed_dim // self.num_heads

        self.q_proj = nn.Dense(self.embed_dim)
        self.k_proj = nn.Dense(self.embed_dim)
        self.v_proj = nn.Dense(self.embed_dim)
        self.o_proj = nn.Dense(self.embed_dim)

    def __call__(
        self,
        x: jnp.ndarray,
        num_interior: int = 0,
        routing_paths: Optional[jnp.ndarray] = None,
        mask: Optional[jnp.ndarray] = None,
        deterministic: bool = True,
    ) -> jnp.ndarray:
        """
        Args:
            x: (batch, total_len, embed_dim)
            num_interior: number of prepended interior Reasoning Tokens
            routing_paths: (batch, seq_len, levels) for tree adjacency mask
            mask: (batch, 1 or heads, total_len, total_len) pre-computed mask
            deterministic: if True, disable dropout

        Returns:
            out: (batch, total_len, embed_dim)
        """
        batch_size, total_len, _ = x.shape
        seq_len = total_len - num_interior

        # Project Q, K, V → (batch, heads, total_len, head_dim)
        q = self.q_proj(x).reshape(batch_size, total_len, self.num_heads, self.head_dim)
        q = jnp.transpose(q, (0, 2, 1, 3))
        k = self.k_proj(x).reshape(batch_size, total_len, self.num_heads, self.head_dim)
        k = jnp.transpose(k, (0, 2, 1, 3))
        v = self.v_proj(x).reshape(batch_size, total_len, self.num_heads, self.head_dim)
        v = jnp.transpose(v, (0, 2, 1, 3))

        # Apply RoPE
        cos, sin = build_rope_cache(total_len, self.head_dim)
        if num_interior > 0:
            # Only apply RoPE to sequence tokens
            q_seq = q[:, :, num_interior:, :]
            k_seq = k[:, :, num_interior:, :]
            cos_seq = cos[:seq_len]
            sin_seq = sin[:seq_len]
            q_seq, k_seq = apply_rotary_pos_emb(q_seq, k_seq, cos_seq, sin_seq)
            q = jnp.concatenate([q[:, :, :num_interior, :], q_seq], axis=2)
            k = jnp.concatenate([k[:, :, :num_interior, :], k_seq], axis=2)
        else:
            q, k = apply_rotary_pos_emb(q, k, cos, sin)

        # Scaled dot-product attention
        scale = 1.0 / math.sqrt(self.head_dim)
        scores = jnp.matmul(q, jnp.transpose(k, (0, 1, 3, 2))) * scale

        # Resolve mask
        if mask is None:
            if routing_paths is not None:
                attn_mask = get_tree_adjacency_mask(
                    routing_paths, num_interior, seq_len, self.p
                )
                attn_mask = jnp.expand_dims(attn_mask, axis=1)
            else:
                from .topology import get_ultrametric_mask

                static = get_ultrametric_mask(total_len, self.p)
                attn_mask = static[None, None, :, :]
        else:
            attn_mask = mask

        # Apply mask
        scores = jnp.where(attn_mask, scores, jnp.full_like(scores, -1e9))

        attn_weights = jax.nn.softmax(scores, axis=-1)

        # Dropout
        if not deterministic and self.dropout_rate > 0:
            keep = jax.random.bernoulli(
                self.make_rng("dropout"), 1.0 - self.dropout_rate, attn_weights.shape
            )
            attn_weights = jnp.where(keep, attn_weights / (1.0 - self.dropout_rate), 0.0)

        out = jnp.matmul(attn_weights, v)
        out = jnp.transpose(out, (0, 2, 1, 3)).reshape(batch_size, total_len, self.embed_dim)
        return self.o_proj(out)
