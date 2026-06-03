import torch
from transformers import Gemma4Config
from transformers.models.gemma4.modeling_gemma4 import Gemma4ForConditionalGeneration

def main():
    print("Testing AdelicGemma4ForConditionalGeneration using base config from google/gemma-4-E2B...")
    
    # 1. Load Multimodal Config
    base_dict = Gemma4Config.from_pretrained("google/gemma-4-E2B").to_dict()
    config = Gemma4Config(**base_dict)
    
    # Scale down sizes for CPU dummy test
    config.text_config.num_hidden_layers = 4
    config.text_config.hidden_size = 64
    config.text_config.intermediate_size = 128
    config.text_config.num_attention_heads = 4
    config.text_config.num_key_value_heads = 4
    
    print("Initializing dummy model...")
    model = Gemma4ForConditionalGeneration(config)
    model.eval()

    # Monkey patch
    model.config.adelic_soft_capacity = 64
    model.config.adelic_hard_capacity = 128
    model.config.adelic_local_window = 32
    model.config.adelic_similarity_threshold = 0.95
    model.config.adelic_hologram_decay = 0.9

    original_forward = model.forward

    def adelic_forward(input_ids=None, past_key_values=None, use_cache=None, position_ids=None, **kwargs):
        if past_key_values is not None and hasattr(past_key_values, "adelic_true_seen_tokens"):
            if input_ids is not None:
                seq_len = input_ids.shape[1]
                past_len = past_key_values.adelic_true_seen_tokens
                position_ids = torch.arange(past_len, past_len + seq_len, dtype=torch.long, device=input_ids.device).unsqueeze(0)

        outputs = original_forward(
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

            # Dummy shrink cache logic to simulate Adelic condensation
            if hasattr(cache, "key_cache"):
                for idx in range(len(cache.key_cache)):
                    k = cache.key_cache[idx]
                    v = cache.value_cache[idx]
                    seq_len = k.shape[-2]
                    excess = seq_len - model.config.adelic_soft_capacity
                    if excess > 0:
                        cache.key_cache[idx] = k[:, :, excess:, :]
                        cache.value_cache[idx] = v[:, :, excess:, :]

        return outputs

    model.forward = adelic_forward

    print("Generating dummy input of 200 tokens...")
    input_ids = torch.randint(0, 32000, (1, 200))
    
    print("Testing generation with do_sample=True...")
    outputs = model.generate(input_ids, max_new_tokens=5, use_cache=True, do_sample=True)
    print("Generation successful!")

if __name__ == "__main__":
    main()
