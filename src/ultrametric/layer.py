import torch
import torch.nn as nn
import torch.nn.functional as F
import math

from .topology import get_ultrametric_mask

class UltrametricAttention(nn.Module):
    """
    High-level PyTorch implementation of Ultrametric (p-adic) Attention.
    
    This layer drops the O(N^2) dense attention in favor of a block-sparse
    attention pattern modeled after the Bruhat-Tits tree topology.
    """
    def __init__(self, embed_dim: int, num_heads: int, p: int = 2):
        super().__init__()
        self.embed_dim = embed_dim
        self.num_heads = num_heads
        self.head_dim = embed_dim // num_heads
        self.p = p
        
        assert self.head_dim * num_heads == self.embed_dim, "embed_dim must be divisible by num_heads"
        
        self.q_proj = nn.Linear(embed_dim, embed_dim)
        self.k_proj = nn.Linear(embed_dim, embed_dim)
        self.v_proj = nn.Linear(embed_dim, embed_dim)
        self.o_proj = nn.Linear(embed_dim, embed_dim)

    def forward(self, x: torch.Tensor, dynamic_mask: torch.Tensor = None, routing: torch.Tensor = None) -> torch.Tensor:
        batch_size, seq_len, _ = x.size()
        
        # Project Q, K, V
        q = self.q_proj(x).view(batch_size, seq_len, self.num_heads, self.head_dim).transpose(1, 2)
        k = self.k_proj(x).view(batch_size, seq_len, self.num_heads, self.head_dim).transpose(1, 2)
        v = self.v_proj(x).view(batch_size, seq_len, self.num_heads, self.head_dim).transpose(1, 2)
        
        # Scaled dot-product attention
        scores = torch.matmul(q, k.transpose(-2, -1)) / math.sqrt(self.head_dim)
        
        if dynamic_mask is not None:
            mask = dynamic_mask.to(x.device)
        else:
            # Apply the Ultrametric Bruhat-Tits topological mask
            # We cache this in a real implementation, but compute it dynamically for the PoC
            mask = get_ultrametric_mask(seq_len, self.p).to(x.device)
            
        # Invert mask: True means keep, False means drop (-inf)
        scores = scores.masked_fill(~mask, float('-inf'))
        
        attn_weights = F.softmax(scores, dim=-1)
        
        if routing is not None:
            attn_weights = attn_weights * routing
            
        # Apply weights to values
        out = torch.matmul(attn_weights, v)
        
        # Reshape and project out
        out = out.transpose(1, 2).contiguous().view(batch_size, seq_len, self.embed_dim)
        return self.o_proj(out)
