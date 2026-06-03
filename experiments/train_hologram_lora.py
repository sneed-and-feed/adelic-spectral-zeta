import torch
from transformers import AutoTokenizer, BitsAndBytesConfig, AutoModelForCausalLM
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
import random
import string
import time

def generate_sample(tokenizer):
    """Generates a synthetic Needle-In-A-Haystack sample."""
    num_facts = 150 # Creates a prompt of ~1200 tokens
    facts = []
    keys = []
    values = []
    for _ in range(num_facts):
        k = "".join(random.choices(string.ascii_uppercase, k=6))
        v = str(random.randint(10000, 99999))
        keys.append(k)
        values.append(v)
        facts.append(f"The access code for server {k} is {v}.")
    
    haystack = " ".join(facts)
    target_idx = random.randint(0, num_facts-1)
    target_k = keys[target_idx]
    target_v = values[target_idx]
    
    prompt = f"{haystack} What is the access code for server {target_k}? The access code is"
    
    prompt_ids = tokenizer.encode(prompt, return_tensors="pt")
    target_ids = tokenizer.encode(f" {target_v}", return_tensors="pt", add_special_tokens=False)
    
    return prompt_ids, target_ids

def main():
    print("Loading tokenizer...")
    tokenizer = AutoTokenizer.from_pretrained("sneedjak/AdelicLlama-3.1-8B-Instruct", trust_remote_code=True)
    
    print("Loading model in 4-bit...")
    bnb_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_use_double_quant=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_compute_dtype=torch.bfloat16
    )
    
    # We load our custom Adelic model from the Hub
    model = AutoModelForCausalLM.from_pretrained(
        "sneedjak/AdelicLlama-3.1-8B-Instruct",
        quantization_config=bnb_config,
        trust_remote_code=True,
        device_map="auto"
    )
    
    print("Preparing model for LoRA training...")
    model = prepare_model_for_kbit_training(model, use_gradient_checkpointing=False)
    
    config = LoraConfig(
        r=16,
        lora_alpha=32,
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
        lora_dropout=0.05,
        bias="none",
        task_type="CAUSAL_LM"
    )
    
    model = get_peft_model(model, config)
    model.print_trainable_parameters()
    
    optimizer = torch.optim.AdamW(model.parameters(), lr=2e-4)
    device = model.device
    
    print("\nStarting Cache-Injected BPTT Training Loop...")
    epochs = 1000
    
    for epoch in range(epochs):
        
        prompt_ids, target_ids = generate_sample(tokenizer)
        prompt_ids = prompt_ids.to(device)
        target_ids = target_ids.to(device)
        
        # 1. Prefill (No Gradients)
        # We MUST set model.eval() because Hugging Face will silently disable `use_cache=True` if the model is in training mode!
        model.eval()
        with torch.no_grad():
            prefill_input = prompt_ids[:, :-1]
            outputs = model(input_ids=prefill_input, use_cache=True)
            past_key_values = outputs.past_key_values
            
        # 2. Gradient Pass (Backpropagation through Time)
        # Re-enable training mode for the LoRA adapters
        model.train()
        optimizer.zero_grad()
        grad_input = torch.cat([prompt_ids[:, -1:], target_ids[:, :-1]], dim=-1)
        
        # Forward pass on the Question and Answer tokens, attending to the frozen compressed cache
        outputs = model(input_ids=grad_input, past_key_values=past_key_values, use_cache=False)
        logits = outputs.logits
        
        loss = torch.nn.functional.cross_entropy(logits.view(-1, logits.size(-1)), target_ids.view(-1))
        
        loss.backward()
        optimizer.step()
        
        if epoch % 10 == 0:
            print(f"Epoch {epoch} | Loss: {loss.item():.4f} | Cache Size: {past_key_values.get_seq_length()}")
            
    print("Training complete! The LoRA can now decode the Holographic State.")
    model.save_pretrained("hologram_lora_adapter")

if __name__ == "__main__":
    main()
