"""
Grokking Experiment: Modular Addition mod 113
Tests whether p-adic inductive bias accelerates grokking.

3-way comparison:
  1. Dense (standard softmax attention)
  2. Ultrametric (softmax + p-adic token distance bias)
  3. Linear (no softmax, normalized Q@K@V)

Runs on CPU in ~10-20 minutes. No GPU needed.

Usage: python experiments/grokking_mod113.py
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
import math
import json
import time
from itertools import product as cart_product

# ============================================================
# CONFIG
# ============================================================

P = 113           # prime modulus
FRAC_TRAIN = 0.3  # 30% train, 70% test (standard grokking split)
EMBED_DIM = 128
NUM_HEADS = 4
NUM_LAYERS = 1
LR = 1e-3
WD = 1.0          # weight decay — crucial for grokking
STEPS = 40_000
LOG_EVERY = 200
GROK_THRESHOLD = 0.95  # test acc to count as "grokked"
SEED = 42
P_ADIC_PRIME = 2  # prime for ultrametric distance

# ============================================================
# DATA
# ============================================================

def make_dataset(p=P, frac_train=FRAC_TRAIN, seed=SEED):
    """All (a, b, (a+b) mod p) triples, split into train/test."""
    torch.manual_seed(seed)
    pairs = torch.tensor([(a, b) for a, b in cart_product(range(p), repeat=2)])
    labels = (pairs[:, 0] + pairs[:, 1]) % p
    n = len(pairs)
    perm = torch.randperm(n)
    split = int(n * frac_train)
    train_idx, test_idx = perm[:split], perm[split:]
    return pairs[train_idx], labels[train_idx], pairs[test_idx], labels[test_idx]


# ============================================================
# P-ADIC DISTANCE BIAS
# ============================================================

def p_adic_valuation(n, p=2):
    """v_p(n) = largest k such that p^k divides n."""
    if n == 0:
        return 8  # stand-in for infinity, clamped
    n = abs(n)
    v = 0
    while n % p == 0:
        n //= p
        v += 1
    return v


def build_padic_bias_matrix(vocab_size, p=P_ADIC_PRIME):
    """
    Build a (vocab_size x vocab_size) matrix where entry [a,b] = v_p(a - b).
    Higher valuation = p-adically closer = stronger attention bias.
    """
    bias = torch.zeros(vocab_size, vocab_size)
    for a in range(vocab_size):
        for b in range(vocab_size):
            bias[a, b] = p_adic_valuation(a - b, p)
    # Normalize to zero mean, unit variance for stable training
    bias = (bias - bias.mean()) / (bias.std() + 1e-8)
    return bias


# ============================================================
# MODELS
# ============================================================

class Attention(nn.Module):
    def __init__(self, embed_dim, num_heads, mode='dense', padic_bias=None):
        super().__init__()
        self.embed_dim = embed_dim
        self.num_heads = num_heads
        self.head_dim = embed_dim // num_heads
        self.mode = mode

        self.qkv = nn.Linear(embed_dim, 3 * embed_dim)
        self.out_proj = nn.Linear(embed_dim, embed_dim)

        if mode == 'ultrametric' and padic_bias is not None:
            self.register_buffer('padic_bias', padic_bias)
            # Learnable scaling per head
            self.bias_scale = nn.Parameter(torch.ones(num_heads) * 0.1)

    def forward(self, x, input_tokens=None):
        B, S, E = x.shape
        qkv = self.qkv(x).reshape(B, S, 3, self.num_heads, self.head_dim)
        q, k, v = qkv.unbind(dim=2)  # (B, S, H, D)
        q = q.transpose(1, 2)  # (B, H, S, D)
        k = k.transpose(1, 2)
        v = v.transpose(1, 2)

        scale = 1.0 / math.sqrt(self.head_dim)
        scores = torch.matmul(q, k.transpose(-2, -1)) * scale  # (B, H, S, S)

        if self.mode == 'ultrametric' and input_tokens is not None:
            # Add p-adic content-based bias
            # input_tokens: (B, S) — token IDs at each position
            # padic_bias[token_i, token_j] gives the p-adic similarity
            tok_i = input_tokens.unsqueeze(2).expand(B, S, S)  # (B, S, S)
            tok_j = input_tokens.unsqueeze(1).expand(B, S, S)  # (B, S, S)
            bias = self.padic_bias[tok_i, tok_j]  # (B, S, S)
            bias = bias.unsqueeze(1)  # (B, 1, S, S)
            scales = self.bias_scale.view(1, self.num_heads, 1, 1)
            scores = scores + bias * scales

        if self.mode == 'linear':
            # Linear attention: no softmax, just normalize
            q_norm = F.elu(q) + 1
            k_norm = F.elu(k) + 1
            kv = torch.matmul(k_norm.transpose(-2, -1), v)  # (B, H, D, D)
            out = torch.matmul(q_norm, kv)  # (B, H, S, D)
            denom = torch.matmul(q_norm, k_norm.transpose(-2, -1).sum(dim=-1, keepdim=True))
            out = out / (denom + 1e-8)
        else:
            attn = F.softmax(scores, dim=-1)
            out = torch.matmul(attn, v)

        out = out.transpose(1, 2).contiguous().reshape(B, S, E)
        return self.out_proj(out)


class GrokTransformer(nn.Module):
    def __init__(self, vocab_size, embed_dim, num_heads, num_layers,
                 mode='dense', padic_bias=None):
        super().__init__()
        self.tok_embed = nn.Embedding(vocab_size, embed_dim)
        self.pos_embed = nn.Embedding(3, embed_dim)  # 3 positions: a, b, =
        self.mode = mode

        self.layers = nn.ModuleList([
            nn.ModuleDict({
                'attn': Attention(embed_dim, num_heads, mode, padic_bias),
                'ln1': nn.LayerNorm(embed_dim),
                'mlp': nn.Sequential(
                    nn.Linear(embed_dim, embed_dim * 4),
                    nn.GELU(),
                    nn.Linear(embed_dim * 4, embed_dim),
                ),
                'ln2': nn.LayerNorm(embed_dim),
            })
            for _ in range(num_layers)
        ])
        self.ln_final = nn.LayerNorm(embed_dim)
        self.unembed = nn.Linear(embed_dim, vocab_size, bias=False)

    def forward(self, tokens):
        """
        tokens: (B, 2) — [a, b]
        Returns: logits (B, vocab_size) at the = position
        """
        B = tokens.shape[0]
        eq_token = torch.full((B, 1), P, device=tokens.device, dtype=tokens.dtype)
        full_seq = torch.cat([tokens, eq_token], dim=1)  # (B, 3)

        pos = torch.arange(3, device=tokens.device).unsqueeze(0).expand(B, 3)
        x = self.tok_embed(full_seq) + self.pos_embed(pos)

        for layer in self.layers:
            h = layer['ln1'](x)
            if self.mode == 'ultrametric':
                h = layer['attn'](h, input_tokens=full_seq)
            else:
                h = layer['attn'](h)
            x = x + h
            x = x + layer['mlp'](layer['ln2'](x))

        x = self.ln_final(x)
        logits = self.unembed(x[:, -1, :])  # predict at = position
        return logits


# ============================================================
# TRAINING
# ============================================================

def train_model(mode, padic_bias=None, steps=STEPS, seed=SEED):
    torch.manual_seed(seed)
    train_pairs, train_labels, test_pairs, test_labels = make_dataset()

    vocab_size = P + 1  # 0..112 + = token
    model = GrokTransformer(vocab_size, EMBED_DIM, NUM_HEADS, NUM_LAYERS,
                            mode=mode, padic_bias=padic_bias)
    optimizer = torch.optim.AdamW(model.parameters(), lr=LR, weight_decay=WD)

    n_params = sum(p.numel() for p in model.parameters())
    print(f"  [{mode}] params: {n_params:,}")

    history = {'train_acc': [], 'test_acc': [], 'train_loss': [], 'step': []}
    grok_step = None

    for step in range(steps):
        model.train()
        logits = model(train_pairs)
        loss = F.cross_entropy(logits, train_labels)

        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

        if step % LOG_EVERY == 0 or step == steps - 1:
            model.eval()
            with torch.no_grad():
                train_preds = model(train_pairs).argmax(dim=-1)
                train_acc = (train_preds == train_labels).float().mean().item()

                test_preds = model(test_pairs).argmax(dim=-1)
                test_acc = (test_preds == test_labels).float().mean().item()

            history['step'].append(step)
            history['train_acc'].append(train_acc)
            history['test_acc'].append(test_acc)
            history['train_loss'].append(loss.item())

            if grok_step is None and test_acc >= GROK_THRESHOLD:
                grok_step = step
                print(f"  [{mode}] 🧠 GROKKED at step {step}! "
                      f"test_acc={test_acc:.3f}")

            if step % (LOG_EVERY * 10) == 0:
                print(f"  [{mode}] step={step:>6} | loss={loss.item():.4f} | "
                      f"train={train_acc:.3f} | test={test_acc:.3f}")

    return history, grok_step


# ============================================================
# MAIN
# ============================================================

def main():
    print("=" * 70)
    print("  GROKKING EXPERIMENT: (a + b) mod 113")
    print(f"  {FRAC_TRAIN:.0%} train | {1-FRAC_TRAIN:.0%} test | "
          f"embed={EMBED_DIM} | heads={NUM_HEADS} | wd={WD}")
    print(f"  p-adic prime = {P_ADIC_PRIME}")
    print("=" * 70)

    # Build p-adic bias matrix
    print("\nBuilding p-adic bias matrix...")
    padic_bias = build_padic_bias_matrix(P + 1, P_ADIC_PRIME)
    print(f"  Shape: {padic_bias.shape}, "
          f"mean valuation: {padic_bias.mean():.2f}, "
          f"max: {padic_bias.max():.2f}")

    results = {}

    # 1. Dense baseline
    print("\n--- Dense Attention ---")
    t0 = time.time()
    h_dense, grok_dense = train_model('dense')
    t_dense = time.time() - t0
    results['dense'] = {
        'history': h_dense, 'grok_step': grok_dense,
        'time': round(t_dense, 1)
    }
    print(f"  Time: {t_dense:.1f}s | Grok step: {grok_dense or 'DID NOT GROK'}")

    # 2. Ultrametric
    print("\n--- Ultrametric Attention (p-adic bias) ---")
    t0 = time.time()
    h_ultra, grok_ultra = train_model('ultrametric', padic_bias=padic_bias)
    t_ultra = time.time() - t0
    results['ultrametric'] = {
        'history': h_ultra, 'grok_step': grok_ultra,
        'time': round(t_ultra, 1)
    }
    print(f"  Time: {t_ultra:.1f}s | Grok step: {grok_ultra or 'DID NOT GROK'}")

    # 3. Linear attention
    print("\n--- Linear Attention ---")
    t0 = time.time()
    h_linear, grok_linear = train_model('linear')
    t_linear = time.time() - t0
    results['linear'] = {
        'history': h_linear, 'grok_step': grok_linear,
        'time': round(t_linear, 1)
    }
    print(f"  Time: {t_linear:.1f}s | Grok step: {grok_linear or 'DID NOT GROK'}")

    # Summary
    print("\n" + "=" * 70)
    print("  GROKKING RESULTS")
    print("=" * 70)
    print(f"  {'Mode':<20} | {'Grok Step':>10} | {'Final Test Acc':>15} | {'Time':>8}")
    print("-" * 65)
    for mode in ['dense', 'ultrametric', 'linear']:
        r = results[mode]
        gs = r['grok_step'] or 'NEVER'
        fa = r['history']['test_acc'][-1]
        t = r['time']
        print(f"  {mode:<20} | {str(gs):>10} | {fa:>14.3f} | {t:>7.1f}s")

    if grok_ultra and grok_dense:
        ratio = grok_dense / grok_ultra
        print(f"\n  Ultrametric groks {ratio:.1f}× faster than dense!")
    elif grok_ultra and not grok_dense:
        print(f"\n  Ultrametric groks but dense doesn't! p-adic bias wins.")
    elif grok_dense and not grok_ultra:
        print(f"\n  Dense groks but ultrametric doesn't. Bias may hurt.")
    else:
        print(f"\n  Neither grokked in {STEPS} steps. Try more steps or tune WD.")

    # Save
    # Convert for JSON serialization
    save_results = {}
    for mode, r in results.items():
        save_results[mode] = {
            'grok_step': r['grok_step'],
            'time': r['time'],
            'final_train_acc': r['history']['train_acc'][-1],
            'final_test_acc': r['history']['test_acc'][-1],
            'steps': r['history']['step'],
            'train_acc': r['history']['train_acc'],
            'test_acc': r['history']['test_acc'],
        }

    with open("grokking_results.json", "w") as f:
        json.dump(save_results, f, indent=2)
    print("\n✅ Saved to grokking_results.json")

    # Plot (if matplotlib available)
    try:
        import matplotlib
        matplotlib.use('Agg')
        import matplotlib.pyplot as plt

        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

        colors = {'dense': '#4A90D9', 'ultrametric': '#E74C3C', 'linear': '#2ECC71'}
        for mode in ['dense', 'ultrametric', 'linear']:
            h = results[mode]['history']
            ax1.plot(h['step'], h['train_acc'], color=colors[mode],
                     alpha=0.4, linestyle='--')
            ax1.plot(h['step'], h['test_acc'], color=colors[mode],
                     label=f"{mode} (test)", linewidth=2)

        ax1.set_xlabel('Training Steps')
        ax1.set_ylabel('Accuracy')
        ax1.set_title(f'Grokking: (a + b) mod {P}')
        ax1.legend()
        ax1.set_ylim(-0.05, 1.05)
        ax1.axhline(y=GROK_THRESHOLD, color='gray', linestyle=':', alpha=0.5)
        ax1.grid(True, alpha=0.3)

        for mode in ['dense', 'ultrametric', 'linear']:
            h = results[mode]['history']
            ax2.plot(h['step'], h['train_loss'], color=colors[mode],
                     label=mode, linewidth=2)

        ax2.set_xlabel('Training Steps')
        ax2.set_ylabel('Loss')
        ax2.set_title('Training Loss')
        ax2.legend()
        ax2.set_yscale('log')
        ax2.grid(True, alpha=0.3)

        plt.tight_layout()
        plt.savefig('grokking_curves.png', dpi=150, bbox_inches='tight')
        print("📊 Saved grokking_curves.png")
    except ImportError:
        print("(matplotlib not available — skipping plot)")


if __name__ == "__main__":
    main()
