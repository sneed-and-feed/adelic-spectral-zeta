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
        keys = self.key_cache[layer_idx]     
        values = self.value_cache[layer_idx] 

        seq_len = keys.shape[-2]
        far_history_len = seq_len - self.local_window
        
        if far_history_len <= 0:
            return 
            
        far_keys = keys[:, :, :far_history_len, :]
        far_values = values[:, :, :far_history_len, :]
        
        local_keys = keys[:, :, far_history_len:, :]
        local_values = values[:, :, far_history_len:, :]
        
        batch_size, num_heads, _, head_dim = keys.shape
        
        new_far_keys_list = []
        new_far_values_list = []
        
        for b in range(batch_size):
            b_keys = []
            b_values = []
            for h in range(num_heads):
                h_k = far_keys[b, h] 
                h_v = far_values[b, h]
                
                # Use fp32 for stable cosine similarity
                norm_v = torch.nn.functional.normalize(h_v.float(), p=2, dim=-1)
                sim_matrix = torch.matmul(norm_v, norm_v.transpose(0, 1)) 
                
                visited = torch.zeros(far_history_len, dtype=torch.bool, device=keys.device)
                merged_k = []
                merged_v = []
                
                for i in range(far_history_len):
                    if visited[i]: continue
                    
                    cluster_indices = (sim_matrix[i] > self.similarity_threshold) & (~visited)
                    
                    if not cluster_indices.any():
                        visited[i] = True
                        continue
                        
                    visited[cluster_indices] = True
                    
                    pooled_v = h_v[cluster_indices].mean(dim=0)
                    last_idx = torch.where(cluster_indices)[0][-1]
                    medoid_k = h_k[last_idx]
                    
                    merged_k.append(medoid_k)
                    merged_v.append(pooled_v)
                
                b_keys.append(torch.stack(merged_k))
                b_values.append(torch.stack(merged_v))
                
            max_len = max([k.shape[0] for k in b_keys])
            padded_k = []
            padded_v = []
            for k, v in zip(b_keys, b_values):
                pad_len = max_len - k.shape[0]
                if pad_len > 0:
                    k = torch.cat([k, torch.zeros(pad_len, head_dim, dtype=k.dtype, device=k.device)])
                    v = torch.cat([v, torch.zeros(pad_len, head_dim, dtype=v.dtype, device=v.device)])
                padded_k.append(k)
                padded_v.append(v)
                
            new_far_keys_list.append(torch.stack(padded_k))
            new_far_values_list.append(torch.stack(padded_v))
            
        new_far_keys = torch.stack(new_far_keys_list)     
        new_far_values = torch.stack(new_far_values_list) 
        
        self.key_cache[layer_idx] = torch.cat([new_far_keys, local_keys], dim=-2)
        self.value_cache[layer_idx] = torch.cat([new_far_values, local_values], dim=-2)

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
