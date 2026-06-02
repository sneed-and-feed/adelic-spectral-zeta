import torch
from transformers import AutoTokenizer, AutoConfig
from peft import PeftModel
import sys, os

# Add project root to sys.path so we can import the local custom model package
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from hf_hub_poc.configuration_adelic_llama import AdelicLlamaConfig
from hf_hub_poc.modeling_adelic_llama import AdelicLlamaForCausalLM

def generate_niah_prompt(tokenizer, haystack_len_tokens=2000):
    """
    Generates a Needle-In-A-Haystack prompt.
    The total length will be slightly larger than haystack_len_tokens.
    """
    filler_sentence = "The city council decided to plant more trees in the park to improve air quality and provide shade for the residents. "
    
    # Estimate tokens per sentence roughly
    tokens_per_sentence = len(tokenizer(filler_sentence).input_ids)
    num_sentences = (haystack_len_tokens // tokens_per_sentence) + 1
    
    haystack_sentences = [filler_sentence] * num_sentences
    
    # The Needle
    needle = "The secret launch code for the Mars mission is 'OMEGA-77'. "
    
    # Insert the needle into a random location in the first half of the document 
    # to guarantee it falls out of the Adelic local window and forces retrieval 
    # from the compressed spectral centroids.
    insert_idx = len(haystack_sentences) // 4
    haystack_sentences.insert(insert_idx, needle)
    
    context = "".join(haystack_sentences)
    
    query = "Based on the text above, what is the secret launch code for the Mars mission?"
    
    messages = [
        {"role": "system", "content": "You are a helpful assistant. Answer the user's question based strictly on the provided text."},
        {"role": "user", "content": f"Text:\n{context}\n\nQuestion:\n{query}"}
    ]
    
    prompt = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    return prompt

def run_niah_inference():
    base_model_id = "meta-llama/Meta-Llama-3.1-8B-Instruct"
    lora_model_id = "./adelic_gsm8k_lora"
    
    print(f"Loading Base Configuration: {base_model_id}")
    base_config = AutoConfig.from_pretrained(base_model_id)
    config = AdelicLlamaConfig(**base_config.to_dict())
    
    # Compress a ~2000 token context down to just 256 tokens in memory!
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
    
    # Disable LoRA adapter to test if it caused Context Window Collapse
    # if os.path.exists(lora_model_id):
    #     print(f"Injecting trained Adèlic LoRA adapter from {lora_model_id}...")
    #     model = PeftModel.from_pretrained(model, lora_model_id)
    # else:
    print(f"Running purely with base weights + AdelicCache (No LoRA).")
        
    tokenizer = AutoTokenizer.from_pretrained(base_model_id)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token
        
    model.eval()
    
    print("Generating 2000-token Needle-In-A-Haystack sequence...")
    prompt = generate_niah_prompt(tokenizer, haystack_len_tokens=2000)
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    
    print(f"Total Input Sequence Length: {inputs.input_ids.shape[1]} tokens")
    print(f"Adèlic Cache Max Capacity: {config.adelic_max_capacity} tokens")
    print("\nStarting generation... The model must retrieve the needle from the compressed topological history!\n")
    
    with torch.no_grad():
        outputs = model.generate(
            **inputs, 
            max_new_tokens=50, 
            temperature=0.1, 
            do_sample=True,
            use_cache=True, # This triggers the AdelicCache injection
            pad_token_id=tokenizer.eos_token_id,
            eos_token_id=tokenizer.convert_tokens_to_ids("<|eot_id|>") # Correct Llama-3 stop token!
        )
        
    # Extract only the newly generated tokens
    generated_ids = outputs[0][inputs.input_ids.shape[1]:]
    response = tokenizer.decode(generated_ids, skip_special_tokens=True)
    
    print("--- RESPONSE ---")
    print(response.strip())

if __name__ == "__main__":
    run_niah_inference()
