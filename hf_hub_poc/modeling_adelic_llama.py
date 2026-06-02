import torch
from transformers import LlamaForCausalLM
from transformers.cache_utils import DynamicCache
from .configuration_adelic_llama import AdelicLlamaConfig

class AdelicCache(DynamicCache):
    """
    AdelicCache implements Level 4 Adelic KV-Cache Condensation via the Medoid-Value Strategy.
    """
    def __init__(self, soft_capacity: int = 256, hard_capacity: int = 1024, local_window: int = 128, similarity_threshold: float = 0.95):
        super().__init__()
        self.soft_capacity = soft_capacity
        self.hard_capacity = hard_capacity
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
        # Wrapping in no_grad() prevents Autograd from building a massive graph, dropping step time drastically!
        with torch.no_grad():
            for i in range(excess):
                v_new = new_v[:, :, i:i+1, :] # [B, H, 1, D]
                k_new = new_k[:, :, i:i+1, :] # [B, H, 1, D]
                
                # Topological Clustering: Append the new token
                c_v = torch.cat([centroids_v, v_new], dim=-2) # [B, H, K+1, D]
                c_k = torch.cat([centroids_k, k_new], dim=-2)
                
                # We MUST cluster by Value vectors, not Key vectors!
                # Key vectors have RoPE (Rotary Position Embeddings) applied to them, so their cosine similarity is corrupted by rotational phase!
                # Value vectors are unrotated and perfectly represent the semantic meaning of the token.
                norm_c_v = torch.nn.functional.normalize(c_v.float(), p=2, dim=-1)
                sim_matrix = torch.matmul(norm_c_v, norm_c_v.transpose(-1, -2)) # [B, H, K+1, K+1]
                
                num_c = c_v.shape[-2]
                
                # Mask diagonal to prevent self-matching
                mask = torch.eye(num_c, device=sim_matrix.device, dtype=torch.bool).unsqueeze(0).unsqueeze(0)
                sim_matrix = torch.where(mask, torch.tensor(-1.0, device=sim_matrix.device, dtype=sim_matrix.dtype), sim_matrix)
                
                # PROTECT THE ATTENTION SINK!
                # The first few tokens of the prompt act as an Attention Sink (StreamingLLM).
                # If these tokens are dropped, the Softmax denominator explodes and the model hallucinates gibberish!
                sink_size = min(16, num_c - 1)
                if sink_size > 0:
                    sim_matrix[:, :, :sink_size, :] = -1.0
                    sim_matrix[:, :, :, :sink_size] = -1.0
                
                # GLOBAL HEAD CONSENSUS
                # A single attention head's low-dimensional subspace might accidentally alias the Needle with a common token (e.g. they are both nouns).
                # To prevent the Needle from being destroyed in some heads, we average the similarity across ALL heads.
                # A token is only merged if it is universally redundant across the entire multi-headed representation.
                global_sim = sim_matrix.mean(dim=1, keepdim=True) # [B, 1, K, K]
                
                # ADAPTIVE CAPACITY CHECK
                # If the most similar pair across all heads is below the threshold, they are NOT redundant.
                # If we haven't hit the hard memory limit yet, we can safely stop condensing and let the cache grow!
                max_sim_val = global_sim.view(B, -1).max(dim=-1)[0] # [B]
                hard_excess = (seq_len - i) - self.hard_capacity
                
                # We break if ALL batches have max similarity < threshold AND ALL batches are under hard_capacity
                # (For simplicity in this batch processing loop, we break if the condition holds for the whole batch)
                if torch.all(max_sim_val < self.similarity_threshold) and hard_excess <= 0:
                    # We broke early! Concatenate the unprocessed new tokens back into centroids.
                    centroids_k = torch.cat([centroids_k, new_k[:, :, i:, :]], dim=-2)
                    centroids_v = torch.cat([centroids_v, new_v[:, :, i:, :]], dim=-2)
                    break
                
                flat_idx = torch.argmax(global_sim.view(B, 1, -1), dim=-1) # [B, 1]
                idx1 = flat_idx // num_c # [B, 1]
                idx2 = flat_idx % num_c # [B, 1]
                
                # Expand idx1 and idx2 to all heads so every head merges the exact same global token!
                idx1 = idx1.expand(B, H) # [B, H]
                idx2 = idx2.expand(B, H) # [B, H]
                
                # Ensure idx1 < idx2
                swap_mask = idx1 > idx2
                temp = idx1.clone()
                idx1 = torch.where(swap_mask, idx2, idx1)
                idx2 = torch.where(swap_mask, temp, idx2)
                
                # Merge the redundant centroid (idx2) into the first one (idx1)
                # Do NOT average the Value vectors!
                # Averaging shrinks the magnitude of the vectors, shifting the MLP input out-of-distribution and causing Context Window Collapse.
                # By keeping the pristine $idx1$ vector untouched, we guarantee the condensed cache is 100% in-distribution.
                # We simply let the keep_mask below drop the redundant idx2.
                
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
                soft_capacity=self.config.adelic_soft_capacity,
                hard_capacity=self.config.adelic_hard_capacity,
                local_window=self.config.adelic_local_window,
                similarity_threshold=self.config.adelic_similarity_threshold
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
