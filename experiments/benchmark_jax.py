"""
Ultrametric AI — JAX/XLA Benchmark (Colab A100)

Cell 1: !pip install -U jax[cuda12] flax
Cell 2: Paste this entire file

Benchmarks JAX ultrametric masked attention vs dense attention,
both under jax.jit XLA compilation.
"""

import jax
import jax.numpy as jnp
import flax.linen as nn
import math
import time
import json
from functools import partial


print(f"JAX version: {jax.__version__}")
print(f"Devices: {jax.devices()}")
print(f"Backend: {jax.default_backend()}")
print()


# ============================================================
# ULTRAMETRIC MASK (JAX)
# ============================================================

def get_ultrametric_mask(seq_len: int, p: int = 2) -> jnp.ndarray:
    """Static ultrametric mask from p-adic tree topology."""
    import numpy as np
    levels = int(math.ceil(math.log(max(seq_len, 2), p)))
    pad_len = p ** levels
    mask = np.zeros((pad_len, pad_len), dtype=bool)
    for level in range(levels):
        bs = p ** level
        for i in range(0, pad_len, bs):
            mask[i:i+bs, i:i+bs] = True
    return jnp.array(mask[:seq_len, :seq_len])


# ============================================================
# ROPE (JAX)
# ============================================================

def build_rope_cache(seq_len, head_dim, base=10000.0):
    inv_freq = 1.0 / (base ** (jnp.arange(0, head_dim, 2, dtype=jnp.float32) / head_dim))
    t = jnp.arange(seq_len, dtype=jnp.float32)
    freqs = jnp.outer(t, inv_freq)
    emb = jnp.concatenate([freqs, freqs], axis=-1)
    return jnp.cos(emb), jnp.sin(emb)

def rotate_half(x):
    d = x.shape[-1] // 2
    return jnp.concatenate([-x[..., d:], x[..., :d]], axis=-1)

def apply_rope(q, k, cos, sin):
    cos = cos[None, None, :, :]
    sin = sin[None, None, :, :]
    return q * cos + rotate_half(q) * sin, k * cos + rotate_half(k) * sin


# ============================================================
# ATTENTION FUNCTIONS
# ============================================================

@partial(jax.jit, static_argnames=('num_heads', 'head_dim'))
def dense_attention_jax(q, k, v, num_heads, head_dim):
    """Pure dense attention — no mask, just Q @ K^T @ V."""
    scale = 1.0 / math.sqrt(head_dim)
    B, H, S, D = q.shape
    cos, sin = build_rope_cache(S, D)
    q, k = apply_rope(q, k, cos, sin)
    scores = jnp.matmul(q, jnp.transpose(k, (0, 1, 3, 2))) * scale
    attn = jax.nn.softmax(scores, axis=-1)
    return jnp.matmul(attn, v)

@partial(jax.jit, static_argnames=('num_heads', 'head_dim'))
def masked_attention_jax(q, k, v, mask, num_heads, head_dim):
    """Ultrametric masked attention — XLA-compiled sparse pattern."""
    scale = 1.0 / math.sqrt(head_dim)
    B, H, S, D = q.shape
    cos, sin = build_rope_cache(S, D)
    q, k = apply_rope(q, k, cos, sin)
    scores = jnp.matmul(q, jnp.transpose(k, (0, 1, 3, 2))) * scale
    scores = jnp.where(mask[None, None, :, :], scores, jnp.float32(-1e9))
    attn = jax.nn.softmax(scores, axis=-1)
    return jnp.matmul(attn, v)


# ============================================================
# FULL FLAX TRANSFORMER BLOCK
# ============================================================

class UltrametricBlock(nn.Module):
    embed_dim: int
    num_heads: int
    p: int = 2
    mlp_ratio: float = 4.0

    @nn.compact
    def __call__(self, x, mask=None):
        B, S, E = x.shape
        head_dim = E // self.num_heads

        # Pre-LN Attention
        h = nn.LayerNorm()(x)
        q = nn.Dense(E)(h).reshape(B, S, self.num_heads, head_dim).transpose((0, 2, 1, 3))
        k = nn.Dense(E)(h).reshape(B, S, self.num_heads, head_dim).transpose((0, 2, 1, 3))
        v = nn.Dense(E)(h).reshape(B, S, self.num_heads, head_dim).transpose((0, 2, 1, 3))

        cos, sin = build_rope_cache(S, head_dim)
        q, k = apply_rope(q, k, cos, sin)

        scale = 1.0 / math.sqrt(head_dim)
        scores = jnp.matmul(q, jnp.transpose(k, (0, 1, 3, 2))) * scale
        if mask is not None:
            scores = jnp.where(mask[None, None, :, :], scores, jnp.float32(-1e9))
        attn = jax.nn.softmax(scores, axis=-1)
        out = jnp.matmul(attn, v)
        out = out.transpose((0, 2, 1, 3)).reshape(B, S, E)
        out = nn.Dense(E)(out)
        x = x + out

        # Pre-LN MLP
        h2 = nn.LayerNorm()(x)
        mlp_dim = int(E * self.mlp_ratio)
        h2 = nn.Dense(mlp_dim)(h2)
        h2 = nn.gelu(h2)
        h2 = nn.Dense(E)(h2)
        x = x + h2
        return x

class DenseBlock(nn.Module):
    embed_dim: int
    num_heads: int
    mlp_ratio: float = 4.0

    @nn.compact
    def __call__(self, x):
        B, S, E = x.shape
        head_dim = E // self.num_heads

        h = nn.LayerNorm()(x)
        q = nn.Dense(E)(h).reshape(B, S, self.num_heads, head_dim).transpose((0, 2, 1, 3))
        k = nn.Dense(E)(h).reshape(B, S, self.num_heads, head_dim).transpose((0, 2, 1, 3))
        v = nn.Dense(E)(h).reshape(B, S, self.num_heads, head_dim).transpose((0, 2, 1, 3))

        cos, sin = build_rope_cache(S, head_dim)
        q, k = apply_rope(q, k, cos, sin)

        scale = 1.0 / math.sqrt(head_dim)
        scores = jnp.matmul(q, jnp.transpose(k, (0, 1, 3, 2))) * scale
        attn = jax.nn.softmax(scores, axis=-1)
        out = jnp.matmul(attn, v)
        out = out.transpose((0, 2, 1, 3)).reshape(B, S, E)
        out = nn.Dense(E)(out)
        x = x + out

        h2 = nn.LayerNorm()(x)
        mlp_dim = int(E * self.mlp_ratio)
        h2 = nn.Dense(mlp_dim)(h2)
        h2 = nn.gelu(h2)
        h2 = nn.Dense(E)(h2)
        x = x + h2
        return x

class HybridModel(nn.Module):
    embed_dim: int
    num_heads: int
    p: int = 2

    @nn.compact
    def __call__(self, x, mask=None):
        x = UltrametricBlock(self.embed_dim, self.num_heads, self.p)(x, mask)
        x = DenseBlock(self.embed_dim, self.num_heads)(x)
        return x

class DenseModel(nn.Module):
    embed_dim: int
    num_heads: int

    @nn.compact
    def __call__(self, x):
        x = DenseBlock(self.embed_dim, self.num_heads)(x)
        x = DenseBlock(self.embed_dim, self.num_heads)(x)
        return x

class UltraModel(nn.Module):
    embed_dim: int
    num_heads: int
    p: int = 2

    @nn.compact
    def __call__(self, x, mask=None):
        x = UltrametricBlock(self.embed_dim, self.num_heads, self.p)(x, mask)
        x = UltrametricBlock(self.embed_dim, self.num_heads, self.p)(x, mask)
        return x

# ============================================================
# BENCHMARK
# ============================================================

def bench_jax(fn, warmup=10, runs=30):
    """Benchmark a JAX function with proper synchronization."""
    # Warmup (includes JIT compilation)
    for _ in range(warmup):
        out = fn()
        out.block_until_ready()

    times = []
    for _ in range(runs):
        start = time.perf_counter()
        out = fn()
        out.block_until_ready()
        end = time.perf_counter()
        times.append((end - start) * 1000)  # ms

    return sorted(times)[len(times) // 2]


def main():
    embed_dim = 512
    num_heads = 8
    head_dim = embed_dim // num_heads
    batch = 8
    p = 2

    seq_lengths = [128, 256, 512, 1024, 2048, 4096, 8192]

    print("=" * 90)
    print(f"  JAX/XLA ULTRAMETRIC ATTENTION BENCHMARK")
    print(f"  embed={embed_dim}, heads={num_heads}, head_dim={head_dim}, batch={batch}")
    print(f"  Backend: {jax.default_backend()}, Device: {jax.devices()[0]}")
    print("=" * 90)

    # ---- Part 1: Raw Attention Kernel ----
    print("\n📊 Part 1: Raw Attention Kernel (q @ k^T @ v)")
    print("-" * 80)

    results_raw = []
    for sl in seq_lengths:
        key = jax.random.PRNGKey(42)
        q = jax.random.normal(key, (batch, num_heads, sl, head_dim), dtype=jnp.float16)
        k = jax.random.normal(key, (batch, num_heads, sl, head_dim), dtype=jnp.float16)
        v = jax.random.normal(key, (batch, num_heads, sl, head_dim), dtype=jnp.float16)
        mask = get_ultrametric_mask(sl, p)
        sparsity = 1.0 - mask.astype(jnp.float32).mean().item()

        try:
            d_ms = bench_jax(lambda: dense_attention_jax(q, k, v, num_heads, head_dim))
        except Exception as e:
            d_ms = float('inf')
            print(f"  Dense OOM/error at seq_len={sl}: {e}")

        try:
            m_ms = bench_jax(lambda: masked_attention_jax(q, k, v, mask, num_heads, head_dim))
        except Exception as e:
            m_ms = float('inf')
            print(f"  Masked OOM/error at seq_len={sl}: {e}")

        ratio = d_ms / m_ms if m_ms > 0 and m_ms != float('inf') else 0
        row = {
            "seq_len": sl, "sparsity": f"{sparsity:.0%}",
            "dense_ms": round(d_ms, 2), "masked_ms": round(m_ms, 2),
            "ratio": f"{ratio:.2f}x",
        }
        results_raw.append(row)
        fire = "🔥" if ratio > 1.0 else "  "
        print(f"{fire} seq={sl:>5} | sparse={sparsity:>4.0%}"
              f" | dense={d_ms:>7.2f}ms | masked={m_ms:>7.2f}ms"
              f" | ratio={ratio:>5.2f}x")

        del q, k, v, mask

    # ---- Part 2: Full Transformer Block ----
    print(f"\n📊 Part 2: Full Transformer Block (Attn + MLP + LayerNorm)")
    print("-" * 80)

    results_block = []
    for sl in seq_lengths:
        key = jax.random.PRNGKey(42)
        x = jax.random.normal(key, (batch, sl, embed_dim), dtype=jnp.float32)
        mask = get_ultrametric_mask(sl, p)
        sparsity = 1.0 - mask.astype(jnp.float32).mean().item()

        # Init models
        dense_block = DenseBlock(embed_dim=embed_dim, num_heads=num_heads)
        ultra_block = UltrametricBlock(embed_dim=embed_dim, num_heads=num_heads, p=p)

        d_params = dense_block.init(key, x)
        u_params = ultra_block.init(key, x, mask)

        # JIT compile
        dense_fn = jax.jit(dense_block.apply)
        ultra_fn = jax.jit(ultra_block.apply, static_argnames=())

        try:
            d_ms = bench_jax(lambda: dense_fn(d_params, x))
        except Exception as e:
            d_ms = float('inf')
            print(f"  Dense block error at seq={sl}: {e}")

        try:
            u_ms = bench_jax(lambda: ultra_fn(u_params, x, mask))
        except Exception as e:
            u_ms = float('inf')
            print(f"  Ultra block error at seq={sl}: {e}")

        ratio = d_ms / u_ms if u_ms > 0 and u_ms != float('inf') else 0
        row = {
            "seq_len": sl, "sparsity": f"{sparsity:.0%}",
            "dense_ms": round(d_ms, 2), "ultra_ms": round(u_ms, 2),
            "ratio": f"{ratio:.2f}x",
        }
        results_block.append(row)
        fire = "🔥" if ratio > 1.0 else "  "
        print(f"{fire} seq={sl:>5} | sparse={sparsity:>4.0%}"
              f" | dense={d_ms:>7.2f}ms | ultra={u_ms:>7.2f}ms"
              f" | ratio={ratio:>5.2f}x")

        del x, mask, d_params, u_params

    # ---- Part 3: Gradient Throughput ----
    print(f"\n📊 Part 3: Forward + Backward (Gradient Throughput)")
    print("-" * 80)

    results_grad = []
    for sl in [256, 512, 1024, 2048, 4096]:
        key = jax.random.PRNGKey(42)
        x = jax.random.normal(key, (batch, sl, embed_dim), dtype=jnp.float32)
        mask = get_ultrametric_mask(sl, p)
        sparsity = 1.0 - mask.astype(jnp.float32).mean().item()

        dense_block = DenseBlock(embed_dim=embed_dim, num_heads=num_heads)
        ultra_block = UltrametricBlock(embed_dim=embed_dim, num_heads=num_heads, p=p)

        d_params = dense_block.init(key, x)
        u_params = ultra_block.init(key, x, mask)

        def dense_loss(params, x):
            return dense_block.apply(params, x).mean()

        def ultra_loss(params, x, mask):
            return ultra_block.apply(params, x, mask).mean()

        dense_grad_fn = jax.jit(jax.grad(dense_loss))
        ultra_grad_fn = jax.jit(jax.grad(ultra_loss))

        try:
            d_ms = bench_jax(lambda: dense_grad_fn(d_params, x))
        except Exception as e:
            d_ms = float('inf')
            print(f"  Dense grad error at seq={sl}: {e}")

        try:
            u_ms = bench_jax(lambda: ultra_grad_fn(u_params, x, mask))
        except Exception as e:
            u_ms = float('inf')
            print(f"  Ultra grad error at seq={sl}: {e}")

        ratio = d_ms / u_ms if u_ms > 0 and u_ms != float('inf') else 0
        row = {
            "seq_len": sl, "sparsity": f"{sparsity:.0%}",
            "dense_ms": round(d_ms, 2), "ultra_ms": round(u_ms, 2),
            "ratio": f"{ratio:.2f}x",
        }
        results_grad.append(row)
        fire = "🔥" if ratio > 1.0 else "  "
        print(f"{fire} seq={sl:>5} | sparse={sparsity:>4.0%}"
              f" | dense_grad={d_ms:>7.2f}ms | ultra_grad={u_ms:>7.2f}ms"
              f" | ratio={ratio:>5.2f}x")

        del x, mask, d_params, u_params

    # ---- Part 4: Hybrid Architecture (2-Layer Models) ----
    print(f"\n📊 Part 4: Hybrid Architecture (2-Layer Models)")
    print("-" * 80)

    results_hybrid = []
    for sl in seq_lengths:
        key = jax.random.PRNGKey(42)
        x = jax.random.normal(key, (batch, sl, embed_dim), dtype=jnp.float32)
        mask = get_ultrametric_mask(sl, p)
        sparsity = 1.0 - mask.astype(jnp.float32).mean().item()

        dense_model = DenseModel(embed_dim=embed_dim, num_heads=num_heads)
        ultra_model = UltraModel(embed_dim=embed_dim, num_heads=num_heads, p=p)
        hybrid_model = HybridModel(embed_dim=embed_dim, num_heads=num_heads, p=p)

        d_params = dense_model.init(key, x)
        u_params = ultra_model.init(key, x, mask)
        h_params = hybrid_model.init(key, x, mask)

        dense_fn = jax.jit(dense_model.apply)
        ultra_fn = jax.jit(ultra_model.apply, static_argnames=())
        hybrid_fn = jax.jit(hybrid_model.apply, static_argnames=())

        try:
            d_ms = bench_jax(lambda: dense_fn(d_params, x))
        except Exception as e:
            d_ms = float('inf')
            print(f"  Dense error at seq={sl}: {e}")

        try:
            u_ms = bench_jax(lambda: ultra_fn(u_params, x, mask))
        except Exception as e:
            u_ms = float('inf')
            print(f"  Ultra error at seq={sl}: {e}")

        try:
            h_ms = bench_jax(lambda: hybrid_fn(h_params, x, mask))
        except Exception as e:
            h_ms = float('inf')
            print(f"  Hybrid error at seq={sl}: {e}")

        ultra_ratio = d_ms / u_ms if u_ms > 0 and u_ms != float('inf') else 0
        hybrid_ratio = d_ms / h_ms if h_ms > 0 and h_ms != float('inf') else 0
        row = {
            "seq_len": sl, "sparsity": f"{sparsity:.0%}",
            "dense_ms": round(d_ms, 2), "ultra_ms": round(u_ms, 2), "hybrid_ms": round(h_ms, 2),
            "ultra_ratio": f"{ultra_ratio:.2f}x", "hybrid_ratio": f"{hybrid_ratio:.2f}x"
        }
        results_hybrid.append(row)
        print(f"  seq={sl:>5} | sparse={sparsity:>4.0%}"
              f" | dense={d_ms:>7.2f}ms | ultra={u_ms:>7.2f}ms | hybrid={h_ms:>7.2f}ms"
              f" | ultra_speed={ultra_ratio:>5.2f}x | hybrid_speed={hybrid_ratio:>5.2f}x")

        del x, mask, d_params, u_params, h_params

    # Save
    all_results = {
        "raw_attention": results_raw,
        "full_block": results_block,
        "gradient": results_grad,
        "hybrid": results_hybrid,
    }
    with open("benchmark_jax_results.json", "w") as f:
        json.dump(all_results, f, indent=2)
    print(f"\n✅ Saved to benchmark_jax_results.json")


if __name__ == "__main__":
    main()
