import json

with open('experiments/llama_surgery/finetune_colab.ipynb', 'r', encoding='utf-8') as f:
    nb = json.load(f)

# Update Cell 1 source
new_source = [
    "# 1. Install dependencies\n",
    "!pip install transformers datasets accelerate huggingface_hub peft \"torchao>=0.16.0\"\n",
    "\n",
    "# 2. Login to Hugging Face\n",
    "from huggingface_hub import login\n",
    "login(\"hf_YOUR_TOKEN_HERE\") # Replace with your token\n"
]
nb['cells'][0]['source'] = new_source

with open('experiments/llama_surgery/finetune_colab.ipynb', 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=1)

print("Dependencies fixed in notebook!")
