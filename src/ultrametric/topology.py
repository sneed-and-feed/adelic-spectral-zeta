import torch
import torch.nn as nn
import torch.nn.functional as F
import math

class DynamicTopologyRouter(nn.Module):
    """
    Learned Dynamic Topology router mapping continuous token embeddings 
    into discrete Bruhat-Tits tree branches based on semantic meaning.
    """
    def __init__(self, embed_dim: int, seq_len: int, p: int = 2, tau: float = 1.0, hard: bool = True):
        super().__init__()
        self.embed_dim = embed_dim
        self.p = p
        self.levels = int(math.ceil(math.log(max(seq_len, 1), p)))
        self.tau = tau
        self.hard = hard
        
        # Project continuous token embeddings to unnormalized log-probabilities over each tree level
        self.proj = nn.Linear(embed_dim, self.levels * self.p)
        
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        x: (batch, seq_len, embed_dim)
        Returns:
            assignments: (batch, seq_len, levels, p) soft or hard assignments
        """
        batch_size, seq_len, _ = x.shape
        logits = self.proj(x).view(batch_size, seq_len, self.levels, self.p)
        # Gumbel-Softmax for differentiable discrete routing at every level of the tree
        assignments = F.gumbel_softmax(logits, tau=self.tau, hard=self.hard, dim=-1)
        return assignments

def get_dynamic_ultrametric_mask(assignments: torch.Tensor, p: int = 2, max_dist: int = None) -> torch.Tensor:
    """
    Generates a dynamic ultrametric mask based on learned token assignments.
    Two tokens attend to each other if their expected p-adic distance is within max_dist.
    """
    batch_size, seq_len, levels, p_dim = assignments.shape
    device = assignments.device
    
    # M[b, i, j, l] is the probability token i and j take the same branch at level l
    M = torch.einsum('bilp,bjlp->bijl', assignments, assignments)
    
    # expected_dist = levels - sum_{l=0}^{levels-1} prod_{m=l}^{levels-1} M_m
    # We do a reversed cumulative product over levels
    M_flipped = M.flip(dims=[-1])
    P_flipped = M_flipped.cumprod(dim=-1)
    sum_P = P_flipped.sum(dim=-1)
    expected_dist = levels - sum_P
    
    if max_dist is None:
        # If not specified, default to half the max possible depth
        max_dist = levels // 2

    # Use a Straight-Through Estimator (STE) to make the hard mask differentiable
    temperature = 0.5
    soft_mask = torch.sigmoid((max_dist - expected_dist) / temperature)
    hard_mask = (expected_dist <= max_dist).float()
    
    # mask forward is hard_mask, backward is soft_mask
    mask = hard_mask.detach() - soft_mask.detach() + soft_mask
    return mask

def get_ultrametric_mask(seq_len: int, p: int = 2) -> torch.Tensor:
    """
    Generates a boolean mask for an ultrametric (p-adic) attention layer.
    
    In a standard dense transformer, every token attends to every other token (or causal).
    In an ultrametric Bruhat-Tits topology, tokens are leaves on a tree. 
    Tokens only strongly attend to tokens that share a deep common ancestor.
    
    This function generates a block-sparse mask where the density decreases 
    as the p-adic distance increases, dropping connections that are topologically "far".
    """
    # Ensure sequence length is a power of p for perfect tree mapping
    levels = int(math.ceil(math.log(seq_len, p)))
    pad_len = p ** levels
    
    # Initialize full mask
    mask = torch.zeros((pad_len, pad_len), dtype=torch.bool)
    
    # Base heuristic: We keep local blocks fully dense, and progressively drop 
    # out off-diagonal blocks to simulate the tree distance.
    for level in range(levels):
        block_size = p ** level
        # A simple fractal block-sparse pattern
        for i in range(0, pad_len, block_size):
            # Tokens within the same block share a common ancestor at this level
            # We keep the block dense
            mask[i:i+block_size, i:i+block_size] = True
            
    return mask[:seq_len, :seq_len]

def compute_p_adic_distance(i: int, j: int, p: int = 2) -> int:
    """
    Computes the p-adic distance between two token indices.
    This corresponds to the height of their lowest common ancestor in a p-ary tree.
    """
    if i == j:
        return 0
    # The lowest common ancestor height in a complete p-ary tree
    # is determined by the highest differing bit in base p.
    diff = i ^ j
    return int(math.floor(math.log(diff, p))) + 1
