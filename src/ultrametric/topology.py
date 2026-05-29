import torch
import math

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
