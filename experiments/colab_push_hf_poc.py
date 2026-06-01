import os
from huggingface_hub import login
try:
    from google.colab import userdata
    hf_token = userdata.get('HF_TOKEN')
    if hf_token:
        login(token=hf_token)
        print("Successfully logged into Hugging Face Hub using Colab Secrets.")
    else:
        print("Warning: HF_TOKEN not found in Colab Secrets.")
except ImportError:
    print("Not running in Colab. Ensure you have run `huggingface-cli login`.")

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
    
    base_model_id = "TinyLlama/TinyLlama-1.1B-intermediate-step-1431k-3T"
    
    print(f"Loading Base Model: {base_model_id}")
    # Load base config
    base_config = AutoConfig.from_pretrained(base_model_id)
    
    # Create Custom Adelic Config using the base config's attributes
    adelic_config = AdelicLlamaConfig(**base_config.to_dict())
    
    # Configure the Adelic Condensation defaults
    adelic_config.adelic_max_capacity = 512
    adelic_config.adelic_local_window = 128
    adelic_config.adelic_similarity_threshold = 0.95
    
    print("Instantiating AdelicLlamaForCausalLM architecture...")
    # Instantiate the custom model architecture and load the pre-trained weights from TinyLlama
    # We use from_pretrained on the custom class directly!
    model = AdelicLlamaForCausalLM.from_pretrained(base_model_id, config=adelic_config)
    
    # Load Tokenizer
    tokenizer = AutoTokenizer.from_pretrained(base_model_id)
    
    # Determine repo name
    username = os.environ.get("HF_USERNAME", "anon")
    try:
        from huggingface_hub import whoami
        username = whoami()["name"]
    except Exception:
        pass
        
    repo_id = f"{username}/Adelic-TinyLlama-1.1B"
    
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
