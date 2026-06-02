import torch
from transformers import AutoTokenizer, AutoConfig
import sys, os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from hf_hub_poc.configuration_adelic_llama import AdelicLlamaConfig
from hf_hub_poc.modeling_adelic_llama import AdelicLlamaForCausalLM

def push_model():
    hf_repo_name = "sneedjak/AdelicLlama-3-8B-Instruct" 
    base_model_id = "meta-llama/Meta-Llama-3.1-8B-Instruct"
    
    print("Loading base config...")
    base_config = AutoConfig.from_pretrained(base_model_id)
    config = AdelicLlamaConfig(**base_config.to_dict())
    
    # Set default Adèlic hyperparameters
    config.adelic_max_capacity = 256
    config.adelic_local_window = 128
    config.adelic_similarity_threshold = 0.90
    
    # Register the custom architecture so AutoClasses know how to load it
    AdelicLlamaConfig.register_for_auto_class()
    AdelicLlamaForCausalLM.register_for_auto_class("AutoModelForCausalLM")
    
    print("Loading model weights (this takes a moment)...")
    model = AdelicLlamaForCausalLM.from_pretrained(
        base_model_id, 
        config=config, 
        torch_dtype=torch.bfloat16,
        device_map="auto"
    )
    
    tokenizer = AutoTokenizer.from_pretrained(base_model_id)
    
    print(f"Pushing to Hugging Face Hub: {hf_repo_name}")
    # Push everything to the Hub!
    config.push_to_hub(hf_repo_name)
    model.push_to_hub(hf_repo_name)
    tokenizer.push_to_hub(hf_repo_name)
    
    print("Successfully pushed! Anyone can now use it with trust_remote_code=True.")

if __name__ == "__main__":
    push_model()
