import jax
import jax.numpy as jnp
from jax.experimental import pallas as pl
from jax.experimental.pallas import tpu as pltpu
import functools

def _bruhat_tits_kernel(
    routing_vectors,
    req_depth,
    x_ref,
    weight_ref,
    out_ref,
):
    """
    Pallas kernel for nested hierarchical block-sparsity (Bruhat-Tits).
    Dynamically skips memory loads for blocks that don't share phylogenetic ancestor depth.
    """
    i = pl.program_id(0)
    j = pl.program_id(1)

    vec_i = routing_vectors[i]
    vec_j = routing_vectors[j]
    
    depth = req_depth[0]
    tree_depth = routing_vectors.shape[1]
    
    iota = jax.lax.iota(jnp.int32, tree_depth)
    mask = iota < depth
    
    match = jnp.all(jnp.logical_or(~mask, vec_i == vec_j))

    def _do_compute():
        x_val = x_ref[...]
        w_val = weight_ref[...]
        # x_val: (block_size, hidden_dim)
        # w_val: (hidden_dim, out_dim)
        # out_ref: (block_size, out_dim)
        out_ref[...] = jnp.dot(x_val, w_val)

    def _do_zero():
        out_ref[...] = jnp.zeros_like(out_ref[...])

    jax.lax.cond(match, _do_compute, _do_zero)

def lhs_index_map(i, j, routing_vectors, req_depth):
    depth = req_depth[0]
    tree_depth = routing_vectors.shape[1]
    iota = jax.lax.iota(jnp.int32, tree_depth)
    mask = iota < depth
    match = jnp.all(jnp.logical_or(~mask, routing_vectors[i] == routing_vectors[j]))
    
    safe_i = jax.lax.select(match, i, 0)
    return (safe_i, 0)

def rhs_index_map(i, j, routing_vectors, req_depth):
    depth = req_depth[0]
    tree_depth = routing_vectors.shape[1]
    iota = jax.lax.iota(jnp.int32, tree_depth)
    mask = iota < depth
    match = jnp.all(jnp.logical_or(~mask, routing_vectors[i] == routing_vectors[j]))
    
    safe_i = jax.lax.select(match, i, 0)
    safe_j = jax.lax.select(match, j, 0)
    return (safe_i, safe_j, 0, 0)

def out_index_map(i, j, routing_vectors, req_depth):
    # Output mapped unconditionally so we can initialize zeros
    return (i, j, 0, 0)

@functools.partial(jax.jit, static_argnames=['block_size', 'interpret'])
def bruhat_tits_matmul(x, weight, routing_vectors, req_depth, block_size=128, interpret=False):
    """
    x: (num_blocks * block_size, hidden_dim)
    weight: (num_blocks, num_blocks, hidden_dim, out_dim)
    routing_vectors: (num_blocks, tree_depth)
    req_depth: scalar integer specifying phylogenetic ancestor depth required.
    """
    num_blocks = routing_vectors.shape[0]
    hidden_dim = x.shape[1]
    out_dim = weight.shape[3]
    
    if req_depth.shape == ():
        req_depth = req_depth[None]
        
    x_spec = pl.BlockSpec(
        (block_size, hidden_dim),
        lhs_index_map
    )
    
    weight_spec = pl.BlockSpec(
        (None, None, hidden_dim, out_dim),
        rhs_index_map
    )
    
    out_spec = pl.BlockSpec(
        (None, None, block_size, out_dim),
        out_index_map
    )
    
    grid_spec = pltpu.PrefetchScalarGridSpec(
        num_scalar_prefetch=2,
        in_specs=[x_spec, weight_spec],
        out_specs=out_spec,
        grid=(num_blocks, num_blocks),
    )
    
    out_shape = jax.ShapeDtypeStruct(
        (num_blocks, num_blocks, block_size, out_dim),
        weight.dtype
    )
    
    return pl.pallas_call(
        _bruhat_tits_kernel,
        out_shape=out_shape,
        grid_spec=grid_spec,
        compiler_params=pltpu.CompilerParams(
            dimension_semantics=("parallel", "parallel")
        ),
        interpret=interpret,
    )(routing_vectors, req_depth, x, weight)
