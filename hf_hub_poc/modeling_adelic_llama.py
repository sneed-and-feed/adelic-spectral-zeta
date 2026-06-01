import torch
from transformers import LlamaForCausalLM
from transformers.cache_utils import DynamicCache
from .configuration_adelic_llama import AdelicLlamaConfig

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
        
        batch_size, num_heads, _, head_dim = keys.shape
        
        # Online clustering loop: O(excess * K) -> Amortized O(1) per token
        for b in range(batch_size):
            for h in range(num_heads):
                c_k = centroids_k[b, h] # [K, D]
                c_v = centroids_v[b, h] # [K, D]
                
                n_k = new_k[b, h] # [excess, D]
                n_v = new_v[b, h] # [excess, D]
                
                for i in range(excess):
                    v_new = n_v[i:i+1] # [1, D]
                    k_new = n_k[i:i+1]
                    
                    norm_v_new = torch.nn.functional.normalize(v_new.float(), p=2, dim=-1)
                    norm_c_v = torch.nn.functional.normalize(c_v.float(), p=2, dim=-1)
                    
                    sims = torch.matmul(norm_v_new, norm_c_v.transpose(0, 1)).squeeze(0) # [K]
                    max_sim, best_idx = sims.max(dim=0)
                    
                    if max_sim > self.similarity_threshold:
                        # Merge into existing semantic cluster (Differentiable, no inplace ops)
                        mask = (torch.arange(c_v.shape[0], device=c_v.device) == best_idx).unsqueeze(1)
                        c_v = torch.where(mask, (c_v + v_new.squeeze(0)) / 2.0, c_v)
                        c_k = torch.where(mask, k_new.squeeze(0), c_k) # Update medoid
                    else:
                        # Unique Needle: Append as new centroid and LRU evict the oldest
                        c_v = torch.cat([c_v[1:], v_new], dim=0)
                        c_k = torch.cat([c_k[1:], k_new], dim=0)
                        
                centroids_k[b, h] = c_k
                centroids_v[b, h] = c_v
                
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
