import os
import sys
import torch
import time
from pathlib import Path

# Add experiments dir to sys.path so the dummy 'triton' package can be imported
exp_dir = Path(__file__).parent
sys.path.insert(0, str(exp_dir))

# Add src to path
src_dir = exp_dir.parent / "src"
sys.path.append(str(src_dir))

from ultrametric.kernel_eaas import run_eaas_attention

def main():
    print("Testing EAAS Kernel Wrapper on CPU...")
    num_nodes = 4
    num_heads = 2
    head_dim = 16
    
    # Mock data
    torch.manual_seed(42)
    q = torch.randn(num_nodes, num_heads, head_dim)
    k = torch.randn(num_nodes, num_heads, head_dim)
    v = torch.randn(num_nodes, num_heads, head_dim)
    r = torch.randn(num_nodes, head_dim)
    cg = torch.randn(head_dim)
    
    # CSR Graph: simple cycle connections
    row_ptr = torch.tensor([0, 2, 4, 6, 8], dtype=torch.int32)
    col_idx = torch.tensor([0, 1, 1, 2, 2, 3, 3, 0], dtype=torch.int32)
    
    try:
        out = run_eaas_attention(q, k, v, r, cg, row_ptr, col_idx)
        print("Kernel wrapper executed successfully!")
        print("Output shape:", out.shape)
        
        # Verify output has no NaNs
        assert not torch.isnan(out).any(), "Output contains NaNs"
        print("Test passed.")
    except Exception as e:
        print(f"Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
