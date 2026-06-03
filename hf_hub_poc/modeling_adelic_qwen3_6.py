import torch
import warnings

try:
    import triton
    import triton.language as tl
    HAS_TRITON = True
except ImportError:
    HAS_TRITON = False

try:
    from transformers.models.qwen2.modeling_qwen2 import Qwen2ForCausalLM as BaseCausalLM
except ImportError:
    try:
        from transformers import Qwen2ForCausalLM as BaseCausalLM
    except ImportError:
        warnings.warn("Qwen2ForCausalLM not found. Please ensure you are using a compatible transformers version.")
        raise

from .configuration_adelic_qwen3_6 import AdelicQwen3Config

if HAS_TRITON:
    @triton.jit
    def _adelic_triton_kernel(
        cv_ptr, max_val_ptr, max_idx_ptr,
        B, H, S, D, protect_size,
        stride_b, stride_h, stride_s, stride_d,
        stride_out_b, stride_out_s,
        BLOCK_S: tl.constexpr, BLOCK_N: tl.constexpr, BLOCK_D: tl.constexpr
    ):
        pid_b = tl.program_id(0)
        pid_s = tl.program_id(1)

        offs_s = pid_s * BLOCK_S + tl.arange(0, BLOCK_S)
        offs_d = tl.arange(0, BLOCK_D)

        m_i = tl.full([BLOCK_S], -float('inf'), dtype=tl.float32)
        idx_i = tl.full([BLOCK_S], -1, dtype=tl.int32)

        for start_n in range(0, S, BLOCK_N):
            offs_n = start_n + tl.arange(0, BLOCK_N)
            
            sum_sim = tl.zeros([BLOCK_S, BLOCK_N], dtype=tl.float32)
            
            for h in range(H):
                cv_s_ptrs = cv_ptr + pid_b * stride_b + h * stride_h + offs_s[:, None] * stride_s + offs_d[None, :] * stride_d
                mask_s = (offs_s[:, None] < S) & (offs_d[None, :] < D)
                cv_s = tl.load(cv_s_ptrs, mask=mask_s, other=0.0)
                
                cv_n_ptrs = cv_ptr + pid_b * stride_b + h * stride_h + offs_n[:, None] * stride_s + offs_d[None, :] * stride_d
                mask_n = (offs_n[:, None] < S) & (offs_d[None, :] < D)
                cv_n = tl.load(cv_n_ptrs, mask=mask_n, other=0.0)
                
                sim = tl.dot(cv_s, tl.trans(cv_n), out_dtype=tl.float32)
                sum_sim += sim
                
            mean_sim = sum_sim / H
            
            protect_mask = offs_n[None, :] < protect_size
            mean_sim = tl.where(protect_mask, -float('inf'), mean_sim)
            
            diag_mask = offs_s[:, None] == offs_n[None, :]
            mean_sim = tl.where(diag_mask, -float('inf'), mean_sim)
            
            valid_n_mask = offs_n[None, :] < S
            mean_sim = tl.where(valid_n_mask, mean_sim, -float('inf'))
            
            mask_s_1d = offs_s < S
            mean_sim = tl.where(mask_s_1d[:, None], mean_sim, -float('inf'))
            
            local_max = tl.max(mean_sim, axis=1)
            local_idx = tl.argmax(mean_sim, axis=1)
            local_idx_absolute = local_idx + start_n
            
            update_mask = local_max > m_i
            m_i = tl.where(update_mask, local_max, m_i)
            idx_i = tl.where(update_mask, local_idx_absolute, idx_i)

        out_max_ptr = max_val_ptr + pid_b * stride_out_b + offs_s * stride_out_s
        out_idx_ptr = max_idx_ptr + pid_b * stride_out_b + offs_s * stride_out_s
        
        write_mask = offs_s < S
        tl.store(out_max_ptr, m_i, mask=write_mask)
        tl.store(out_idx_ptr, idx_i, mask=write_mask)

def triton_adelic_condense(c_v, protect_size):
    if not HAS_TRITON:
        raise ImportError("Triton is not available. Please use PyTorch fallback.")

    B, H, S, D = c_v.shape
    
    max_vals = torch.empty((B, S), device=c_v.device, dtype=torch.float32)
    max_idxs = torch.empty((B, S), device=c_v.device, dtype=torch.int32)
    
    BLOCK_S = triton.next_power_of_2(S) if S < 32 else 32
    BLOCK_N = 64
    BLOCK_D = triton.next_power_of_2(D)
    
    grid = (B, triton.cdiv(S, BLOCK_S))
    
    _adelic_triton_kernel[grid](
        c_v, max_vals, max_idxs,
        B, H, S, D, protect_size,
        c_v.stride(0), c_v.stride(1), c_v.stride(2), c_v.stride(3),
        max_vals.stride(0), max_vals.stride(1),
        BLOCK_S=BLOCK_S, BLOCK_N=BLOCK_N, BLOCK_D=BLOCK_D,
        num_stages=1, num_warps=4
    )
    
    return max_vals, max_idxs.long()

def _condense_cache_layer_vectorized(layer_cache, layer_idx, config, cache_container):
    if not hasattr(layer_cache, "keys") or not hasattr(layer_cache, "values") or layer_cache.keys is None:
        return

    keys = layer_cache.keys
    values = layer_cache.values 

    seq_len = keys.shape[-2]
    excess = seq_len - config.adelic_soft_capacity
    
    if excess <= 0:
        return 
        
    max_far_history = config.adelic_soft_capacity - config.adelic_local_window
    
    centroids_k = keys[:, :, :max_far_history, :].clone()
    centroids_v = values[:, :, :max_far_history, :].clone()
    
    new_k = keys[:, :, max_far_history : max_far_history + excess, :]
    new_v = values[:, :, max_far_history : max_far_history + excess, :]
    
    local_k = keys[:, :, max_far_history + excess :, :]
    local_v = values[:, :, max_far_history + excess :, :]
    
    B, H, _, D = keys.shape
    
    if not hasattr(cache_container, "has_hologram"):
        cache_container.has_hologram = {}
    if layer_idx not in cache_container.has_hologram:
        cache_container.has_hologram[layer_idx] = False

    has_hologram = cache_container.has_hologram[layer_idx]

    with torch.no_grad():
        c_v = torch.cat([centroids_v, new_v], dim=-2) 
        c_k = torch.cat([centroids_k, new_k], dim=-2)
        
        current_num = c_v.shape[-2]
        
        # TRITON KERNEL OR CPU FALLBACK
        protect_size = min(17, current_num)
        
        if HAS_TRITON and c_v.device.type == 'cuda':
            norm_c_v = torch.nn.functional.normalize(c_v.float(), p=2, dim=-1).to(c_v.dtype)
            max_sim_val, _ = triton_adelic_condense(norm_c_v, protect_size)
        else:
            # PyTorch fallback for laptops / CPU
            norm_c_v = torch.nn.functional.normalize(c_v.float(), p=2, dim=-1)
            sim_matrix = torch.matmul(norm_c_v, norm_c_v.transpose(-1, -2))
            
            mask = torch.eye(current_num, device=sim_matrix.device, dtype=torch.bool).unsqueeze(0).unsqueeze(0)
            sim_matrix = torch.where(mask, torch.tensor(-1.0, device=sim_matrix.device, dtype=sim_matrix.dtype), sim_matrix)
            
            if protect_size > 0:
                sim_matrix[:, :, :protect_size, :] = -1.0
                sim_matrix[:, :, :, :protect_size] = -1.0
                
            global_sim = sim_matrix.mean(dim=1)
            max_sim_val = global_sim.max(dim=-1)[0]
        
        hard_excess = current_num - (config.adelic_hard_capacity - config.adelic_local_window)
        if torch.all(max_sim_val < config.adelic_similarity_threshold) and hard_excess <= 0:
            centroids_v = c_v
            centroids_k = c_k
        else:
            drop_count = max(excess, hard_excess)
            _, drop_indices = torch.topk(max_sim_val, k=drop_count, dim=-1)
            
            keep_mask = torch.ones(current_num, device=c_v.device, dtype=torch.bool)
            keep_mask[drop_indices[0]] = False
            
            if has_hologram:
                dropped_v = c_v[:, :, ~keep_mask, :].mean(dim=-2, keepdim=True)
                dropped_k = c_k[:, :, ~keep_mask, :][:, :, -1:, :]
                decay = config.adelic_hologram_decay
                c_v[:, :, 16:17, :] = decay * c_v[:, :, 16:17, :] + (1 - decay) * dropped_v
                c_k[:, :, 16:17, :] = decay * c_k[:, :, 16:17, :] + (1 - decay) * dropped_k
                
                centroids_v = c_v[:, :, keep_mask, :]
                centroids_k = c_k[:, :, keep_mask, :]
            else:
                dropped_v = c_v[:, :, ~keep_mask, :].mean(dim=-2, keepdim=True)
                dropped_k = c_k[:, :, ~keep_mask, :][:, :, -1:, :]
                
                keep_mask_early = keep_mask[:16]
                keep_mask_late = keep_mask[16:]
                
                c_v_kept = c_v[:, :, keep_mask, :]
                c_k_kept = c_k[:, :, keep_mask, :]
                
                centroids_v = torch.cat([c_v_kept[:, :, :16, :], dropped_v, c_v_kept[:, :, 16:, :]], dim=-2)
                centroids_k = torch.cat([c_k_kept[:, :, :16, :], dropped_k, c_k_kept[:, :, 16:, :]], dim=-2)
                cache_container.has_hologram[layer_idx] = True
            
    layer_cache.keys = torch.cat([centroids_k, local_k], dim=-2)
    layer_cache.values = torch.cat([centroids_v, local_v], dim=-2)
    
    if hasattr(layer_cache, "cumulative_length") and isinstance(layer_cache.cumulative_length, int):
        layer_cache.cumulative_length = layer_cache.keys.shape[-2]
    if hasattr(layer_cache, "seen_tokens"):
        layer_cache.seen_tokens = layer_cache.keys.shape[-2]


class AdelicQwen3ForCausalLM(BaseCausalLM):
    config_class = AdelicQwen3Config

    def forward(self, input_ids=None, past_key_values=None, use_cache=None, position_ids=None, **kwargs):
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

        if use_cache and outputs.past_key_values is not None:
            cache = outputs.past_key_values
            
            if not hasattr(cache, "adelic_true_seen_tokens"):
                cache.adelic_true_seen_tokens = 0
            if input_ids is not None:
                cache.adelic_true_seen_tokens += input_ids.shape[1]

            if hasattr(cache, "layers"):
                for idx, layer_cache in enumerate(cache.layers):
                    _condense_cache_layer_vectorized(layer_cache, idx, self.config, cache)
            elif hasattr(cache, "key_cache"):
                for idx in range(len(cache.key_cache)):
                    class DummyLayer: pass
                    layer_cache = DummyLayer()
                    layer_cache.keys = cache.key_cache[idx]
                    layer_cache.values = cache.value_cache[idx]
                    _condense_cache_layer_vectorized(layer_cache, idx, self.config, cache)
                    cache.key_cache[idx] = layer_cache.keys
                    cache.value_cache[idx] = layer_cache.values
                    
        return outputs
