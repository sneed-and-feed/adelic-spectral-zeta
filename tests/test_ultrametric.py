import torch
import pytest
from src.ultrametric.topology import get_ultrametric_mask, compute_p_adic_distance
from src.ultrametric.layer import UltrametricAttention
from src.ultrametric.model import UltrametricTransformerBlock

def test_p_adic_distance():
    # Distance to self is 0
    assert compute_p_adic_distance(0, 0, p=2) == 0
    # Siblings
    assert compute_p_adic_distance(0, 1, p=2) == 1
    # Cousins
    assert compute_p_adic_distance(0, 2, p=2) == 2
    assert compute_p_adic_distance(0, 3, p=2) == 2

def test_ultrametric_mask_shape():
    seq_len = 16
    mask = get_ultrametric_mask(seq_len, p=2)
    assert mask.shape == (seq_len, seq_len)
    # The diagonal should be entirely True (self-attention is always kept)
    assert torch.all(mask.diag())

def test_ultrametric_attention_forward():
    batch_size = 2
    seq_len = 16
    embed_dim = 64
    num_heads = 4
    
    layer = UltrametricAttention(embed_dim, num_heads)
    x = torch.randn(batch_size, seq_len, embed_dim)
    
    out = layer(x)
    assert out.shape == (batch_size, seq_len, embed_dim)

def test_ultrametric_attention_backward():
    batch_size = 2
    seq_len = 16
    embed_dim = 64
    num_heads = 4
    
    layer = UltrametricAttention(embed_dim, num_heads)
    x = torch.randn(batch_size, seq_len, embed_dim, requires_grad=True)
    
    out = layer(x)
    loss = out.sum()
    loss.backward()
    
    # Check if gradients flow back to input
    assert x.grad is not None
    assert not torch.isnan(x.grad).any()

def test_transformer_block():
    block = UltrametricTransformerBlock(embed_dim=64, num_heads=4)
    x = torch.randn(2, 16, 64)
    out = block(x)
    assert out.shape == (2, 16, 64)
