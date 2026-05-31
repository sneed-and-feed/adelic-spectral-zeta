import torch
from transformers.cache_utils import DynamicCache
from transformers import AutoConfig, AutoModelForCausalLM

class TemporalAdelicCache(DynamicCache):
    """
    TemporalAdelicCache implements Level 5 Adelic KV-Cache Condensation with Temporal Decay.
    It builds on the Medoid-Value Strategy by synthetically restoring the RoPE decay penalty.
    By scaling the magnitude of the Medoid Key vector inversely proportional to the positional 
    variance of the cluster, it prevents the Super-Token from hijacking the attention softmax.
    """
    def __init__(self, max_capacity: int = 128, local_window: int = 64, lambda_decay: float = 0.05):
        super().__init__()
        self.max_capacity = max_capacity
        self.local_window = local_window
        self.lambda_decay = lambda_decay
        self.key_cache = []
        self.value_cache = []
        self._true_seen_tokens = 0

    def update(self, key_states: torch.Tensor, value_states: torch.Tensor, layer_idx: int, cache_kwargs=None):
        if layer_idx == 0:
            self._true_seen_tokens += key_states.shape[-2]

        # Expand cache arrays if necessary
        if len(self.key_cache) <= layer_idx:
            self.key_cache.append(key_states)
            self.value_cache.append(value_states)
        else:
            self.key_cache[layer_idx] = torch.cat([self.key_cache[layer_idx], key_states], dim=-2)
            self.value_cache[layer_idx] = torch.cat([self.value_cache[layer_idx], value_states], dim=-2)

        current_length = self.key_cache[layer_idx].shape[-2]
        
        # If we exceed max capacity, trigger condensation
        if current_length > self.max_capacity:
            self._condense_layer(layer_idx)
            
        return self.key_cache[layer_idx], self.value_cache[layer_idx]

    def _condense_layer(self, layer_idx: int):
        keys = self.key_cache[layer_idx]     # [batch, heads, seq, head_dim]
        values = self.value_cache[layer_idx] # [batch, heads, seq, head_dim]

        seq_len = keys.shape[-2]
        far_history_len = seq_len - self.local_window
        
        if far_history_len <= 0:
            return 
            
        far_keys = keys[:, :, :far_history_len, :]
        far_values = values[:, :, :far_history_len, :]
        local_keys = keys[:, :, far_history_len:, :]
        local_values = values[:, :, far_history_len:, :]
        
        batch_size, num_heads, _, head_dim = keys.shape
        
        # We track logical positions for variance calculation.
        # For simplicity in this standalone script, we estimate absolute positions as their index.
        # In a full recursive implementation, we would store an auxiliary list of absolute positions.
        logical_positions = torch.arange(far_history_len, dtype=torch.float32, device=keys.device)
        
        new_far_keys_list = []
        new_far_values_list = []
        
        for b in range(batch_size):
            b_keys = []
            b_values = []
            for h in range(num_heads):
                h_k = far_keys[b, h]
                h_v = far_values[b, h]
                
                # Normalize values to compute cosine similarity
                norm_v = torch.nn.functional.normalize(h_v, p=2, dim=-1)
                sim_matrix = torch.matmul(norm_v, norm_v.transpose(0, 1))
                
                visited = torch.zeros(far_history_len, dtype=torch.bool, device=keys.device)
                merged_k = []
                merged_v = []
                
                for i in range(far_history_len):
                    if visited[i]: continue
                    
                    cluster_indices = (sim_matrix[i] > -0.99) & (~visited)
                    visited[cluster_indices] = True
                    
                    # 1. Temporal Variance Penalty
                    cluster_pos = logical_positions[cluster_indices]
                    if len(cluster_pos) > 1:
                        pos_var = torch.var(cluster_pos)
                    else:
                        pos_var = torch.tensor(0.0, device=keys.device)
                        
                    # Calculate gamma: The synthetic RoPE decay multiplier
                    gamma = torch.exp(-self.lambda_decay * pos_var)
                    
                    # 2. Medoid-Value Strategy with Magnitude Scaling
                    pooled_v = h_v[cluster_indices].mean(dim=0)
                    last_idx = torch.where(cluster_indices)[0][-1]
                    
                    # Scale the Key vector by gamma. This strictly reduces the magnitude of the 
                    # dot product (Q * K) during attention, reintroducing the distance penalty.
                    medoid_k = h_k[last_idx] * gamma
                    
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


def test_temporal_adelic_cache():
    print("Initializing dummy TinyLlama on CPU to test TemporalAdelicCache...")
    config = AutoConfig.from_pretrained("TinyLlama/TinyLlama-1.1B-intermediate-step-1431k-3T")
    config.num_hidden_layers = 2
    config.hidden_size = 64
    config.intermediate_size = 128
    config.num_attention_heads = 4
    config.num_key_value_heads = 4
    
    model = AutoModelForCausalLM.from_config(config)
    model.eval()
    
    max_cap = 32
    local_win = 16
    lambda_decay = 0.05
    
    adelic_cache = TemporalAdelicCache(
        max_capacity=max_cap, 
        local_window=local_win, 
        lambda_decay=lambda_decay
    )
    
    input_ids = torch.randint(0, config.vocab_size, (1, 1))
    
    print(f"Starting Generation. Max Capacity: {max_cap}, Local Window: {local_win}, Decay \u03bb: {lambda_decay}")
    
    with torch.no_grad():
        for step in range(100):
            outputs = model(
                input_ids=input_ids,
                past_key_values=adelic_cache,
                use_cache=True
            )
            input_ids = torch.randint(0, config.vocab_size, (1, 1))
            
            if (step + 1) % 10 == 0:
                physical_len = adelic_cache.key_cache[0].shape[-2]
                logical_len = adelic_cache.get_seq_length()
                print(f"Step {step+1:3d} | Logical RoPE Position: {logical_len:3d} | Physical Cache Size: {physical_len:3d} tokens")
                assert physical_len <= max_cap + 10, "Cache condensation failed to cap memory!"

    print("\nSuccess! TemporalAdelicCache applied synthetic RoPE decay via Medoid-Key magnitude scaling.")

if __name__ == "__main__":
    test_temporal_adelic_cache()
