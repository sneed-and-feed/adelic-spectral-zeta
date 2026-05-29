"""
Ultrametric AI — Complete Transformer Model (JAX / Flax)

A full, trainable language model built on fractal p-adic attention.
Google-native JAX/Flax implementation with explicit PRNG key threading
for deterministic, reproducible execution across distributed TPU superpods.

Architecture:
    Input IDs → Token Embedding → [N × UltrametricTransformerBlock] → LayerNorm → LM Head

Usage:
    model = UltrametricTransformer(vocab_size=32000, num_layers=6)
    variables = model.init(rng, input_ids, prng_key=rng)
    logits, loss, aux_loss = model.apply(variables, input_ids, targets=targets, prng_key=rng)
"""

import jax
import jax.numpy as jnp
import flax.linen as nn
import math
from typing import Optional, Tuple, Any

from .layer import UltrametricAttention
from .topology import DynamicTopologyRouter, get_ultrametric_mask


class UltrametricTransformerBlock(nn.Module):
    """
    Pre-LN Transformer block with sparse p-adic UltrametricAttention (Flax).

    Attributes:
        embed_dim: model dimension
        num_heads: number of attention heads
        p: tree arity for Bruhat-Tits topology
        mlp_ratio: MLP hidden dim multiplier
        max_seq_len: max sequence length for RoPE
        dropout_rate: dropout probability
    """

    embed_dim: int
    num_heads: int
    p: int = 2
    mlp_ratio: float = 4.0
    max_seq_len: int = 8192
    dropout_rate: float = 0.0

    @nn.compact
    def __call__(
        self,
        x: jnp.ndarray,
        mask: Optional[jnp.ndarray] = None,
        routing_paths: Optional[jnp.ndarray] = None,
        deterministic: bool = True,
        use_interior: bool = False,
    ) -> jnp.ndarray:
        """
        Args:
            x: (batch, seq_len, embed_dim)
            mask: pre-computed attention mask
            routing_paths: routing for tree adjacency
            deterministic: if True, disable dropout
            use_interior: whether to use Holographic Reasoning Tokens

        Returns:
            out: (batch, seq_len, embed_dim)
        """
        batch_size, seq_len, _ = x.shape
        num_interior = 0

        if use_interior:
            levels = int(math.ceil(math.log(max(seq_len, 2), self.p)))
            pad_len = self.p**levels
            num_interior = (pad_len - 1) // (self.p - 1)
            interior_token = self.param(
                "interior_token",
                nn.initializers.normal(stddev=0.02),
                (1, 1, self.embed_dim),
            )
            interior_nodes = jnp.broadcast_to(
                interior_token, (batch_size, num_interior, self.embed_dim)
            )
            x_full = jnp.concatenate([interior_nodes, x], axis=1)
        else:
            x_full = x

        # Pre-LN Attention
        h = nn.LayerNorm()(x_full)
        attn = UltrametricAttention(
            embed_dim=self.embed_dim,
            num_heads=self.num_heads,
            p=self.p,
            max_seq_len=self.max_seq_len,
            dropout_rate=self.dropout_rate,
        )
        attn_out = attn(
            h,
            num_interior=num_interior,
            routing_paths=routing_paths,
            mask=mask,
            deterministic=deterministic,
        )
        x_full = x_full + attn_out

        # Pre-LN MLP
        h2 = nn.LayerNorm()(x_full)
        mlp_dim = int(self.embed_dim * self.mlp_ratio)
        h2 = nn.Dense(mlp_dim)(h2)
        h2 = nn.gelu(h2)
        if not deterministic:
            h2 = nn.Dropout(rate=self.dropout_rate)(h2, deterministic=False)
        mlp_out = nn.Dense(self.embed_dim)(h2)
        if not deterministic:
            mlp_out = nn.Dropout(rate=self.dropout_rate)(mlp_out, deterministic=False)
        x_full = x_full + mlp_out

        # Strip interior tokens
        if use_interior and num_interior > 0:
            return x_full[:, num_interior:, :]
        return x_full


class UltrametricTransformer(nn.Module):
    """
    Complete Ultrametric Transformer language model (Flax).

    A GPT-style autoregressive model where dense self-attention is replaced
    by hierarchical block-sparse attention on a Bruhat-Tits tree.

    Attributes:
        vocab_size: vocabulary size
        num_layers: number of transformer blocks
        embed_dim: model embedding dimension
        num_heads: number of attention heads
        p: tree arity
        max_seq_len: maximum sequence length
        mlp_ratio: MLP hidden dimension multiplier
        dropout_rate: dropout probability
        use_interior: whether to use Holographic Reasoning Tokens
    """

    vocab_size: int = 32000
    num_layers: int = 6
    embed_dim: int = 512
    num_heads: int = 8
    p: int = 2
    max_seq_len: int = 2048
    mlp_ratio: float = 4.0
    dropout_rate: float = 0.1
    use_interior: bool = False

    @nn.compact
    def __call__(
        self,
        input_ids: jnp.ndarray,
        prng_key: jax.Array,
        targets: Optional[jnp.ndarray] = None,
        tau_override: Optional[float] = None,
        deterministic: bool = True,
    ) -> Tuple[jnp.ndarray, Optional[jnp.ndarray], jnp.ndarray]:
        """
        Forward pass with optional language modeling loss.

        Args:
            input_ids: (batch, seq_len) integer token IDs
            prng_key: JAX PRNG key for routing and dropout
            targets: (batch, seq_len) target token IDs (None to skip loss)
            tau_override: optional Gumbel-Softmax temperature
            deterministic: if True, disable dropout and use argmax routing

        Returns:
            logits: (batch, seq_len, vocab_size)
            loss: scalar cross-entropy loss (None if no targets)
            aux_loss: scalar routing load-balance loss
        """
        batch_size, seq_len = input_ids.shape

        # Token embeddings
        tok_emb = nn.Embed(
            num_embeddings=self.vocab_size,
            features=self.embed_dim,
            embedding_init=nn.initializers.normal(stddev=0.02),
        )
        x = tok_emb(input_ids)  # (batch, seq_len, embed_dim)

        if not deterministic:
            x = nn.Dropout(rate=self.dropout_rate)(x, deterministic=False)

        # Dynamic routing (shared across layers)
        router_key, dropout_key = jax.random.split(prng_key)
        router = DynamicTopologyRouter(
            embed_dim=self.embed_dim,
            seq_len=self.max_seq_len,
            num_heads=self.num_heads,
            p=self.p,
            tau=1.0,
            hard=True,
        )
        routing_assignments, aux_loss = router(
            x, prng_key=router_key, tau_override=tau_override, deterministic=deterministic
        )

        # Build causal + ultrametric mask
        causal = jnp.tril(jnp.ones((seq_len, seq_len), dtype=bool))
        ultra = get_ultrametric_mask(seq_len, self.p)
        combined = causal & ultra  # (seq_len, seq_len)
        combined = combined[None, None, :, :]  # (1, 1, S, S)

        # Transformer blocks
        for i in range(self.num_layers):
            x = UltrametricTransformerBlock(
                embed_dim=self.embed_dim,
                num_heads=self.num_heads,
                p=self.p,
                mlp_ratio=self.mlp_ratio,
                max_seq_len=self.max_seq_len,
                dropout_rate=self.dropout_rate,
                name=f"block_{i}",
            )(
                x,
                mask=combined,
                deterministic=deterministic,
                use_interior=self.use_interior,
            )

        # Final layer norm + LM head
        x = nn.LayerNorm()(x)

        # Tie weights with embedding matrix
        logits = tok_emb.attend(x)  # (batch, seq_len, vocab_size)

        # Cross-entropy loss
        loss = None
        if targets is not None:
            one_hot = jax.nn.one_hot(targets, num_classes=self.vocab_size)
            log_probs = jax.nn.log_softmax(logits, axis=-1)
            loss = -jnp.sum(one_hot * log_probs, axis=-1)
            # Mask out padding (target == -1)
            valid = (targets >= 0).astype(jnp.float32)
            loss = jnp.sum(loss * valid) / jnp.maximum(jnp.sum(valid), 1.0)

        return logits, loss, aux_loss

    def generate(
        self,
        variables: Any,
        input_ids: jnp.ndarray,
        prng_key: jax.Array,
        max_new_tokens: int = 100,
        temperature: float = 1.0,
        top_k: Optional[int] = 50,
    ) -> jnp.ndarray:
        """
        Autoregressive text generation.

        Args:
            variables: model parameters (from model.init())
            input_ids: (batch, prompt_len) starting token IDs
            prng_key: JAX PRNG key
            max_new_tokens: tokens to generate
            temperature: sampling temperature
            top_k: top-k sampling (None to disable)

        Returns:
            output_ids: (batch, prompt_len + generated_len)
        """

        def _step(carry, _):
            tokens, key = carry
            key, subkey, sample_key = jax.random.split(key, 3)

            # Crop to max_seq_len
            context = tokens[:, -self.max_seq_len :]
            logits, _, _ = self.apply(
                variables, context, prng_key=subkey, deterministic=True
            )

            # Sample from last position
            next_logits = logits[:, -1, :] / jnp.maximum(temperature, 1e-8)

            if top_k is not None and top_k > 0:
                top_k_vals = jax.lax.top_k(next_logits, min(top_k, next_logits.shape[-1]))[0]
                threshold = top_k_vals[:, -1:]
                next_logits = jnp.where(
                    next_logits < threshold, jnp.full_like(next_logits, -1e9), next_logits
                )

            next_token = jax.random.categorical(sample_key, next_logits, axis=-1)
            next_token = next_token[:, None]
            tokens = jnp.concatenate([tokens, next_token], axis=1)

            return (tokens, key), next_token

        (generated, _), _ = jax.lax.scan(
            _step, (input_ids, prng_key), None, length=max_new_tokens
        )
        return generated
