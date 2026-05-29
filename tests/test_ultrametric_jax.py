import jax
import jax.numpy as jnp
from src.ultrametric_jax.topology import DynamicTopologyRouter
from src.ultrametric_jax.layer import UltrametricAttention
from src.ultrametric_jax.model import UltrametricTransformerBlock

def test_dynamic_topology_router():
    key = jax.random.PRNGKey(0)
    batch, seq_len, embed_dim = 2, 16, 64
    levels, p = 3, 2
    
    router = DynamicTopologyRouter(levels=levels, p=p)
    x = jax.random.normal(key, (batch, seq_len, embed_dim))
    
    # Initialize variables
    variables = router.init(key, x)
    
    # Forward pass
    routing_paths = router.apply(variables, x, rngs={'gumbel': key})
    
    # The output should be the exact recursive path down the tree
    assert routing_paths.shape == (batch, seq_len, levels, p)

def test_transformer_block_compilation():
    key = jax.random.PRNGKey(1)
    batch, seq_len, embed_dim = 2, 16, 64
    num_heads = 4
    
    block = UltrametricTransformerBlock(embed_dim=embed_dim, num_heads=num_heads)
    x = jax.random.normal(key, (batch, seq_len, embed_dim))
    
    # JIT compile the initialization and forward pass
    @jax.jit
    def init_and_apply(k, inputs):
        var = block.init(k, inputs, True)
        return block.apply(var, inputs, True, rngs={'gumbel': k})
        
    out, interior = init_and_apply(key, x)
    
    # Check that sequence leaves are returned with correct shapes
    assert out.shape == (batch, seq_len, embed_dim)
    # Check that interior reasoning tokens exist
    assert interior is not None
