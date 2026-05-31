import torch.nn as nn
from .surgery import SurgicalLlamaAttention

def inject_surgery(model):
    """
    Iterates over model.model.layers, replaces self_attn with SurgicalLlamaAttention,
    and copies over the pre-trained q_proj, k_proj, v_proj, o_proj weights.
    """
    for i, layer in enumerate(model.model.layers):
        old_attn = layer.self_attn
        
        # Instantiate new attention
        new_attn = SurgicalLlamaAttention(model.config, layer_idx=i)
        
        # Copy weights
        new_attn.q_proj.weight = old_attn.q_proj.weight
        new_attn.k_proj.weight = old_attn.k_proj.weight
        new_attn.v_proj.weight = old_attn.v_proj.weight
        new_attn.o_proj.weight = old_attn.o_proj.weight
        
        # If bias exists, copy that too
        if hasattr(old_attn.q_proj, 'bias') and old_attn.q_proj.bias is not None:
            new_attn.q_proj.bias = old_attn.q_proj.bias
        if hasattr(old_attn.k_proj, 'bias') and old_attn.k_proj.bias is not None:
            new_attn.k_proj.bias = old_attn.k_proj.bias
        if hasattr(old_attn.v_proj, 'bias') and old_attn.v_proj.bias is not None:
            new_attn.v_proj.bias = old_attn.v_proj.bias
        if hasattr(old_attn.o_proj, 'bias') and old_attn.o_proj.bias is not None:
            new_attn.o_proj.bias = old_attn.o_proj.bias

        # Move to the same device and dtype
        new_attn.to(old_attn.q_proj.weight.device, dtype=old_attn.q_proj.weight.dtype)
        
        # Replace the module
        layer.self_attn = new_attn
    
    return model
