import torch
import warnings

# Attempt to load Gemma4ForCausalLM
try:
    from transformers.models.gemma4.modeling_gemma4 import Gemma4ForCausalLM as BaseCausalLM
except ImportError:
    try:
        from transformers import Gemma4ForCausalLM as BaseCausalLM
    except ImportError:
        warnings.warn("Gemma4ForCausalLM not found in transformers. Falling back to GemmaForCausalLM.")
        from transformers.models.gemma.modeling_gemma import GemmaForCausalLM as BaseCausalLM

from .configuration_adelic_gemma4 import AdelicGemma4Config

def _condense_cache_layer(layer_cache, layer_idx, config, cache_container):
    """
    Applies Adèlic Condensation to a single CacheLayer object (e.g. DynamicLayer).
    Adapted for Gemma 4's hybrid local/global attention architecture.
    """
    # If the layer doesn't have keys, or it's a sliding window layer whose cache size
    # never exceeds the soft capacity anyway, it will naturally be bypassed or exit early.
    if not hasattr(layer_cache, "keys") or not hasattr(layer_cache, "values") or layer_cache.keys is None:
        return

    keys = layer_cache.keys       # [B, H, seq_len, D]
    values = layer_cache.values 

    seq_len = keys.shape[-2]
    excess = seq_len - config.adelic_soft_capacity
    
    # If it's a local sliding window layer, its sequence length in the cache should be bounded 
    # by the sliding window size (e.g., 4096). If our soft capacity is larger than the local window,
    # it won't trigger. If it does trigger, we condense it normally, treating it as a global memory.
    if excess <= 0:
        return 
        
    max_far_history = config.adelic_soft_capacity - config.adelic_local_window
    
    # Existing centroids (compressed far history)
    centroids_k = keys[:, :, :max_far_history, :].clone()
    centroids_v = values[:, :, :max_far_history, :].clone()
    
    # New tokens that just fell out of the local window
    new_k = keys[:, :, max_far_history : max_far_history + excess, :]
    new_v = values[:, :, max_far_history : max_far_history + excess, :]
    
    # The current local window (untouched)
    local_k = keys[:, :, max_far_history + excess :, :]
    local_v = values[:, :, max_far_history + excess :, :]
    
    B, H, _, D = keys.shape
    
    if not hasattr(cache_container, "has_hologram"):
        cache_container.has_hologram = {}
    if layer_idx not in cache_container.has_hologram:
        cache_container.has_hologram[layer_idx] = False

    has_hologram = cache_container.has_hologram[layer_idx]
    num_c = centroids_v.shape[-2]

    # Vectorized online clustering loop
    with torch.no_grad():
        for i in range(excess):
            v_new = new_v[:, :, i:i+1, :] 
            k_new = new_k[:, :, i:i+1, :] 
            
            c_v = torch.cat([centroids_v, v_new], dim=-2) 
            c_k = torch.cat([centroids_k, k_new], dim=-2)
            
            norm_c_v = torch.nn.functional.normalize(c_v.float(), p=2, dim=-1)
            sim_matrix = torch.matmul(norm_c_v, norm_c_v.transpose(-1, -2)) 
            
            current_num = c_v.shape[-2]
            
            mask = torch.eye(current_num, device=sim_matrix.device, dtype=torch.bool).unsqueeze(0).unsqueeze(0)
            sim_matrix = torch.where(mask, torch.tensor(-1.0, device=sim_matrix.device, dtype=sim_matrix.dtype), sim_matrix)
            
            sink_size = min(17, current_num - 1)
            if sink_size > 0:
                sim_matrix[:, :, :sink_size, :] = -1.0
                sim_matrix[:, :, :, :sink_size] = -1.0
            
            global_sim = sim_matrix.mean(dim=1, keepdim=True) 
            
            max_sim_val = global_sim.view(B, -1).max(dim=-1)[0] 
            hard_excess = (seq_len - i) - config.adelic_hard_capacity
            
            if torch.all(max_sim_val < config.adelic_similarity_threshold) and hard_excess <= 0:
                centroids_k = torch.cat([centroids_k, new_k[:, :, i:, :]], dim=-2)
                centroids_v = torch.cat([centroids_v, new_v[:, :, i:, :]], dim=-2)
                break
            
            flat_idx = torch.argmax(global_sim.view(B, 1, -1), dim=-1) 
            idx1 = flat_idx // current_num 
            idx2 = flat_idx % current_num 
            
            idx1 = idx1.expand(B, H) 
            idx2 = idx2.expand(B, H) 
            
            swap_mask = idx1 > idx2
            temp = idx1.clone()
            idx1 = torch.where(swap_mask, idx2, idx1)
            idx2 = torch.where(swap_mask, temp, idx2)
            
            idx2_expand = idx2.unsqueeze(-1).unsqueeze(-1).expand(B, H, 1, D)
            v_drop = torch.gather(c_v, 2, idx2_expand) 
            k_drop = torch.gather(c_k, 2, idx2_expand) 
            
            if has_hologram:
                decay = config.adelic_hologram_decay
                hologram_v = decay * c_v[:, :, 16:17, :] + (1 - decay) * v_drop
                hologram_k = decay * c_k[:, :, 16:17, :] + (1 - decay) * k_drop
                c_v[:, :, 16:17, :] = hologram_v
                c_k[:, :, 16:17, :] = hologram_k
            else:
                c_v = torch.cat([c_v[:, :, :16, :], v_drop, c_v[:, :, 16:, :]], dim=-2)
                c_k = torch.cat([c_k[:, :, :16, :], k_drop, c_k[:, :, 16:, :]], dim=-2)
                has_hologram = True
                current_num += 1
                idx2 = torch.where(idx2 >= 16, idx2 + 1, idx2)
            
            seq_indices = torch.arange(current_num, device=c_v.device).view(1, 1, current_num)
            keep_mask = seq_indices != idx2.unsqueeze(-1) 
            
            centroids_v = c_v[keep_mask.unsqueeze(-1).expand(B, H, current_num, D)].view(B, H, current_num - 1, D)
            centroids_k = c_k[keep_mask.unsqueeze(-1).expand(B, H, current_num, D)].view(B, H, current_num - 1, D)
            
    cache_container.has_hologram[layer_idx] = has_hologram
    layer_cache.keys = torch.cat([centroids_k, local_k], dim=-2)
    layer_cache.values = torch.cat([centroids_v, local_v], dim=-2)
    
    if hasattr(layer_cache, "cumulative_length") and isinstance(layer_cache.cumulative_length, int):
        layer_cache.cumulative_length = layer_cache.keys.shape[-2]
    # For Gemma 2+ style caches that track seen_tokens separately
    if hasattr(layer_cache, "seen_tokens"):
        layer_cache.seen_tokens = layer_cache.keys.shape[-2]


class AdelicGemma4ForCausalLM(BaseCausalLM):
    config_class = AdelicGemma4Config

    def forward(self, input_ids=None, past_key_values=None, use_cache=None, position_ids=None, **kwargs):
        # We need to compute proper position_ids for the current step since the cache length is compressed
        if past_key_values is not None and hasattr(past_key_values, "adelic_true_seen_tokens"):
            if input_ids is not None:
                seq_len = input_ids.shape[1]
                past_len = past_key_values.adelic_true_seen_tokens
                device = input_ids.device
                position_ids = torch.arange(past_len, past_len + seq_len, dtype=torch.long, device=device).unsqueeze(0)

        outputs = super().forward(
            input_ids=input_ids, 
            past_key_values=past_key_values, 
            use_cache=use_cache, 
            position_ids=position_ids,
            **kwargs
        )

        # Post-forward cache condensation interception
        if use_cache and outputs.past_key_values is not None:
            cache = outputs.past_key_values
            
            # Track true uncompressed sequence length for position_ids
            if not hasattr(cache, "adelic_true_seen_tokens"):
                cache.adelic_true_seen_tokens = 0
            if input_ids is not None:
                cache.adelic_true_seen_tokens += input_ids.shape[1]

            # Condense full attention layers
            if hasattr(cache, "layers"):
                for idx, layer_cache in enumerate(cache.layers):
                    _condense_cache_layer(layer_cache, idx, self.config, cache)
            elif hasattr(cache, "key_cache"): # legacy cache format
                for idx in range(len(cache.key_cache)):
                    # Wrap in a dummy object to match signature
                    class DummyLayer:
                        pass
                    layer_cache = DummyLayer()
                    layer_cache.keys = cache.key_cache[idx]
                    layer_cache.values = cache.value_cache[idx]
                    _condense_cache_layer(layer_cache, idx, self.config, cache)
                    cache.key_cache[idx] = layer_cache.keys
                    cache.value_cache[idx] = layer_cache.values
                    
        return outputs
