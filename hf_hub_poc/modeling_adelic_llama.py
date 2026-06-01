import torch
from transformers import LlamaForCausalLM
from transformers.cache_utils import DynamicCache
from .configuration_adelic_llama import AdelicLlamaConfig

@torch.compile(mode="reduce-overhead", fullgraph=False)
def _condense_tensors(centroids_k, centroids_v, new_k, new_v, similarity_threshold, excess):
    for i in range(excess):
        v_new = new_v[:, :, i:i+1, :] # [B, H, 1, D]
        k_new = new_k[:, :, i:i+1, :]
        
        norm_v_new = torch.nn.functional.normalize(v_new.float(), p=2, dim=-1)
        norm_c_v = torch.nn.functional.normalize(centroids_v.float(), p=2, dim=-1)
        
        sims = torch.matmul(norm_v_new, norm_c_v.transpose(-1, -2)).squeeze(-2) # [B, H, K]
        max_sim, best_idx = sims.max(dim=-1) # [B, H]
        
        mask_cond = (max_sim > similarity_threshold).unsqueeze(-1) # [B, H, 1]
        
        idx_mask = (torch.arange(centroids_v.shape[-2], device=centroids_v.device).view(1, 1, -1) == best_idx.unsqueeze(-1)) # [B, H, K]
        merge_mask = (idx_mask & mask_cond).unsqueeze(-1) # [B, H, K, 1]
        
        centroids_v = torch.where(merge_mask, (centroids_v + v_new) / 2.0, centroids_v)
        centroids_k = torch.where(merge_mask, k_new, centroids_k)
        
        evict_mask = (~mask_cond).unsqueeze(-1) # [B, H, 1, 1]
        evicted_c_v = torch.cat([centroids_v[:, :, 1:, :], v_new], dim=-2)
        evicted_c_k = torch.cat([centroids_k[:, :, 1:, :], k_new], dim=-2)
        
        centroids_v = torch.where(evict_mask, evicted_c_v, centroids_v)
        centroids_k = torch.where(evict_mask, evicted_c_k, centroids_k)
        
    return centroids_k, centroids_v

class AdelicCache(DynamicCache):
    """
    AdelicCache implements Level 4 Adelic KV-Cache Condensation via the Medoid-Value Strategy.
    """
    def __init__(self, max_capacity: int = 512, local_window: int = 128, similarity_threshold: float = 0.95):
        super().__init__()
        self.max_capacity = max_capacity
        self.local_window = local_window
        self.similarity_threshold = similarity_threshold
        self.key_cache = []
        self.value_cache = []
        self._true_seen_tokens = 0

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
        
        if current_length > self.max_capacity:
            self._condense_layer(layer_idx)
            
        return self.key_cache[layer_idx], self.value_cache[layer_idx]

    def _condense_layer(self, layer_idx: int):
        keys = self.key_cache[layer_idx]     # [B, H, seq_len, D]
        values = self.value_cache[layer_idx] 

        seq_len = keys.shape[-2]
        excess = seq_len - self.max_capacity
        
        if excess <= 0:
            return 
            
        max_far_history = self.max_capacity - self.local_window
        
        # 1. Existing centroids (the compressed far history)
        centroids_k = keys[:, :, :max_far_history, :].clone()
        centroids_v = values[:, :, :max_far_history, :].clone()
        
        # 2. New tokens that just fell out of the local window
        new_k = keys[:, :, max_far_history : max_far_history + excess, :]
        new_v = values[:, :, max_far_history : max_far_history + excess, :]
        
        # 3. The current local window (untouched)
        local_k = keys[:, :, max_far_history + excess :, :]
        local_v = values[:, :, max_far_history + excess :, :]
        
        # O(1) graph-compiled highly optimized condensation
        centroids_k, centroids_v = _condense_tensors(
            centroids_k, centroids_v, new_k, new_v, self.similarity_threshold, excess
        )
                
        self.key_cache[layer_idx] = torch.cat([centroids_k, local_k], dim=-2)
        self.value_cache[layer_idx] = torch.cat([centroids_v, local_v], dim=-2)

    def get_seq_length(self, layer_idx: int = 0) -> int:
        if hasattr(self, '_seen_tokens'):
            return self._seen_tokens
        return self._true_seen_tokens


class AdelicLlamaForCausalLM(LlamaForCausalLM):
    config_class = AdelicLlamaConfig

    def forward(self, input_ids=None, past_key_values=None, use_cache=None, **kwargs):
        # Automatically inject the AdelicCache if generation requests a cache but none is provided yet
        if use_cache and past_key_values is None:
            past_key_values = AdelicCache(
                max_capacity=self.config.adelic_max_capacity,
                local_window=self.config.adelic_local_window,
                similarity_threshold=self.config.adelic_similarity_threshold
            )
        return super().forward(
            input_ids=input_ids, 
            past_key_values=past_key_values, 
            use_cache=use_cache, 
            **kwargs
        )
