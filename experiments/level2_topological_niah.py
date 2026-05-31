import sys
import torch
import torch.nn as nn
import random
from transformers import AutoConfig, AutoModelForCausalLM, AutoTokenizer
from llama_surgery.llama_patcher import inject_surgery

"""
Level 2 Experiment: Topological Needle-In-A-Haystack (NIAH)

Objective: 
Determine what geometric object emerges inside the Bruhat-Tits tree when the 
model is forced to route for retrieval.

Hypothesis:
To successfully retrieve the needle, the router must assign the query tokens and 
the needle tokens to the same branch of the tree, while potentially isolating 
the irrelevant haystack tokens into a different branch.

Setup:
1. Load TinyLlama with the Dynamic Topology Router.
2. Freeze backbone, train only the router.
3. Construct a synthetic dataset where a specific key-value pair (the needle) 
   is hidden within a sequence of irrelevant filler text (the haystack).
4. Append a query to the end of the context asking for the value.
5. Train with standard Causal LM loss on the answer tokens.
6. Extract the routing assignments to analyze the emergent topology.
"""

def generate_niah_sample(tokenizer, haystack_len=512):
    """
    Generates a synthetic Needle-In-A-Haystack sample.
    """
    filler = "The quick brown fox jumps over the lazy dog. "
    haystack = filler * (haystack_len // 10 + 1)
    
    haystack_tokens = tokenizer(haystack, return_tensors="pt", add_special_tokens=False).input_ids[0][:haystack_len]
    
    needle_text = "The magic password is 'KRAKEN'. "
    needle_tokens = tokenizer(needle_text, return_tensors="pt", add_special_tokens=False).input_ids[0]
    
    query_text = "What is the magic password? The magic password is '"
    query_tokens = tokenizer(query_text, return_tensors="pt", add_special_tokens=False).input_ids[0]
    
    answer_text = "KRAKEN'"
    answer_tokens = tokenizer(answer_text, return_tensors="pt", add_special_tokens=False).input_ids[0]
    
    # insert needle at random depth
    insert_idx = random.randint(0, len(haystack_tokens) - 1)
    
    input_ids = torch.cat([
        haystack_tokens[:insert_idx],
        needle_tokens,
        haystack_tokens[insert_idx:],
        query_tokens,
        answer_tokens
    ], dim=0)
    
    # Keep track of indices for extraction
    needle_start = insert_idx
    needle_end = insert_idx + len(needle_tokens)
    query_start = len(input_ids) - len(answer_tokens) - len(query_tokens)
    query_end = len(input_ids) - len(answer_tokens)
    
    # We want to train on the answer tokens
    labels = torch.full_like(input_ids, -100)
    labels[-len(answer_tokens):] = answer_tokens
    
    return {
        "input_ids": input_ids.unsqueeze(0),
        "labels": labels.unsqueeze(0),
        "needle_span": (needle_start, needle_end),
        "query_span": (query_start, query_end),
        "haystack_span": (0, max(1, insert_idx)) # just picking the first chunk of haystack
    }

def train_router_niah():
    """
    Main training loop for the Topological NIAH experiment.
    """
    # 1. Load Model & Tokenizer
    # For Colab, we load the real model in float16 onto the GPU
    model_id = "TinyLlama/TinyLlama-1.1B-intermediate-step-1431k-3T"
    tokenizer = AutoTokenizer.from_pretrained(model_id)
    
    model = AutoModelForCausalLM.from_pretrained(
        model_id,
        torch_dtype=torch.float16,
        device_map="auto"
    )

    # 2. Inject the Surgeon
    print("Injecting Dynamic Topology Router...")
    model = inject_surgery(model)

    # 3. Freeze Backbone, Unfreeze Router
    for param in model.parameters():
        param.requires_grad = False
    
    for name, param in model.named_parameters():
        if "route" in name:
            param.requires_grad = True

    # 4. Set up Optimizer and Training Loop
    optimizer = torch.optim.Adam(filter(lambda p: p.requires_grad, model.parameters()), lr=1e-3)
    
    num_steps = 200
    for step in range(num_steps):
        model.train()
        sample = generate_niah_sample(tokenizer, haystack_len=1024)
        input_ids = sample["input_ids"]
        labels = sample["labels"]
        
        optimizer.zero_grad()
        outputs = model(input_ids=input_ids, labels=labels)
        loss = outputs.loss
        
        lb_loss = 0.0
        for layer in model.model.layers:
            if hasattr(layer.self_attn, 'current_penalty'):
                lb_loss += layer.self_attn.current_penalty
        
        total_loss = loss + 0.01 * lb_loss
        total_loss.backward()
        optimizer.step()
        
        print(f"Step {step}: Loss = {loss.item():.4f}, LB Loss = {lb_loss.item() if isinstance(lb_loss, torch.Tensor) else lb_loss:.4f}")
    
    # 5. Extract Emerging Topology
    model.eval()
    with torch.no_grad():
        sample = generate_niah_sample(tokenizer, haystack_len=1024)
        input_ids = sample["input_ids"]
        
        # Forward pass to cache assignments
        _ = model(input_ids=input_ids)
        
        # Extract from the last layer for analysis
        last_layer = model.model.layers[-1].self_attn
        if hasattr(last_layer, '_cached_assignments'):
            assignments = last_layer._cached_assignments
            if assignments.dim() == 5:
                M = torch.einsum("bhilp,bhjlp->bhijl", assignments, assignments)
                M_mean = M.mean(dim=1) # (batch, seq_len, seq_len, levels)
            else:
                M = torch.einsum("bilp,bjlp->bijl", assignments, assignments)
                M_mean = M
                
            M_flipped = M_mean.flip(dims=[-1])
            P_flipped = M_flipped.cummin(dim=-1)[0]
            sum_P = P_flipped.sum(dim=-1)
            levels = assignments.shape[-2]
            expected_dist = levels - sum_P # (batch, seq_len, seq_len)
            
            # LCA depth = levels - expected_dist
            lca_depth = sum_P[0] # shape (seq_len, seq_len)
            
            n_start, n_end = sample["needle_span"]
            q_start, q_end = sample["query_span"]
            h_start, h_end = sample["haystack_span"]
            
            # Take one representative token from each
            needle_idx = n_start
            query_idx = q_start
            haystack_idx = h_start
            
            depth_qn = lca_depth[query_idx, needle_idx].item()
            depth_qh = lca_depth[query_idx, haystack_idx].item()
            depth_nh = lca_depth[needle_idx, haystack_idx].item()
            
            print(f"\nEmergent Topology (Last Layer):")
            print(f"Cophenetic Depths (LCA Depth) between key elements:")
            print(f"Query-Needle: {depth_qn:.4f}")
            print(f"Query-Haystack: {depth_qh:.4f}")
            print(f"Needle-Haystack: {depth_nh:.4f}")

            # Also check the Ultrametric Triangle Inequality for these three!
            # d(x, z) <= max(d(x,y), d(y,z))
            # Distances are expected_dist = levels - lca_depth
            dist_qn = expected_dist[0, query_idx, needle_idx].item()
            dist_qh = expected_dist[0, query_idx, haystack_idx].item()
            dist_nh = expected_dist[0, needle_idx, haystack_idx].item()
            
            print(f"\nUltrametric Triangle Inequality Check:")
            print(f"d(Q, H) <= max(d(Q, N), d(N, H)) => {dist_qh:.4f} <= max({dist_qn:.4f}, {dist_nh:.4f})")
            print(f"Satisfied? {'Yes' if dist_qh <= max(dist_qn, dist_nh) else 'No'}")

if __name__ == "__main__":
    train_router_niah()
