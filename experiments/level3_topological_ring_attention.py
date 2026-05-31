import sys
import torch
import torch.nn as nn
import random
import math
from transformers import AutoConfig, AutoModelForCausalLM, AutoTokenizer
from llama_surgery.llama_patcher import inject_surgery

"""
Level 3 Experiment: Topological Ring Attention (Block-Sparse Routing)

Objective:
Demonstrate that the discovered ultrametric topology can radically reduce
the communication bandwidth of distributed Long-Context attention (e.g., Ring Attention).
In a standard Ring Attention, every GPU must send its Key-Value blocks to every
other GPU (dense O(N^2) communication).
In Topological Ring Attention, GPUs only request KV blocks if the router
determines they share a branch on the Bruhat-Tits tree.

Setup:
1. Load TinyLlama with the Dynamic Topology Router.
2. Generate a long synthetic sequence composed of distinct domains.
3. Simulate splitting the sequence into N GPU blocks.
4. Extract the routing distance matrix.
5. Apply a pruning threshold: if the ultrametric distance between Block A
   and Block B is too large, drop the communication edge.
6. Calculate theoretical bandwidth savings compared to dense Ring Attention.
"""

def generate_multi_domain_sequence(tokenizer, seq_len=1024):
    """
    Generates a sequence with distinctly different semantic domains to
    encourage the router to map them to different branches.
    """
    domains = [
        "The quick brown fox jumps over the lazy dog. ", # NL
        "def fibonacci(n): if n <= 1: return n else: return fibonacci(n-1) + fibonacci(n-2) ", # Code
        "Let X be a projective variety over an algebraically closed field k. ", # Math
        "<html><body><h1>Hello World</h1><p>This is a test.</p></body></html> " # HTML
    ]
    
    # Create chunks of 512 tokens from each domain
    tokens = []
    current_domain = 0
    while len(tokens) < seq_len:
        text = domains[current_domain % len(domains)] * 20
        toks = tokenizer(text, return_tensors="pt", add_special_tokens=False).input_ids[0].tolist()
        # append chunk of ~512
        tokens.extend(toks[:512])
        current_domain += 1
        
    tokens = tokens[:seq_len]
    return torch.tensor(tokens).unsqueeze(0)

def simulate_ring_attention():
    # 1. Load Model & Tokenizer
    model_id = "TinyLlama/TinyLlama-1.1B-intermediate-step-1431k-3T"
    tokenizer = AutoTokenizer.from_pretrained(model_id)
    
    print("Loading model in bfloat16...")
    model = AutoModelForCausalLM.from_pretrained(
        model_id,
        torch_dtype=torch.bfloat16,
        device_map="auto"
    )

    # 2. Inject Surgeon
    print("Injecting Dynamic Topology Router...")
    model = inject_surgery(model)

    # 3. Dummy step to shatter the Continuous Logit Homotopy slightly
    # (So it isn't 100% dense Child 0)
    optimizer = torch.optim.Adam(filter(lambda p: p.requires_grad, model.parameters()), lr=1e-2)
    model.train()
    
    print("Shattering initial dense manifold (10 steps)...")
    for _ in range(10):
        # random short inputs to train the router gates just enough to separate
        dummy_input = torch.randint(0, 32000, (1, 128)).to(model.device)
        outputs = model(input_ids=dummy_input, labels=dummy_input)
        lb_loss = sum(layer.self_attn.current_penalty for layer in model.model.layers if hasattr(layer.self_attn, 'current_penalty'))
        loss = outputs.loss + 0.1 * lb_loss
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

    # Clear memory from the training step before the big forward pass
    torch.cuda.empty_cache()

    # 4. Extract Routing for Long Sequence
    model.eval()
    seq_len = 1024
    num_gpus = 8
    block_size = seq_len // num_gpus
    
    print(f"\\nSimulating sequence of {seq_len} tokens distributed across {num_gpus} GPUs.")
    print(f"Block size: {block_size} tokens per GPU.")
    
    input_ids = generate_multi_domain_sequence(tokenizer, seq_len=seq_len).to(model.device)
    
    with torch.no_grad():
        _ = model(input_ids=input_ids)
        
        # Analyze middle layer (where routing is usually most active)
        layer_idx = len(model.model.layers) // 2
        layer = model.model.layers[layer_idx].self_attn
        
        if not hasattr(layer, '_cached_assignments'):
            print("Error: No cached assignments found.")
            return
            
        assignments = layer._cached_assignments
        # compute distances
        if assignments.dim() == 5:
            M = torch.einsum("bhilp,bhjlp->bhijl", assignments, assignments)
            M_mean = M.mean(dim=1)
        else:
            M = torch.einsum("bilp,bjlp->bijl", assignments, assignments)
            M_mean = M
            
        M_flipped = M_mean.flip(dims=[-1])
        P_flipped = M_flipped.cummin(dim=-1)[0]
        sum_P = P_flipped.sum(dim=-1)
        levels = assignments.shape[-2]
        distances = levels - sum_P # shape: (1, seq_len, seq_len)
        
        dist_matrix = distances[0].float() # (seq_len, seq_len)

    # 5. Simulate Block-to-Block Communication Pruning
    print("\\n--- Communication Bandwidth Analysis ---")
    
    dense_edges = num_gpus * num_gpus
    active_edges = 0
    
    # We define a topological distance threshold.
    # If the average distance between block I and block J is > threshold, we prune it.
    tau = levels * 0.75 # e.g., if max distance is 13, threshold is 9.75
    
    block_distances = torch.zeros((num_gpus, num_gpus))
    
    for i in range(num_gpus):
        for j in range(num_gpus):
            start_i = i * block_size
            end_i = start_i + block_size
            start_j = j * block_size
            end_j = start_j + block_size
            
            # Average distance between tokens in block i and block j
            avg_dist = dist_matrix[start_i:end_i, start_j:end_j].mean().item()
            block_distances[i, j] = avg_dist
            
            if avg_dist <= tau:
                active_edges += 1
                
    savings = (1.0 - (active_edges / dense_edges)) * 100
    
    print(f"Max possible topological distance: {levels}")
    print(f"Pruning Threshold (tau): {tau:.2f}")
    print(f"Dense Ring Attention Communication Edges: {dense_edges} (O(N^2))")
    print(f"Topological Ring Attention Edges: {active_edges}")
    print(f"Network Bandwidth Savings: {savings:.1f}%")
    
    print("\\nBlock-to-Block Distance Matrix:")
    # Print formatted matrix
    header = "      " + "".join([f"GPU{j:<4}" for j in range(num_gpus)])
    print(header)
    for i in range(num_gpus):
        row_str = f"GPU{i}: "
        for j in range(num_gpus):
            val = block_distances[i, j].item()
            if val <= tau:
                row_str += f"\033[92m{val:4.1f}\033[0m " # Green (Communicates)
            else:
                row_str += f"\033[91m{val:4.1f}\033[0m " # Red (Pruned)
        print(row_str)

if __name__ == "__main__":
    simulate_ring_attention()
