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
        # Load the original LongBench dataset (v1)
        # Hugging Face recently disabled dataset scripts by default; must pass trust_remote_code=True
        dataset = load_dataset('THUDM/LongBench', args.dataset, split='test', trust_remote_code=True)
    except Exception as e:
        print(f"Failed to load dataset: {e}")
        return

    if args.max_samples is not None:
        dataset = dataset.select(range(min(args.max_samples, len(dataset))))

    print(f"Loading Adèlic Llama 3.1 8B Model (Optimized for A100 / BF16)...")
    # Load model on GPU with bfloat16 for maximum A100 performance
    model_id = "sneedjak/AdelicLlama-3.1-8B-Instruct"
    
    tokenizer = AutoTokenizer.from_pretrained(model_id)
    
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
            
            # Truncate to maximum acceptable context if necessary (though Adelic handles infinity, 
            # let's cap at 64k for sanity/time in testing unless we want true infinity)
            # We'll just pass the full context! Adelic will compress it perfectly.
            
            outputs = model.generate(
                input_ids,
                max_new_tokens=args.max_new_tokens,
                temperature=0.1, # Low temperature for factual QA
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
