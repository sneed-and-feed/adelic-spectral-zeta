import os
import sys
import math
import time
import torch
import torch.nn as nn
import torch.nn.functional as F

try:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
except NameError:
    if os.path.exists('experiments'):
        sys.path.insert(0, os.path.abspath('experiments'))
    else:
        sys.path.insert(0, os.path.abspath('.'))

from dataset_listops import make_listops_dataset, VOCAB_SIZE
from grokking_v4_dyck import GrokTransformer, DynamicUltrametricAttention, tree_distance_matrix

DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# Config for Phase 3: ListOps
SEQ_LEN = 128
MAX_DEPTH = 5
NUM_SAMPLES = 20000
EMBED_DIM = 128
NUM_HEADS = 4
NUM_LAYERS = 2
LR = 1e-3
WD = 0.1
STEPS = 10000
BATCH_SIZE = 64

def main():
    print("=" * 80)
    print("  PHASE 3: Generalized Inductive Bias (ListOps)")
    print("=" * 80)

    print(f"\n[PHASE A] Generating ListOps dataset (len={SEQ_LEN}, max_depth={MAX_DEPTH})...", flush=True)
    train_seqs, train_labels = make_listops_dataset(
        num_samples=NUM_SAMPLES, seq_len=SEQ_LEN, max_depth=MAX_DEPTH
    )
    
    # Split into train/test
    split = int(NUM_SAMPLES * 0.8)
    
    test_seqs = train_seqs[split:].to(DEVICE)
    test_labels = train_labels[split:].to(DEVICE)
    
    train_seqs = train_seqs[:split].to(DEVICE)
    train_labels = train_labels[:split].to(DEVICE)
    
    print(f"  Train: {len(train_seqs)} | Test: {len(test_seqs)}")
    
    tree_bias = tree_distance_matrix(SEQ_LEN).to(DEVICE)
    
    model = GrokTransformer(
        VOCAB_SIZE, EMBED_DIM, NUM_HEADS, NUM_LAYERS,
        mode='dynamic_ultra', tree_bias=tree_bias
    ).to(DEVICE)
    
    model.pos_embed = nn.Embedding(SEQ_LEN, EMBED_DIM).to(DEVICE)
    optimizer = torch.optim.AdamW(model.parameters(), lr=LR, weight_decay=WD)
    
    print(f"\n[PHASE A] Training model to predict the final ListOps digit...")
    model.train()
    for step in range(STEPS):
        tau = max(0.1, 1.0 - (step / (STEPS * 0.8)) * 0.9)
        for m in model.modules():
            if isinstance(m, DynamicUltrametricAttention):
                m.tau = tau
                
        idx = torch.randint(0, len(train_seqs), (BATCH_SIZE,), device=DEVICE)
        
        batch_seqs = train_seqs[idx]
        batch_labels = train_labels[idx]
        
        logits = model(batch_seqs)
        
        # Sequence classification loss
        loss = F.cross_entropy(logits, batch_labels)
        
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        
        if step % 500 == 0 or step == STEPS - 1:
            model.eval()
            with torch.no_grad():
                sub = min(512, len(test_seqs))
                test_logits = model(test_seqs[:sub])
                preds = test_logits.argmax(dim=-1)
                targets = test_labels[:sub]
                
                ans_acc = (preds == targets).float().mean().item()
                
            print(f"  Step {step:>5} | Loss: {loss.item():.4f} | Ans Acc: {ans_acc:.3f} | Tau: {tau:.2f}")
            model.train()

    print("\n[PHASE B] Extracting polarized gates per layer...")
    model.eval()
    
    with torch.no_grad():
        sample = test_seqs[:32]
        BLOCK_M = 32 # smaller block size for 128 seq len
        num_blocks = SEQ_LEN // BLOCK_M
        real_depth = max(int(math.ceil(math.log2(max(num_blocks, 2)))), 1)
        
        for i, layer in enumerate(model.layers):
            attn = layer['attn']
            dq = attn.depth_q(model.tok_embed(sample) + model.pos_embed(torch.arange(SEQ_LEN, device=DEVICE).unsqueeze(0).expand(32, SEQ_LEN)))
            dk = attn.depth_k(model.tok_embed(sample) + model.pos_embed(torch.arange(SEQ_LEN, device=DEVICE).unsqueeze(0).expand(32, SEQ_LEN)))
            da = F.softmax(torch.matmul(dq, dk.transpose(-2,-1)) / math.sqrt(dq.shape[-1]), dim=-1)
            dc = torch.matmul(da, dq)
            depth_logits = attn.depth_proj(dc)
            
            gate_probs = torch.sigmoid(depth_logits).mean(dim=(0, 1))
            req_depth = torch.where(gate_probs > 0.5, real_depth, 0).to(torch.int32)
            
            print(f"  Layer {i}:")
            print(f"    Raw probabilities : {gate_probs.cpu().numpy().round(3)}")
            print(f"    Mapped req_depth  : {req_depth.cpu().numpy().tolist()} (max={real_depth})")

if __name__ == "__main__":
    main()
