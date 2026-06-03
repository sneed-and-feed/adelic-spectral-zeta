import torch
from transformers.models.qwen2.modeling_qwen2 import Qwen2ForCausalLM
from transformers.cache_utils import DynamicCache
from .configuration_adelic_qwen import AdelicQwenConfig

class AdelicCache(DynamicCache):
    """
    AdelicCache implements Level 4 Adelic KV-Cache Condensation via the Medoid-Value Strategy.
    """
    def __init__(self, soft_capacity: int = 256, hard_capacity: int = 1024, local_window: int = 128, similarity_threshold: float = 0.95, hologram_decay: float = 0.9):
        super().__init__()
        self.soft_capacity = soft_capacity
        self.hard_capacity = hard_capacity
        self.local_window = local_window
        self.similarity_threshold = similarity_threshold
        self.hologram_decay = hologram_decay
        self.key_cache = []
        self.value_cache = []
        self._true_seen_tokens = 0
        self.has_hologram = [False] * 128

    def update(self, key_states: torch.Tensor, value_states: torch.Tensor, layer_idx: int, cache_kwargs=None):
        if layer_idx == 0:
            self._true_seen_tokens += key_states.shape[-2]

        if len(self.key_cache) <= layer_idx:
            self.key_cache.append(key_states)
            self.value_cache.append(value_states)
        else:
            self.key_cache[layer_idx] = torch.cat([self.key_cache[layer_idx], key_states], dim=-2)
            self.value_cache[layer_idx] = torch.cat([self.value_cache[layer_idx], value_states], dim=-2)

        current_length = self.key_cache[layer_idx].shape[-2]
        
        if current_length > self.soft_capacity:
            self._condense_layer(layer_idx)
            
        return self.key_cache[layer_idx], self.value_cache[layer_idx]

    def _condense_layer(self, layer_idx: int):
        keys = self.key_cache[layer_idx]     # [B, H, seq_len, D]
        values = self.value_cache[layer_idx] 

        seq_len = keys.shape[-2]
        excess = seq_len - self.soft_capacity
        
        if excess <= 0:
            return 
            
        max_far_history = self.soft_capacity - self.local_window
        
        # 1. Existing centroids (the compressed far history)
        centroids_k = keys[:, :, :max_far_history, :].clone()
        centroids_v = values[:, :, :max_far_history, :].clone()
        
        # 2. New tokens that just fell out of the local window
        new_k = keys[:, :, max_far_history : max_far_history + excess, :]
        new_v = values[:, :, max_far_history : max_far_history + excess, :]
        
        # 3. The current local window (untouched)
        local_k = keys[:, :, max_far_history + excess :, :]
        local_v = values[:, :, max_far_history + excess :, :]
        
        B, H, _, D = keys.shape
        
        # Vectorized online clustering loop across all batches and heads
        with torch.no_grad():
            for i in range(excess):
                v_new = new_v[:, :, i:i+1, :] # [B, H, 1, D]
                k_new = new_k[:, :, i:i+1, :] # [B, H, 1, D]
                
                # Topological Clustering: Append the new token
                c_v = torch.cat([centroids_v, v_new], dim=-2) # [B, H, K+1, D]
                c_k = torch.cat([centroids_k, k_new], dim=-2)
                
                # Value vectors are unrotated and perfectly represent semantic meaning
                norm_c_v = torch.nn.functional.normalize(c_v.float(), p=2, dim=-1)
                sim_matrix = torch.matmul(norm_c_v, norm_c_v.transpose(-1, -2)) # [B, H, K+1, K+1]
                
                num_c = c_v.shape[-2]
                
                # Mask diagonal to prevent self-matching
                mask = torch.eye(num_c, device=sim_matrix.device, dtype=torch.bool).unsqueeze(0).unsqueeze(0)
                sim_matrix = torch.where(mask, torch.tensor(-1.0, device=sim_matrix.device, dtype=sim_matrix.dtype), sim_matrix)
                
                # Protect the Attention Sink and Hologram
                sink_size = min(17, num_c - 1)
                if sink_size > 0:
                    sim_matrix[:, :, :sink_size, :] = -1.0
                    sim_matrix[:, :, :, :sink_size] = -1.0
                
                # Global Head Consensus
                global_sim = sim_matrix.mean(dim=1, keepdim=True) # [B, 1, K, K]
                
                # Adaptive Capacity Check
                max_sim_val = global_sim.view(B, -1).max(dim=-1)[0] # [B]
                hard_excess = (seq_len - i) - self.hard_capacity
                
                if torch.all(max_sim_val < self.similarity_threshold) and hard_excess <= 0:
                    centroids_k = torch.cat([centroids_k, new_k[:, :, i:, :]], dim=-2)
                    centroids_v = torch.cat([centroids_v, new_v[:, :, i:, :]], dim=-2)
                    break
                
                flat_idx = torch.argmax(global_sim.view(B, 1, -1), dim=-1) # [B, 1]
                idx1 = flat_idx // num_c # [B, 1]
                idx2 = flat_idx % num_c # [B, 1]
                
                # Expand idx1 and idx2 to all heads
                idx1 = idx1.expand(B, H) # [B, H]
                idx2 = idx2.expand(B, H) # [B, H]
                
                # Ensure idx1 < idx2
                swap_mask = idx1 > idx2
                temp = idx1.clone()
                idx1 = torch.where(swap_mask, idx2, idx1)
                idx2 = torch.where(swap_mask, temp, idx2)
                
                # Extract dropped token for Hologram folding
                idx2_expand = idx2.unsqueeze(-1).unsqueeze(-1).expand(B, H, 1, D)
                v_drop = torch.gather(c_v, 2, idx2_expand) # [B, H, 1, D]
                k_drop = torch.gather(c_k, 2, idx2_expand) # [B, H, 1, D]
                
                if self.has_hologram[layer_idx]:
                    decay = self.hologram_decay
                    hologram_v = decay * c_v[:, :, 16:17, :] + (1 - decay) * v_drop
                    hologram_k = decay * c_k[:, :, 16:17, :] + (1 - decay) * k_drop
                    c_v[:, :, 16:17, :] = hologram_v
                    c_k[:, :, 16:17, :] = hologram_k
                else:
                    c_v = torch.cat([c_v[:, :, :16, :], v_drop, c_v[:, :, 16:, :]], dim=-2)
                    c_k = torch.cat([c_k[:, :, :16, :], k_drop, c_k[:, :, 16:, :]], dim=-2)
                    self.has_hologram[layer_idx] = True
                    num_c += 1
                    idx2 = torch.where(idx2 >= 16, idx2 + 1, idx2)
                
                # Remove redundant centroid (idx2)
                seq_indices = torch.arange(num_c, device=c_v.device).view(1, 1, num_c)
                keep_mask = seq_indices != idx2.unsqueeze(-1) # [B, H, num_c]
                
                centroids_v = c_v[keep_mask.unsqueeze(-1).expand(B, H, num_c, D)].view(B, H, num_c - 1, D)
                centroids_k = c_k[keep_mask.unsqueeze(-1).expand(B, H, num_c, D)].view(B, H, num_c - 1, D)
                
        self.key_cache[layer_idx] = torch.cat([centroids_k, local_k], dim=-2)
        self.value_cache[layer_idx] = torch.cat([centroids_v, local_v], dim=-2)

    def get_seq_length(self, layer_idx: int = 0) -> int:
        if len(self.key_cache) <= layer_idx:
            return 0
        return self.key_cache[layer_idx].shape[-2]


class AdelicQwenForCausalLM(Qwen2ForCausalLM):
    config_class = AdelicQwenConfig

    def forward(self, input_ids=None, past_key_values=None, use_cache=None, position_ids=None, **kwargs):
        # Automatically inject the AdelicCache if generation requests a cache but none is provided yet
        if use_cache and past_key_values is None:
            past_key_values = AdelicCache(
                soft_capacity=self.config.adelic_soft_capacity,
                hard_capacity=self.config.adelic_hard_capacity,
                local_window=self.config.adelic_local_window,
                similarity_threshold=self.config.adelic_similarity_threshold,
                hologram_decay=self.config.adelic_hologram_decay
            )
            
        # Provide correct position_ids since the physical cache length is compressed
        if past_key_values is not None and isinstance(past_key_values, AdelicCache):
            if input_ids is not None:
                seq_len = input_ids.shape[1]
                past_len = past_key_values._true_seen_tokens
                device = input_ids.device
                # Overwrite HF's incorrect position_ids which are based on the compressed cache size
                position_ids = torch.arange(past_len, past_len + seq_len, dtype=torch.long, device=device).unsqueeze(0)
                
        return super().forward(
            input_ids=input_ids, 
            past_key_values=past_key_values, 
            use_cache=use_cache, 
            position_ids=position_ids,
            **kwargs
        )
