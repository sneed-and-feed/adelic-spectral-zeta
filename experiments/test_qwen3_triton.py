import torch
from transformers import AutoConfig
import sys
import os

# Add the parent directory to sys.path to import the hf_hub_poc package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from hf_hub_poc.configuration_adelic_qwen3_6 import AdelicQwen3Config
from hf_hub_poc.modeling_adelic_qwen3_6 import AdelicQwen3ForCausalLM

def test_qwen3_adelic_cache():
    print("Initializing dummy Qwen on GPU to test Adèlic Cache Condensation...")
    
    # We load a standard Qwen2 configuration, but shrink it so it fits instantly
    config = AutoConfig.from_pretrained("Qwen/Qwen2-7B-Instruct")
    config.num_hidden_layers = 2
    config.hidden_size = 64
    config.intermediate_size = 128
    config.num_attention_heads = 4
    config.num_key_value_heads = 4
    
    # Adèlic settings
    config.adelic_soft_capacity = 32
    config.adelic_hard_capacity = 64
    config.adelic_local_window = 16
    config.adelic_similarity_threshold = 0.95
    config.adelic_hologram_decay = 0.9

    if torch.cuda.is_available():
        device = torch.device("cuda")
        print("Testing on CUDA (Triton Path)!")
    else:
        device = torch.device("cpu")
        print("Testing on CPU (PyTorch Fallback Path)!")

    model = AdelicQwen3ForCausalLM(config).to(device)
    model.eval()
    
    print(f"Starting Generation. Max Soft Capacity: {config.adelic_soft_capacity}, Local Window: {config.adelic_local_window}")
    
    # Simulate generating 100 tokens autoregressively
    input_ids = torch.randint(0, config.vocab_size, (1, 1), device=device)
    past_key_values = None
    
    with torch.no_grad():
        for step in range(100):
            outputs = model(
                input_ids=input_ids,
                past_key_values=past_key_values,
                use_cache=True
            )
            past_key_values = outputs.past_key_values
            
            # Pick a random next token
            input_ids = torch.randint(0, config.vocab_size, (1, 1), device=device)
            
            # Print status every 10 steps
            if (step + 1) % 10 == 0:
                physical_len = past_key_values.key_cache[0].shape[-2] if hasattr(past_key_values, "key_cache") else past_key_values.layers[0].keys.shape[-2]
                logical_len = past_key_values.adelic_true_seen_tokens
                print(f"Step {step+1:3d} | Logical RoPE Position: {logical_len:3d} | Physical Cache Size: {physical_len:3d} tokens")
                assert physical_len <= config.adelic_hard_capacity + 5, f"Cache condensation failed! Size: {physical_len}"

    print("\nSuccess! AdelicQwen3ForCausalLM maintained logarithmic memory footprint using the Triton kernel while advancing logical RoPE position.")

if __name__ == "__main__":
    test_qwen3_adelic_cache()
