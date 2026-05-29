import jax
import jax.numpy as jnp
import flax.linen as nn
import math

class DynamicTopologyRouter(nn.Module):
    """
    Recursive, Multi-Level Dynamic Topology router.
    Projects continuous token embeddings into a recursive routing path 
    (e.g., [Root_Branch, Sub_Branch, Leaf]) to map to discrete Bruhat-Tits 
    tree branches using a hierarchical differentiable Gumbel-Softmax bridge.
    """
    embed_dim: int
    seq_len: int
    p: int = 2
    tau: float = 1.0
    hard: bool = True

    def setup(self):
        # Calculate the number of tree levels based on sequence length and arity
        self.levels = int(math.ceil(math.log(max(self.seq_len, 1), self.p)))
        # For each level in the tree, we need `p` logits to choose a branch.
        self.proj = nn.Dense(self.levels * self.p)

    def __call__(self, x, prng_key):
        """
        x: (batch, seq_len, embed_dim)
        prng_key: jax.random.PRNGKey
        Returns:
            assignments: (batch, seq_len, levels, p) soft or hard assignments
                         representing the chosen branch path through the tree.
        """
        logits = self.proj(x)
        # Reshape to (..., levels, p) to represent the path decisions
        logits = jnp.reshape(logits, x.shape[:-1] + (self.levels, self.p))
        
        # Gumbel-Softmax for differentiable discrete routing at each level
        gumbel_noise = jax.random.gumbel(prng_key, shape=logits.shape)
        
        # Softmax with temperature along the `p` dimension
        y_soft = jax.nn.softmax((logits + gumbel_noise) / self.tau, axis=-1)
        
        if self.hard:
            # Find the argmax branch at each level
            index = jnp.argmax(y_soft, axis=-1, keepdims=True)
            # Create one-hot encoding for the chosen branches
            y_hard = jax.nn.one_hot(index[..., 0], num_classes=self.p, dtype=y_soft.dtype)
            # Straight-through estimator
            assignments = jax.lax.stop_gradient(y_hard - y_soft) + y_soft
        else:
            assignments = y_soft
            
        return assignments
