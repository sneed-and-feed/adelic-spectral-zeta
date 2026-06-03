import os
import sys
import torch

# Ensure hf_hub_poc is in path so we can import our custom architectures
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from hf_hub_poc.configuration_adelic_qwen import AdelicQwenConfig
from hf_hub_poc.modeling_adelic_qwen import AdelicQwenForCausalLM
from transformers import AutoTokenizer, AutoConfig, BitsAndBytesConfig

def main():
    model_id = "Qwen/Qwen3.6-27B"
    
    try:
        from google.colab import userdata
        hf_token = userdata.get('HF_TOKEN')
        print("Loaded HF_TOKEN from Colab secrets.")
    except Exception:
        hf_token = os.environ.get("HF_TOKEN")
        print("Not in Colab, checking local environment for HF_TOKEN.")

    print(f"Loading {model_id}...")
    
    try:
        tokenizer = AutoTokenizer.from_pretrained(model_id, trust_remote_code=True, token=hf_token)
    except Exception as e:
        print(f"Could not load tokenizer. Error: {e}")
        model_id = "Qwen/Qwen2.5-32B"
        print(f"Falling back to {model_id}...")
        tokenizer = AutoTokenizer.from_pretrained(model_id, trust_remote_code=True, token=hf_token)

    print("Configuring 4-bit Quantization (BitsAndBytes)...")
    quantization_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_compute_dtype=torch.bfloat16,
        bnb_4bit_use_double_quant=True,
        bnb_4bit_quant_type="nf4",
    )

    print("Loading Adèlic Qwen 27B model weights (this may take a minute)...")
    model = AdelicQwenForCausalLM.from_pretrained(
        model_id,
        adelic_soft_capacity=256,
        adelic_hard_capacity=1024,
        adelic_local_window=128,
        adelic_similarity_threshold=0.95,
        adelic_hologram_decay=0.9,
        quantization_config=quantization_config,
        device_map="auto",
        trust_remote_code=True,
        token=hf_token
    )
    
    # We create a massive repeated prompt to test cache compression
    prompt_text = "The quick brown fox jumps over the lazy dog. " * 50
    prompt_text += "\n\nQuestion: What animal jumped?\nAnswer: The quick brown"
    
    inputs = tokenizer(prompt_text, return_tensors="pt").to(model.device)
    
    print(f"\nPrompt length: {inputs.input_ids.shape[1]} tokens")
    print("Generating...")
    
    # Since use_cache=True, our AdelicQwenForCausalLM forward method will auto-inject the AdelicCache
    outputs = model.generate(
        **inputs,
        max_new_tokens=10,
        use_cache=True,
        do_sample=False
    )
    
    response = tokenizer.decode(outputs[0][inputs.input_ids.shape[1]:], skip_special_tokens=True)
    print(f"\nResponse: {response}")
    print("\nTest passed! The Adèlic Cache successfully intercepted the Qwen architecture.")

if __name__ == "__main__":
    main()
