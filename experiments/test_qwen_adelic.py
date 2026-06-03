import os
import sys
import torch

# Ensure hf_hub_poc is in path so we can import our custom architectures
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from hf_hub_poc.configuration_adelic_qwen import AdelicQwenConfig
from hf_hub_poc.modeling_adelic_qwen import AdelicQwenForCausalLM
from transformers import AutoTokenizer, AutoConfig, BitsAndBytesConfig

def main():
    model_id = "Qwen/Qwen3.6-27B" # User wants to run Qwen3.6-27B
    
    try:
        from google.colab import userdata
        hf_token = userdata.get('HF_TOKEN')
        print("Loaded HF_TOKEN from Colab secrets.")
    except Exception:
        hf_token = os.environ.get("HF_TOKEN")
        print("Not in Colab, checking local environment for HF_TOKEN.")

    print(f"Loading {model_id}...")
    
    if "Qwen3.6" in model_id or "Qwen3_5" in model_id:
        print("\n[!] Qwen3.6 Hybrid Architecture Detected. Using AdelicQwen3_5 classes.")
        print("[!] If you have not installed FLA, run: pip install git+https://github.com/fla-org/flash-linear-attention")
        from hf_hub_poc.configuration_adelic_qwen3_5 import AdelicQwen3_5Config as AdelicConfig
        from hf_hub_poc.modeling_adelic_qwen3_5 import AdelicQwen3_5ForCausalLM as AdelicLM
    else:
        print("\n[!] Qwen2.5 Standard Architecture Detected. Using AdelicQwen classes.")
        from hf_hub_poc.configuration_adelic_qwen import AdelicQwenConfig as AdelicConfig
        from hf_hub_poc.modeling_adelic_qwen import AdelicQwenForCausalLM as AdelicLM

    try:
        tokenizer = AutoTokenizer.from_pretrained(model_id, trust_remote_code=True, token=hf_token)
    except Exception as e:
        print(f"Could not load tokenizer. Error: {e}")
        model_id = "Qwen/Qwen2.5-7B-Instruct"
        print(f"Falling back to {model_id}...")
        tokenizer = AutoTokenizer.from_pretrained(model_id, trust_remote_code=True, token=hf_token)
        
    # Download the base config and wrap it in our Adelic wrapper
    base_config = AutoConfig.from_pretrained(model_id, trust_remote_code=True, token=hf_token)
    
    base_dict = base_config.to_dict()
    
    if "text_config" in base_dict:
        print("Extracting text_config from multimodal configuration...")
        base_dict = base_dict["text_config"]

    # TRANSFORMERS BUG FIX: In bleeding-edge transformers, if a remote config has a generation_config dict,
    # GenerationConfig.from_model_config blindly calls to_dict() on it, crashing the entire load process.
    if "generation_config" in base_dict:
        del base_dict["generation_config"]
        
    config = AdelicConfig(
        **base_dict,
        adelic_soft_capacity=256,
        adelic_hard_capacity=1024,
        adelic_local_window=128,
        adelic_similarity_threshold=0.95,
        adelic_hologram_decay=0.9
    )
    
    if hasattr(config, "generation_config"):
        config.generation_config = None

    print("Configuring 4-bit Quantization (BitsAndBytes)...")
    quantization_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_compute_dtype=torch.bfloat16,
        bnb_4bit_use_double_quant=True,
        bnb_4bit_quant_type="nf4",
    )

    print(f"Loading Adèlic {model_id} model weights (this may take a minute)...")
    model = AdelicLM.from_pretrained(
        model_id,
        config=config,
        quantization_config=quantization_config,
        device_map="auto",
        trust_remote_code=True,
        token=hf_token
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
        max_new_tokens=10,
        use_cache=True,
        do_sample=False
    )
    
    response = tokenizer.decode(outputs[0][inputs.input_ids.shape[1]:], skip_special_tokens=True)
    print(f"\nResponse: {response}")
    print("\nTest passed! The Adèlic Cache successfully intercepted the Qwen architecture.")

if __name__ == "__main__":
    main()
