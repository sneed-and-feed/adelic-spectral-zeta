import random
import torch
import math

VOCAB = {
    '[PAD]': 0,
    '[': 1, ']': 2, 'MIN': 3, 'MAX': 4, 'MED': 5, 'SUMMOD': 6,
    '0': 7, '1': 8, '2': 9, '3': 10, '4': 11, '5': 12, '6': 13, '7': 14, '8': 15, '9': 16,
    '=': 17
}
INV_VOCAB = {v: k for k, v in VOCAB.items()}
VOCAB_SIZE = len(VOCAB)

def generate_listops_tree(max_depth, current_depth=1):
    # 70% chance to just output a digit if not at root, or if max depth reached
    if current_depth >= max_depth or (current_depth > 1 and random.random() > 0.3):
        val = random.randint(0, 9)
        return val, [str(val)]
    
    op = random.choice(['MIN', 'MAX', 'MED', 'SUMMOD'])
    # Lower max branching factor to prevent massive tree rejection rates
    num_args = random.randint(2, 4)
    
    args_vals = []
    tokens = ['[', op]
    
    for _ in range(num_args):
        val, sub_tokens = generate_listops_tree(max_depth, current_depth + 1)
        args_vals.append(val)
        tokens.extend(sub_tokens)
        
    tokens.append(']')
    
    if op == 'MIN':
        res = min(args_vals)
    elif op == 'MAX':
        res = max(args_vals)
    elif op == 'MED':
        sorted_vals = sorted(args_vals)
        res = sorted_vals[(len(sorted_vals) - 1) // 2]
    elif op == 'SUMMOD':
        res = sum(args_vals) % 10
        
    return res, tokens

def make_listops_dataset(num_samples=10000, seq_len=128, max_depth=5, seed=42):
    random.seed(seed)
    torch.manual_seed(seed)
    
    seqs = []
    labels = []
    
    attempts = 0
    while len(seqs) < num_samples:
        attempts += 1
        if attempts > num_samples * 100:
            break
            
        res, tokens = generate_listops_tree(max_depth)
        tokens.append('=')
        
        if len(tokens) > seq_len:
            continue
        if len(tokens) < 5:
            continue
            
        token_ids = [VOCAB[t] for t in tokens]
        
        # Left-pad to exactly seq_len so the '=' is always at the very end
        pad_len = seq_len - len(token_ids)
        token_ids = [0] * pad_len + token_ids
        
        seqs.append(token_ids)
        labels.append(VOCAB[str(res)])
        
        if len(seqs) % 2000 == 0:
            print(f"    ...generated {len(seqs)} / {num_samples} samples", flush=True)
            
    return torch.tensor(seqs, dtype=torch.long), torch.tensor(labels, dtype=torch.long)
