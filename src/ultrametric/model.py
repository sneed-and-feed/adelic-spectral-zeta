import torch
import torch.nn as nn
from .layer import UltrametricAttention

class UltrametricTransformerBlock(nn.Module):
    """
    A standard transformer block (Pre-LN architecture) where the 
    dense self-attention is replaced by the sparse p-adic UltrametricAttention.
    """
    def __init__(self, embed_dim: int, num_heads: int, p: int = 2, mlp_ratio: float = 4.0):
        super().__init__()
        self.ln_1 = nn.LayerNorm(embed_dim)
        self.attn = UltrametricAttention(embed_dim, num_heads, p)
        
        self.ln_2 = nn.LayerNorm(embed_dim)
        mlp_dim = int(embed_dim * mlp_ratio)
        self.mlp = nn.Sequential(
            nn.Linear(embed_dim, mlp_dim),
            nn.GELU(),
            nn.Linear(mlp_dim, embed_dim)
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # Pre-LN
        h = x + self.attn(self.ln_1(x))
        out = h + self.mlp(self.ln_2(h))
        return out
