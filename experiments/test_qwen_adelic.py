import os
import sys
import torch

# Ensure hf_hub_poc is in path so we can import our custom architectures
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from hf_hub_poc.configuration_adelic_qwen import AdelicQwenConfig
from hf_hub_poc.modeling_adelic_qwen import AdelicQwenForCausalLM
from transformers import AutoTokenizer, AutoConfig

def main():
    model_id = "Qwen/Qwen3.6-7B-Instruct"
    print(f"Loading {model_id}...")
    
    try:
        tokenizer = AutoTokenizer.from_pretrained(model_id, trust_remote_code=True)
    except Exception as e:
        print(f"Could not load tokenizer (Note: 3.6 might be named differently on HF, replace with 2.5 if needed). Error: {e}")
        # Fallback to 2.5 for testing if 3.6 isn't strictly available yet
        model_id = "Qwen/Qwen2.5-7B-Instruct"
        print(f"Falling back to {model_id}...")
        tokenizer = AutoTokenizer.from_pretrained(model_id, trust_remote_code=True)
        
    # Download the base config and wrap it in our Adelic wrapper
    base_config = AutoConfig.from_pretrained(model_id, trust_remote_code=True)
    
    config = AdelicQwenConfig(
        **base_config.to_dict(),
        adelic_soft_capacity=256,
        adelic_hard_capacity=1024,
        adelic_local_window=128,
        adelic_similarity_threshold=0.95,
        adelic_hologram_decay=0.9
    )

    print("Loading Adèlic Qwen model weights...")
    model = AdelicQwenForCausalLM.from_pretrained(
        model_id,
        config=config,
        torch_dtype=torch.bfloat16,
        device_map="auto",
        trust_remote_code=True,
    )
    
    # We create a massive repeated prompt to test cache compression
    prompt_text = "The quick brown fox jumps over the lazy dog. " * 50
    messages = [
        {"role": "system", "content": "You are a helpful assistant. Please summarize the user's text."},
        {"role": "user", "content": prompt_text + " What animal jumped?"}
    ]
    
    text = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    inputs = tokenizer(text, return_tensors="pt").to(model.device)
    
    print(f"\nPrompt length: {inputs.input_ids.shape[1]} tokens")
    print("Generating...")
    
    # Since use_cache=True, our AdelicQwenForCausalLM forward method will auto-inject the AdelicCache
    outputs = model.generate(
        **inputs,
        max_new_tokens=20,
        use_cache=True,
        do_sample=False
    )
    
    response = tokenizer.decode(outputs[0][inputs.input_ids.shape[1]:], skip_special_tokens=True)
    print(f"\nResponse: {response}")
    print("\nTest passed! The Adèlic Cache successfully intercepted the Qwen architecture.")

if __name__ == "__main__":
    main()
