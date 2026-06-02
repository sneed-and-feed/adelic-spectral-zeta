import os
import json
import argparse
import torch
from tqdm import tqdm
from datasets import load_dataset
from transformers import AutoModelForCausalLM, AutoTokenizer

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dataset', type=str, default='qasper', help='LongBench dataset to evaluate (e.g., qasper, narrativeqa, lcc)')
    parser.add_argument('--max_samples', type=int, default=None, help='Maximum number of samples to evaluate (useful for quick testing)')
    parser.add_argument('--output_dir', type=str, default='results', help='Directory to save the predictions')
    parser.add_argument('--max_new_tokens', type=int, default=128, help='Max generated tokens')
    return parser.parse_args()

def main():
    args = parse_args()
    os.makedirs(args.output_dir, exist_ok=True)
    out_file = os.path.join(args.output_dir, f"adelic_{args.dataset}.jsonl")
    
    print(f"Loading LongBench dataset: {args.dataset}...")
    try:
        import urllib.request
        import zipfile
        
        # Hugging Face permanently banned dataset scripts. The data is inside a data.zip file.
        # We download and extract it manually.
        url = "https://huggingface.co/datasets/THUDM/LongBench/resolve/main/data.zip"
        zip_path = "data.zip"
        local_file = f"data/{args.dataset}.jsonl"
        
        if not os.path.exists(local_file):
            print("Downloading THUDM/LongBench data.zip...")
            urllib.request.urlretrieve(url, zip_path)
            print("Extracting...")
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(".")
                
        if not os.path.exists(local_file):
            print(f"Dataset file {local_file} not found inside data.zip!")
            return
            
        dataset = load_dataset('json', data_files=local_file, split='train')
    except Exception as e:
        print(f"Failed to load dataset: {e}")
        return

    if args.max_samples is not None:
        dataset = dataset.select(range(min(args.max_samples, len(dataset))))

    print(f"Loading Adèlic Llama 3.1 8B Model (Optimized for A100 / BF16)...")
    # Load model on GPU with bfloat16 for maximum A100 performance
    model_id = "sneedjak/AdelicLlama-3.1-8B-Instruct"
    
    tokenizer = AutoTokenizer.from_pretrained(model_id, trust_remote_code=True)
    
    # trust_remote_code=True tells HuggingFace to download our topology router architecture
    model = AutoModelForCausalLM.from_pretrained(
        model_id,
        trust_remote_code=True,
        torch_dtype=torch.bfloat16,
        device_map="auto"
    )
    
    # We don't need torch.no_grad() around generate(), but it's safe.
    model.eval()

    print(f"Starting evaluation on {len(dataset)} samples...")
    fout = open(out_file, 'w', encoding='utf-8')
    
    with torch.no_grad():
        for item in tqdm(dataset):
            context = item['context']
            question = item['input']
            
            # Construct a generic instruction prompt
            instruction = f"Please read the following text and answer the question based on it.\n\nText:\n{context}\n\nQuestion:\n{question}"
            
            # Use Llama 3.1's native chat template
            messages = [{"role": "user", "content": instruction}]
            prompt = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
            
            input_ids = tokenizer(prompt, return_tensors="pt").input_ids.to(model.device)
            
            # Monkey-patch model.forward for this instance to intercept massive prefills
            # This perfectly prevents Causal Smearing while keeping HF `generate()` completely oblivious,
            # bypassing HF's internal sequence slicing bugs.
            if not hasattr(model, "_original_forward"):
                model._original_forward = model.forward
                
                def chunked_forward(input_ids=None, past_key_values=None, use_cache=None, position_ids=None, **kwargs):
                    if input_ids is not None and input_ids.shape[1] > 512 and past_key_values is None:
                        chunk_size = 512
                        for i in range(0, input_ids.shape[1] - 1, chunk_size):
                            chunk = input_ids[:, i:i+chunk_size]
                            
                            past_len = past_key_values._true_seen_tokens if past_key_values is not None else 0
                            chunk_pos = torch.arange(past_len, past_len + chunk.shape[1], dtype=torch.long, device=input_ids.device).unsqueeze(0)
                            
                            out = model._original_forward(
                                input_ids=chunk,
                                past_key_values=past_key_values,
                                use_cache=True,
                                position_ids=chunk_pos
                            )
                            past_key_values = out.past_key_values
                            
                        # Process the final token
                        last_token = input_ids[:, -1:]
                        past_len = past_key_values._true_seen_tokens
                        last_pos = torch.arange(past_len, past_len + 1, dtype=torch.long, device=input_ids.device).unsqueeze(0)
                        
                        out = model._original_forward(
                            input_ids=last_token,
                            past_key_values=past_key_values,
                            use_cache=use_cache,
                            position_ids=last_pos
                        )
                        
                        # Pad the logits so `generate()` can slice [:, -1, :] correctly without crashing
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
                temperature=0.1, 
                do_sample=False,
                pad_token_id=tokenizer.eos_token_id
            )
            
            # Decode only the newly generated tokens
            output_tokens = outputs[0][input_ids.shape[1]:]
            response = tokenizer.decode(output_tokens, skip_special_tokens=True).strip()
            
            # Save format matching LongBench's expected eval format
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
