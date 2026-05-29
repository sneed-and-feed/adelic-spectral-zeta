import torch
import torch.nn as nn
import torch.nn.functional as F
import math

from .topology import get_ultrametric_mask

def get_tree_adjacency_mask(routing: torch.Tensor, num_interior: int, seq_len: int, p: int = 2) -> torch.Tensor:
    """
    Generates a boolean adjacency mask for a tree topology.
    routing: (batch, seq_len, levels, p) one-hots or (batch, seq_len, levels) branch IDs
    Returns: mask of shape (batch, num_interior + seq_len, num_interior + seq_len)
    """
    if routing.dim() == 4:
        routing_paths = routing.argmax(dim=-1)
    else:
        routing_paths = routing
        
    batch_size, _, levels = routing_paths.shape
    total_len = num_interior + seq_len
    device = routing_paths.device
    
    # Build mask
    mask = torch.zeros((batch_size, total_len, total_len), dtype=torch.bool, device=device)
    
    # Self loops
    idx = torch.arange(total_len, device=device)
    mask[:, idx, idx] = True
    
    # Interior to interior
    if num_interior > 1:
        i_idx = torch.arange(1, num_interior, device=device)
        parent_idx = (i_idx - 1) // p
        mask[:, i_idx, parent_idx] = True
        mask[:, parent_idx, i_idx] = True
    
    # Sequence tokens to their leaf parents
    current_node_offset = 0
    current_path_val = torch.zeros((batch_size, seq_len), dtype=torch.long, device=device)
    
    for l in range(1, levels):
        current_node_offset += p**(l-1)
        current_path_val = current_path_val * p + routing_paths[:, :, l-1]
        
    leaf_parents = current_node_offset + current_path_val # (batch, seq_len)
    
    seq_idx = num_interior + torch.arange(seq_len, device=device)
    batch_idx = torch.arange(batch_size, device=device).unsqueeze(1)
    seq_idx_broadcast = seq_idx.unsqueeze(0).expand(batch_size, seq_len)
    
    mask[batch_idx, seq_idx_broadcast, leaf_parents] = True
    mask[batch_idx, leaf_parents, seq_idx_broadcast] = True
    
    return mask
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

    def forward(self, x: torch.Tensor, num_interior: int = 0, dynamic_mask: torch.Tensor = None, routing: torch.Tensor = None) -> torch.Tensor:
        batch_size, seq_len, _ = x.size()
        
        # Project Q, K, V
        q = self.q_proj(x).view(batch_size, seq_len, self.num_heads, self.head_dim).transpose(1, 2)
        k = self.k_proj(x).view(batch_size, seq_len, self.num_heads, self.head_dim).transpose(1, 2)
        v = self.v_proj(x).view(batch_size, seq_len, self.num_heads, self.head_dim).transpose(1, 2)
        
        # Scaled dot-product attention
        scores = torch.matmul(q, k.transpose(-2, -1)) / math.sqrt(self.head_dim)
        
        total_len = x.size(1)
        seq_len = total_len - num_interior
        
        if routing is not None:
            mask = get_tree_adjacency_mask(routing, num_interior, seq_len, self.p)
            mask = mask.unsqueeze(1) # (batch, 1, total_len, total_len)
        elif dynamic_mask is not None:
            mask = dynamic_mask.to(x.device).unsqueeze(1)
        else:
            # Fallback to dense if no routing provided
            mask = torch.ones((batch_size, 1, total_len, total_len), dtype=torch.bool, device=x.device)
            
        # Invert mask: True means keep, False means drop (-inf)
        scores = scores.masked_fill(~mask, float('-inf'))
        
        attn_weights = F.softmax(scores, dim=-1)
            
        # Apply weights to values
        out = torch.matmul(attn_weights, v)
        
        # Reshape and project out
        out = out.transpose(1, 2).contiguous().view(batch_size, total_len, self.embed_dim)
        return self.o_proj(out)
