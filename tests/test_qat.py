import torch
import torch.nn as nn
from transformers import AutoConfig, AutoModelForCausalLM
from llama_surgery import inject_surgery, inject_qat, QATLinear, SurgicalLlamaAttention

def test_qat_pipeline():
    # 1. Construct a tiny Llama config to avoid heavy internet downloads and memory use
    config = AutoConfig.from_pretrained("TinyLlama/TinyLlama-1.1B-Intermediate-Step-1431k-3T")
    config.num_hidden_layers = 2
    config.hidden_size = 64
    config.intermediate_size = 128
    config.num_attention_heads = 4
    config.num_key_value_heads = 2
    config.head_dim = 16
    config.max_position_embeddings = 256
    
    # 2. Instantiate the model from config (initialized with random weights)
    print("[Test] Initializing tiny model from config...")
    model = AutoModelForCausalLM.from_config(config)
    
    # 3. Inject Topological Surgery
    print("[Test] Injecting surgery layers...")
    model = inject_surgery(model)
    
    # Check that surgery was injected
    assert isinstance(model.model.layers[0].self_attn, SurgicalLlamaAttention)
    
    # 4. Inject QAT (Gemma 4 style: 4-bit, channel-wise, static activations)
    print("[Test] Injecting QAT layers...")
    qat_config = {
        "lm_head": 2, # targeted 2-bit quantization for projection
        "down_proj": {"bits": 2}
    }
    model = inject_qat(
        model, 
        bits=4, 
        static_activations=True, 
        channel_wise=True, 
        qat_config=qat_config
    )
    
    # Verify linear layers were replaced by QATLinear
    first_layer = model.model.layers[0]
    assert isinstance(first_layer.self_attn.q_proj, QATLinear)
    assert isinstance(first_layer.self_attn.k_proj, QATLinear)
    assert isinstance(first_layer.mlp.gate_proj, QATLinear)
    
    # Check targeted bitwidth override
    assert model.lm_head.bits == 2
    assert first_layer.mlp.down_proj.bits == 2
    assert first_layer.mlp.gate_proj.bits == 4
    
    # Verify static activation tracking structures are initialized
    assert hasattr(first_layer.self_attn.q_proj, "running_scale")
    assert first_layer.self_attn.q_proj.static_activations is True
    
    # 5. Run dummy forward and backward pass
    print("[Test] Running forward/backward pass validation...")
    model.train()
    dummy_input = torch.randint(0, 1000, (2, 32))
    
    # Forward pass
    outputs = model(dummy_input, labels=dummy_input)
    loss = outputs.loss
    assert loss is not None
    assert not torch.isnan(loss)
    
    # Backward pass
    loss.backward()
    
    # Verify gradients flow back to the router and projections
    assert first_layer.self_attn.router.backbone.weight.grad is not None
    assert first_layer.self_attn.q_proj.weight.grad is not None
    
    # 6. Verify static activation inference scaling
    print("[Test] Verifying static activations during eval mode...")
    model.eval()
    with torch.no_grad():
        outputs_eval = model(dummy_input)
        assert outputs_eval.logits is not None
        
    print("[Test] QAT Pipeline validation successful!")

if __name__ == "__main__":
    test_qat_pipeline()
