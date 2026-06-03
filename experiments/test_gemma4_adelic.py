import os
import sys
import torch
from transformers import AutoConfig

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from hf_hub_poc.configuration_adelic_gemma4 import AdelicGemma4Config
from hf_hub_poc.modeling_adelic_gemma4 import AdelicGemma4ForCausalLM

def main():
    model_id = "google/gemma-4-E2B"
    print(f"Testing AdelicGemma4ForCausalLM using base config from {model_id}...")

    # Load base config
    try:
        base_config = AutoConfig.from_pretrained(model_id, trust_remote_code=True)
        base_dict = base_config.to_dict()
    except Exception as e:
        print(f"Could not load {model_id} config from HF: {e}. Falling back to default GemmaConfig.")
        try:
            from transformers import Gemma4Config
            base_config = Gemma4Config()
    print("Testing AdelicGemma4ForConditionalGeneration using base config from google/gemma-4-E2B...")
    
    # 1. Load Multimodal Config
    from transformers import Gemma4Config
    base_dict = Gemma4Config.from_pretrained("google/gemma-4-E2B").to_dict()
    
    # We patch the config to be topological
    base_dict["adelic_soft_capacity"] = 128
    base_dict["adelic_hard_capacity"] = 256
    base_dict["adelic_local_window"] = 64
    base_dict["adelic_similarity_threshold"] = 0.95
    base_dict["adelic_hologram_decay"] = 0.9
    
    config = AdelicGemma4Config(**base_dict)
    
    # Scale down sizes for CPU dummy test
    config.text_config.num_hidden_layers = 4
    config.text_config.hidden_size = 64
    config.text_config.intermediate_size = 128
    config.text_config.num_attention_heads = 4
    config.text_config.num_key_value_heads = 4
    
    print("Initializing dummy model...")
    model = AdelicGemma4ForCausalLM(config)
    model.eval()

    batch_size = 1
    seq_len = 200
    print(f"Generating dummy input of {seq_len} tokens...")
    input_ids = torch.randint(0, config.vocab_size, (batch_size, seq_len))
    
    with torch.no_grad():
        print("Running forward pass (Prefill)...")
        outputs = model(input_ids=input_ids, use_cache=True)
        
        cache = outputs.past_key_values
        print("Forward pass successful.")
        
        # Verify cache length
        if hasattr(cache, "layers"):
            for idx, layer_cache in enumerate(cache.layers):
                if hasattr(layer_cache, "keys"):
                    k_len = layer_cache.keys.shape[-2]
                    print(f"Layer {idx} KV cache length: {k_len}")
                    assert k_len <= config.adelic_hard_capacity + config.adelic_local_window, \
                        f"Layer {idx} cache {k_len} exceeds capacity bounds!"
        elif hasattr(cache, "key_cache"):
            for idx in range(len(cache.key_cache)):
                k_len = cache.key_cache[idx].shape[-2]
                print(f"Layer {idx} KV cache length: {k_len}")
                print("Forward pass successful.")
    
    print("Testing generation...")
    outputs = model.generate(input_ids, max_new_tokens=5, use_cache=True, do_sample=True)
    print("Generation successful!")
    print("Gemma 4 POC Test Passed.")

if __name__ == "__main__":
    main()
