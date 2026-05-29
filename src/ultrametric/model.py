import torch
import torch.nn as nn
import math
from .layer import UltrametricAttention

class UltrametricTransformerBlock(nn.Module):
    """
    A standard transformer block (Pre-LN architecture) where the 
    dense self-attention is replaced by the sparse p-adic UltrametricAttention.
    """
    def __init__(self, embed_dim: int, num_heads: int, p: int = 2, mlp_ratio: float = 4.0):
        super().__init__()
        self.p = p
        self.embed_dim = embed_dim
        
        # Allocate capacity for the interior nodes of the Bruhat-Tits tree
        self.interior_token = nn.Parameter(torch.randn(1, 1, embed_dim))
        
        self.ln_1 = nn.LayerNorm(embed_dim)
        self.attn = UltrametricAttention(embed_dim, num_heads, p)
        
        self.ln_2 = nn.LayerNorm(embed_dim)
        mlp_dim = int(embed_dim * mlp_ratio)
        self.mlp = nn.Sequential(
            nn.Linear(embed_dim, mlp_dim),
            nn.GELU(),
            nn.Linear(mlp_dim, embed_dim)
        )

    def forward(self, x: torch.Tensor, interior_nodes: torch.Tensor = None, dynamic_mask: torch.Tensor = None, routing: torch.Tensor = None, return_interior: bool = False):
        batch_size, seq_len, _ = x.size()
        
        # Allocate interior nodes if they are not explicitly passed
        if interior_nodes is None:
            levels = int(math.ceil(math.log(seq_len, self.p)))
            pad_len = self.p ** levels
            num_interior = (pad_len - 1) // (self.p - 1)
            interior_nodes = self.interior_token.expand(batch_size, num_interior, self.embed_dim)
            
        num_interior = interior_nodes.size(1)
        
        # Concatenate interior nodes and boundary tokens
        x_full = torch.cat([interior_nodes, x], dim=1)
        
        # Pre-LN and Attention
        h = self.ln_1(x_full)
        attn_out = self.attn(h, dynamic_mask=dynamic_mask, routing=routing)
        x_full = x_full + attn_out
        
        # MLP
        x_full = x_full + self.mlp(self.ln_2(x_full))
        
        # Extract the updated components
        out_interior = x_full[:, :num_interior, :]
        out_leaves = x_full[:, num_interior:, :]
        
        if return_interior:
            return out_leaves, out_interior
        return out_leaves
