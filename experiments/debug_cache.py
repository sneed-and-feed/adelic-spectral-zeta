import torch
from transformers import AutoTokenizer, AutoConfig
import sys, os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from hf_hub_poc.configuration_adelic_llama import AdelicLlamaConfig
from hf_hub_poc.modeling_adelic_llama import AdelicLlamaForCausalLM
from experiments.infer_adelic_niah import generate_niah_prompt

base_model_id = "meta-llama/Meta-Llama-3.1-8B-Instruct"

print("Loading config...")
base_config = AutoConfig.from_pretrained(base_model_id)
config = AdelicLlamaConfig(**base_config.to_dict())
config.adelic_max_capacity = 256
config.adelic_local_window = 128
config.adelic_similarity_threshold = 0.90

print("Loading model...")
model = AdelicLlamaForCausalLM.from_pretrained(
    base_model_id, 
    config=config, 
    torch_dtype=torch.bfloat16,
    device_map="auto"
)
model.eval()

tokenizer = AutoTokenizer.from_pretrained(base_model_id)

print("Generating sequence...")
prompt = generate_niah_prompt(tokenizer, haystack_len_tokens=2000)
inputs = tokenizer(prompt, return_tensors="pt").to(model.device)

# Find where "OMEGA" is in the prompt by progressively decoding
tokens = inputs.input_ids[0].tolist()
needle_pos = -1
for i in range(1, len(tokens)):
    prefix = tokenizer.decode(tokens[:i])
    if "OMEGA" in prefix:
        needle_pos = i - 1 # The token that just triggered the inclusion of "OMEGA"
        break

print(f"OMEGA is at position {needle_pos}")

print("Running prefill WITHOUT cache condensation to extract the pristine Key for OMEGA...")
# Temporarily bump capacity so AdelicCache doesn't condense
model.config.adelic_max_capacity = 999999
with torch.no_grad():
    res_pristine = model(inputs.input_ids, use_cache=True)
    
pristine_keys = res_pristine.past_key_values.key_cache[0] # layer 0, keys [B, H, K, D]
omega_key_pristine = pristine_keys[0, 0, needle_pos, :] # head 0

# Restore capacity
model.config.adelic_max_capacity = 256

print("Running prefill WITH AdelicCache condensation...")
with torch.no_grad():
    res_condensed = model(inputs.input_ids, use_cache=True, past_key_values=None) # this will trigger AdelicCache injection

condensed_cache = res_condensed.past_key_values
layer0_keys = condensed_cache.key_cache[0] # [B, H, K, D]

print(f"Condensed cache size: {layer0_keys.shape[2]}")

# Compute similarity of pristine OMEGA key to all condensed keys in head 0
condensed_keys_head0 = layer0_keys[0, 0, :, :] # [K, D]

norm_omega = torch.nn.functional.normalize(omega_key_pristine.float(), p=2, dim=-1)
norm_condensed = torch.nn.functional.normalize(condensed_keys_head0.float(), p=2, dim=-1)

sim = torch.matmul(norm_condensed, norm_omega)
max_sim, best_idx = torch.max(sim, dim=0)

print(f"Max similarity to pristine OMEGA key: {max_sim.item()} at index {best_idx.item()}")

if max_sim.item() > 0.99:
    print("SUCCESS: OMEGA SURVIVED PERFECTLY!")
else:
    print("FAILURE: OMEGA WAS DESTROYED BY CLUSTERING!")
