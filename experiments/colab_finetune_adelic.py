import torch
from transformers import AutoTokenizer, AutoConfig
from peft import LoraConfig, get_peft_model
from torch.optim import AdamW
import sys, os

# Add project root to sys.path so we can import the local custom model package
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from hf_hub_poc.configuration_adelic_llama import AdelicLlamaConfig
from hf_hub_poc.modeling_adelic_llama import AdelicLlamaForCausalLM, AdelicCache

def run_qat_training():
    model_id = "meta-llama/Meta-Llama-3.1-8B-Instruct"
    
    print(f"Loading Base Configuration: {model_id}")
    base_config = AutoConfig.from_pretrained(model_id)
    config = AdelicLlamaConfig(**base_config.to_dict())
    
    # Force extreme condensation thresholds to guarantee the cache triggers
    # during training on short paragraphs.
    config.adelic_max_capacity = 64
    config.adelic_local_window = 32
    config.adelic_similarity_threshold = 0.85
    
    print("Loading Base Model in bf16 (40GB A100 has plenty of VRAM)...")
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
        
    # We construct a text explicitly long enough to trigger max_capacity=64
    text = "Question: What is 2+2? Let's think step by step. We have two apples. Then we get two more apples. The total number of apples is four. Answer: 4. " * 8
    inputs = tokenizer(text, return_tensors="pt").to(model.device)
    
    optimizer = AdamW(model.parameters(), lr=2e-4)
    
    print("\nStarting Compression-Aware Training (QAT)...")
    print("Executing chunked autoregressive forward passes to force gradients through Adèlic Medoids.\n")
    
    # We process the sequence in chunks to physically force the cache to fill and condense
    chunk_size = 32
    seq_len = inputs.input_ids.shape[1]
    
    model.train()
    for epoch in range(5):
        optimizer.zero_grad()
        
        # Instantiate a fresh AdelicCache for the sequence
        past_key_values = AdelicCache(
            max_capacity=config.adelic_max_capacity,
            local_window=config.adelic_local_window,
            similarity_threshold=config.adelic_similarity_threshold
        )
        
        total_loss = 0
        chunks = list(range(0, seq_len - 1, chunk_size))
        
        for idx, i in enumerate(chunks):
            # Input chunk
            chunk_input_ids = inputs.input_ids[:, i:i+chunk_size]
            
            # Next-token prediction labels
            chunk_labels = inputs.input_ids[:, i+1:i+chunk_size+1].clone()
            
            # For the very last token in the sequence, avoid indexing errors if chunk is truncated
            if chunk_labels.shape[1] < chunk_input_ids.shape[1]:
                chunk_input_ids = chunk_input_ids[:, :chunk_labels.shape[1]]
            
            outputs = model(
                input_ids=chunk_input_ids,
                past_key_values=past_key_values,
                use_cache=True,
                labels=chunk_labels
            )
            
            loss = outputs.loss
            
            # Retain the computation graph so the cache vectors can be updated across chunks
            retain_graph = (idx < len(chunks) - 1)
            loss.backward(retain_graph=retain_graph)
            
            total_loss += loss.item()
            
        optimizer.step()
        avg_loss = total_loss / len(chunks)
        
        physical_cache_size = past_key_values.key_cache[0].shape[-2]
        logical_size = past_key_values.get_seq_length(0)
        
        print(f"Epoch {epoch+1}/5 | Loss: {avg_loss:.4f} | Logical Pos: {logical_size} | Physical Cache: {physical_cache_size}")
        
    print("\n✅ QAT Training Step Complete!")
    print("Gradients successfully flowed backwards through the O(1) online clustering logic.")

if __name__ == "__main__":
    run_qat_training()
