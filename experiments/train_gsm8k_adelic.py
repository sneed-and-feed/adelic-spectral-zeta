import torch
from transformers import AutoTokenizer, AutoConfig
from peft import LoraConfig, get_peft_model
from torch.optim import AdamW
from datasets import load_dataset
from torch.utils.data import DataLoader
from tqdm import tqdm
import sys, os

# Add project root to sys.path so we can import the local custom model package
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from hf_hub_poc.configuration_adelic_llama import AdelicLlamaConfig
from hf_hub_poc.modeling_adelic_llama import AdelicLlamaForCausalLM, AdelicCache

def train_gsm8k():
    model_id = "meta-llama/Meta-Llama-3.1-8B-Instruct"
    
    print(f"Loading Base Configuration: {model_id}")
    base_config = AutoConfig.from_pretrained(model_id)
    config = AdelicLlamaConfig(**base_config.to_dict())
    
    # Configure Adelic parameters for the math curriculum
    # Setting an aggressive threshold to force the network to adapt to condensation during reasoning
    config.adelic_max_capacity = 64
    config.adelic_local_window = 32
    config.adelic_similarity_threshold = 0.90
    
    print("Loading Base Model in bf16...")
    model = AdelicLlamaForCausalLM.from_pretrained(
        model_id, 
        config=config, 
        torch_dtype=torch.bfloat16,
        device_map="auto"
    )
    
    print("Initializing LoRA Adapters...")
    lora_config = LoraConfig(
        r=16,
        lora_alpha=32,
        target_modules=["q_proj", "v_proj", "k_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
        lora_dropout=0.05,
        bias="none",
        task_type="CAUSAL_LM"
    )
    model = get_peft_model(model, lora_config)
    model.print_trainable_parameters()
    
    tokenizer = AutoTokenizer.from_pretrained(model_id)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token
        
    print("\nLoading GSM8K dataset...")
    # Requires `pip install datasets` in Colab
    try:
        dataset = load_dataset("openai/gsm8k", "main")
    except Exception as e:
        print(f"Dataset load failed. Make sure you ran `pip install datasets`. Error: {e}")
        return
        
    def format_data(example):
        messages = [
            {"role": "user", "content": example["question"]},
            {"role": "assistant", "content": example["answer"]}
        ]
        text = tokenizer.apply_chat_template(messages, tokenize=False)
        tokens = tokenizer(text, truncation=True, max_length=1024, padding=False)
        return tokens

    print("Tokenizing data...")
    train_data = dataset["train"].map(format_data, batched=False)
    
    def collate_fn(batch):
        return {
            "input_ids": torch.tensor([x["input_ids"] for x in batch]),
            "attention_mask": torch.tensor([x["attention_mask"] for x in batch])
        }
    
    dataloader = DataLoader(train_data, batch_size=1, shuffle=True, collate_fn=collate_fn)
    optimizer = AdamW(model.parameters(), lr=2e-4)
    
    epochs = 3
    chunk_size = 256
    
    print(f"\nStarting Adèlic QAT on GSM8K for {epochs} epochs...")
    print(f"Chunk size: {chunk_size} | Condensation max_capacity: 256 | local_window: 128")
    
    model.train()
    
    for epoch in range(epochs):
        total_loss = 0
        pbar = tqdm(dataloader, desc=f"Epoch {epoch+1}/{epochs}")
        
        for batch in pbar:
            input_ids = batch["input_ids"].to(model.device)
            
            # Find the actual valid length of the sequence (ignoring padding)
            valid_len = (input_ids[0] != tokenizer.pad_token_id).sum().item()
            if valid_len <= 1:
                continue
                
            input_ids = input_ids[:, :valid_len]
            seq_len = valid_len
            
            optimizer.zero_grad()
            
            # Instantiate a fresh AdelicCache for the sequence
            past_key_values = AdelicCache(
                max_capacity=config.adelic_max_capacity,
                local_window=config.adelic_local_window
            )
            
            loss_accum = 0
            chunks = list(range(0, seq_len - 1, chunk_size))
            
            if not chunks:
                continue
                
            for idx, i in enumerate(chunks):
                chunk_input_ids = input_ids[:, i:i+chunk_size]
                chunk_labels = input_ids[:, i+1:i+chunk_size+1].clone()
                
                # Avoid out of bounds for the final truncated chunk
                if chunk_labels.shape[1] < chunk_input_ids.shape[1]:
                    chunk_input_ids = chunk_input_ids[:, :chunk_labels.shape[1]]
                
                outputs = model(
                    input_ids=chunk_input_ids,
                    past_key_values=past_key_values,
                    use_cache=True
                )
                
                logits = outputs.logits
                min_len = min(logits.shape[1], chunk_labels.shape[1])
                logits = logits[:, :min_len, :].contiguous()
                chunk_labels = chunk_labels[:, :min_len].contiguous()
                
                loss_fct = torch.nn.CrossEntropyLoss()
                loss = loss_fct(logits.view(-1, logits.size(-1)), chunk_labels.view(-1))
                
                # Scale the loss to normalize gradients across sequence lengths
                scaled_loss = loss / len(chunks)
                
                retain_graph = (idx < len(chunks) - 1)
                scaled_loss.backward(retain_graph=retain_graph)
                loss_accum += loss.item()
                
            # Gradient clipping to prevent explosion
            torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            optimizer.step()
            # Optional: Step the scheduler if we add one (not strictly necessary with clipping and scaled loss, but safe)
            
            total_loss += (loss_accum / len(chunks))
            
            pbar.set_postfix({
                "loss": f"{(loss_accum / len(chunks)):.4f}", 
                "cache_size": f"{past_key_values.key_cache[0].shape[-2]}"
            })
            
        print(f"Epoch {epoch+1} Average Loss: {total_loss / len(dataloader):.4f}")
        
    print("\nTraining Complete! Saving Adèlic LoRA weights...")
    os.makedirs("./adelic_gsm8k_lora", exist_ok=True)
    model.save_pretrained("./adelic_gsm8k_lora")
    print("✅ Saved to ./adelic_gsm8k_lora")

if __name__ == "__main__":
    train_gsm8k()
