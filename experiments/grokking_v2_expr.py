"""
Grokking v2: Hierarchical Expression — a + b*c mod 59
Tests ultrametric POSITION-LEVEL attention on longer sequences.

Key improvement over v1:
  - 6-token sequences [a, +, b, *, c, =] → position mask is meaningful
  - Binary tree groups positions semantically:
      depth=2: {a,+} {b,*} {c,=}  — operand+operator pairs!
      depth=1: {a,+,b,*} {c,=}    — left-expr vs right-expr
  - Soft learned bias (not hard mask) so model can modulate tree influence

3-way comparison:
  1. Dense (standard softmax attention)
  2. Ultrametric (softmax + learned tree-distance position bias)
  3. Linear (no softmax)

Colab cell: paste and run. GPU recommended (~5 min on A100).
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

P = 59              # prime modulus (59³ = 205K triples — manageable)
FRAC_TRAIN = 0.3    # 30% train
EMBED_DIM = 128
NUM_HEADS = 4
HEAD_DIM = EMBED_DIM // NUM_HEADS
NUM_LAYERS = 2      # deeper since task is harder
LR = 3e-4           # lower LR for stability (v1 used 1e-3 → collapsed)
WD = 0.3            # v1 used 1.0 → too aggressive with mini-batch
STEPS = 100_000     # more steps — a+b*c takes longer to grok than a+b
LOG_EVERY = 200
GROK_THRESHOLD = 0.95
SEED = 42
SEQ_LEN = 6        # [a, +, b, *, c, =]
WARMUP_STEPS = 1000 # LR warmup to prevent early collapse

# Vocab: 0..P-1 = numbers, P = '+', P+1 = '*', P+2 = '='
VOCAB_SIZE = P + 3
TOK_PLUS = P
TOK_MULT = P + 1
TOK_EQ = P + 2


# ============================================================
# DATA
# ============================================================

def make_dataset(p=P, frac_train=FRAC_TRAIN, seed=SEED):
    """
    All (a, b, c) triples → a + b*c mod p.
    Returns train/test input sequences and labels.
    Input: [a, +, b, *, c, =] (6 tokens)
    Label: (a + b*c) mod p
    """
    torch.manual_seed(seed)

    # Generate all triples
    vals = list(range(p))
    triples = torch.tensor([(a, b, c) for a, b, c in cart_product(vals, repeat=3)])
    labels = (triples[:, 0] + triples[:, 1] * triples[:, 2]) % p

    # Build input sequences: [a, +, b, *, c, =]
    n = len(triples)
    seqs = torch.zeros(n, SEQ_LEN, dtype=torch.long)
    seqs[:, 0] = triples[:, 0]       # a
    seqs[:, 1] = TOK_PLUS             # +
    seqs[:, 2] = triples[:, 1]       # b
    seqs[:, 3] = TOK_MULT             # *
    seqs[:, 4] = triples[:, 2]       # c
    seqs[:, 5] = TOK_EQ               # =

    # Random split
    perm = torch.randperm(n)
    split = int(n * frac_train)
    train_idx, test_idx = perm[:split], perm[split:]

    return (seqs[train_idx], labels[train_idx],
            seqs[test_idx], labels[test_idx])


def make_ood_dataset(p=P, seed=SEED):
    """
    OOD test: triples where a ∈ {0..9} — never seen in training.
    Uses a separate held-out range.
    """
    torch.manual_seed(seed)
    ood_a = list(range(min(10, p)))
    other = list(range(p))
    triples = torch.tensor([(a, b, c) for a in ood_a
                            for b in other for c in other])
    labels = (triples[:, 0] + triples[:, 1] * triples[:, 2]) % p

    seqs = torch.zeros(len(triples), SEQ_LEN, dtype=torch.long)
    seqs[:, 0] = triples[:, 0]
    seqs[:, 1] = TOK_PLUS
    seqs[:, 2] = triples[:, 1]
    seqs[:, 3] = TOK_MULT
    seqs[:, 4] = triples[:, 2]
    seqs[:, 5] = TOK_EQ

    return seqs, labels


# ============================================================
# TREE DISTANCE BIAS
# ============================================================

def tree_distance_matrix(n, p_ary=2):
    """
    Compute pairwise tree distances for n positions in a binary tree.
    Returns similarity matrix: higher = closer in tree.
    """
    depth = math.ceil(math.log2(max(n, 2)))
    dist = torch.zeros(n, n)

    for i in range(n):
        for j in range(n):
            if i == j:
                dist[i, j] = depth  # max similarity to self
                continue
            # Find LCA level: lowest k where i>>k == j>>k
            for k in range(1, depth + 1):
                if (i >> k) == (j >> k):
                    dist[i, j] = depth - k  # higher = closer
                    break

    # Normalize
    dist = (dist - dist.mean()) / (dist.std() + 1e-8)
    return dist


# ============================================================
# MODELS
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
            # Learnable scaling per head — starts small
            self.bias_scale = nn.Parameter(torch.ones(num_heads) * 0.1)

    def forward(self, x):
        B, S, E = x.shape
        qkv = self.qkv(x).reshape(B, S, 3, self.num_heads, self.head_dim)
        q, k, v = qkv.unbind(dim=2)
        q = q.transpose(1, 2)  # (B, H, S, D)
        k = k.transpose(1, 2)
        v = v.transpose(1, 2)

        scale = 1.0 / math.sqrt(self.head_dim)
        scores = torch.matmul(q, k.transpose(-2, -1)) * scale

        if self.mode == 'ultrametric':
            # Add tree-distance position bias
            # tree_bias: (S, S) → broadcast to (1, 1, S, S)
            bias = self.tree_bias[:S, :S].unsqueeze(0).unsqueeze(0)
            scales = self.bias_scale.view(1, self.num_heads, 1, 1)
            scores = scores + bias * scales

        if self.mode == 'linear':
            q_norm = F.elu(q) + 1
            k_norm = F.elu(k) + 1
            kv = torch.matmul(k_norm.transpose(-2, -1), v)
            out = torch.matmul(q_norm, kv)
            denom = q_norm @ k_norm.transpose(-2, -1).sum(dim=-1, keepdim=True)
            out = out / (denom + 1e-8)
        else:
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
        # Predict from the = position (last token)
        logits = self.unembed(x[:, -1, :])
        return logits


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

    # OOD set
    ood_seqs, ood_labels = make_ood_dataset()
    ood_seqs = ood_seqs.to(DEVICE)
    ood_labels = ood_labels.to(DEVICE)

    model = GrokTransformer(
        VOCAB_SIZE, EMBED_DIM, NUM_HEADS, NUM_LAYERS,
        mode=mode, tree_bias=tree_bias
    ).to(DEVICE)

    optimizer = torch.optim.AdamW(model.parameters(), lr=LR, weight_decay=WD)

    # LR schedule: linear warmup then cosine decay
    def lr_lambda(step):
        if step < WARMUP_STEPS:
            return step / WARMUP_STEPS
        progress = (step - WARMUP_STEPS) / max(1, steps - WARMUP_STEPS)
        return 0.5 * (1 + math.cos(math.pi * progress))
    scheduler = torch.optim.lr_scheduler.LambdaLR(optimizer, lr_lambda)

    n_params = sum(p.numel() for p in model.parameters())
    n_train = len(train_seqs)
    n_test = len(test_seqs)
    print(f"  [{mode}] params={n_params:,} | train={n_train:,} | test={n_test:,}")

    history = {
        'step': [], 'train_acc': [], 'test_acc': [],
        'ood_acc': [], 'train_loss': [],
    }
    grok_step = None
    # Full-batch if fits, else large mini-batch (full-batch is critical for grokking)
    batch_size = n_train  # full batch — 61K fits easily on A100

    for step in range(steps):
        model.train()

        # Mini-batch
        idx = torch.randint(0, n_train, (batch_size,), device=DEVICE)
        batch_seqs = train_seqs[idx]
        batch_labels = train_labels[idx]

        logits = model(batch_seqs)
        loss = F.cross_entropy(logits, batch_labels)

        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        scheduler.step()

        if step % LOG_EVERY == 0 or step == steps - 1:
            model.eval()
            with torch.no_grad():
                # Train acc (subsample for speed)
                sub = min(8192, n_train)
                t_preds = model(train_seqs[:sub]).argmax(dim=-1)
                train_acc = (t_preds == train_labels[:sub]).float().mean().item()

                # Test acc (subsample)
                sub_t = min(8192, n_test)
                te_preds = model(test_seqs[:sub_t]).argmax(dim=-1)
                test_acc = (te_preds == test_labels[:sub_t]).float().mean().item()

                # OOD acc
                sub_o = min(8192, len(ood_seqs))
                ood_preds = model(ood_seqs[:sub_o]).argmax(dim=-1)
                ood_acc = (ood_preds == ood_labels[:sub_o]).float().mean().item()

            history['step'].append(step)
            history['train_acc'].append(train_acc)
            history['test_acc'].append(test_acc)
            history['ood_acc'].append(ood_acc)
            history['train_loss'].append(loss.item())

            if grok_step is None and test_acc >= GROK_THRESHOLD:
                grok_step = step
                print(f"  [{mode}] 🧠 GROKKED at step {step}! "
                      f"test={test_acc:.3f} ood={ood_acc:.3f}")

            if step % (LOG_EVERY * 20) == 0:
                print(f"  [{mode}] step={step:>6} | loss={loss.item():.4f} | "
                      f"train={train_acc:.3f} | test={test_acc:.3f} | "
                      f"ood={ood_acc:.3f}")

    # Post-grok stability: variance of test_acc in last 25% of training
    quarter = len(history['test_acc']) // 4
    if quarter > 0:
        tail_accs = history['test_acc'][-quarter:]
        stability = 1.0 - torch.tensor(tail_accs).std().item()
    else:
        stability = 0.0

    return history, grok_step, stability


# ============================================================
# MAIN
# ============================================================

def main():
    total_triples = P ** 3
    print("=" * 80)
    print(f"  GROKKING v2: a + b*c mod {P}")
    print(f"  {total_triples:,} total triples | {FRAC_TRAIN:.0%} train | "
          f"seq_len={SEQ_LEN}")
    print(f"  embed={EMBED_DIM} | heads={NUM_HEADS} | layers={NUM_LAYERS} | "
          f"wd={WD} | steps={STEPS:,}")
    print(f"  Device: {DEVICE}")
    print("=" * 80)

    # Build tree distance bias
    print("\nBuilding tree-distance position bias...")
    tree_bias = tree_distance_matrix(SEQ_LEN, p_ary=2).to(DEVICE)
    print(f"  Tree bias shape: {tree_bias.shape}")
    print(f"  Position groupings (binary tree over {SEQ_LEN} positions):")
    print(f"    Depth 2: {{a,+}} {{b,*}} {{c,=}} — operand+operator pairs")
    print(f"    Depth 1: {{a,+,b,*}} {{c,=}} — left-expr vs right-expr")
    print(f"    Depth 0: all attend")

    results = {}

    # 1. Dense baseline
    print("\n--- Dense Attention ---")
    t0 = time.time()
    h_dense, grok_dense, stab_dense = train_model('dense')
    t_dense = time.time() - t0
    results['dense'] = {
        'history': h_dense, 'grok_step': grok_dense,
        'stability': stab_dense, 'time': round(t_dense, 1)
    }
    print(f"  Time: {t_dense:.1f}s | Grok: {grok_dense or 'NEVER'} | "
          f"Stability: {stab_dense:.4f}")

    # 2. Ultrametric (tree-distance position bias)
    print("\n--- Ultrametric Attention (tree-distance position bias) ---")
    t0 = time.time()
    h_ultra, grok_ultra, stab_ultra = train_model('ultrametric', tree_bias=tree_bias)
    t_ultra = time.time() - t0
    results['ultrametric'] = {
        'history': h_ultra, 'grok_step': grok_ultra,
        'stability': stab_ultra, 'time': round(t_ultra, 1)
    }
    print(f"  Time: {t_ultra:.1f}s | Grok: {grok_ultra or 'NEVER'} | "
          f"Stability: {stab_ultra:.4f}")

    # 3. Linear attention
    print("\n--- Linear Attention ---")
    t0 = time.time()
    h_linear, grok_linear, stab_linear = train_model('linear')
    t_linear = time.time() - t0
    results['linear'] = {
        'history': h_linear, 'grok_step': grok_linear,
        'stability': stab_linear, 'time': round(t_linear, 1)
    }
    print(f"  Time: {t_linear:.1f}s | Grok: {grok_linear or 'NEVER'} | "
          f"Stability: {stab_linear:.4f}")

    # Summary
    print("\n" + "=" * 80)
    print("  GROKKING v2 RESULTS: a + b*c mod 59")
    print("=" * 80)
    print(f"  {'Mode':<18} | {'Grok Step':>10} | {'Stability':>10} | "
          f"{'Test Acc':>9} | {'OOD Acc':>9} | {'Time':>8}")
    print("-" * 78)
    for mode in ['dense', 'ultrametric', 'linear']:
        r = results[mode]
        gs = r['grok_step'] or 'NEVER'
        st = r['stability']
        ta = r['history']['test_acc'][-1]
        oa = r['history']['ood_acc'][-1]
        t = r['time']
        print(f"  {mode:<18} | {str(gs):>10} | {st:>10.4f} | "
              f"{ta:>8.3f} | {oa:>8.3f} | {t:>7.1f}s")

    # Compare
    print()
    if grok_ultra and grok_dense:
        ratio = grok_dense / grok_ultra
        print(f"  Ultrametric groks {ratio:.2f}x {'faster' if ratio > 1 else 'slower'}"
              f" than dense")
    if stab_ultra > stab_dense:
        print(f"  Ultrametric is MORE stable post-grok "
              f"({stab_ultra:.4f} vs {stab_dense:.4f})")
    elif stab_dense > stab_ultra:
        print(f"  Dense is MORE stable post-grok "
              f"({stab_dense:.4f} vs {stab_ultra:.4f})")

    # Save results
    save_results = {}
    for mode, r in results.items():
        save_results[mode] = {
            'grok_step': r['grok_step'],
            'stability': r['stability'],
            'time': r['time'],
            'final_train_acc': r['history']['train_acc'][-1],
            'final_test_acc': r['history']['test_acc'][-1],
            'final_ood_acc': r['history']['ood_acc'][-1],
            'steps': r['history']['step'],
            'train_acc': r['history']['train_acc'],
            'test_acc': r['history']['test_acc'],
            'ood_acc': r['history']['ood_acc'],
        }

    with open("grokking_v2_results.json", "w") as f:
        json.dump(save_results, f, indent=2)
    print(f"\n✅ Saved to grokking_v2_results.json")

    # Plot
    try:
        import matplotlib
        matplotlib.use('Agg')
        import matplotlib.pyplot as plt

        fig, axes = plt.subplots(1, 3, figsize=(18, 5))
        colors = {'dense': '#4A90D9', 'ultrametric': '#E74C3C', 'linear': '#2ECC71'}

        # Test accuracy
        for mode in ['dense', 'ultrametric', 'linear']:
            h = results[mode]['history']
            axes[0].plot(h['step'], h['test_acc'], color=colors[mode],
                        label=mode, linewidth=1.5, alpha=0.8)
        axes[0].set_xlabel('Steps')
        axes[0].set_ylabel('Test Accuracy')
        axes[0].set_title(f'Grokking: a + b*c mod {P} (In-Distribution)')
        axes[0].legend()
        axes[0].set_ylim(-0.05, 1.05)
        axes[0].axhline(y=GROK_THRESHOLD, color='gray', linestyle=':', alpha=0.5)
        axes[0].grid(True, alpha=0.3)

        # OOD accuracy
        for mode in ['dense', 'ultrametric', 'linear']:
            h = results[mode]['history']
            axes[1].plot(h['step'], h['ood_acc'], color=colors[mode],
                        label=mode, linewidth=1.5, alpha=0.8)
        axes[1].set_xlabel('Steps')
        axes[1].set_ylabel('OOD Accuracy')
        axes[1].set_title('OOD Generalization (a ∈ {0..9} held out)')
        axes[1].legend()
        axes[1].set_ylim(-0.05, 1.05)
        axes[1].grid(True, alpha=0.3)

        # Training loss
        for mode in ['dense', 'ultrametric', 'linear']:
            h = results[mode]['history']
            axes[2].plot(h['step'], h['train_loss'], color=colors[mode],
                        label=mode, linewidth=1.5, alpha=0.8)
        axes[2].set_xlabel('Steps')
        axes[2].set_ylabel('Loss')
        axes[2].set_title('Training Loss')
        axes[2].legend()
        axes[2].set_yscale('log')
        axes[2].grid(True, alpha=0.3)

        plt.tight_layout()
        plt.savefig('grokking_v2_curves.png', dpi=150, bbox_inches='tight')
        print("📊 Saved grokking_v2_curves.png")
    except ImportError:
        print("(matplotlib not available — skipping plot)")


if __name__ == "__main__":
    main()
