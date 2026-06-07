import torch
import torch.nn as nn
import torch.nn.functional as F
import math
from transformers import AutoConfig, AutoModelForCausalLM, AutoTokenizer

# Import Llama Surgery components
from llama_surgery import inject_surgery, SurgicalLlamaAttention, DynamicTopologyRouter
from llama_surgery.layer import apply_rotary_pos_emb

# ==============================================================================
# 1. Vision Projection Layer (ViT patch to Llama embedding space)
# ==============================================================================

class VisionProjection(nn.Module):
    """
    Projects raw visual features (e.g. from a ViT output) into the LLM's hidden space.
    Typical ViT dimension is 768 (ViT-Base); Llama hidden size is 2048 or 4096.
    """
    def __init__(self, vit_dim: int = 768, llm_dim: int = 2048):
        super().__init__()
        self.proj = nn.Sequential(
            nn.Linear(vit_dim, llm_dim),
            nn.GELU(),
            nn.Linear(llm_dim, llm_dim)
        )
        
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.proj(x)


# ==============================================================================
# 2. Surgical Multimodal Attention with Ternary Routing (p=3)
# ==============================================================================

class SurgicalMultimodalAttention(SurgicalLlamaAttention):
    """
    Extends SurgicalLlamaAttention to support Ternary Arity (p=3) for multimodal routing:
      Branch 0: Text
      Branch 1: Vision
      Branch 2: Audio / Auxiliary
    """
    def __init__(self, config, layer_idx=None):
        # Force arity to 3 for Ternary Modality routing
        config.surgical_p = 3
        super().__init__(config, layer_idx=layer_idx)
        
    def forward(
        self,
        hidden_states: torch.Tensor,
        position_embeddings = None,
        attention_mask = None,
        past_key_values = None,
        modality_indices = None, # Dict containing tensor of shape (seq_len,) indicating token modality (0=Text, 1=Vision)
        **kwargs,
    ):
        batch_size, seq_len, _ = hidden_states.size()
        past_key_value = kwargs.get("past_key_value", past_key_values)
        tau = getattr(self.config, "surgical_tau", 1.0)
        
        # Get routing assignments and balance loss
        curr_assignments, load_balance_loss = self.router(hidden_states, tau_override=tau)
        self.current_penalty = load_balance_loss
        
        # MODALITY SEGREGATION AUXILIARY LOSS
        # If modality indices are provided, we can add a loss to encourage
        # early layers to separate text and vision onto distinct tree branches.
        if modality_indices is not None and self.training:
            # modality_indices: (seq_len,) containing 0 or 1
            # curr_assignments: (batch, num_heads, seq_len, levels, p)
            # We look at level 0 (the primary branch decision)
            level0_routing = curr_assignments[..., 0, :] # (batch, num_heads, seq_len, p)
            
            # We want Text tokens (modality=0) to have high probability in Branch 0,
            # and Vision tokens (modality=1) to have high probability in Branch 1.
            text_mask = (modality_indices == 0).float().view(1, 1, seq_len, 1)
            vision_mask = (modality_indices == 1).float().view(1, 1, seq_len, 1)
            
            # Text routing loss: penalize if text is not on Branch 0
            text_loss = (1.0 - level0_routing[..., 0]) * text_mask.squeeze(-1)
            # Vision routing loss: penalize if vision is not on Branch 1
            vision_loss = (1.0 - level0_routing[..., 1]) * vision_mask.squeeze(-1)
            
            seg_loss = (text_loss.sum() + vision_loss.sum()) / (seq_len + 1e-8)
            self.current_penalty = load_balance_loss + 0.5 * seg_loss
            
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

        # Project Q, K, V
        q = self.q_proj(hidden_states).view(batch_size, seq_len, self.num_heads, self.head_dim).transpose(1, 2)
        k = self.k_proj(hidden_states).view(batch_size, seq_len, self.num_key_value_heads, self.head_dim).transpose(1, 2)
        v = self.v_proj(hidden_states).view(batch_size, seq_len, self.num_key_value_heads, self.head_dim).transpose(1, 2)

        # Apply RoPE
        if position_embeddings is not None:
            cos, sin = position_embeddings
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

        # Broadcast KV for GQA
        k = self._repeat_kv(k, self.num_key_value_groups)
        v = self._repeat_kv(v, self.num_key_value_groups)

        # Standard attention computation using p-adic distance mask
        scores = torch.matmul(q.to(torch.float32), k.to(torch.float32).transpose(-2, -1)) * self.scale
        if attention_mask is not None:
            scores = scores + attention_mask
        else:
            causal_mask = torch.triu(torch.ones(seq_len, seq_len, dtype=torch.bool, device=hidden_states.device), diagonal=1)
            scores = scores.masked_fill(causal_mask, float('-inf'))

        # Retrieve dynamic topological mask (using arity p=3)
        from llama_surgery.topology import get_dynamic_ultrametric_mask
        local_window = getattr(self.config, "surgical_local_window", 16)
        full_mask = get_dynamic_ultrametric_mask(assignments, p=self.p, local_window=local_window).to(hidden_states.device)
        um_mask_bool = full_mask > 0.5
        
        sparse_scores = scores.masked_fill(~um_mask_bool, float('-inf'))
        is_all_neg_inf = (sparse_scores == float('-inf')).all(dim=-1, keepdim=True)
        sparse_scores = sparse_scores.masked_fill(is_all_neg_inf, 0.0)
        
        attn_weights = F.softmax(sparse_scores, dim=-1, dtype=torch.float32)
        attn_weights = torch.nan_to_num(attn_weights, 0.0)
        
        # STE backprop bridge
        attn_weights = attn_weights * full_mask
        attn_weights = attn_weights / (attn_weights.sum(dim=-1, keepdim=True) + 1e-8)

        attn_weights = attn_weights.to(v.dtype)
        attn_weights = self.attn_dropout(attn_weights)

        out = torch.matmul(attn_weights, v)
        out = out.transpose(1, 2).contiguous().view(batch_size, seq_len, self.embed_dim)
        out = self.o_proj(out)
        
        return out, attn_weights

    def _repeat_kv(self, x, n_rep):
        if n_rep == 1:
            return x
        batch, num_key_value_heads, slen, head_dim = x.shape
        x = x[:, :, None, :, :].expand(batch, num_key_value_heads, n_rep, slen, head_dim)
        return x.reshape(batch, num_key_value_heads * n_rep, slen, head_dim)


# ==============================================================================
# 3. Modality Injection Patcher
# ==============================================================================

def inject_multimodal_surgery(model):
    """
    Replaces Llama attention layers with SurgicalMultimodalAttention (p=3).
    """
    for i, layer in enumerate(model.model.layers):
        old_attn = layer.self_attn
        new_attn = SurgicalMultimodalAttention(model.config, layer_idx=i)
        
        # Copy weights
        new_attn.q_proj.weight = old_attn.q_proj.weight
        new_attn.k_proj.weight = old_attn.k_proj.weight
        new_attn.v_proj.weight = old_attn.v_proj.weight
        new_attn.o_proj.weight = old_attn.o_proj.weight
        
        if hasattr(old_attn.q_proj, 'bias') and old_attn.q_proj.bias is not None:
            new_attn.q_proj.bias = old_attn.q_proj.bias
        if hasattr(old_attn.k_proj, 'bias') and old_attn.k_proj.bias is not None:
            new_attn.k_proj.bias = old_attn.k_proj.bias
        if hasattr(old_attn.v_proj, 'bias') and old_attn.v_proj.bias is not None:
            new_attn.v_proj.bias = old_attn.v_proj.bias
        if hasattr(old_attn.o_proj, 'bias') and old_attn.o_proj.bias is not None:
            new_attn.o_proj.bias = old_attn.o_proj.bias
            
        new_attn.to(old_attn.q_proj.weight.device, dtype=old_attn.q_proj.weight.dtype)
        layer.self_attn = new_attn
        
    return model


# ==============================================================================
# 4. Interactive Simulation & Verification
# ==============================================================================

def run_multimodal_simulation():
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Running Multimodal Topological Fusion simulation on {device}...")
    
    # 1. Initialize a tiny model to represent our LLM backbone
    config = AutoConfig.from_pretrained("TinyLlama/TinyLlama-1.1B-Intermediate-Step-1431k-3T")
    config.num_hidden_layers = 2
    config.hidden_size = 64
    config.intermediate_size = 128
    config.num_attention_heads = 4
    config.num_key_value_heads = 2
    config.head_dim = 16
    config.max_position_embeddings = 256
    
    model = AutoModelForCausalLM.from_config(config)
    model = inject_multimodal_surgery(model)
    model.to(device)
    
    # 2. Setup mock multimodal inputs (Interleaved Text & Image tokens)
    # Let's say our sequence has:
    #   - 16 Text tokens (modality 0)
    #   - 32 Image patch tokens (modality 1)
    #   - 16 Text tokens (modality 0)
    # Total seq_len = 64
    seq_len = 64
    text_len1 = 16
    image_len = 32
    text_len2 = 16
    
    # Define modality index vector (0 = Text, 1 = Vision)
    modality_indices = torch.cat([
        torch.zeros(text_len1, dtype=torch.long),
        torch.ones(image_len, dtype=torch.long),
        torch.zeros(text_len2, dtype=torch.long)
    ]).to(device)
    
    # Define static inputs and projector
    text_ids = torch.randint(0, 1000, (1, text_len1 + text_len2)).to(device)
    vision_features = torch.randn(1, image_len, 768).to(device)
    vision_proj = VisionProjection(vit_dim=768, llm_dim=64).to(device)
    
    # 3. Setup optimizer for the router parameters and vision projector
    optimizer = torch.optim.AdamW([
        {'params': vision_proj.parameters(), 'lr': 1e-3},
        {'params': [p for n, p in model.named_parameters() if "router" in n], 'lr': 5e-3}
    ])
    
    # Train only the router and projection layers
    for name, param in model.named_parameters():
        if "router" not in name:
            param.requires_grad = False
            
    # 4. Training Loop Simulation (10 steps)
    model.train()
    print("\n--- Starting Training Loop Simulation ---")
    for step in range(1, 11):
        optimizer.zero_grad()
        
        # Generate mock embeddings inside loop to construct fresh computation graph
        text_embeds = model.model.embed_tokens(text_ids)
        vision_embeds = vision_proj(vision_features)
        
        # Interleave them: [Text1, Vision, Text2]
        interleaved_embeds = torch.cat([
            text_embeds[:, :text_len1, :],
            vision_embeds,
            text_embeds[:, text_len1:, :]
        ], dim=1) # (1, 64, 64)
        
        # Override the forward call of attention layers to accept modality_indices
        for layer in model.model.layers:
            # We pass modality_indices inside a closure or custom hook.
            # For this simple prototype, we inject it directly into the layer instance
            layer.self_attn.modality_indices = modality_indices
            
        # Forward pass through model model
        # We bypass the standard model forward wrapper to pass custom hidden states directly
        hidden_states = interleaved_embeds
        cos, sin = model.model.layers[0].self_attn.rope(hidden_states)
        position_embeddings = (cos.unsqueeze(0), sin.unsqueeze(0))
        
        # Run layers manually to collect custom losses
        for layer in model.model.layers:
            # Attention forward
            hidden_states, _ = layer.self_attn(
                hidden_states=hidden_states,
                position_embeddings=position_embeddings,
                modality_indices=modality_indices
            )
            hidden_states = layer.post_attention_layernorm(hidden_states)
            # Run MLP
            hidden_states = hidden_states + layer.mlp(hidden_states)
            
        # Final dummy task loss: average final state energy
        lm_loss = hidden_states.pow(2).mean()
        
        # Retrieve auxiliary modality routing penalties
        aux_penalty = 0.0
        for layer in model.model.layers:
            if hasattr(layer.self_attn, "current_penalty") and layer.self_attn.current_penalty is not None:
                aux_penalty += layer.self_attn.current_penalty
                
        total_loss = lm_loss + 0.1 * aux_penalty
        
        total_loss.backward()
        optimizer.step()
        
        if step % 2 == 0 or step == 1:
            print(f"Step {step:2d} | LM Loss: {lm_loss.item():.4f} | Routing Penalty: {aux_penalty.item():.4f} | Total: {total_loss.item():.4f}")
            
    # 5. Extract and print routing choices to verify modality separation
    print("\n--- Routing Assignments Extraction ---")
    model.eval()
    with torch.no_grad():
        # Compute final interleaved embeds
        text_embeds = model.model.embed_tokens(text_ids)
        vision_embeds = vision_proj(vision_features)
        interleaved_embeds = torch.cat([
            text_embeds[:, :text_len1, :],
            vision_embeds,
            text_embeds[:, text_len1:, :]
        ], dim=1)
        
        first_layer = model.model.layers[0].self_attn
        assignments, _ = first_layer.router(interleaved_embeds)
        # assignments shape: (1, num_heads, seq_len, levels, p)
        # Look at Head 0, Level 0 (primary branch decision)
        level0_choices = assignments[0, 0, :, 0, :].argmax(dim=-1) # (seq_len,)
        
        print(f"Token indices [0-{text_len1-1}] (Text Block 1) routed to primary branches:")
        print(level0_choices[:text_len1].tolist())
        
        print(f"Token indices [{text_len1}-{text_len1+image_len-1}] (Vision Patch Block) routed to primary branches:")
        print(level0_choices[text_len1:text_len1+image_len].tolist())
        
        print(f"Token indices [{text_len1+image_len}-{seq_len-1}] (Text Block 2) routed to primary branches:")
        print(level0_choices[text_len1+image_len:].tolist())
        
    print("\nSimulation successfully completed!")

if __name__ == "__main__":
    run_multimodal_simulation()
