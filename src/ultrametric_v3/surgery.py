import torch
import torch.nn as nn
import torch.nn.functional as F
import math
from typing import Optional

from src.ultrametric.layer import RotaryPositionEmbedding, apply_rotary_pos_emb
from src.ultrametric.topology import DynamicTopologyRouter, get_dynamic_ultrametric_mask

def repeat_kv(hidden_states: torch.Tensor, n_rep: int) -> torch.Tensor:
    """
    Equiv to torch.repeat_interleave(x, dim=1, repeats=n_rep)
    hidden_states: (batch, num_key_value_heads, seqlen, head_dim) -> (batch, num_attention_heads, seqlen, head_dim)
    """
    batch, num_key_value_heads, slen, head_dim = hidden_states.shape
    if n_rep == 1:
        return hidden_states
    hidden_states = hidden_states[:, :, None, :, :].expand(batch, num_key_value_heads, n_rep, slen, head_dim)
    return hidden_states.reshape(batch, num_key_value_heads * n_rep, slen, head_dim)



class SurgeryLossRamp(nn.Module):
    """
    Computes auxiliary loss for Llama Surgery to encourage sparsity.
    """
    def __init__(self, lambda_init: float = 0.0, lambda_max: float = 1.0, ramp_steps: int = 1000):
        super().__init__()
        self.lambda_init = lambda_init
        self.lambda_max = lambda_max
        self.ramp_steps = ramp_steps

    def get_lambda(self, step: int) -> float:
        if step >= self.ramp_steps:
            return self.lambda_max
        return self.lambda_init + (self.lambda_max - self.lambda_init) * (step / self.ramp_steps)

    def forward(self, g_h: torch.Tensor, step: int) -> torch.Tensor:
        """
        g_h: Tensor of shape (num_heads,)
        Loss penalizes dense execution (g_h \approx 0).
        """
        lambda_t = self.get_lambda(step)
        # Average over heads
        sparsity_penalty = (1.0 - g_h).mean()
        return lambda_t * sparsity_penalty

class SurgicalLlamaAttention(nn.Module):
    """
    Llama Attention modified for Continuous Sparsification (Surgery).
    Integrates the per-head routing gate to interpolate between dense and sparse topology.
    """
    def __init__(self, config, layer_idx: Optional[int] = None):
        super().__init__()
        self.config = config
        self.layer_idx = layer_idx
        
        self.embed_dim = config.hidden_size
        self.num_heads = config.num_attention_heads
        self.head_dim = self.embed_dim // self.num_heads
        
        # GQA compliance
        self.num_key_value_heads = getattr(config, "num_key_value_heads", self.num_heads)
        self.num_key_value_groups = self.num_heads // self.num_key_value_heads
        
        # Get surgery-specific config params, default to some values if not present
        self.p = getattr(config, "surgical_p", 2)
        self.alpha = getattr(config, "surgical_alpha", 10000.0)
        
        self.scale = 1.0 / math.sqrt(self.head_dim)

        assert self.head_dim * self.num_heads == self.embed_dim, "embed_dim must be divisible by num_heads"

        self.q_proj = nn.Linear(self.embed_dim, self.num_heads * self.head_dim, bias=getattr(config, "attention_bias", False))
        self.k_proj = nn.Linear(self.embed_dim, self.num_key_value_heads * self.head_dim, bias=getattr(config, "attention_bias", False))
        self.v_proj = nn.Linear(self.embed_dim, self.num_key_value_heads * self.head_dim, bias=getattr(config, "attention_bias", False))
        self.o_proj = nn.Linear(self.num_heads * self.head_dim, self.embed_dim, bias=getattr(config, "attention_bias", False))

        max_pos_embeddings = getattr(config, "max_position_embeddings", 8192)
        self.rope = RotaryPositionEmbedding(self.head_dim, max_pos_embeddings)
        self.attn_dropout = nn.Dropout(getattr(config, "attention_dropout", 0.0))
        
        self.router = DynamicTopologyRouter(
            embed_dim=self.embed_dim,
            seq_len=max_pos_embeddings,
            num_heads=self.num_heads,
            p=self.p
        )

    def forward(
        self,
        hidden_states: torch.Tensor,
        position_embeddings: Optional[tuple[torch.Tensor, torch.Tensor]] = None,
        attention_mask: Optional[torch.Tensor] = None,
        past_key_values = None,
        **kwargs,
    ):
        batch_size, seq_len, _ = hidden_states.size()
        past_key_value = kwargs.get("past_key_value", past_key_values)

        tau = getattr(self.config, "surgical_tau", 1.0)
        curr_assignments, load_balance_loss = self.router(hidden_states, tau_override=tau)
        self.current_penalty = load_balance_loss

        if past_key_value is None or seq_len > 1:
            self._cached_assignments = curr_assignments
            assignments = curr_assignments
        else:
            if hasattr(self, '_cached_assignments') and self._cached_assignments is not None:
                assignments = torch.cat([self._cached_assignments, curr_assignments], dim=2)
                self._cached_assignments = assignments
            else:
                assignments = curr_assignments
                self._cached_assignments = assignments

        # Accumulate sparsity penalty during forward pass (REMOVED for gradient checkpointing safety)

        # Project Q, K, V
        q = self.q_proj(hidden_states).view(batch_size, seq_len, self.num_heads, self.head_dim).transpose(1, 2)
        k = self.k_proj(hidden_states).view(batch_size, seq_len, self.num_key_value_heads, self.head_dim).transpose(1, 2)
        v = self.v_proj(hidden_states).view(batch_size, seq_len, self.num_key_value_heads, self.head_dim).transpose(1, 2)

        # Apply RoPE
        if position_embeddings is not None:
            cos, sin = position_embeddings
            # HF position_embeddings can be 3D or 4D depending on version
            if cos.dim() == 3:
                cos = cos.unsqueeze(1)
                sin = sin.unsqueeze(1)
            def rotate_half(x):
                x1, x2 = x[..., : x.shape[-1] // 2], x[..., x.shape[-1] // 2 :]
                return torch.cat((-x2, x1), dim=-1)
            q = (q * cos) + (rotate_half(q) * sin)
            k = (k * cos) + (rotate_half(k) * sin)
        else:
            cos, sin = self.rope(q)
            q, k = apply_rotary_pos_emb(q, k, cos, sin)

        if past_key_value is not None:
            if hasattr(past_key_value, "update"):
                cache_kwargs = {"sin": getattr(self, "_dummy", None), "cos": getattr(self, "_dummy", None)}
                k, v = past_key_value.update(k, v, self.layer_idx, cache_kwargs)
            elif isinstance(past_key_value, tuple):
                # tuple format: (past_k, past_v)
                k = torch.cat([past_key_value[0], k], dim=-2)
                v = torch.cat([past_key_value[1], v], dim=-2)
                past_key_value = (k, v)

        # Broadcast KV for GQA before attention computation
        k = repeat_kv(k, self.num_key_value_groups)
        v = repeat_kv(v, self.num_key_value_groups)

        # Raw attention scores
        scores = torch.matmul(q, k.transpose(-2, -1)) * self.scale

        # Base causal masking (simplified, since HF usually passes attention_mask)
        # HF passes attention_mask as (batch_size, 1, tgt_len, src_len) with -inf for masked
        if attention_mask is not None:
            # Handle possible broadcast shapes
            scores = scores + attention_mask
        else:
            causal_mask = torch.triu(torch.ones(seq_len, seq_len, dtype=torch.bool, device=hidden_states.device), diagonal=1)
            scores = scores.masked_fill(causal_mask, float('-inf'))

        # Dynamic Sparsification
        L = k.shape[-2]
        full_mask = get_dynamic_ultrametric_mask(assignments, p=self.p, local_window=128).to(hidden_states.device)
        um_mask_bool = full_mask > 0.5  # Shape: (B, H, S_full, L) or (B, H, L, L)
        
        if seq_len == 1 and L > 1:
            # Decode phase: extract the row for the current absolute token index
            um_mask_bool = um_mask_bool[:, :, -1:, :]
            full_mask = full_mask[:, :, -1:, :]
            
        sparse_scores = scores.masked_fill(~um_mask_bool, float('-inf'))
        attn_weights = F.softmax(sparse_scores, dim=-1, dtype=torch.float32)
        attn_weights = torch.nan_to_num(attn_weights, 0.0)

        # CRITICAL FIX: Multiply by the differentiable soft mask!
        # The boolean mask blocked gradients to the router. By multiplying by the STE full_mask,
        # the language modeling loss can successfully backpropagate into the routing assignments!
        attn_weights = attn_weights * full_mask
        attn_weights = attn_weights / (attn_weights.sum(dim=-1, keepdim=True) + 1e-8)

        attn_weights = attn_weights.to(v.dtype)
        attn_weights = self.attn_dropout(attn_weights)

        out = torch.matmul(attn_weights, v)
        out = out.transpose(1, 2).contiguous().view(batch_size, seq_len, self.embed_dim)
        
        out = self.o_proj(out)
        
        return out, attn_weights

