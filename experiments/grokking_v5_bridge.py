import os
import sys
import math
import time
import json
import torch
import torch.nn as nn
import torch.nn.functional as F

try:
    # If running as a script
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
except NameError:
    # If running in a notebook cell
    if os.path.exists('experiments'):
        sys.path.insert(0, os.path.abspath('experiments'))
    else:
        sys.path.insert(0, os.path.abspath('.'))

from dataset_dyck import make_dyck_dataset
from grokking_v4_dyck import GrokTransformer, DynamicUltrametricAttention, tree_distance_matrix

try:
    from benchmark_triton import triton_attention, make_tree_routing, next_pow2
    HAS_TRITON = True
except ImportError:
    HAS_TRITON = False

DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# Config for Phase A
K = 4
SEQ_LEN = 512
MAX_DEPTH = 20
NUM_SAMPLES = 10000
FRAC_TRAIN = 0.8

EMBED_DIM = 128
NUM_HEADS = 4
NUM_LAYERS = 2
LR = 1e-3
WD = 0.1
STEPS = 5000
BATCH_SIZE = 32

def main():
    print("=" * 80)
    print("  PHASE 1 BRIDGE: Learned Gates -> Triton Block-Sparse")
    print("=" * 80)

    # ---------------------------------------------------------
    # PHASE A: Train
    # ---------------------------------------------------------
    print(f"\n[PHASE A] Generating Dyck-{K} dataset (len={SEQ_LEN}, max_depth={MAX_DEPTH})...")
    train_seqs, train_labels, test_seqs, test_labels = make_dyck_dataset(
        k=K, num_samples=NUM_SAMPLES, seq_len=SEQ_LEN, max_depth=MAX_DEPTH
    )
    train_seqs = train_seqs.to(DEVICE)
    train_labels = train_labels.to(DEVICE)
    test_seqs = test_seqs.to(DEVICE)
    test_labels = test_labels.to(DEVICE)
    
    vocab_size = 2 * K + 1
    tree_bias = tree_distance_matrix(SEQ_LEN).to(DEVICE)
    
    model = GrokTransformer(
        vocab_size, EMBED_DIM, NUM_HEADS, NUM_LAYERS,
        mode='dynamic_ultra', tree_bias=tree_bias
    ).to(DEVICE)
    
    # FIX: The imported GrokTransformer hardcodes pos_embed to its original SEQ_LEN=32.
    # Overwrite it here so it can handle our new sequence length of 512 without OOB asserts.
    model.pos_embed = nn.Embedding(SEQ_LEN, EMBED_DIM).to(DEVICE)

    optimizer = torch.optim.AdamW(model.parameters(), lr=LR, weight_decay=WD)
    
    print("\n[PHASE A] Training model to learn depth gates...")
    model.train()
    for step in range(STEPS):
        tau = max(0.1, 1.0 - (step / (STEPS * 0.8)) * 0.9)
        for m in model.modules():
            if isinstance(m, DynamicUltrametricAttention):
                m.tau = tau
                
        idx = torch.randint(0, len(train_seqs), (BATCH_SIZE,), device=DEVICE)
        logits = model(train_seqs[idx])
        loss = F.cross_entropy(logits, train_labels[idx])
        
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        
        if step % 500 == 0 or step == STEPS - 1:
            model.eval()
            with torch.no_grad():
                sub = min(512, len(test_seqs))
                acc = (model(test_seqs[:sub]).argmax(-1) == test_labels[:sub]).float().mean().item()
            print(f"  Step {step:>4} | Loss: {loss.item():.4f} | Test Acc: {acc:.3f} | Tau: {tau:.2f}")
            model.train()

    # ---------------------------------------------------------
    # PHASE B: Extract Gates
    # ---------------------------------------------------------
    print("\n[PHASE B] Extracting polarized gates per layer...")
    model.eval()
    
    layer_req_depths = [] # one 1D tensor per layer
    
    with torch.no_grad():
        # Get a sample batch to compute dynamic gates
        sample = test_seqs[:16]
        
        # Real depth of the binary tree
        BLOCK_M = 128
        num_blocks = SEQ_LEN // BLOCK_M
        real_depth = max(int(math.ceil(math.log2(max(num_blocks, 2)))), 1)
        
        for i, layer in enumerate(model.layers):
            attn = layer['attn']
            dq = attn.depth_q(model.tok_embed(sample) + model.pos_embed(torch.arange(SEQ_LEN, device=DEVICE).unsqueeze(0).expand(16, SEQ_LEN)))
            dk = attn.depth_k(model.tok_embed(sample) + model.pos_embed(torch.arange(SEQ_LEN, device=DEVICE).unsqueeze(0).expand(16, SEQ_LEN)))
            da = F.softmax(torch.matmul(dq, dk.transpose(-2,-1)) / math.sqrt(dq.shape[-1]), dim=-1)
            dc = torch.matmul(da, dq)
            depth_logits = attn.depth_proj(dc) # (B, S, H)
            
            # Mean gate value per head
            gate_probs = torch.sigmoid(depth_logits).mean(dim=(0, 1)) # (H,)
            
            # Threshold: > 0.5 becomes max sparse (real_depth), else 0 (dense)
            req_depth = torch.where(gate_probs > 0.5, real_depth, 0).to(torch.int32)
            layer_req_depths.append(req_depth)
            
            print(f"  Layer {i}:")
            print(f"    Raw probabilities : {gate_probs.cpu().numpy().round(3)}")
            print(f"    Mapped req_depth  : {req_depth.cpu().numpy().tolist()} (max={real_depth})")

    # ---------------------------------------------------------
    # PHASE C: Inference Benchmark
    # ---------------------------------------------------------
    print("\n[PHASE C] Inference Benchmarking...")
    
    if not HAS_TRITON:
        print("  ⚠️ Triton not installed. Skipping benchmark phase. Please run on Colab A100.")
        return
        
    print("  Comparing: PyTorch Dense vs Triton Dense vs Triton Learned Hybrid")
    
    td_p2 = next_pow2(real_depth)
    
    # We will do inference on a larger batch
    batch_inf = 16
    q = torch.randn(batch_inf, NUM_HEADS, SEQ_LEN, EMBED_DIM//NUM_HEADS, dtype=torch.float16, device=DEVICE)
    k = torch.randn_like(q)
    v = torch.randn_like(q)
    
    router = make_tree_routing(num_blocks, td_p2, real_depth, batch_inf, NUM_HEADS, p=2, device=DEVICE)
    
    def run_pt_dense():
        scale = 1.0 / math.sqrt(EMBED_DIM // NUM_HEADS)
        scores = torch.matmul(q, k.transpose(-2, -1)) * scale
        attn = F.softmax(scores, dim=-1)
        return torch.matmul(attn, v)
        
    def run_triton_dense():
        # req_depth = 0 for all heads = totally dense
        req_depth_dense = torch.zeros(NUM_HEADS, dtype=torch.int32, device=DEVICE)
        return triton_attention(q, k, v, router, req_depth_dense, td_p2)
        
    def run_triton_hybrid():
        out0 = triton_attention(q, k, v, router, layer_req_depths[0], td_p2)
        out1 = triton_attention(q, k, v, router, layer_req_depths[1], td_p2)
        return out1
        
    def bench(fn, runs=20):
        # Warmup
        for _ in range(5):
            fn()
        torch.cuda.synchronize()
        t0 = time.time()
        for _ in range(runs):
            fn()
        torch.cuda.synchronize()
        return (time.time() - t0) / runs * 1000 # ms
        
    ms_pt = bench(lambda: [run_pt_dense() for _ in range(NUM_LAYERS)])
    ms_triton_dense = bench(lambda: [run_triton_dense() for _ in range(NUM_LAYERS)])
    ms_triton_hybrid = bench(run_triton_hybrid)
    
    print(f"\n  Results (SeqLen={SEQ_LEN}, Batch={batch_inf}):")
    print(f"    PyTorch Dense     : {ms_pt:.2f} ms")
    print(f"    Triton Dense      : {ms_triton_dense:.2f} ms")
    print(f"    Triton Hybrid     : {ms_triton_hybrid:.2f} ms")
    print(f"    Speedup vs PT     : {ms_pt / ms_triton_hybrid:.2f}x")
    print(f"    Speedup vs Dense  : {ms_triton_dense / ms_triton_hybrid:.2f}x")
    
if __name__ == "__main__":
    main()
