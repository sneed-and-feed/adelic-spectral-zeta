"""
Grokking v3 (TERNARY): Dynamic Ultrametric Attention + Polynomial Evaluation

Same as v3 but with a TERNARY (p=3) tree instead of binary (p=2).
Run on GPU 2 while GPU 1 runs the binary version.

Task: Degree-3 polynomial in Horner's form
  p(x) = a₀ + x·(a₁ + x·(a₂ + x·a₃))  mod 11

Sequence: [a₃, x, a₂, x, a₁, x, a₀, =]  (8 tokens)

Ternary tree over 8 positions (padded to 9):
  Depth 1: {a₃,x,a₂} {x,a₁,x} {a₀,=,pad}
  Depth 0: all attend

4-way comparison:
  1. Dense (standard softmax)
  2. Static ultrametric (fixed TERNARY tree bias)
  3. Dynamic ultrametric (self-attention-regulated ternary depth)
  4. Linear (no softmax baseline)

Colab A100: ~15-20 min.
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

P = 11              # prime modulus  (11⁵ = 161K triples)
DEGREE = 3          # polynomial degree
FRAC_TRAIN = 0.3
EMBED_DIM = 128
NUM_HEADS = 4
NUM_LAYERS = 2
LR = 1e-3
WD = 0.8            # from sweep: high enough to push toward grokking
STEPS = 60_000
BATCH_SIZE = 4096
LOG_EVERY = 200
GROK_THRESHOLD = 0.95
SEED = 42
SEQ_LEN = 2 * (DEGREE + 1)  # [a₃,x, a₂,x, a₁,x, a₀,=] = 8
P_ARY = 3                   # TERNARY tree (vs binary in v3_poly.py)

# Vocab: 0..P-1 = numbers, P = '=' token
VOCAB_SIZE = P + 1
TOK_EQ = P


# ============================================================
# DATA: Horner's form polynomial
# ============================================================

def horner_eval(coeffs, x, p):
    """Evaluate polynomial via Horner's method: a₀ + x(a₁ + x(a₂ + x·a₃))."""
    result = 0
    for c in reversed(coeffs):
        result = (result * x + c) % p
    return result


def make_dataset(p=P, degree=DEGREE, frac_train=FRAC_TRAIN, seed=SEED):
    """
    All (a₀, a₁, ..., a_d, x) tuples → polynomial mod p.
    Sequence in Horner's form: [a_d, x, a_{d-1}, x, ..., a₁, x, a₀, =]
    """
    torch.manual_seed(seed)

    n_vars = degree + 2  # d+1 coefficients + x
    vals = list(range(p))

    # Generate all tuples: (a₀, a₁, ..., a_d, x)
    all_tuples = list(cart_product(vals, repeat=n_vars))
    n = len(all_tuples)
    print(f"  Dataset: {n:,} total | {degree}rd-degree poly mod {p}")

    tuples_t = torch.tensor(all_tuples)
    # tuples_t[:, :degree+1] = coefficients a₀..a_d
    # tuples_t[:, -1] = x
    coeffs = tuples_t[:, :degree+1]  # (N, d+1)
    x_vals = tuples_t[:, -1]         # (N,)

    # Compute labels via Horner's method
    labels = torch.zeros(n, dtype=torch.long)
    for i in range(n):
        labels[i] = horner_eval(coeffs[i].tolist(), x_vals[i].item(), p)

    # Build sequences in Horner's form: [a_d, x, a_{d-1}, x, ..., a₁, x, a₀, =]
    seqs = torch.zeros(n, SEQ_LEN, dtype=torch.long)
    for j in range(degree + 1):
        coeff_idx = degree - j  # go from a_d down to a_0
        pos = 2 * j
        if pos < SEQ_LEN - 1:
            seqs[:, pos] = coeffs[:, coeff_idx]
            if j < degree:
                seqs[:, pos + 1] = x_vals  # x interleaved
            else:
                seqs[:, pos + 1] = TOK_EQ  # = at the end

    # Split
    perm = torch.randperm(n)
    split = int(n * frac_train)
    train_idx, test_idx = perm[:split], perm[split:]

    return (seqs[train_idx], labels[train_idx],
            seqs[test_idx], labels[test_idx])


# ============================================================
# TREE DISTANCE BIAS
# ============================================================

def tree_distance_matrix(n, p_ary=P_ARY):
    """p-ary tree pairwise similarity for n positions."""
    depth = math.ceil(math.log(max(n, 2), p_ary))
    dist = torch.zeros(n, n)
    for i in range(n):
        for j in range(n):
            if i == j:
                dist[i, j] = depth
                continue
            for k in range(1, depth + 1):
                if (i // (p_ary ** k)) == (j // (p_ary ** k)):
                    dist[i, j] = depth - k
                    break
    dist = (dist - dist.mean()) / (dist.std() + 1e-8)
    return dist


# ============================================================
# ATTENTION VARIANTS
# ============================================================

class DenseAttention(nn.Module):
    def __init__(self, embed_dim, num_heads):
        super().__init__()
        self.num_heads = num_heads
        self.head_dim = embed_dim // num_heads
        self.qkv = nn.Linear(embed_dim, 3 * embed_dim)
        self.out_proj = nn.Linear(embed_dim, embed_dim)

    def forward(self, x):
        B, S, E = x.shape
        qkv = self.qkv(x).reshape(B, S, 3, self.num_heads, self.head_dim)
        q, k, v = qkv.unbind(2)
        q, k, v = q.transpose(1, 2), k.transpose(1, 2), v.transpose(1, 2)
        scale = 1.0 / math.sqrt(self.head_dim)
        scores = torch.matmul(q, k.transpose(-2, -1)) * scale
        attn = F.softmax(scores, dim=-1)
        out = torch.matmul(attn, v)
        out = out.transpose(1, 2).contiguous().reshape(B, S, E)
        return self.out_proj(out)


class StaticUltrametricAttention(nn.Module):
    """Fixed tree-distance bias (same as v2)."""
    def __init__(self, embed_dim, num_heads, tree_bias):
        super().__init__()
        self.num_heads = num_heads
        self.head_dim = embed_dim // num_heads
        self.qkv = nn.Linear(embed_dim, 3 * embed_dim)
        self.out_proj = nn.Linear(embed_dim, embed_dim)
        self.register_buffer('tree_bias', tree_bias)
        self.bias_scale = nn.Parameter(torch.ones(num_heads) * 0.1)

    def forward(self, x):
        B, S, E = x.shape
        qkv = self.qkv(x).reshape(B, S, 3, self.num_heads, self.head_dim)
        q, k, v = qkv.unbind(2)
        q, k, v = q.transpose(1, 2), k.transpose(1, 2), v.transpose(1, 2)
        scale = 1.0 / math.sqrt(self.head_dim)
        scores = torch.matmul(q, k.transpose(-2, -1)) * scale
        bias = self.tree_bias[:S, :S].unsqueeze(0).unsqueeze(0)
        scales = self.bias_scale.view(1, self.num_heads, 1, 1)
        scores = scores + bias * scales
        attn = F.softmax(scores, dim=-1)
        out = torch.matmul(attn, v)
        out = out.transpose(1, 2).contiguous().reshape(B, S, E)
        return self.out_proj(out)


class DynamicUltrametricAttention(nn.Module):
    """
    Self-attention-regulated tree depth.

    Each query position gets a per-head "depth gate" in [0, 1] that
    controls how strongly the tree bias is applied.
      gate → 0: ignore tree (dense attention)
      gate → 1: full tree bias (maximally hierarchical)

    The gate is computed from the input via a small self-attention:
      depth_attn(x) → per-position, per-head depth gate
    """
    def __init__(self, embed_dim, num_heads, tree_bias):
        super().__init__()
        self.num_heads = num_heads
        self.head_dim = embed_dim // num_heads
        self.qkv = nn.Linear(embed_dim, 3 * embed_dim)
        self.out_proj = nn.Linear(embed_dim, embed_dim)
        self.register_buffer('tree_bias', tree_bias)

        # Depth controller: self-attention → per-position per-head gate
        # Small 1-head self-attention + projection
        self.depth_q = nn.Linear(embed_dim, embed_dim // 4)
        self.depth_k = nn.Linear(embed_dim, embed_dim // 4)
        self.depth_proj = nn.Linear(embed_dim // 4, num_heads)
        # Learnable base scale (how strong tree bias is when gate=1)
        self.bias_amplitude = nn.Parameter(torch.ones(num_heads) * 0.5)

    def forward(self, x):
        B, S, E = x.shape

        # === Depth controller ===
        dq = self.depth_q(x)  # (B, S, E//4)
        dk = self.depth_k(x)  # (B, S, E//4)
        depth_attn = torch.matmul(dq, dk.transpose(-2, -1))  # (B, S, S)
        depth_attn = depth_attn / math.sqrt(dq.shape[-1])
        depth_attn = F.softmax(depth_attn, dim=-1)
        depth_ctx = torch.matmul(depth_attn, dq)  # (B, S, E//4)
        depth_gate = torch.sigmoid(self.depth_proj(depth_ctx))  # (B, S, H) in [0,1]

        # === Main attention ===
        qkv = self.qkv(x).reshape(B, S, 3, self.num_heads, self.head_dim)
        q, k, v = qkv.unbind(2)
        q, k, v = q.transpose(1, 2), k.transpose(1, 2), v.transpose(1, 2)
        scale = 1.0 / math.sqrt(self.head_dim)
        scores = torch.matmul(q, k.transpose(-2, -1)) * scale  # (B, H, S, S)

        # === Dynamic tree bias ===
        # gate: (B, S, H) → (B, H, S, 1) — per-query depth
        gate = depth_gate.permute(0, 2, 1).unsqueeze(-1)  # (B, H, S, 1)
        amp = self.bias_amplitude.view(1, self.num_heads, 1, 1)
        bias = self.tree_bias[:S, :S].unsqueeze(0).unsqueeze(0)  # (1, 1, S, S)
        # Each query position i applies tree bias scaled by its own gate
        scores = scores + bias * gate * amp

        attn = F.softmax(scores, dim=-1)
        out = torch.matmul(attn, v)
        out = out.transpose(1, 2).contiguous().reshape(B, S, E)
        return self.out_proj(out)


class LinearAttention(nn.Module):
    def __init__(self, embed_dim, num_heads):
        super().__init__()
        self.num_heads = num_heads
        self.head_dim = embed_dim // num_heads
        self.qkv = nn.Linear(embed_dim, 3 * embed_dim)
        self.out_proj = nn.Linear(embed_dim, embed_dim)

    def forward(self, x):
        B, S, E = x.shape
        qkv = self.qkv(x).reshape(B, S, 3, self.num_heads, self.head_dim)
        q, k, v = qkv.unbind(2)
        q, k, v = q.transpose(1, 2), k.transpose(1, 2), v.transpose(1, 2)
        q_norm = F.elu(q) + 1
        k_norm = F.elu(k) + 1
        kv = torch.matmul(k_norm.transpose(-2, -1), v)
        out = torch.matmul(q_norm, kv)
        denom = q_norm @ k_norm.transpose(-2, -1).sum(dim=-1, keepdim=True)
        out = out / (denom + 1e-8)
        out = out.transpose(1, 2).contiguous().reshape(B, S, E)
        return self.out_proj(out)


# ============================================================
# TRANSFORMER
# ============================================================

ATTN_CLASSES = {
    'dense': DenseAttention,
    'static_ultra': StaticUltrametricAttention,
    'dynamic_ultra': DynamicUltrametricAttention,
    'linear': LinearAttention,
}

class GrokTransformer(nn.Module):
    def __init__(self, vocab_size, embed_dim, num_heads, num_layers,
                 mode='dense', tree_bias=None):
        super().__init__()
        self.tok_embed = nn.Embedding(vocab_size, embed_dim)
        self.pos_embed = nn.Embedding(SEQ_LEN, embed_dim)

        self.layers = nn.ModuleList()
        for _ in range(num_layers):
            attn_cls = ATTN_CLASSES[mode]
            if mode in ('static_ultra', 'dynamic_ultra'):
                attn = attn_cls(embed_dim, num_heads, tree_bias)
            else:
                attn = attn_cls(embed_dim, num_heads)

            self.layers.append(nn.ModuleDict({
                'attn': attn,
                'ln1': nn.LayerNorm(embed_dim),
                'mlp': nn.Sequential(
                    nn.Linear(embed_dim, embed_dim * 4),
                    nn.GELU(),
                    nn.Linear(embed_dim * 4, embed_dim),
                ),
                'ln2': nn.LayerNorm(embed_dim),
            }))
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
        return self.unembed(x[:, -1, :])  # predict at = position


# ============================================================
# TRAINING
# ============================================================

def train_model(mode, tree_bias=None, steps=STEPS, seed=SEED):
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

    optimizer = torch.optim.AdamW(model.parameters(), lr=LR, weight_decay=WD)
    n_params = sum(p.numel() for p in model.parameters())
    print(f"  [{mode}] params={n_params:,} | train={n_train:,}")

    history = {'step': [], 'train_acc': [], 'test_acc': [], 'train_loss': []}
    grok_step = None
    stable_grok_step = None
    grok_streak = 0

    # For dynamic_ultra: track depth gate statistics
    gate_stats = []

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

            # Track depth gates for dynamic model
            if mode == 'dynamic_ultra' and step % (LOG_EVERY * 10) == 0:
                with torch.no_grad():
                    sample = train_seqs[:256]
                    for layer in model.layers:
                        attn = layer['attn']
                        dq = attn.depth_q(model.tok_embed(sample) +
                             model.pos_embed(torch.arange(SEQ_LEN, device=DEVICE).unsqueeze(0).expand(256, SEQ_LEN)))
                        dk = attn.depth_k(model.tok_embed(sample) +
                             model.pos_embed(torch.arange(SEQ_LEN, device=DEVICE).unsqueeze(0).expand(256, SEQ_LEN)))
                        da = F.softmax(torch.matmul(dq, dk.transpose(-2,-1)) / math.sqrt(dq.shape[-1]), dim=-1)
                        dc = torch.matmul(da, dq)
                        gate = torch.sigmoid(attn.depth_proj(dc))
                        gate_stats.append({
                            'step': step,
                            'mean': gate.mean().item(),
                            'std': gate.std().item(),
                            'per_head_mean': gate.mean(dim=(0,1)).tolist(),
                        })

            if grok_step is None and test_acc >= GROK_THRESHOLD:
                grok_step = step
                print(f"  [{mode}] 🧠 GROKKED at step {step}! test={test_acc:.3f}")

            if test_acc >= GROK_THRESHOLD:
                grok_streak += LOG_EVERY
                if stable_grok_step is None and grok_streak >= 2000:
                    stable_grok_step = step - 2000
                    print(f"  [{mode}] 🔒 STABLE GROK confirmed at step {stable_grok_step}!")
            else:
                grok_streak = 0

            if step % (LOG_EVERY * 15) == 0:
                tag = "🔥" if test_acc > GROK_THRESHOLD else "  "
                extra = ""
                if mode == 'dynamic_ultra' and gate_stats:
                    g = gate_stats[-1]
                    extra = f" | gate={g['mean']:.3f}±{g['std']:.3f}"
                print(f"  {tag} [{mode}] step={step:>6} | loss={loss.item():.4f} | "
                      f"train={train_acc:.3f} | test={test_acc:.3f}{extra}")

    quarter = len(history['test_acc']) // 4
    frac_stable = 0.0
    if quarter > 0:
        tail = history['test_acc'][-quarter:]
        frac_stable = sum(1 for x in tail if x >= GROK_THRESHOLD) / len(tail)

    return {
        'grok_step': grok_step,
        'stable_grok_step': stable_grok_step,
        'final_test_acc': history['test_acc'][-1],
        'frac_stable': frac_stable,
        'history': history,
        'gate_stats': gate_stats if mode == 'dynamic_ultra' else None,
    }


# ============================================================
# MAIN
# ============================================================

def main():
    total = P ** (DEGREE + 2)
    print("=" * 80)
    print(f"  GROKKING v3: Degree-{DEGREE} Polynomial mod {P} (Horner's Form)")
    print(f"  p(x) = a₀ + x·(a₁ + x·(a₂ + x·a₃))")
    print(f"  Sequence: [a₃, x, a₂, x, a₁, x, a₀, =]  ({SEQ_LEN} tokens)")
    print(f"  {total:,} total | {FRAC_TRAIN:.0%} train | "
          f"embed={EMBED_DIM} | heads={NUM_HEADS} | wd={WD}")
    print(f"  Device: {DEVICE}")
    print("=" * 80)

    tree_bias = tree_distance_matrix(SEQ_LEN, p_ary=P_ARY).to(DEVICE)
    print(f"\n  TERNARY tree bias ({SEQ_LEN}×{SEQ_LEN}, p={P_ARY}):")
    print(f"    Depth 1: {{a₃,x,a₂}} {{x,a₁,x}} {{a₀,=,pad}}")
    print(f"    Depth 0: all attend")

    modes = ['dense', 'static_ultra', 'dynamic_ultra', 'linear']
    results = {}

    for mode in modes:
        print(f"\n{'='*60}")
        print(f"  {mode.upper()}")
        print(f"{'='*60}")
        t0 = time.time()
        tb = tree_bias if 'ultra' in mode else None
        result = train_model(mode, tree_bias=tb)
        elapsed = time.time() - t0
        result['time'] = round(elapsed, 1)
        results[mode] = result

        gs = result['grok_step'] or 'NEVER'
        sgs = result['stable_grok_step'] or 'NEVER'
        print(f"\n  [{mode}] Grok={gs} | Stable={sgs} | "
              f"Final test={result['final_test_acc']:.3f} | "
              f"Frac stable={result['frac_stable']:.1%} | Time={elapsed:.0f}s")

    # Summary
    print("\n" + "=" * 85)
    print(f"  GROKKING v3: Degree-{DEGREE} Polynomial mod {P}")
    print("=" * 85)
    print(f"  {'Mode':<18} | {'Grok':>8} | {'Stable':>8} | "
          f"{'Test Acc':>9} | {'% Stable':>9} | {'Time':>7}")
    print("-" * 75)
    for mode in modes:
        r = results[mode]
        gs = r['grok_step'] or 'NEVER'
        sgs = r['stable_grok_step'] or 'NEVER'
        print(f"  {mode:<18} | {str(gs):>8} | {str(sgs):>8} | "
              f"{r['final_test_acc']:>8.3f} | {r['frac_stable']:>8.1%} | "
              f"{r['time']:>6.0f}s")

    # Dynamic gate analysis
    if results['dynamic_ultra']['gate_stats']:
        print(f"\n  Dynamic depth gate evolution:")
        for g in results['dynamic_ultra']['gate_stats'][-5:]:
            heads = ", ".join(f"h{i}={v:.2f}" for i, v in enumerate(g['per_head_mean']))
            print(f"    step={g['step']:>6} | mean={g['mean']:.3f} | {heads}")

    # Save
    save = {}
    for mode, r in results.items():
        save[mode] = {
            'grok_step': r['grok_step'],
            'stable_grok_step': r['stable_grok_step'],
            'final_test_acc': r['final_test_acc'],
            'frac_stable': r['frac_stable'],
            'time': r['time'],
            'steps': r['history']['step'],
            'test_acc': r['history']['test_acc'],
            'train_acc': r['history']['train_acc'],
        }
        if r.get('gate_stats'):
            save[mode]['gate_stats'] = r['gate_stats']
    with open("grokking_v3_ternary_results.json", "w") as f:
        json.dump(save, f, indent=2)
    print(f"\n✅ Saved to grokking_v3_ternary_results.json")

    # Plot
    try:
        import matplotlib
        matplotlib.use('Agg')
        import matplotlib.pyplot as plt

        fig, axes = plt.subplots(1, 3, figsize=(18, 5))
        colors = {
            'dense': '#4A90D9', 'static_ultra': '#E74C3C',
            'dynamic_ultra': '#9B59B6', 'linear': '#2ECC71'
        }

        for mode in modes:
            h = results[mode]['history']
            axes[0].plot(h['step'], h['test_acc'], color=colors[mode],
                        label=mode, linewidth=1.5, alpha=0.8)
        axes[0].set_xlabel('Steps')
        axes[0].set_ylabel('Test Accuracy')
        axes[0].set_title(f'Grokking: Degree-{DEGREE} Poly mod {P}')
        axes[0].legend()
        axes[0].set_ylim(-0.05, 1.05)
        axes[0].axhline(y=GROK_THRESHOLD, color='gray', linestyle=':', alpha=0.5)
        axes[0].grid(True, alpha=0.3)

        for mode in modes:
            h = results[mode]['history']
            axes[1].plot(h['step'], h['train_loss'], color=colors[mode],
                        label=mode, linewidth=1.5, alpha=0.8)
        axes[1].set_xlabel('Steps')
        axes[1].set_ylabel('Loss')
        axes[1].set_title('Training Loss')
        axes[1].legend()
        axes[1].set_yscale('log')
        axes[1].grid(True, alpha=0.3)

        # Gate evolution for dynamic model
        gs = results['dynamic_ultra'].get('gate_stats', [])
        if gs:
            steps_g = [g['step'] for g in gs]
            for hi in range(NUM_HEADS):
                vals = [g['per_head_mean'][hi] for g in gs]
                axes[2].plot(steps_g, vals, label=f'Head {hi}', linewidth=1.5)
            axes[2].set_xlabel('Steps')
            axes[2].set_ylabel('Depth Gate (0=dense, 1=tree)')
            axes[2].set_title('Dynamic Depth Gate per Head')
            axes[2].legend()
            axes[2].set_ylim(-0.05, 1.05)
            axes[2].grid(True, alpha=0.3)

        plt.suptitle(f'TERNARY Ultrametric Attention — p(x) mod {P}',
                     fontsize=14, fontweight='bold')
        plt.tight_layout()
        plt.savefig('grokking_v3_ternary_curves.png', dpi=150, bbox_inches='tight')
        print("📊 Saved grokking_v3_ternary_curves.png")
    except ImportError:
        print("(matplotlib not available — skipping plot)")


if __name__ == "__main__":
    main()
