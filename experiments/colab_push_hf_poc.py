import os
from huggingface_hub import login

hf_token = os.environ.get('HF_TOKEN')
if hf_token:
    login(token=hf_token)
    print("Successfully logged into Hugging Face Hub using HF_TOKEN environment variable.")
else:
    print("Warning: HF_TOKEN environment variable not found. Ensure you are logged in.")

from transformers import AutoTokenizer, AutoModelForCausalLM, AutoConfig
import torch
import sys

# Add project root to sys.path so we can import the local custom model package
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from hf_hub_poc.configuration_adelic_llama import AdelicLlamaConfig
from hf_hub_poc.modeling_adelic_llama import AdelicLlamaForCausalLM

def push_to_hub():
    # Register the custom architecture to HF AutoClasses
    AdelicLlamaConfig.register_for_auto_class()
    AdelicLlamaForCausalLM.register_for_auto_class("AutoModelForCausalLM")
    
    base_model_id = "meta-llama/Meta-Llama-3.1-8B-Instruct"
    
    print(f"Loading Base Model: {base_model_id}")
    # Load base config
    base_config = AutoConfig.from_pretrained(base_model_id)
    
    # Create Custom Adelic Config using the base config's attributes
    adelic_config = AdelicLlamaConfig(**base_config.to_dict())
    
    # Configure the Adelic Condensation defaults for an 8B model
    adelic_config.adelic_max_capacity = 2048
    adelic_config.adelic_local_window = 512
    adelic_config.adelic_similarity_threshold = 0.95
    
    print("Instantiating AdelicLlamaForCausalLM architecture...")
    # Instantiate the custom model architecture and load the pre-trained weights
    # Note: Meta Llama 3.1 requires bfloat16 for optimal loading on A100
    model = AdelicLlamaForCausalLM.from_pretrained(
        base_model_id, 
        config=adelic_config,
        torch_dtype=torch.bfloat16
    )
    
    # Load Tokenizer
    tokenizer = AutoTokenizer.from_pretrained(base_model_id)
    
    # Determine repo name
    username = os.environ.get("HF_USERNAME", "anon")
    try:
        from huggingface_hub import whoami
        username = whoami()["name"]
    except Exception:
        pass
        
    repo_id = f"{username}/Adelic-Llama-3.1-8B-Instruct"
    
    print(f"\nPushing Custom Model with Adelic Condensation Cache to Hugging Face Hub: {repo_id}")
    print("This will upload the custom `modeling_adelic_llama.py` and `configuration_adelic_llama.py` alongside the weights.")
    
    model.push_to_hub(repo_id)
    tokenizer.push_to_hub(repo_id)
    
    print(f"\n✅ Success! The model is live at: https://huggingface.co/{repo_id}")
    print("Users can now load and run it out-of-the-box with logarithmic condensation:")
    print("```python")
    print("from transformers import AutoModelForCausalLM")
    print(f'model = AutoModelForCausalLM.from_pretrained("{repo_id}", trust_remote_code=True)')
    print('outputs = model.generate(inputs, max_new_tokens=100)')
    print("```")

if __name__ == "__main__":
    push_to_hub()
