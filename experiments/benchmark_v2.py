"""
Ultrametric AI v2 Benchmark — Tests the UPGRADED code paths.
Paste this entire file into a Colab cell with A100 runtime.

Prerequisites (run in a prior cell):
    !pip install torch numpy
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
import math
import time
import json
import sys

# ============================================================
# ULTRAMETRIC ATTENTION — UPGRADED (3 execution paths)
# ============================================================

# --- RoPE ---
class RotaryPositionEmbedding(nn.Module):
    def __init__(self, head_dim, max_seq_len=8192, base=10000.0):
        super().__init__()
        inv_freq = 1.0 / (base ** (torch.arange(0, head_dim, 2, dtype=torch.float32) / head_dim))
        self.register_buffer("inv_freq", inv_freq, persistent=False)
        t = torch.arange(max_seq_len, dtype=torch.float32)
        freqs = torch.outer(t, inv_freq)
        emb = torch.cat([freqs, freqs], dim=-1)
        self.register_buffer("cos_cached", emb.cos(), persistent=False)
        self.register_buffer("sin_cached", emb.sin(), persistent=False)

    def forward(self, x):
        seq_len = x.shape[-2]
        return self.cos_cached[:seq_len].to(x.dtype), self.sin_cached[:seq_len].to(x.dtype)

def _rotate_half(x):
    x1, x2 = x[..., :x.shape[-1]//2], x[..., x.shape[-1]//2:]
    return torch.cat([-x2, x1], dim=-1)

def apply_rope(q, k, cos, sin):
    cos = cos[None, None, :, :]
    sin = sin[None, None, :, :]
    return q * cos + _rotate_half(q) * sin, k * cos + _rotate_half(k) * sin

# --- Mask ---
def get_ultrametric_mask(seq_len, p=2):
    levels = int(math.ceil(math.log(max(seq_len, 2), p)))
    pad_len = p ** levels
    mask = torch.zeros((pad_len, pad_len), dtype=torch.bool)
    for level in range(levels):
        bs = p ** level
        for i in range(0, pad_len, bs):
            mask[i:i+bs, i:i+bs] = True
    return mask[:seq_len, :seq_len]

# --- Attention with 2 paths ---
class UltrametricAttentionV2(nn.Module):
    def __init__(self, embed_dim, num_heads, p=2, max_seq_len=8192):
        super().__init__()
        self.embed_dim = embed_dim
        self.num_heads = num_heads
        self.head_dim = embed_dim // num_heads
        self.scale = 1.0 / math.sqrt(self.head_dim)
        self.q_proj = nn.Linear(embed_dim, embed_dim)
        self.k_proj = nn.Linear(embed_dim, embed_dim)
        self.v_proj = nn.Linear(embed_dim, embed_dim)
        self.o_proj = nn.Linear(embed_dim, embed_dim)
        self.rope = RotaryPositionEmbedding(self.head_dim, max_seq_len)

    def forward(self, x, mask, mode='dense'):
        B, S, _ = x.size()
        q = self.q_proj(x).view(B, S, self.num_heads, self.head_dim).transpose(1, 2)
        k = self.k_proj(x).view(B, S, self.num_heads, self.head_dim).transpose(1, 2)
        v = self.v_proj(x).view(B, S, self.num_heads, self.head_dim).transpose(1, 2)
        cos, sin = self.rope(q)
        q, k = apply_rope(q, k, cos, sin)

        if mode == 'chunked':
            return self._chunked(q, k, v, mask, B, S)
        else:
            return self._dense(q, k, v, mask, B, S)

    def _dense(self, q, k, v, mask, B, S):
        scores = torch.matmul(q, k.transpose(-2, -1)) * self.scale
        scores = scores.masked_fill(~mask.unsqueeze(0).unsqueeze(0), float('-inf'))
        attn = F.softmax(scores, dim=-1)
        out = torch.matmul(attn, v)
        return self.o_proj(out.transpose(1, 2).contiguous().view(B, S, self.embed_dim))

    def _chunked(self, q, k, v, mask, B, S, block_size=64):
        H, D = self.num_heads, self.head_dim
        num_blocks = math.ceil(S / block_size)
        pad = num_blocks * block_size - S
        if pad > 0:
            q = F.pad(q, (0,0,0,pad))
            k = F.pad(k, (0,0,0,pad))
            v = F.pad(v, (0,0,0,pad))
            mask = F.pad(mask, (0,pad,0,pad), value=False)
        Sp = num_blocks * block_size
        q_b = q.view(B, H, num_blocks, block_size, D)
        k_b = k.view(B, H, num_blocks, block_size, D)
        v_b = v.view(B, H, num_blocks, block_size, D)
        mask_exp = mask.unsqueeze(0).unsqueeze(0).expand(B, H, Sp, Sp)
        mask_blk = mask_exp.view(B, H, num_blocks, block_size, num_blocks, block_size)
        blk_active = mask_blk.any(dim=3).any(dim=-1)

        out = torch.zeros(B, H, Sp, D, device=q.device, dtype=q.dtype)
        m_acc = torch.full((B, H, Sp), -1e9, device=q.device, dtype=torch.float32)
        l_acc = torch.zeros(B, H, Sp, device=q.device, dtype=torch.float32)

        for j in range(num_blocks):
            if not blk_active[:,:,:,j].any():
                continue
            k_j = k_b[:,:,j]
            v_j = v_b[:,:,j]
            for i in range(num_blocks):
                if not blk_active[:,:,i,j].any():
                    continue
                q_i = q_b[:,:,i]
                sc = torch.matmul(q_i, k_j.transpose(-2,-1)) * self.scale
                tm = mask_exp[:,:, i*block_size:(i+1)*block_size, j*block_size:(j+1)*block_size]
                sc = sc.masked_fill(~tm, float('-inf'))
                rs, re = i*block_size, (i+1)*block_size
                m_old = m_acc[:,:,rs:re]
                m_new = torch.maximum(m_old, sc.max(dim=-1).values)
                alpha = torch.exp(m_old - m_new)
                p_blk = torch.exp(sc - m_new.unsqueeze(-1))
                out[:,:,rs:re] = out[:,:,rs:re] * alpha.unsqueeze(-1) + torch.matmul(p_blk.to(v_j.dtype), v_j)
                l_acc[:,:,rs:re] = l_acc[:,:,rs:re] * alpha + p_blk.sum(dim=-1)
                m_acc[:,:,rs:re] = m_new

        out = (out / l_acc.unsqueeze(-1).clamp(min=1e-8)).to(q.dtype)
        out = out[:,:,:S]
        return self.o_proj(out.transpose(1,2).contiguous().view(B, S, self.embed_dim))

# --- Block ---
class Block(nn.Module):
    def __init__(self, embed_dim, num_heads, p=2):
        super().__init__()
        self.ln1 = nn.LayerNorm(embed_dim)
        self.attn = UltrametricAttentionV2(embed_dim, num_heads, p)
        self.ln2 = nn.LayerNorm(embed_dim)
        self.mlp = nn.Sequential(
            nn.Linear(embed_dim, embed_dim * 4), nn.GELU(),
            nn.Linear(embed_dim * 4, embed_dim))
    def forward(self, x, mask, mode='dense'):
        x = x + self.attn(self.ln1(x), mask, mode=mode)
        x = x + self.mlp(self.ln2(x))
        return x

# --- Dense Baseline (no mask overhead at all) ---
class DenseBlock(nn.Module):
    def __init__(self, embed_dim, num_heads):
        super().__init__()
        self.ln1 = nn.LayerNorm(embed_dim)
        self.embed_dim = embed_dim
        self.num_heads = num_heads
        self.head_dim = embed_dim // num_heads
        self.scale = 1.0 / math.sqrt(self.head_dim)
        self.q_proj = nn.Linear(embed_dim, embed_dim)
        self.k_proj = nn.Linear(embed_dim, embed_dim)
        self.v_proj = nn.Linear(embed_dim, embed_dim)
        self.o_proj = nn.Linear(embed_dim, embed_dim)
        self.rope = RotaryPositionEmbedding(self.head_dim, 8192)
        self.ln2 = nn.LayerNorm(embed_dim)
        self.mlp = nn.Sequential(
            nn.Linear(embed_dim, embed_dim * 4), nn.GELU(),
            nn.Linear(embed_dim * 4, embed_dim))

    def forward(self, x):
        B, S, _ = x.size()
        h = self.ln1(x)
        q = self.q_proj(h).view(B,S,self.num_heads,self.head_dim).transpose(1,2)
        k = self.k_proj(h).view(B,S,self.num_heads,self.head_dim).transpose(1,2)
        v = self.v_proj(h).view(B,S,self.num_heads,self.head_dim).transpose(1,2)
        cos, sin = self.rope(q)
        q, k = apply_rope(q, k, cos, sin)
        scores = torch.matmul(q, k.transpose(-2,-1)) * self.scale
        attn = F.softmax(scores, dim=-1)
        out = torch.matmul(attn, v)
        out = self.o_proj(out.transpose(1,2).contiguous().view(B,S,self.embed_dim))
        x = x + out
        x = x + self.mlp(self.ln2(x))
        return x

class ModelStack(nn.Module):
    def __init__(self, layers):
        super().__init__()
        self.layers = nn.ModuleList(layers)
    def forward(self, x, mask=None, mode='dense'):
        for layer in self.layers:
            if isinstance(layer, Block):
                x = layer(x, mask, mode=mode)
            else:
                x = layer(x)
        return x

# ============================================================
# BENCHMARK HARNESS
# ============================================================

def benchmark(fn, warmup=5, runs=20):
    """Returns median ms and peak GPU MB."""
    with torch.no_grad():
        for _ in range(warmup):
            fn()
        torch.cuda.synchronize()
        times = []
        for _ in range(runs):
            torch.cuda.reset_peak_memory_stats()
            s = torch.cuda.Event(enable_timing=True)
            e = torch.cuda.Event(enable_timing=True)
            s.record(); fn(); e.record()
            torch.cuda.synchronize()
            times.append(s.elapsed_time(e))
    return sorted(times)[len(times)//2], torch.cuda.max_memory_allocated()/1024**2

def main():
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    if device.type != "cuda":
        print("⚠️  No GPU! Use Colab with A100.")
        return

    embed_dim, num_heads, batch, p = 512, 8, 8, 2
    seq_lengths = [128, 256, 512, 1024, 2048, 4096]

    # Try 8192 if we have enough VRAM
    try:
        test = torch.randn(batch, 8192, embed_dim, device=device, dtype=torch.float16)
        del test
        seq_lengths.append(8192)
    except:
        pass

    print("=" * 80)
    print(f"  ULTRAMETRIC AI v2 BENCHMARK — {torch.cuda.get_device_name(0)}")
    print(f"  embed={embed_dim}, heads={num_heads}, batch={batch}, p={p}")
    print(f"  Paths: Dense (baseline) | Masked-Dense (v1) | Chunked-Sparse (v2)")
    print("=" * 80)

    results = []
    for sl in seq_lengths:
        print(f"\n--- seq_len = {sl} ---")
        mask = get_ultrametric_mask(sl, p).to(device)
        sp = 1.0 - mask.float().mean().item()

        # Build 2-layer stacks
        dense_stack = ModelStack([DenseBlock(embed_dim, num_heads), DenseBlock(embed_dim, num_heads)]).to(device).half().eval()
        sparse_stack = ModelStack([Block(embed_dim, num_heads, p), Block(embed_dim, num_heads, p)]).to(device).half().eval()
        hybrid_stack = ModelStack([Block(embed_dim, num_heads, p), DenseBlock(embed_dim, num_heads)]).to(device).half().eval()

        x = torch.randn(batch, sl, embed_dim, device=device, dtype=torch.float16)

        # 1. Dense baseline (no mask at all)
        try:
            d_ms, d_mb = benchmark(lambda: dense_stack(x))
        except torch.cuda.OutOfMemoryError:
            d_ms, d_mb = float('inf'), float('inf')
            print("  Dense: OOM!")

        # 2. Masked-dense (v1) on sparse_stack
        try:
            md_ms, md_mb = benchmark(lambda: sparse_stack(x, mask, mode='dense'))
        except torch.cuda.OutOfMemoryError:
            md_ms, md_mb = float('inf'), float('inf')
            print("  Masked-Dense: OOM!")

        # 3. Chunked-sparse (v2) on sparse_stack
        try:
            ch_ms, ch_mb = benchmark(lambda: sparse_stack(x, mask, mode='chunked'))
        except torch.cuda.OutOfMemoryError:
            ch_ms, ch_mb = float('inf'), float('inf')
            print("  Chunked: OOM!")

        # 4. Chunked-hybrid (v2) on hybrid_stack
        try:
            hybrid_ms, hybrid_mb = benchmark(lambda: hybrid_stack(x, mask, mode='chunked'))
        except torch.cuda.OutOfMemoryError:
            hybrid_ms, hybrid_mb = float('inf'), float('inf')
            print("  Hybrid: OOM!")

        row = {
            "seq_len": sl,
            "sparsity": f"{sp:.1%}",
            "dense_ms": round(d_ms, 2),
            "dense_mb": round(d_mb, 1),
            "masked_ms": round(md_ms, 2),
            "masked_mb": round(md_mb, 1),
            "chunked_ms": round(ch_ms, 2),
            "chunked_mb": round(ch_mb, 1),
            "hybrid_ms": round(hybrid_ms, 2),
            "hybrid_mb": round(hybrid_mb, 1),
            "chunked_vs_dense_speed": f"{d_ms/ch_ms:.2f}x" if ch_ms > 0 and ch_ms != float('inf') else "N/A",
            "chunked_vs_dense_mem": f"{(1-ch_mb/d_mb)*100:.1f}%" if d_mb > 0 and d_mb != float('inf') else "N/A",
        }
        results.append(row)
        print(f"  Dense      : {d_ms:8.2f} ms | {d_mb:8.1f} MB")
        print(f"  Masked-Den : {md_ms:8.2f} ms | {md_mb:8.1f} MB")
        print(f"  Chunked-Sp : {ch_ms:8.2f} ms | {ch_mb:8.1f} MB")
        print(f"  Hybrid-Sp  : {hybrid_ms:8.2f} ms | {hybrid_mb:8.1f} MB")
        print(f"  Sparsity={sp:.0%} | Chunked vs Dense: speed={row['chunked_vs_dense_speed']}, mem={row['chunked_vs_dense_mem']}")

        del sparse_stack, dense_stack, hybrid_stack, x, mask
        torch.cuda.empty_cache()

    # Summary
    print("\n" + "=" * 90)
    print("  RESULTS SUMMARY")
    print("=" * 90)
    hdr = f"{'SeqLen':>7} | {'Sparse':>7} | {'Dense ms':>9} | {'Masked ms':>10} | {'Chunked ms':>11} | {'Hybrid ms':>10} | {'Dense MB':>9} | {'Chunk MB':>9} | {'Speed':>7} | {'MemSave':>8}"
    print(hdr)
    print("-" * len(hdr))
    for r in results:
        print(f"{r['seq_len']:>7} | {r['sparsity']:>7} | {r['dense_ms']:>9} | {r['masked_ms']:>10} | {r['chunked_ms']:>11} | {r['hybrid_ms']:>10} | {r['dense_mb']:>9} | {r['chunked_mb']:>9} | {r['chunked_vs_dense_speed']:>7} | {r['chunked_vs_dense_mem']:>8}")

    with open("benchmark_v2_results.json", "w") as f:
        json.dump(results, f, indent=2)
    print("\n✅ Saved to benchmark_v2_results.json")

if __name__ == "__main__":
    main()
