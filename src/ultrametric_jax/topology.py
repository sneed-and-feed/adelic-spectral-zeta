"""
Ultrametric AI — Dynamic Topology Router (JAX / Flax)

Multi-head Gumbel-Softmax routing for Bruhat-Tits tree topology.
Each attention head gets independent routing paths, producing genuinely
nested hierarchical attention masks.

JAX-native with explicit PRNG key threading for deterministic,
reproducible routing across distributed TPU superpods.
"""

import jax
import jax.numpy as jnp
import flax.linen as nn
import math
from typing import Optional, Tuple


class DynamicTopologyRouter(nn.Module):
    """
    Multi-Head Dynamic Topology Router (Flax).

    Projects token embeddings into per-head recursive p-adic tree paths
    via factorized Gumbel-Softmax with explicit PRNG key management.

    Attributes:
        embed_dim: token embedding dimension
        seq_len: maximum sequence length (determines tree depth)
        num_heads: number of independent routing heads
        p: tree arity (2 = binary Bruhat-Tits tree)
        tau: Gumbel-Softmax temperature
        hard: if True, use straight-through estimator
    """

    embed_dim: int
    seq_len: int
    num_heads: int = 1
    p: int = 2
    tau: float = 1.0
    hard: bool = True

    def setup(self):
        self.levels = int(math.ceil(math.log(max(self.seq_len, 2), self.p)))
        self.backbone = nn.Dense(self.embed_dim)
        self.route_heads = nn.Dense(self.num_heads * self.levels * self.p)

    def __call__(
        self,
        x: jnp.ndarray,
        prng_key: jax.Array,
        tau_override: Optional[float] = None,
        deterministic: bool = False,
    ) -> Tuple[jnp.ndarray, jnp.ndarray]:
        """
        Args:
            x: (batch, seq_len, embed_dim)
            prng_key: JAX PRNG key for Gumbel noise
            tau_override: optional temperature override
            deterministic: if True, use argmax instead of Gumbel sampling

        Returns:
            assignments: (batch, num_heads, seq_len, levels, p)
            load_balance_loss: scalar auxiliary loss
        """
        batch_size, seq_len, _ = x.shape
        tau = tau_override if tau_override is not None else self.tau

        # Shared backbone → per-head routing logits
        h = nn.gelu(self.backbone(x))
        logits = self.route_heads(h)
        logits = jnp.reshape(
            logits, (batch_size, seq_len, self.num_heads, self.levels, self.p)
        )
        logits = jnp.transpose(logits, (0, 2, 1, 3, 4))  # (B, H, S, L, p)

        if deterministic:
            indices = jnp.argmax(logits, axis=-1)
            assignments = jax.nn.one_hot(indices, num_classes=self.p)
        else:
            # Gumbel-Softmax with explicit PRNG
            gumbel_noise = jax.random.gumbel(prng_key, shape=logits.shape)
            y_soft = jax.nn.softmax((logits + gumbel_noise) / tau, axis=-1)

            if self.hard:
                indices = jnp.argmax(y_soft, axis=-1)
                y_hard = jax.nn.one_hot(indices, num_classes=self.p, dtype=y_soft.dtype)
                assignments = jax.lax.stop_gradient(y_hard - y_soft) + y_soft
            else:
                assignments = y_soft

        load_balance_loss = compute_load_balance_loss(assignments)
        return assignments, load_balance_loss


def compute_load_balance_loss(assignments: jnp.ndarray) -> jnp.ndarray:
    """
    Switch Transformer-style load balancing loss.

    L_balance = p * mean(f_i * P_i) where:
      f_i = fraction of tokens routed to branch i
      P_i = mean routing probability to branch i

    Args:
        assignments: (batch, num_heads, seq_len, levels, p)
    Returns:
        loss: scalar
    """
    p = assignments.shape[-1]
    f = jnp.mean((jax.lax.stop_gradient(assignments) > 0.5).astype(jnp.float32), axis=2)
    P = jnp.mean(assignments, axis=2)
    loss = jnp.mean(jnp.sum(f * P, axis=-1)) * p
    return loss


def get_tau_schedule(
    step: int,
    warmup_steps: int = 2000,
    tau_start: float = 2.0,
    tau_end: float = 0.1,
) -> float:
    """Cosine temperature annealing: soft → hard routing over training."""
    if step >= warmup_steps:
        return tau_end
    progress = step / warmup_steps
    return tau_end + 0.5 * (tau_start - tau_end) * (1 + math.cos(math.pi * progress))


# ============================================================================
# Ultrametric Mask Utilities (JAX)
# ============================================================================


def get_ultrametric_mask(seq_len: int, p: int = 2) -> jnp.ndarray:
    """
    Static boolean mask for ultrametric (p-adic) attention.
    Block-sparse with density decreasing as p-adic distance increases.

    Args:
        seq_len: sequence length
        p: tree arity
    Returns:
        mask: (seq_len, seq_len) boolean array
    """
    levels = int(math.ceil(math.log(max(seq_len, 2), p)))
    pad_len = p**levels

    # Build mask on CPU numpy, convert to JAX
    import numpy as np

    mask = np.zeros((pad_len, pad_len), dtype=bool)
    for level in range(levels):
        block_size = p**level
        for i in range(0, pad_len, block_size):
            mask[i : i + block_size, i : i + block_size] = True

    return jnp.array(mask[:seq_len, :seq_len])


def compute_p_adic_distance(i: int, j: int, p: int = 2) -> int:
    """
    Computes the p-adic distance between two token indices.
    Height of their lowest common ancestor in a p-ary tree.
    """
    if i == j:
        return 0
    diff = i ^ j
    return int(math.floor(math.log(diff, p))) + 1
