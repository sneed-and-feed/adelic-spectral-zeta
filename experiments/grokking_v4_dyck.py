"""
Grokking v4: Dynamic Ultrametric Attention on Complex Dyck-k Languages

Tests the inductive bias of ultrametric (hierarchical) attention on a pure
hierarchical task: Next-Token Prediction of deeply nested Dyck-k brackets.

Colab A100: ~15-20 min.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
import math
import json
import time
import random

# ============================================================
# DYCK-K DATASET GENERATOR
# ============================================================
K = 2
VOCAB_SIZE = 2 * K + 1
SEQ_LEN = 32

def generate_dyck_string(k, max_depth, current_depth=0):
    if current_depth >= max_depth:
        return []
    result = []
    num_siblings = random.randint(1, 3) if current_depth == 0 else random.randint(0, 2)
    for _ in range(num_siblings):
        bracket_type = random.randint(1, k)
        inner = generate_dyck_string(k, max_depth, current_depth + 1)
        result.extend([bracket_type] + inner + [bracket_type + k])
    return result

def make_dyck_dataset(k=K, num_samples=20000, seq_len=SEQ_LEN, max_depth=12, frac_train=0.8, seed=42):
    random.seed(seed)
    torch.manual_seed(seed)
    seqs = []
    labels = []
    attempts = 0
    while len(seqs) < num_samples:
        attempts += 1
        if attempts > num_samples * 100:
            break
        full_string = generate_dyck_string(k, max_depth)
        if len(full_string) < 2:
            continue
        closing_positions = []
        stack = []
        for i, token in enumerate(full_string):
            if 1 <= token <= k:
                stack.append(token)
            elif k + 1 <= token <= 2 * k:
                if not stack: break
                expected_close = stack.pop() + k
                assert token == expected_close
                closing_positions.append((i, expected_close))
        if not closing_positions:
            continue
        pos, target = random.choice(closing_positions)
        prefix = full_string[:pos]
        if len(prefix) > seq_len:
            prefix = prefix[-seq_len:]
        else:
            prefix = [0] * (seq_len - len(prefix)) + prefix
        seqs.append(prefix)
        labels.append(target)
    seqs_t = torch.tensor(seqs, dtype=torch.long)
    labels_t = torch.tensor(labels, dtype=torch.long)
    perm = torch.randperm(len(seqs_t))
    split = int(len(seqs_t) * frac_train)
    train_idx, test_idx = perm[:split], perm[split:]
    print(f"  Dataset Dyck-{k}: {len(seqs_t):,} samples | Max Depth {max_depth}")
    return seqs_t[train_idx], labels_t[train_idx], seqs_t[test_idx], labels_t[test_idx]

DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"Device: {DEVICE}")
if DEVICE.type == 'cuda':
    print(f"GPU: {torch.cuda.get_device_name()}")

# ============================================================
# CONFIG
# ============================================================

FRAC_TRAIN = 0.8
EMBED_DIM = 128
NUM_HEADS = 4
NUM_LAYERS = 2
LR = 1e-3
WD = 0.1            # relaxed weight decay for bracket matching
STEPS = 20_000      # shorter steps needed for Dyck
BATCH_SIZE = 512
LOG_EVERY = 200
GROK_THRESHOLD = 0.95
SEED = 42

# ============================================================
# TREE DISTANCE BIAS
# ============================================================

def tree_distance_matrix(n):
    """Binary tree pairwise similarity for n positions."""
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
    """Fixed tree-distance bias."""
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
    Self-attention-regulated tree depth with Gumbel-Sigmoid regularization.
    """
    def __init__(self, embed_dim, num_heads, tree_bias):
        super().__init__()
        self.num_heads = num_heads
        self.head_dim = embed_dim // num_heads
        self.qkv = nn.Linear(embed_dim, 3 * embed_dim)
        self.out_proj = nn.Linear(embed_dim, embed_dim)
        self.register_buffer('tree_bias', tree_bias)

        # Depth controller: self-attention → per-position per-head gate
        self.depth_q = nn.Linear(embed_dim, embed_dim // 4)
        self.depth_k = nn.Linear(embed_dim, embed_dim // 4)
        self.depth_proj = nn.Linear(embed_dim // 4, num_heads)
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
        depth_logits = self.depth_proj(depth_ctx) # (B, S, H)
        
        if self.training:
            u1 = torch.rand_like(depth_logits)
            u2 = torch.rand_like(depth_logits)
            g1 = -torch.log(-torch.log(u1 + 1e-8) + 1e-8)
            g2 = -torch.log(-torch.log(u2 + 1e-8) + 1e-8)
            tau = getattr(self, 'tau', 1.0)
            depth_gate = torch.sigmoid((depth_logits + g1 - g2) / tau)
        else:
            depth_gate = (depth_logits > 0).float()

        # === Main attention ===
        qkv = self.qkv(x).reshape(B, S, 3, self.num_heads, self.head_dim)
        q, k, v = qkv.unbind(2)
        q, k, v = q.transpose(1, 2), k.transpose(1, 2), v.transpose(1, 2)
        scale = 1.0 / math.sqrt(self.head_dim)
        scores = torch.matmul(q, k.transpose(-2, -1)) * scale  # (B, H, S, S)

        # === Dynamic tree bias ===
        gate = depth_gate.permute(0, 2, 1).unsqueeze(-1)  # (B, H, S, 1)
        amp = self.bias_amplitude.view(1, self.num_heads, 1, 1)
        bias = self.tree_bias[:S, :S].unsqueeze(0).unsqueeze(0)  # (1, 1, S, S)
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
        return self.unembed(x[:, -1, :])  # predict next token at end


# ============================================================
# TRAINING
# ============================================================

def train_model(mode, tree_bias=None, steps=STEPS, seed=SEED):
    torch.manual_seed(seed)
    
    # Use the Dyck dataset instead of the polynomial one
    train_seqs, train_labels, test_seqs, test_labels = make_dyck_dataset(
        k=K, num_samples=20000, seq_len=SEQ_LEN, frac_train=FRAC_TRAIN, seed=seed
    )
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
        # Anneal tau from 1.0 to 0.1 over the first 80% of training
        tau = max(0.1, 1.0 - (step / (steps * 0.8)) * 0.9)
        if mode == 'dynamic_ultra':
            for m in model.modules():
                if isinstance(m, DynamicUltrametricAttention):
                    m.tau = tau

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
                        depth_logits = attn.depth_proj(dc)
                        # We log the hard thresholded gate value during evaluation
                        gate = (depth_logits > 0).float()
                        gate_stats.append({
                            'step': step,
                            'tau': getattr(attn, 'tau', 1.0),
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
                    extra = f" | gate={g['mean']:.3f}±{g['std']:.3f} | tau={g.get('tau', 1.0):.2f}"
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
    print("=" * 80)
    print(f"  GROKKING v4: Complex Dyck-{K} Language (Next-Token Prediction)")
    print(f"  Sequence length: {SEQ_LEN} tokens")
    print(f"  {FRAC_TRAIN:.0%} train | embed={EMBED_DIM} | heads={NUM_HEADS} | wd={WD}")
    print(f"  Device: {DEVICE}")
    print("=" * 80)

    tree_bias = tree_distance_matrix(SEQ_LEN).to(DEVICE)
    print(f"\n  Tree bias ({SEQ_LEN}×{SEQ_LEN}) ready.")

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
    print(f"  GROKKING v4: Complex Dyck-{K} Language")
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
    with open("grokking_v4_dyck_results.json", "w") as f:
        json.dump(save, f, indent=2)
    print(f"\n✅ Saved to grokking_v4_dyck_results.json")

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
        axes[0].set_title(f'Dyck-{K} Next-Token Prediction')
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

        plt.suptitle(f'Dynamic Ultrametric Attention — Dyck-{K}',
                     fontsize=14, fontweight='bold')
        plt.tight_layout()
        plt.savefig('grokking_v4_dyck_curves.png', dpi=150, bbox_inches='tight')
        print("📊 Saved grokking_v4_dyck_curves.png")
    except ImportError:
        print("(matplotlib not available — skipping plot)")

if __name__ == "__main__":
    main()
