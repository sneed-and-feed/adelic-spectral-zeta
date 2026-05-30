import random
import torch
from torch.utils.data import IterableDataset

VOCAB = {
    "<PAD>": 0,
    "(": 1,
    ")": 2,
    "[": 3,
    "]": 4,
    "<FILLER>": 5
}

class Dyck2Dataset(IterableDataset):
    def __init__(self, seq_len=128, filler_prob=0.0, batch_size=32, num_batches=1000):
        super().__init__()
        self.seq_len = seq_len
        self.filler_prob = filler_prob
        self.batch_size = batch_size
        self.num_batches = num_batches
        self.pairs = {'(': ')', '[': ']'}
        self.open_brackets = list(self.pairs.keys())

    def _generate_dyck2(self, n):
        stack = []
        seq = []
        for remaining in range(n, 0, -1):
            if len(stack) == 0:
                choice = "OPEN"
            elif len(stack) == remaining:
                choice = "CLOSE"
            else:
                choice = random.choice(["OPEN", "CLOSE"])
                
            if choice == "OPEN":
                b = random.choice(self.open_brackets)
                seq.append(b)
                stack.append(self.pairs[b])
            else:
                seq.append(stack.pop())
        return seq

    def _generate_sequence(self):
        # Determine number of fillers
        num_fillers = sum(random.random() < self.filler_prob for _ in range(self.seq_len))
        # Ensure remaining dyck tokens are even
        if (self.seq_len - num_fillers) % 2 != 0:
            if num_fillers > 0:
                num_fillers -= 1
            else:
                num_fillers += 1
                
        num_dyck = self.seq_len - num_fillers
        dyck_seq = self._generate_dyck2(num_dyck)
        
        # Interleave
        seq = []
        dyck_idx = 0
        filler_count = 0
        
        for i in range(self.seq_len):
            rem_slots = self.seq_len - i
            rem_fillers = num_fillers - filler_count
            
            if rem_fillers > 0 and dyck_idx < num_dyck:
                if random.random() < rem_fillers / rem_slots:
                    seq.append("<FILLER>")
                    filler_count += 1
                else:
                    seq.append(dyck_seq[dyck_idx])
                    dyck_idx += 1
            elif rem_fillers > 0:
                seq.append("<FILLER>")
                filler_count += 1
            else:
                seq.append(dyck_seq[dyck_idx])
                dyck_idx += 1
                
        return [VOCAB[token] for token in seq]

    def __iter__(self):
        for _ in range(self.num_batches):
            batch_x = []
            for _ in range(self.batch_size):
                batch_x.append(self._generate_sequence())
            yield torch.tensor(batch_x, dtype=torch.long)

if __name__ == "__main__":
    ds = Dyck2Dataset(seq_len=16, filler_prob=0.25, batch_size=2, num_batches=1)
    for b in ds:
        print("Batch shape:", b.shape)
        # Reverse lookup for printing
        rev_vocab = {v: k for k, v in VOCAB.items()}
        for seq in b:
            print(" ".join([rev_vocab[t.item()] for t in seq]))
