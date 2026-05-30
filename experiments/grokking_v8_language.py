import os
import sys
import math
import torch
import torch.nn.functional as F
from datasets import load_dataset
import tiktoken

try:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
except NameError:
    if os.path.exists('experiments'):
        sys.path.insert(0, os.path.abspath('experiments'))
    else:
        sys.path.insert(0, os.path.abspath('.'))

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.ultrametric.model import UltrametricTransformer
from src.ultrametric.topology import get_dynamic_ultrametric_mask

DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
torch.autograd.set_detect_anomaly(True)

# Config
SEQ_LEN = 256
BATCH_SIZE = 8
LR = 5e-4
WD = 0.1
STEPS = 500
AUX_LOSS_WEIGHT = 0.01

def main():
    print("=" * 80)
    print("  PHASE 8: Language Modeling Layer Polarization")
    print("=" * 80)

    import urllib.request
    import tempfile
    print(f"\n[PHASE A] Downloading tiny_shakespeare dataset...")
    url = "https://raw.githubusercontent.com/karpathy/char-rnn/master/data/tinyshakespeare/input.txt"
    data_path = os.path.join(tempfile.gettempdir(), "tinyshakespeare.txt")
    if not os.path.exists(data_path):
        urllib.request.urlretrieve(url, data_path)
    with open(data_path, "r", encoding="utf-8") as f:
        text = f.read()
    
    # Tokenize
    print("Tokenizing...")
    enc = tiktoken.get_encoding("gpt2")
    tokens = enc.encode(text)
    vocab_size = enc.n_vocab
    
    print(f"Total tokens: {len(tokens)}")
    
    # Convert to tensor
    data = torch.tensor(tokens, dtype=torch.long)
    
    def get_batch():
        ix = torch.randint(len(data) - SEQ_LEN, (BATCH_SIZE,))
        x = torch.stack([data[i:i+SEQ_LEN] for i in ix])
        y = torch.stack([data[i+1:i+SEQ_LEN+1] for i in ix])
        return x.to(DEVICE), y.to(DEVICE)
    
    # Initialize model
    print("\n[PHASE B] Initializing UltrametricTransformer...")
    model = UltrametricTransformer(
        vocab_size=vocab_size,
        num_layers=4,
        embed_dim=256,
        num_heads=4,
        p=2,
        max_seq_len=SEQ_LEN,
        mlp_ratio=4.0,
        dropout=0.1,
        tie_weights=True,
        use_interior=False,
        attn_mode='dense'
    ).to(DEVICE)
    
    optimizer = torch.optim.AdamW(model.parameters(), lr=LR, weight_decay=WD)
    
    print("\n[PHASE C] Training...")
    model.train()
    
    layer_densities = []
    
    for step in range(STEPS):
        # Anneal tau from 1.0 to 0.1 over 80% of steps
        tau = max(0.1, 1.0 - (step / (STEPS * 0.8)) * 0.9)
        
        xb, yb = get_batch()
        
        logits, ce_loss, aux_loss = model(xb, targets=yb, tau_override=tau)
        loss = ce_loss + AUX_LOSS_WEIGHT * aux_loss
        
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        
        if step % 50 == 0 or step == STEPS - 1:
            # Print per-layer density
            layer_densities = []
            for i, routing_assignments in enumerate(model.layer_routings):
                # routing_assignments: (batch, heads, seq_len, levels, p)
                mask = get_dynamic_ultrametric_mask(routing_assignments, p=model.p)
                # mask: (batch, heads, seq_len, seq_len)
                density = mask.float().mean().item()
                layer_densities.append(density)
                
            density_str = " | ".join([f"L{i}:{d:.3f}" for i, d in enumerate(layer_densities)])
            print(f"Step {step:>4} | Loss: {loss.item():.4f} | CE: {ce_loss.item():.4f} | Aux: {aux_loss.item():.4f} | Tau: {tau:.2f}")
            print(f"  Densities -> {density_str}")
            
    print("\n[PHASE D] Final Per-Layer Sparsity Polarization:")
    for i, d in enumerate(layer_densities):
        print(f"Layer {i}: Density = {d:.4f} ({'SPARSE/HIERARCHICAL' if d < 0.3 else 'DENSE/GLOBAL'})")

if __name__ == "__main__":
    main()
