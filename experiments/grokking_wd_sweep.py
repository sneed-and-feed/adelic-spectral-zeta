"""
Grokking v2.2: Weight Decay Sweep for a + b*c mod 59
Finds the Goldilocks WD where softmax attention groks AND stays grokked.

Known data points:
  WD=0.3 → memorizes, never groks (50K steps)
  WD=1.0 → groks at 3500 then catastrophically forgets

Sweep: WD ∈ {0.5, 0.6, 0.7, 0.8, 1.0}
Models: Dense + Ultrametric only (linear already groks at WD=0.3)
Steps: 80K per model (enough for late grokking)

Colab A100: ~30-40 min total.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
import math
import json
import time
from itertools import product as cart_product

DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"Device: {DEVICE}")
if DEVICE.type == 'cuda':
    print(f"GPU: {torch.cuda.get_device_name()}")

# ============================================================
# CONFIG
# ============================================================

P = 59
FRAC_TRAIN = 0.3
EMBED_DIM = 128
NUM_HEADS = 4
NUM_LAYERS = 2
LR = 1e-3
STEPS = 80_000
BATCH_SIZE = 4096
LOG_EVERY = 200
GROK_THRESHOLD = 0.95
SEED = 42
SEQ_LEN = 6

VOCAB_SIZE = P + 3
TOK_PLUS = P
TOK_MULT = P + 1
TOK_EQ = P + 2

# THE SWEEP
WD_VALUES = [0.5, 0.6, 0.7, 0.8, 1.0]
MODES = ['dense', 'ultrametric']


# ============================================================
# DATA (same as v2)
# ============================================================

def make_dataset(p=P, frac_train=FRAC_TRAIN, seed=SEED):
    torch.manual_seed(seed)
    vals = list(range(p))
    triples = torch.tensor([(a, b, c) for a, b, c in cart_product(vals, repeat=3)])
    labels = (triples[:, 0] + triples[:, 1] * triples[:, 2]) % p
    n = len(triples)
    seqs = torch.zeros(n, SEQ_LEN, dtype=torch.long)
    seqs[:, 0] = triples[:, 0]
    seqs[:, 1] = TOK_PLUS
    seqs[:, 2] = triples[:, 1]
    seqs[:, 3] = TOK_MULT
    seqs[:, 4] = triples[:, 2]
    seqs[:, 5] = TOK_EQ
    perm = torch.randperm(n)
    split = int(n * frac_train)
    train_idx, test_idx = perm[:split], perm[split:]
    return (seqs[train_idx], labels[train_idx],
            seqs[test_idx], labels[test_idx])


# ============================================================
# TREE DISTANCE BIAS (same as v2)
# ============================================================

def tree_distance_matrix(n, p_ary=2):
    depth = math.ceil(math.log2(max(n, 2)))
    dist = torch.zeros(n, n)
    for i in range(n):
        for j in range(n):
            if i == j:
                dist[i, j] = depth
                continue
            for k in range(1, depth + 1):
                if (i >> k) == (j >> k):
                    dist[i, j] = depth - k
                    break
    dist = (dist - dist.mean()) / (dist.std() + 1e-8)
    return dist


# ============================================================
# MODELS (same as v2)
# ============================================================

class Attention(nn.Module):
    def __init__(self, embed_dim, num_heads, mode='dense', tree_bias=None):
        super().__init__()
        self.embed_dim = embed_dim
        self.num_heads = num_heads
        self.head_dim = embed_dim // num_heads
        self.mode = mode
        self.qkv = nn.Linear(embed_dim, 3 * embed_dim)
        self.out_proj = nn.Linear(embed_dim, embed_dim)
        if mode == 'ultrametric' and tree_bias is not None:
            self.register_buffer('tree_bias', tree_bias)
            self.bias_scale = nn.Parameter(torch.ones(num_heads) * 0.1)

    def forward(self, x):
        B, S, E = x.shape
        qkv = self.qkv(x).reshape(B, S, 3, self.num_heads, self.head_dim)
        q, k, v = qkv.unbind(dim=2)
        q, k, v = q.transpose(1, 2), k.transpose(1, 2), v.transpose(1, 2)
        scale = 1.0 / math.sqrt(self.head_dim)
        scores = torch.matmul(q, k.transpose(-2, -1)) * scale
        if self.mode == 'ultrametric':
            bias = self.tree_bias[:S, :S].unsqueeze(0).unsqueeze(0)
            scales = self.bias_scale.view(1, self.num_heads, 1, 1)
            scores = scores + bias * scales
        attn = F.softmax(scores, dim=-1)
        out = torch.matmul(attn, v)
        out = out.transpose(1, 2).contiguous().reshape(B, S, E)
        return self.out_proj(out)


class GrokTransformer(nn.Module):
    def __init__(self, vocab_size, embed_dim, num_heads, num_layers,
                 mode='dense', tree_bias=None):
        super().__init__()
        self.tok_embed = nn.Embedding(vocab_size, embed_dim)
        self.pos_embed = nn.Embedding(SEQ_LEN, embed_dim)
        self.layers = nn.ModuleList([
            nn.ModuleDict({
                'attn': Attention(embed_dim, num_heads, mode, tree_bias),
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
        B, S = tokens.shape
        pos = torch.arange(S, device=tokens.device).unsqueeze(0).expand(B, S)
        x = self.tok_embed(tokens) + self.pos_embed(pos)
        for layer in self.layers:
            h = layer['ln1'](x)
            h = layer['attn'](h)
            x = x + h
            x = x + layer['mlp'](layer['ln2'](x))
        x = self.ln_final(x)
        return self.unembed(x[:, -1, :])


# ============================================================
# TRAINING
# ============================================================

def train_model(mode, wd, tree_bias=None, steps=STEPS, seed=SEED):
    torch.manual_seed(seed)
    train_seqs, train_labels, test_seqs, test_labels = make_dataset()
    train_seqs = train_seqs.to(DEVICE)
    train_labels = train_labels.to(DEVICE)
    test_seqs = test_seqs.to(DEVICE)
    test_labels = test_labels.to(DEVICE)
    n_train = len(train_seqs)

    model = GrokTransformer(
        VOCAB_SIZE, EMBED_DIM, NUM_HEADS, NUM_LAYERS,
        mode=mode, tree_bias=tree_bias
    ).to(DEVICE)

    optimizer = torch.optim.AdamW(model.parameters(), lr=LR, weight_decay=wd)

    history = {'step': [], 'train_acc': [], 'test_acc': [], 'train_loss': []}
    grok_step = None
    stable_grok_step = None  # step where test_acc stays > 0.95 for 2000+ steps
    grok_streak = 0

    for step in range(steps):
        model.train()
        idx = torch.randint(0, n_train, (BATCH_SIZE,), device=DEVICE)
        logits = model(train_seqs[idx])
        loss = F.cross_entropy(logits, train_labels[idx])
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

        if step % LOG_EVERY == 0 or step == steps - 1:
            model.eval()
            with torch.no_grad():
                sub = min(8192, n_train)
                train_acc = (model(train_seqs[:sub]).argmax(-1) ==
                            train_labels[:sub]).float().mean().item()
                sub_t = min(8192, len(test_seqs))
                test_acc = (model(test_seqs[:sub_t]).argmax(-1) ==
                           test_labels[:sub_t]).float().mean().item()

            history['step'].append(step)
            history['train_acc'].append(train_acc)
            history['test_acc'].append(test_acc)
            history['train_loss'].append(loss.item())

            if grok_step is None and test_acc >= GROK_THRESHOLD:
                grok_step = step

            # Track stable grokking (stays above threshold for 2000+ steps)
            if test_acc >= GROK_THRESHOLD:
                grok_streak += LOG_EVERY
                if stable_grok_step is None and grok_streak >= 2000:
                    stable_grok_step = step - 2000
            else:
                grok_streak = 0

            if step % (LOG_EVERY * 20) == 0:
                tag = "🔥" if test_acc > GROK_THRESHOLD else "  "
                print(f"  {tag} [{mode}|wd={wd}] step={step:>6} | "
                      f"loss={loss.item():.4f} | "
                      f"train={train_acc:.3f} | test={test_acc:.3f}")

    # Stability: fraction of last 25% steps above threshold
    quarter = len(history['test_acc']) // 4
    if quarter > 0:
        tail = history['test_acc'][-quarter:]
        frac_above = sum(1 for x in tail if x >= GROK_THRESHOLD) / len(tail)
    else:
        frac_above = 0.0

    return {
        'grok_step': grok_step,
        'stable_grok_step': stable_grok_step,
        'final_test_acc': history['test_acc'][-1],
        'final_train_acc': history['train_acc'][-1],
        'frac_stable': frac_above,
        'history': history,
    }


# ============================================================
# MAIN
# ============================================================

def main():
    print("=" * 80)
    print(f"  WEIGHT DECAY SWEEP: a + b*c mod {P}")
    print(f"  WD ∈ {WD_VALUES}")
    print(f"  Modes: {MODES}")
    print(f"  {STEPS:,} steps × {len(WD_VALUES)} WDs × {len(MODES)} modes "
          f"= {STEPS * len(WD_VALUES) * len(MODES):,} total steps")
    print("=" * 80)

    tree_bias = tree_distance_matrix(SEQ_LEN).to(DEVICE)
    all_results = {}

    for wd in WD_VALUES:
        print(f"\n{'='*60}")
        print(f"  WD = {wd}")
        print(f"{'='*60}")

        for mode in MODES:
            print(f"\n  --- {mode} | WD={wd} ---")
            t0 = time.time()
            tb = tree_bias if mode == 'ultrametric' else None
            result = train_model(mode, wd, tree_bias=tb)
            elapsed = time.time() - t0

            key = f"{mode}_wd{wd}"
            all_results[key] = result
            all_results[key]['time'] = round(elapsed, 1)

            gs = result['grok_step'] or 'NEVER'
            sgs = result['stable_grok_step'] or 'NEVER'
            print(f"  [{mode}|wd={wd}] Grok={gs} | Stable={sgs} | "
                  f"Final test={result['final_test_acc']:.3f} | "
                  f"Frac stable={result['frac_stable']:.2f} | "
                  f"Time={elapsed:.0f}s")

    # Summary table
    print("\n" + "=" * 90)
    print("  WEIGHT DECAY SWEEP RESULTS")
    print("=" * 90)
    print(f"  {'Mode':<14} | {'WD':>5} | {'Grok':>8} | {'Stable':>8} | "
          f"{'Test Acc':>9} | {'% Stable':>9} | {'Time':>7}")
    print("-" * 80)
    for wd in WD_VALUES:
        for mode in MODES:
            key = f"{mode}_wd{wd}"
            r = all_results[key]
            gs = r['grok_step'] or 'NEVER'
            sgs = r['stable_grok_step'] or 'NEVER'
            print(f"  {mode:<14} | {wd:>5.1f} | {str(gs):>8} | {str(sgs):>8} | "
                  f"{r['final_test_acc']:>8.3f} | {r['frac_stable']:>8.1%} | "
                  f"{r['time']:>6.0f}s")
        print("-" * 80)

    # Save
    save = {}
    for key, r in all_results.items():
        save[key] = {k: v for k, v in r.items() if k != 'history'}
        save[key]['steps'] = r['history']['step']
        save[key]['test_acc'] = r['history']['test_acc']
        save[key]['train_acc'] = r['history']['train_acc']
    with open("grokking_wd_sweep.json", "w") as f:
        json.dump(save, f, indent=2)
    print(f"\n✅ Saved to grokking_wd_sweep.json")

    # Plot
    try:
        import matplotlib
        matplotlib.use('Agg')
        import matplotlib.pyplot as plt

        fig, axes = plt.subplots(1, 2, figsize=(16, 6))

        for ax, mode in zip(axes, MODES):
            for wd in WD_VALUES:
                key = f"{mode}_wd{wd}"
                r = all_results[key]
                h = r['history']
                ax.plot(h['step'], h['test_acc'],
                       label=f"WD={wd}", linewidth=1.5, alpha=0.8)
            ax.set_xlabel('Steps')
            ax.set_ylabel('Test Accuracy')
            ax.set_title(f'{mode.capitalize()}: a + b*c mod {P}')
            ax.legend()
            ax.set_ylim(-0.05, 1.05)
            ax.axhline(y=GROK_THRESHOLD, color='gray', linestyle=':', alpha=0.5)
            ax.grid(True, alpha=0.3)

        plt.suptitle('Weight Decay Sweep — Finding the Grokking Sweet Spot',
                     fontsize=14, fontweight='bold')
        plt.tight_layout()
        plt.savefig('grokking_wd_sweep.png', dpi=150, bbox_inches='tight')
        print("📊 Saved grokking_wd_sweep.png")
    except ImportError:
        print("(matplotlib not available — skipping plot)")


if __name__ == "__main__":
    main()
