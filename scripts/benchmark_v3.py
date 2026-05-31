import torch
import time
import argparse
import csv
from datasets import load_dataset
from transformers import AutoTokenizer, AutoModelForCausalLM
import gc

def clear_surgery_cache(model):
    for name, module in model.named_modules():
        if hasattr(module, "_cached_assignments"):
            module._cached_assignments = None
    gc.collect()
    torch.cuda.empty_cache()

def benchmark_hardware(model, tokenizer, seq_lengths, csv_writer):
    print("\n" + "="*50)
    print(" HARDWARE SCALING BENCHMARK (Prefill Phase)")
    print("="*50)
    
    device = model.device
    
    for seq_len in seq_lengths:
        print(f"\nEvaluating Sequence Length: {seq_len}")
        
        # Create dummy input tokens
        input_ids = torch.randint(0, tokenizer.vocab_size, (1, seq_len), device=device)
        
        for use_triton in [False, True]:
            mode_name = "Triton Sparse" if use_triton else "PyTorch Dense"
            model.config.use_triton_sparse_attention = use_triton
            
            # Clear cache and reset memory stats
            clear_surgery_cache(model)
            torch.cuda.reset_peak_memory_stats()
            
            # Warmup
            with torch.no_grad():
                try:
                    _ = model(input_ids, use_cache=False)
                except torch.cuda.OutOfMemoryError:
                    print(f"  [{mode_name}] OOM during warmup!")
                    clear_surgery_cache(model)
                    csv_writer.writerow([seq_len, mode_name, "OOM", "OOM"])
                    continue
            
            torch.cuda.synchronize()
            start_event = torch.cuda.Event(enable_timing=True)
            end_event = torch.cuda.Event(enable_timing=True)
            
            try:
                start_event.record()
                with torch.no_grad():
                    _ = model(input_ids, use_cache=False)
                end_event.record()
                torch.cuda.synchronize()
                
                exec_time_ms = start_event.elapsed_time(end_event)
                peak_vram_mb = torch.cuda.max_memory_allocated() / (1024 ** 2)
                
                print(f"  [{mode_name}] Time: {exec_time_ms:.2f} ms | Peak VRAM: {peak_vram_mb:.2f} MB")
                csv_writer.writerow([seq_len, mode_name, f"{exec_time_ms:.2f}", f"{peak_vram_mb:.2f}"])
            except torch.cuda.OutOfMemoryError:
                print(f"  [{mode_name}] OOM during measurement!")
                clear_surgery_cache(model)
                csv_writer.writerow([seq_len, mode_name, "OOM", "OOM"])

def benchmark_perplexity(model, tokenizer, dataset_name="pg19", max_tokens=100000, stride=1024):
    print("\n" + "="*50)
    print(f" LONG-CONTEXT PERPLEXITY BENCHMARK ({dataset_name})")
    print("="*50)
    
    # Load dataset
    if dataset_name == "pg19":
        # Note: deepmind/pg19 might be slow to download; fallback to wikitext if needed
        try:
            dataset = load_dataset("deepmind/pg19", split="validation", streaming=True, trust_remote_code=True)
            text = next(iter(dataset))['text']
        except Exception as e:
            print(f"Failed to load PG19 ({e}), falling back to wikitext-103...")
            dataset = load_dataset("Salesforce/wikitext", "wikitext-103-raw-v1", split="test")
            text = "\n\n".join(dataset["text"])
    else:
        dataset = load_dataset("Salesforce/wikitext", "wikitext-103-raw-v1", split="test")
        text = "\n\n".join(dataset["text"])
        
    print("Tokenizing long document...")
    encodings = tokenizer(text, return_tensors="pt")
    
    seq_len = encodings.input_ids.size(1)
    print(f"Total document tokens: {seq_len}")
    
    # Cap at max_tokens
    if seq_len > max_tokens:
        input_ids = encodings.input_ids[:, :max_tokens]
        seq_len = max_tokens
    else:
        input_ids = encodings.input_ids
        
    input_ids = input_ids.to(model.device)
    
    # Always evaluate perplexity using the sparse Triton kernel to prove it works
    model.config.use_triton_sparse_attention = True
    
    nlls = []
    prev_end_loc = 0
    
    # Use sliding window evaluate
    # Max length set to 8192 to avoid 40GB A100 OOM on the massive 128k vocab logits tensor
    max_length = 8192
    
    # Let's chunk the evaluation by context size since feeding 100k tokens in one pass might OOM
    # depending on VRAM, even with O(N) memory.
    
    print(f"Evaluating perplexity on {seq_len} tokens in sliding windows of {stride}...")
    for begin_loc in range(0, seq_len, stride):
        clear_surgery_cache(model)
        end_loc = min(begin_loc + max_length, seq_len)
        trg_len = end_loc - prev_end_loc  # may be different from stride on last loop
        
        input_chunk = input_ids[:, begin_loc:end_loc]
        target_ids = input_chunk.clone()
        target_ids[:, :-trg_len] = -100
        
        with torch.no_grad():
            outputs = model(input_chunk, labels=target_ids, use_cache=False)
            # loss is calculated using CrossEntropyLoss which averages over valid labels
            # NLL is loss * trg_len
            neg_log_likelihood = outputs.loss
            
        nlls.append(neg_log_likelihood)
        prev_end_loc = end_loc
        if end_loc == seq_len:
            break
            
    ppl = torch.exp(torch.stack(nlls).mean())
    print(f"Final Sparse Perplexity: {ppl.item():.4f}")
    return ppl.item()

def main():
    parser = argparse.ArgumentParser(description="Benchmark V3 Architecture")
    parser.add_argument("--model", type=str, default="meta-llama/Meta-Llama-3.1-8B", help="HF model name or path")
    parser.add_argument("--dataset", type=str, default="pg19", help="Dataset for perplexity (pg19 or wikitext)")
    parser.add_argument("--output", type=str, default="benchmark_results.csv", help="CSV output file")
    args = parser.parse_args()
    
    print("Loading tokenizer and model...")
    tokenizer = AutoTokenizer.from_pretrained(args.model)
    model = AutoModelForCausalLM.from_pretrained(
        args.model,
        torch_dtype=torch.float16,
        device_map="auto"
    )
    
    # Apply Llama Surgery
    import sys, os
    sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
    from src.ultrametric_v3.llama_patcher import inject_surgery
    
    print("Injecting V3 Surgical Topology Router...")
    model = inject_surgery(model)
    
    if os.path.isdir(args.model):
        print(f"Local model detected at {args.model}. Reloading state dict to attach router weights...")
        from accelerate import load_checkpoint_and_dispatch
        # load_checkpoint_and_dispatch automatically handles sharded and unsharded safetensors/bin
        model = load_checkpoint_and_dispatch(
            model, 
            checkpoint=args.model, 
            device_map="auto",
            dtype=torch.float16
        )
        
    model.eval()
    
    seq_lengths = [4096, 8192, 16384, 32768, 65536, 128000]
    
    with open(args.output, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["Sequence Length", "Mode", "Execution Time (ms)", "Peak VRAM (MB)"])
        
        benchmark_hardware(model, tokenizer, seq_lengths, writer)
        
    print(f"Hardware results saved to {args.output}")
    
    # Run Perplexity
    # Evaluates 100k tokens in 8k independent context chunks
    benchmark_perplexity(model, tokenizer, dataset_name=args.dataset, max_tokens=100000, stride=8192)

if __name__ == "__main__":
    main()
