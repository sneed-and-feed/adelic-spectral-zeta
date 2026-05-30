import argparse
import sys
import os
import torch
import torch.nn as nn
from data import Dyck2Dataset, VOCAB

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../../")))
from src.ultrametric_v2_research.model import UltrametricTransformer

class BaselineTransformer(nn.Module):
    def __init__(self, vocab_size, embed_dim=256, num_heads=4, num_layers=4, max_seq_len=2048):
        super().__init__()
        self.embedding = nn.Embedding(vocab_size, embed_dim)
        self.pos_encoder = nn.Embedding(max_seq_len, embed_dim)
        
        encoder_layer = nn.TransformerEncoderLayer(
            d_model=embed_dim, 
            nhead=num_heads, 
            dim_feedforward=embed_dim * 4, 
            dropout=0.1, 
            batch_first=True
        )
        self.transformer = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)
        self.proj = nn.Linear(embed_dim, vocab_size)
        
    def forward(self, x):
        seq_len = x.size(1)
        positions = torch.arange(0, seq_len, dtype=torch.long, device=x.device)
        
        emb = self.embedding(x) + self.pos_encoder(positions)
        mask = nn.Transformer.generate_square_subsequent_mask(seq_len, device=x.device)
        
        out = self.transformer(emb, mask=mask, is_causal=True)
        logits = self.proj(out)
        return logits, None, torch.tensor(0.0, device=x.device)

def get_closer_accuracy(logits, targets):
    # Logits: (B, S, V) -> Predictions for the NEXT token
    # Targets: (B, S)
    # We align: preds for step t are predicting targets[t+1]
    # So we shift logits and targets
    preds = logits[:, :-1, :].argmax(dim=-1)
    shifted_targets = targets[:, 1:]
    
    # We only care when the target is a closing bracket (2 or 4)
    closer_mask = (shifted_targets == VOCAB[")"]) | (shifted_targets == VOCAB["]"])
    
    if closer_mask.sum() == 0:
        return 0.0
        
    correct = (preds == shifted_targets) & closer_mask
    acc = correct.sum().float() / closer_mask.sum().float()
    return acc.item()

def train(args):
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Using device: {device}")
    
    vocab_size = len(VOCAB)
    embed_dim = 256
    num_heads = 4
    num_layers = 4
    
    if args.model == "baseline":
        print("Initializing Baseline Transformer...")
        model = BaselineTransformer(vocab_size, embed_dim, num_heads, num_layers, args.seq_len).to(device)
    else:
        print("Initializing Ultrametric V2 Transformer...")
        model = UltrametricTransformer(
            vocab_size=vocab_size,
            num_layers=num_layers,
            embed_dim=embed_dim,
            num_heads=num_heads,
            prime_arities=[2, 2], # Base-2 hierarchy matches Dyck-2 branching
            max_seq_len=args.seq_len,
            attn_mode="auto"
        ).to(device)
        
    optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)
    loss_fn = nn.CrossEntropyLoss()
    
    dataset = Dyck2Dataset(seq_len=args.seq_len, filler_prob=args.filler, batch_size=args.batch_size, num_batches=args.steps)
    
    model.train()
    step = 0
    
    print(f"\nTraining {args.model} for {args.steps} steps (filler_prob={args.filler})...")
    
    for batch in dataset:
        batch = batch.to(device)
        
        # Predict the next token
        inputs = batch
        targets = batch
        
        logits, _, aux_loss = model(inputs)
        
        # Shift logits and targets for next-token prediction
        shift_logits = logits[:, :-1, :].contiguous()
        shift_targets = targets[:, 1:].contiguous()
        
        ce_loss = loss_fn(shift_logits.view(-1, vocab_size), shift_targets.view(-1))
        loss = ce_loss + aux_loss
        
        optimizer.zero_grad()
        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
        optimizer.step()
        
        step += 1
        if step % 100 == 0 or step == args.steps:
            acc = get_closer_accuracy(logits, batch)
            print(f"Step {step:4d} | Loss: {loss.item():.4f} | Closer-Bracket Acc: {acc:.4f}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=str, choices=["baseline", "v2"], default="v2", help="Model type to train")
    parser.add_argument("--seq_len", type=int, default=128, help="Sequence length")
    parser.add_argument("--filler", type=float, default=0.25, help="Filler token probability")
    parser.add_argument("--steps", type=int, default=2000, help="Number of training steps")
    parser.add_argument("--batch_size", type=int, default=32, help="Batch size")
    
    args = parser.parse_args()
    train(args)
