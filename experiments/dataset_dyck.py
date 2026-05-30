"""
Dataset generator for Complex Dyck-k languages.
Task: Next-Token Prediction. Given a valid Dyck-k prefix, predict the correct closing bracket.
"""

import torch
import random

K = 2
VOCAB_SIZE = 2 * K + 1
SEQ_LEN = 32

def generate_dyck_string(k, max_depth, current_depth=0):
    """
    Recursively generates a valid Dyck-k string.
    """
    if current_depth >= max_depth:
        return []
        
    result = []
    # Generate 1-3 pairs at the root, and 0-2 pairs at deeper levels
    num_siblings = random.randint(1, 3) if current_depth == 0 else random.randint(0, 2)
    
    for _ in range(num_siblings):
        bracket_type = random.randint(1, k) # 1 to k are opening brackets
        inner = generate_dyck_string(k, max_depth, current_depth + 1)
        result.extend([bracket_type] + inner + [bracket_type + k])
        
    return result

def make_dyck_dataset(k=K, num_samples=20000, seq_len=SEQ_LEN, max_depth=12, frac_train=0.8, seed=42):
    """
    Generates a dataset of Dyck-k prefixes for Next-Token Prediction.
    Vocab: 
      0: PAD
      1..k: Opening brackets
      k+1..2k: Closing brackets
      
    Returns:
      train_seqs, train_labels, test_seqs, test_labels
      Seamlessly matches make_dataset() interface.
    """
    random.seed(seed)
    torch.manual_seed(seed)
    
    seqs = []
    labels = []
    
    attempts = 0
    # Generate until we have enough samples
    while len(seqs) < num_samples:
        attempts += 1
        if attempts > num_samples * 100:
            break
            
        full_string = generate_dyck_string(k, max_depth)
        if len(full_string) < 2:
            continue
            
        # Find all valid positions where a closing bracket occurs
        closing_positions = []
        stack = []
        for i, token in enumerate(full_string):
            if 1 <= token <= k:
                stack.append(token)
            elif k + 1 <= token <= 2 * k:
                if not stack:
                    break # Should not happen with our generator
                expected_close = stack.pop() + k
                assert token == expected_close
                closing_positions.append((i, expected_close))
                
        if not closing_positions:
            continue
            
        # Pick a random closing position to be the target
        pos, target = random.choice(closing_positions)
        prefix = full_string[:pos]
        
        # Pad or truncate prefix to seq_len
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
    
    return (seqs_t[train_idx], labels_t[train_idx], 
            seqs_t[test_idx], labels_t[test_idx])

if __name__ == "__main__":
    tr_s, tr_l, te_s, te_l = make_dyck_dataset(k=2, num_samples=10, seq_len=16)
    print("Train sequences shape:", tr_s.shape)
    print("Sample sequence (0=PAD, 1/2=OPEN, 3/4=CLOSE):")
    print(tr_s[0].tolist())
    print("Sample target:")
    print(tr_l[0].item())
