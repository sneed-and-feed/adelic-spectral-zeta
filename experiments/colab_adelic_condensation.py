import torch
import math
from transformers import AutoModelForCausalLM, AutoTokenizer
from transformers.cache_utils import DynamicCache

class AdelicCache(DynamicCache):
    """
    AdelicCache implements Level 4 Adelic KV-Cache Condensation.
    Instead of quantizing bits (which destroys semantic resolution), we condense the 
    number of tokens dynamically by pooling semantically identical tokens in the far history.
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
        keys = self.key_cache[layer_idx]     # [batch, heads, seq, head_dim]
        values = self.value_cache[layer_idx] # [batch, heads, seq, head_dim]

        seq_len = keys.shape[-2]
        far_history_len = seq_len - self.local_window
        
        if far_history_len <= 0:
            return 
            
        # Split into far history and local window
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
                
                # Normalize values to compute cosine similarity
                norm_v = torch.nn.functional.normalize(h_v.float(), p=2, dim=-1)
                sim_matrix = torch.matmul(norm_v, norm_v.transpose(0, 1)) 
                
                visited = torch.zeros(far_history_len, dtype=torch.bool, device=keys.device)
                merged_k = []
                merged_v = []
                
                for i in range(far_history_len):
                    if visited[i]: continue
                    
                    # Find all tokens similar to token i
                    cluster_indices = (sim_matrix[i] > self.similarity_threshold) & (~visited)
                    visited[cluster_indices] = True
                    
                    # Medoid-Value Strategy:
                    # Average Values (semantic fusion)
                    pooled_v = h_v[cluster_indices].mean(dim=0)
                    
                    # Select Medoid Key (latest key to preserve RoPE)
                    last_idx = torch.where(cluster_indices)[0][-1]
                    medoid_k = h_k[last_idx]
                    
                    merged_k.append(medoid_k)
                    merged_v.append(pooled_v)
                
                b_keys.append(torch.stack(merged_k))
                b_values.append(torch.stack(merged_v))
                
            # Pad heads to same length to maintain rectangular tensor shape
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


def run_experiment():
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Running Adelic KV-Cache Condensation Experiment on {device}")
    
    model_id = "TinyLlama/TinyLlama-1.1B-Intermediate-Step-1431k-3T"
    tokenizer = AutoTokenizer.from_pretrained(model_id)
    model = AutoModelForCausalLM.from_pretrained(model_id, torch_dtype=torch.float16 if device=="cuda" else torch.float32)
    model.eval()
    model.to(device)

    # 1. Generate text using Standard Dense Cache
    prompt = "The intersection of p-adic geometry and quantum field theory reveals that "
    input_ids = tokenizer(prompt, return_tensors="pt")["input_ids"].to(device)
    
    print("\n--- Phase 1: Baseline Generation (Dense Cache) ---")
    dense_outputs = model.generate(
        input_ids,
        max_new_tokens=50,
        use_cache=True,
        pad_token_id=tokenizer.eos_token_id
    )
    print("Output:")
    print(tokenizer.decode(dense_outputs[0], skip_special_tokens=True))
    
    # 2. Generate text using Adelic Cache
    print("\n--- Phase 2: Adelic Cache Generation (Condensation) ---")
    
    # We set a tight capacity to force condensation during a short 50-token generation
    max_cap = 16
    local_win = 8
    
    adelic_cache = AdelicCache(max_capacity=max_cap, local_window=local_win, similarity_threshold=0.90)
    
    current_ids = input_ids.clone()
    generated_ids = input_ids.clone()
    
    # We run autoregressive generation manually to track cache size per step
    for step in range(50):
        with torch.no_grad():
            outputs = model(input_ids=current_ids, past_key_values=adelic_cache, use_cache=True)
            next_token_logits = outputs.logits[:, -1, :]
            next_token = torch.argmax(next_token_logits, dim=-1).unsqueeze(-1)
            
            generated_ids = torch.cat([generated_ids, next_token], dim=-1)
            current_ids = next_token # Pass only the new token since we have cache
            
            if (step + 1) % 10 == 0:
                physical_len = adelic_cache.key_cache[0].shape[-2]
                logical_len = adelic_cache.get_seq_length()
                print(f"  Step {step+1}: Logical RoPE Position = {logical_len} | Physical Cache Size = {physical_len} tokens")

    print("\nOutput:")
    print(tokenizer.decode(generated_ids[0], skip_special_tokens=True))
    
if __name__ == "__main__":
    run_experiment()
