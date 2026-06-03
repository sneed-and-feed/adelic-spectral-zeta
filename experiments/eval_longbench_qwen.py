import os
import json
import argparse
import torch
from tqdm import tqdm
from datasets import load_dataset
from transformers import AutoModelForCausalLM, AutoTokenizer, AutoConfig, BitsAndBytesConfig

# Import directly from the files we downloaded to the root folder (or if running from repo)
try:
    from configuration_adelic_qwen3_5 import AdelicQwen3_5Config
    from modeling_adelic_qwen3_5 import AdelicQwen3_5ForCausalLM
except ImportError:
    import sys
    sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
    from hf_hub_poc.configuration_adelic_qwen3_5 import AdelicQwen3_5Config
    from hf_hub_poc.modeling_adelic_qwen3_5 import AdelicQwen3_5ForCausalLM

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dataset', type=str, default='qasper', help='LongBench dataset to evaluate (e.g., qasper, narrativeqa, lcc)')
    parser.add_argument('--max_samples', type=int, default=None, help='Maximum number of samples to evaluate')
    parser.add_argument('--output_dir', type=str, default='results', help='Directory to save the predictions')
    parser.add_argument('--max_new_tokens', type=int, default=128, help='Max generated tokens')
    return parser.parse_args()

def main():
    args = parse_args()
    os.makedirs(args.output_dir, exist_ok=True)
    out_file = os.path.join(args.output_dir, f"qwen_adelic_{args.dataset}.jsonl")
    
    print(f"Loading LongBench dataset: {args.dataset}...")
    try:
        import urllib.request
        import zipfile
        
        url = "https://huggingface.co/datasets/THUDM/LongBench/resolve/main/data.zip"
        zip_path = "data.zip"
        local_file = f"data/{args.dataset}.jsonl"
        
        if not os.path.exists(local_file):
            print("Downloading THUDM/LongBench data.zip...")
            urllib.request.urlretrieve(url, zip_path)
            print("Extracting...")
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(".")
                
        dataset = load_dataset('json', data_files=local_file, split='train')
    except Exception as e:
        print(f"Failed to load dataset: {e}")
        return

    if args.max_samples is not None:
        dataset = dataset.select(range(min(args.max_samples, len(dataset))))

    model_id = "Qwen/Qwen3.6-27B" 
    print(f"Loading tokenizer from {model_id}...")
    tokenizer = AutoTokenizer.from_pretrained(model_id, trust_remote_code=True)
    
    print("Extracting base config...")
    base_config = AutoConfig.from_pretrained(model_id, trust_remote_code=True)
    base_dict = base_config.to_dict()
    if "text_config" in base_dict:
        base_dict = base_dict["text_config"]
    if "generation_config" in base_dict:
        del base_dict["generation_config"]
        
    print("Wrapping inside Adèlic Spectral Zeta Topology...")
    config = AdelicQwen3_5Config(**base_dict)
    
    bnb_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_compute_dtype=torch.bfloat16,
        bnb_4bit_use_double_quant=True,
        bnb_4bit_quant_type="nf4"
    )
    
    print(f"Loading Weights into Adèlic Architecture in 4-bit...")
    model = AdelicQwen3_5ForCausalLM.from_pretrained(
        model_id,
        config=config,
        quantization_config=bnb_config,
        device_map="auto",
        trust_remote_code=True,
    )
    model.eval()

    print(f"Starting evaluation on {len(dataset)} samples...")
    fout = open(out_file, 'w', encoding='utf-8')
    
    with torch.no_grad():
        for item in tqdm(dataset):
            context = item['context']
            question = item['input']
            
            instruction = f"Please read the following text and answer the question based on it. Answer directly and concisely. DO NOT output any reasoning, thinking process, or explanation.\n\nText:\n{context}\n\nQuestion:\n{question}"
            messages = [{"role": "user", "content": instruction}]
            
            encoded = tokenizer.apply_chat_template(messages, tokenize=True, return_tensors="pt", add_generation_prompt=True, return_dict=True)
            input_ids = encoded["input_ids"].to(model.device)
            
            # Monkey-patch forward to prevent Causal Smearing (chunked prefill)
            if not hasattr(model, "_original_forward"):
                model._original_forward = model.forward
                
                def chunked_forward(input_ids=None, past_key_values=None, use_cache=None, position_ids=None, **kwargs):
                    if input_ids is not None and input_ids.shape[1] > 512 and past_key_values is None:
                        chunk_size = 512
                        context_ids = input_ids[:, :-1]
                        
                        for i in range(0, context_ids.shape[1], chunk_size):
                            chunk = context_ids[:, i:i+chunk_size]
                            
                            past_len = past_key_values._true_seen_tokens if past_key_values is not None else 0
                            chunk_pos = torch.arange(past_len, past_len + chunk.shape[1], dtype=torch.long, device=input_ids.device).unsqueeze(0)
                            
                            out = model._original_forward(
                                input_ids=chunk,
                                past_key_values=past_key_values,
                                use_cache=True,
                                position_ids=chunk_pos
                            )
                            past_key_values = out.past_key_values
                            
                        last_token = input_ids[:, -1:]
                        past_len = past_key_values._true_seen_tokens
                        last_pos = torch.arange(past_len, past_len + 1, dtype=torch.long, device=input_ids.device).unsqueeze(0)
                        
                        out = model._original_forward(
                            input_ids=last_token,
                            past_key_values=past_key_values,
                            use_cache=use_cache,
                            position_ids=last_pos
                        )
                        
                        dummy_logits = torch.zeros(input_ids.shape[0], input_ids.shape[1] - 1, out.logits.shape[-1], dtype=out.logits.dtype, device=out.logits.device)
                        full_logits = torch.cat([dummy_logits, out.logits], dim=1)
                        
                        from transformers.modeling_outputs import CausalLMOutputWithPast
                        return CausalLMOutputWithPast(
                            loss=out.loss,
                            logits=full_logits,
                            past_key_values=out.past_key_values,
                            hidden_states=out.hidden_states,
                            attentions=out.attentions,
                        )
                    return model._original_forward(input_ids=input_ids, past_key_values=past_key_values, use_cache=use_cache, position_ids=position_ids, **kwargs)
                
                model.forward = chunked_forward

            outputs = model.generate(
                input_ids,
                max_new_tokens=args.max_new_tokens,
                do_sample=False,
                pad_token_id=tokenizer.eos_token_id
            )
            
            output_tokens = outputs[0][input_ids.shape[1]:]
            response = tokenizer.decode(output_tokens, skip_special_tokens=True).strip()
            
            result = {
                "pred": response,
                "answers": item["answers"],
                "all_classes": item["all_classes"],
                "length": item["length"],
                "dataset": args.dataset
            }
            fout.write(json.dumps(result, ensure_ascii=False) + '\n')
            fout.flush()
            
    fout.close()
    print(f"Evaluation complete! Results saved to {out_file}")

if __name__ == "__main__":
    main()
