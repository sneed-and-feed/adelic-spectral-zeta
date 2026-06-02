import torch
from transformers import AutoTokenizer, AutoConfig
from peft import PeftModel
import sys, os

# Add project root to sys.path so we can import the local custom model package
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from hf_hub_poc.configuration_adelic_llama import AdelicLlamaConfig
from hf_hub_poc.modeling_adelic_llama import AdelicLlamaForCausalLM

def run_inference():
    base_model_id = "meta-llama/Meta-Llama-3.1-8B-Instruct"
    lora_model_id = "./adelic_gsm8k_lora"
    
    print(f"Loading Base Configuration: {base_model_id}")
    base_config = AutoConfig.from_pretrained(base_model_id)
    config = AdelicLlamaConfig(**base_config.to_dict())
    
    # We use the exact same cache capacity parameters that the model was trained on
    config.adelic_max_capacity = 256
    config.adelic_local_window = 128
    config.adelic_similarity_threshold = 0.90
    
    print("Loading Base Model in bf16...")
    model = AdelicLlamaForCausalLM.from_pretrained(
        base_model_id, 
        config=config, 
        torch_dtype=torch.bfloat16,
        device_map="auto"
    )
    
    print(f"Injecting trained Adèlic LoRA adapter from {lora_model_id}...")
    model = PeftModel.from_pretrained(model, lora_model_id)
    
    tokenizer = AutoTokenizer.from_pretrained(base_model_id)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token
        
    model.eval()
    
    # A classic GSM8K-style reasoning problem
    question = "John has 5 apples. He gives 2 to his friend. Then he buys 3 times as many apples as he currently has. How many apples does John have now?"
    messages = [
        {"role": "user", "content": question}
    ]
    prompt = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    
    print(f"\nPrompt:\n{prompt}\n")
    print("Generating response over the compressed topological cache...\n")
    
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    
    with torch.no_grad():
        outputs = model.generate(
            **inputs, 
            max_new_tokens=100, 
            temperature=0.1, 
            do_sample=True,
            use_cache=True, # This will trigger the AdelicCache injection in our custom forward pass
            pad_token_id=tokenizer.eos_token_id
        )
        
    response = tokenizer.decode(outputs[0], skip_special_tokens=True)
    print("--- RESPONSE ---")
    print(response)

if __name__ == "__main__":
    run_inference()
