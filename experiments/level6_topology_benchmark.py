import torch
import math
from transformers import AutoModelForCausalLM, AutoTokenizer, TrainingArguments
from datasets import Dataset
from llama_surgery import inject_surgery
from llama_surgery.surgery_trainer import SurgeryTrainer, TauAnnealingCallback

def compute_perplexity(model, tokenizer, text, device="cuda"):
    model.eval()
    model.to(device)
    
    # Tokenize and format
    inputs = tokenizer(text, return_tensors="pt", truncation=True, max_length=2048)
    input_ids = inputs["input_ids"].to(device)
    
    with torch.no_grad():
        outputs = model(input_ids, labels=input_ids)
        # Loss is the negative log likelihood
        nll = outputs.loss.item()
        
    return math.exp(nll)

def train_router_briefly(model, tokenizer, train_text):
    """Wake up the router by training it for a few steps to break the deterministic collapse."""
    # Freeze all parameters EXCEPT the router
    for name, param in model.named_parameters():
        if "router" not in name:
            param.requires_grad = False
        else:
            param.requires_grad = True
            
    # Create a dummy dataset (this won't hit the HF hub bug because it's purely in-memory)
    encodings = tokenizer([train_text] * 32, truncation=True, padding=True, max_length=128)
    dataset = Dataset.from_dict({
        'input_ids': encodings['input_ids'],
        'attention_mask': encodings['attention_mask'],
        'labels': encodings['input_ids'] 
    })
    
    training_args = TrainingArguments(
        output_dir="./tmp_surgery_results",
        max_steps=20,  # Just enough steps to pull the logits apart and apply load balancing
        per_device_train_batch_size=4,
        learning_rate=5e-3,
        logging_steps=10,
        report_to="none"
    )
    
    trainer = SurgeryTrainer(
        model=model,
        args=training_args,
        train_dataset=dataset,
        surgery_lambda_max=0.05
    )
    # Anneal the temperature to harden the routing decisions dynamically
    trainer.add_callback(TauAnnealingCallback(initial_tau=1.0, min_tau=0.1, decay_steps=20))
    
    print("  Waking up the router (training for 20 steps)...")
    trainer.train()

def main():
    model_id = "TinyLlama/TinyLlama-1.1B-Intermediate-Step-1431k-3T"
    tokenizer = AutoTokenizer.from_pretrained(model_id)
    tokenizer.pad_token = tokenizer.eos_token
    
    train_text = "The geometry of language is not a linear sequence of events, but a complex, multifaceted web."
    test_text = (
        "The geometry of language is not a linear sequence of events, but a complex, "
        "multifaceted web of relationships. When we speak or write, we traverse a "
        "topological space where concepts are linked not just by their adjacency in time, "
        "but by their semantic and syntactic depth. A rigid binary tree forces every decision "
        "into a left-or-right dichotomy, creating artificial boundaries between related ideas. "
        "However, by adopting a weak n-groupoid structure using odd primes, we allow the "
        "topological space to fold and connect in ways that more accurately reflect human cognition. "
        "This is the essence of p-adic routing in neural attention: breaking the binary constraint "
        "to unlock higher-order semantic manifolds. "
    ) * 50  # Repeat to generate a sufficiently long context for evaluation
    
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Using device: {device}")
    
    # Topologies to test
    topologies = [None, 2, 3, 5, 7]
    results = {}
    
    for p in topologies:
        print("\n" + "="*50)
        if p is None:
            name = "Baseline Dense (No Surgery)"
            print(f"Loading {name}...")
        else:
            name = f"Weak n-groupoid (p={p})"
            print(f"Loading {name}...")
            
        model = AutoModelForCausalLM.from_pretrained(
            model_id,
            torch_dtype=torch.float16 if device == "cuda" else torch.float32
        )
        
        if p is not None:
            model.config.surgical_p = p
            model = inject_surgery(model)
            # Wake up the router!
            train_router_briefly(model, tokenizer, train_text)
            
        ppl = compute_perplexity(model, tokenizer, test_text, device)
        results[name] = ppl
        print(f"Result for {name}: Perplexity = {ppl:.2f}")
        
        # Free memory
        del model
        torch.cuda.empty_cache()
        
    print("\n" + "="*50)
    print("FINAL TOPOLOGICAL PERPLEXITY BENCHMARKS (POST-WAKEUP)")
    print("="*50)
    for name, ppl in results.items():
        print(f"{name.ljust(30)} | {ppl:.2f}")

if __name__ == "__main__":
    main()
