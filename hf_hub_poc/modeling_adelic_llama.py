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
        
        B, H, _, D = keys.shape
        
        # Vectorized online clustering loop across all batches and heads
        for i in range(excess):
            v_new = new_v[:, :, i:i+1, :] # [B, H, 1, D]
            k_new = new_k[:, :, i:i+1, :] # [B, H, 1, D]
            
            # Topological Clustering: Append the new token
            c_v = torch.cat([centroids_v, v_new], dim=-2) # [B, H, K+1, D]
            c_k = torch.cat([centroids_k, k_new], dim=-2)
            
            norm_c_v = torch.nn.functional.normalize(c_v.float(), p=2, dim=-1)
            sim_matrix = torch.matmul(norm_c_v, norm_c_v.transpose(-1, -2)) # [B, H, K+1, K+1]
            
            # Ignore self-similarity
            mask = torch.eye(sim_matrix.shape[-1], dtype=torch.bool, device=sim_matrix.device)
            sim_matrix.masked_fill_(mask, -1.0)
            
            # Find the two most redundant centroids across all batches and heads
            flat_idx = torch.argmax(sim_matrix.view(B, H, -1), dim=-1) # [B, H]
            num_c = c_v.shape[-2]
            
            idx1 = flat_idx // num_c # [B, H]
            idx2 = flat_idx % num_c  # [B, H]
            
            # Ensure idx1 < idx2
            swap_mask = idx1 > idx2
            temp = idx1.clone()
            idx1 = torch.where(swap_mask, idx2, idx1)
            idx2 = torch.where(swap_mask, temp, idx2)
            
            # Merge the redundant centroid (idx2) into the first one (idx1)
            idx1_exp = idx1.unsqueeze(-1).unsqueeze(-1).expand(B, H, 1, D)
            idx2_exp = idx2.unsqueeze(-1).unsqueeze(-1).expand(B, H, 1, D)
            
            c_v_idx1 = torch.gather(c_v, 2, idx1_exp) # [B, H, 1, D]
            c_v_idx2 = torch.gather(c_v, 2, idx2_exp) # [B, H, 1, D]
            
            merged_v = (c_v_idx1 + c_v_idx2) / 2.0
            
            # Update the medoid Value (we leave the Key c_k as the older one: idx1)
            c_v.scatter_(2, idx1_exp, merged_v)
            
            # Remove the second redundant centroid to keep capacity strict
            seq_indices = torch.arange(num_c, device=c_v.device).view(1, 1, num_c)
            keep_mask = seq_indices != idx2.unsqueeze(-1) # [B, H, num_c]
            
            # Boolean masking flattens the tensor to 1D, so we must view() it back
            centroids_v = c_v[keep_mask.unsqueeze(-1).expand(B, H, num_c, D)].view(B, H, num_c - 1, D)
            centroids_k = c_k[keep_mask.unsqueeze(-1).expand(B, H, num_c, D)].view(B, H, num_c - 1, D)
                
        self.key_cache[layer_idx] = torch.cat([centroids_k, local_k], dim=-2)
        self.value_cache[layer_idx] = torch.cat([centroids_v, local_v], dim=-2)

    def get_seq_length(self, layer_idx: int = 0) -> int:
        if len(self.key_cache) <= layer_idx:
            return 0
        return self.key_cache[layer_idx].shape[-2]


class AdelicLlamaForCausalLM(LlamaForCausalLM):
    config_class = AdelicLlamaConfig

    def forward(self, input_ids=None, past_key_values=None, use_cache=None, position_ids=None, **kwargs):
        # Automatically inject the AdelicCache if generation requests a cache but none is provided yet
        if use_cache and past_key_values is None:
            past_key_values = AdelicCache(
                max_capacity=self.config.adelic_max_capacity,
                local_window=self.config.adelic_local_window,
                similarity_threshold=self.config.adelic_similarity_threshold
            )
            
        # Provide correct position_ids since the physical cache length is compressed
        if past_key_values is not None and isinstance(past_key_values, AdelicCache):
            if position_ids is None and input_ids is not None:
                seq_len = input_ids.shape[1]
                past_len = past_key_values._true_seen_tokens
                device = input_ids.device
                position_ids = torch.arange(past_len, past_len + seq_len, dtype=torch.long, device=device).unsqueeze(0)
                
        return super().forward(
            input_ids=input_ids, 
            past_key_values=past_key_values, 
            use_cache=use_cache, 
            position_ids=position_ids,
            **kwargs
        )
