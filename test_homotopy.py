import torch
from src.ultrametric.topology import DynamicTopologyRouter, get_dynamic_ultrametric_mask

# 1. Initialize router
embed_dim = 128
seq_len = 16
num_heads = 4
router = DynamicTopologyRouter(embed_dim=embed_dim, seq_len=seq_len, num_heads=num_heads, p=2)

# 2. Dummy input
x = torch.randn(1, seq_len, embed_dim)

# 3. Forward pass
assignments, _ = router(x)

# 4. Generate mask
mask = get_dynamic_ultrametric_mask(assignments, p=2)

# 5. Assert mask is identically 1.0
print(f"Mask shape: {mask.shape}")
print(f"Mask density: {mask.mean().item()}")
if mask.mean().item() == 1.0:
    print("SUCCESS: Continuous Logit Homotopy preserves identically dense mask!")
else:
    print("ERROR: Mask is not identically 1.0.")
