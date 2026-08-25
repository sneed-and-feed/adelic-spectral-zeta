#!/usr/bin/env python3
"""
ZK-ML Attention Runtime Prover & Cryptographic Certificate Generator.

This tool captures runtime routing decisions and depth gates from `llama_surgery`
(DynamicTopologyRouter, SurgicalLlamaAttention, kernel), translates block indices
into base-p ultrametric tree digits, constructs Rank-1 Constraint Systems (R1CS),
generates complete algebraic witnesses, verifies constraint satisfaction, and produces
tamper-evident cryptographic certificates with SHA-256 commitments and non-interference audits.
"""

from __future__ import annotations

import argparse
import dataclasses
from dataclasses import asdict, dataclass, field
import datetime
import hashlib
import json
import math
from pathlib import Path
import sys
import time
from typing import Any, Dict, List, Optional, Sequence, Tuple, Union

import torch
import torch.nn as nn

# Add project root and src directory to sys.path
_PROJ_ROOT = Path(__file__).resolve().parent.parent
_SRC_DIR = _PROJ_ROOT / "src"
if str(_SRC_DIR) not in sys.path:
    sys.path.insert(0, str(_SRC_DIR))
if str(_PROJ_ROOT) not in sys.path:
    sys.path.insert(0, str(_PROJ_ROOT))

from adelic_spectral_zeta.circuits.padic_r1cs import (
    BN254_R,
    LinearCombination,
    PAdicLCAConstraintBuilder,
    R1CSSystem,
    VariableKind,
    mod_inv,
)
from llama_surgery.kernel import routing_to_block_indices
from llama_surgery.surgery import SurgicalLlamaAttention
from llama_surgery.topology import DynamicTopologyRouter, get_dynamic_ultrametric_mask


# ============================================================================
# Cryptographic Certificate Data Structure
# ============================================================================

@dataclass
class ZKAttentionCertificate:
    """Cryptographic certificate attesting to verified ZK-ML attention routing."""

    certificate_id: str
    timestamp: str
    circuit_metadata: Dict[str, Any]
    routing_metadata: Dict[str, Any]
    cryptographic_commitments: Dict[str, str]
    sparsity_metrics: Dict[str, Any]
    non_interference_audit: Dict[str, Any]
    verification: Dict[str, Any]

    def to_dict(self) -> Dict[str, Any]:
        """Convert certificate to a JSON-serializable dictionary."""
        return asdict(self)

    def to_json(self, indent: int = 2) -> str:
        """Serialize certificate to formatted JSON string."""
        return json.dumps(self.to_dict(), indent=indent)

    def pretty_print(self) -> None:
        """Display a structured summary of the cryptographic certificate."""
        print("=" * 78)
        print("              ZK-ML ATTENTION ROUTING PROOF CERTIFICATE               ")
        print("=" * 78)
        print(f"Certificate ID : {self.certificate_id}")
        print(f"Timestamp      : {self.timestamp}")
        print(f"Status         : {'[VERIFIED - VALID]' if self.verification['valid'] else '[REJECTED - INVALID]'}")
        print("-" * 78)
        print("1. CIRCUIT METADATA:")
        print(f"   - Constraint System : {self.circuit_metadata.get('system')}")
        print(f"   - Field Curve       : {self.circuit_metadata.get('field')} (modulus: {self.circuit_metadata.get('field_modulus')[:18]}...)")
        print(f"   - Total Constraints : {self.circuit_metadata.get('num_constraints')}")
        print(f"   - Total Variables   : {self.circuit_metadata.get('num_variables')}")
        print("-" * 78)
        print("2. ROUTING TOPOLOGY:")
        print(f"   - Sequence Length   : {self.routing_metadata.get('seq_len')} tokens")
        print(f"   - Block Size        : {self.routing_metadata.get('block_size')} tokens ({self.routing_metadata.get('num_blocks')} blocks)")
        print(f"   - Tree Arity (p)    : {self.routing_metadata.get('p')}")
        print(f"   - Tree Depth (D)    : {self.routing_metadata.get('depth')}")
        print(f"   - Required Depth (r): {self.routing_metadata.get('req_depth')}")
        print("-" * 78)
        print("3. CRYPTOGRAPHIC COMMITMENTS (SHA-256):")
        print(f"   - Routing Mask Hash : {self.cryptographic_commitments.get('routing_matrix_sha256')}")
        print(f"   - Block Digits Hash : {self.cryptographic_commitments.get('block_indices_sha256')}")
        print(f"   - Witness Digest    : {self.cryptographic_commitments.get('witness_digest_sha256')}")
        print(f"   - Root Commitment   : {self.cryptographic_commitments.get('root_hash')}")
        print("-" * 78)
        print("4. SPARSITY & PERFORMANCE:")
        print(f"   - Total Block Pairs : {self.sparsity_metrics.get('total_block_pairs')}")
        print(f"   - Active Blocks     : {self.sparsity_metrics.get('active_block_pairs')} (attended)")
        print(f"   - Skipped Blocks    : {self.sparsity_metrics.get('skipped_block_pairs')} (bypassed)")
        print(f"   - Sparsity Fraction : {self.sparsity_metrics.get('sparsity_percentage'):.2f}% compute skipped")
        print(f"   - Prover Time       : {self.verification.get('proof_time_ms'):.3f} ms")
        print(f"   - Verification Time : {self.verification.get('verification_time_ms'):.3f} ms")
        print("-" * 78)
        print("5. NON-INTERFERENCE SAFETY AUDIT:")
        print(f"   - Policy Status     : {self.non_interference_audit.get('status')}")
        print(f"   - Forbidden Pairs   : {len(self.non_interference_audit.get('forbidden_pairs', []))} pairs checked")
        print(f"   - Violations Count  : {len(self.non_interference_audit.get('violations', []))}")
        if self.non_interference_audit.get("violations"):
            print(f"   - VIOLATING PAIRS   : {self.non_interference_audit.get('violations')}")
        print("=" * 78)


# ============================================================================
# Cryptographic Digest & Hashing Utilities
# ============================================================================

def compute_sha256_hex(data: Union[str, bytes]) -> str:
    """Compute SHA-256 hex digest of string or bytes."""
    if isinstance(data, str):
        data = data.encode("utf-8")
    return hashlib.sha256(data).hexdigest()


def compute_routing_matrix_hash(routing_matrix: Sequence[Sequence[int]]) -> str:
    """Compute deterministic SHA-256 hash of a 2D integer routing mask."""
    serialized = ",".join("".join(str(int(cell)) for cell in row) for row in routing_matrix)
    return compute_sha256_hex(serialized)


def compute_block_indices_hash(block_indices: Sequence[int]) -> str:
    """Compute deterministic SHA-256 hash of block indices list."""
    serialized = ",".join(str(idx) for idx in block_indices)
    return compute_sha256_hex(serialized)


def compute_witness_digest(
    witness: Union[Sequence[int], Dict[int, int]],
    num_variables: Optional[int] = None,
    field_modulus: int = BN254_R,
) -> str:
    """Compute deterministic SHA-256 commitment of the complete R1CS witness."""
    if isinstance(witness, dict):
        max_idx = max(witness.keys()) if witness else 0
        limit = num_variables if num_variables is not None else max_idx + 1
        items = [f"{i}:{witness.get(i, 0) % field_modulus}" for i in range(limit)]
    else:
        items = [f"{i}:{val % field_modulus}" for i, val in enumerate(witness)]
    serialized = ";".join(items)
    return compute_sha256_hex(serialized)


def compute_root_hash(routing_hash: str, block_hash: str, witness_hash: str) -> str:
    """Compute chained root commitment over routing matrix, block indices, and witness."""
    payload = f"root:{routing_hash}:{block_hash}:{witness_hash}"
    return compute_sha256_hex(payload)


# ============================================================================
# Runtime Routing Extraction & Translation
# ============================================================================

def extract_block_indices_from_assignments(
    assignments: torch.Tensor,
    seq_len: int,
    block_size: int,
    depth: int,
    p: int = 2,
    head_idx: int = 0,
    batch_idx: int = 0,
) -> Tuple[List[int], List[List[int]]]:
    """
    Extract discrete block indices and base-p tree digits from PyTorch routing assignments.

    Args:
        assignments: Tensor of shape (batch, num_heads, seq_len, levels, p) or (batch, seq_len, levels, p).
        seq_len: Sequence length.
        block_size: Number of tokens per block.
        depth: Required tree depth D.
        p: Prime tree arity.
        head_idx: Head index to inspect.
        batch_idx: Batch index to inspect.

    Returns:
        Tuple (block_indices, block_digits):
            - block_indices: List of integer block IDs in [0, p^depth - 1].
            - block_digits: List of D base-p digits for each block [d_0, ..., d_{D-1}].
    """
    if assignments.dim() == 4:
        # Shape: (batch, seq_len, levels, p) -> unsqueeze head dim
        assignments = assignments.unsqueeze(1)

    # Use kernel helper to extract representative router indices for each block
    # Shape of router_indices: (batch, num_heads, num_blocks, levels)
    router_indices = routing_to_block_indices(assignments, seq_len=seq_len, block_size=block_size)
    
    # Extract branch IDs for specified batch and head: shape (num_blocks, levels)
    block_branches = router_indices[batch_idx, head_idx].cpu().tolist()
    num_blocks = len(block_branches)

    block_indices: List[int] = []
    block_digits: List[List[int]] = []

    for b_idx in range(num_blocks):
        raw_digits = block_branches[b_idx]
        # Align digits with target depth D
        if len(raw_digits) < depth:
            padded_digits = raw_digits + [0] * (depth - len(raw_digits))
        else:
            padded_digits = raw_digits[:depth]

        # Enforce modulo p on digits
        cleaned_digits = [int(d) % p for d in padded_digits]
        block_digits.append(cleaned_digits)

        # Reconstruct integer block value in MSB-first convention: sum_{k=0}^{D-1} d_k * p^{D-1-k}
        int_val = 0
        for k, digit in enumerate(cleaned_digits):
            int_val += digit * (p ** (depth - 1 - k))
        block_indices.append(int_val)

    return block_indices, block_digits


def simulate_runtime_routing(
    seq_len: int,
    embed_dim: int = 128,
    num_heads: int = 1,
    p: int = 2,
    seed: int = 42,
) -> Tuple[DynamicTopologyRouter, torch.Tensor, torch.Tensor]:
    """
    Instantiate an honest DynamicTopologyRouter and generate a deterministic execution trace.

    Returns:
        Tuple (router, input_embeddings, routing_assignments).
    """
    torch.manual_seed(seed)
    router = DynamicTopologyRouter(
        embed_dim=embed_dim,
        seq_len=seq_len,
        num_heads=num_heads,
        p=p,
        hard=True,
    )
    router.eval()

    # Generate synthetic token embeddings
    x = torch.randn(1, seq_len, embed_dim)
    with torch.no_grad():
        assignments, _ = router(x)

    return router, x, assignments


# ============================================================================
# Core ZK Attention Prover Pipeline
# ============================================================================

class ZKAttentionProver:
    """
    End-to-End ZK-ML Runtime Prover and Verification Engine.

    Compiles dynamic attention routing decisions into R1CS circuits, generates
    algebraic witness vectors over BN254, audits non-interference invariants,
    and produces cryptographic proof certificates.
    """

    def __init__(
        self,
        field_modulus: int = BN254_R,
    ) -> None:
        self.field_modulus = field_modulus

    def prove_and_verify(
        self,
        block_indices: List[int],
        p: int = 2,
        depth: int = 4,
        req_depth: int = 2,
        forbidden_pairs: Optional[List[Tuple[int, int]]] = None,
        seq_len: Optional[int] = None,
        block_size: Optional[int] = None,
    ) -> ZKAttentionCertificate:
        """
        Execute full proof generation, R1CS verification, and certificate synthesis.

        Args:
            block_indices: List of integer IDs for each attention block.
            p: Tree branching arity.
            depth: Full tree depth D.
            req_depth: Common ancestor depth required for attention.
            forbidden_pairs: Optional list of forbidden block index pairs (i, j).
            seq_len: Total sequence length in tokens (for metadata).
            block_size: Block size in tokens (for metadata).

        Returns:
            ZKAttentionCertificate containing cryptographic commitments and verification results.
        """
        t_start = time.perf_counter()
        num_blocks = len(block_indices)
        effective_seq_len = seq_len if seq_len is not None else num_blocks * (block_size or 64)
        effective_block_size = block_size if block_size is not None else (effective_seq_len // max(num_blocks, 1))

        # 1. Construct R1CS System
        builder = PAdicLCAConstraintBuilder(field_modulus=self.field_modulus)
        system, block_vars, routing_mask_vars = builder.build_block_routing_system(
            num_blocks=num_blocks,
            p=p,
            depth=depth,
            req_depth=req_depth,
            forbidden_pairs=forbidden_pairs,
        )

        # 2. Generate Complete Algebraic Witness
        t_proof_start = time.perf_counter()
        witness = builder.generate_block_routing_witness(
            block_indices=block_indices,
            p=p,
            depth=depth,
            req_depth=req_depth,
            msb_first=True,
        )
        t_proof_end = time.perf_counter()
        proof_time_ms = (t_proof_end - t_proof_start) * 1000.0

        # 3. Verify Witness Against Constraints
        t_verify_start = time.perf_counter()
        is_valid, fail_idx, fail_err = system.verify_witness(witness)
        t_verify_end = time.perf_counter()
        verify_time_ms = (t_verify_end - t_verify_start) * 1000.0

        # 4. Extract Concrete Routing Matrix M from Witness
        routing_matrix: List[List[int]] = [[0] * num_blocks for _ in range(num_blocks)]
        active_count = 0
        total_pairs = num_blocks * num_blocks

        for i in range(num_blocks):
            for j in range(num_blocks):
                m_var = routing_mask_vars.get((i, j))
                if m_var is not None:
                    val = witness.get(m_var, 0) % self.field_modulus
                    routing_matrix[i][j] = int(val)
                    if val == 1:
                        active_count += 1
                elif i == j:
                    routing_matrix[i][j] = 1
                    active_count += 1

        skipped_count = total_pairs - active_count
        sparsity_pct = (skipped_count / total_pairs * 100.0) if total_pairs > 0 else 0.0

        # 5. Non-Interference Safety Audit
        violations: List[List[int]] = []
        policy_enforced = bool(forbidden_pairs)

        if forbidden_pairs:
            for u_idx, v_idx in forbidden_pairs:
                if 0 <= u_idx < num_blocks and 0 <= v_idx < num_blocks:
                    val = routing_matrix[u_idx][v_idx]
                    if val != 0:
                        violations.append([u_idx, v_idx])

        audit_status = "PASSED"
        if violations:
            audit_status = "VIOLATION_DETECTED"
        elif not is_valid and fail_idx is not None:
            # If the circuit failed due to a non-interference constraint
            failing_c = system.constraints[fail_idx]
            if "Safety guard" in failing_c.comment or "Non-interference" in failing_c.comment:
                audit_status = "VIOLATION_DETECTED"

        # 6. Compute Cryptographic Commitments
        routing_hash = compute_routing_matrix_hash(routing_matrix)
        block_hash = compute_block_indices_hash(block_indices)
        witness_digest = compute_witness_digest(witness, system.num_variables, self.field_modulus)
        root_hash = compute_root_hash(routing_hash, block_hash, witness_digest)
        cert_id = compute_sha256_hex(f"{root_hash}:{time.time_ns()}")[:16]

        certificate = ZKAttentionCertificate(
            certificate_id=f"ZK-ATTN-{cert_id.upper()}",
            timestamp=datetime.datetime.now(datetime.timezone.utc).isoformat(),
            circuit_metadata={
                "system": "padic_r1cs_lca",
                "field": "BN254",
                "field_modulus": str(self.field_modulus),
                "num_constraints": system.num_constraints,
                "num_variables": system.num_variables,
                "num_public_inputs": len(system.public_inputs),
                "num_private_inputs": len(system.private_inputs),
            },
            routing_metadata={
                "seq_len": effective_seq_len,
                "block_size": effective_block_size,
                "num_blocks": num_blocks,
                "depth": depth,
                "req_depth": req_depth,
                "p": p,
                "num_heads": 1,
            },
            cryptographic_commitments={
                "routing_matrix_sha256": routing_hash,
                "block_indices_sha256": block_hash,
                "witness_digest_sha256": witness_digest,
                "root_hash": root_hash,
            },
            sparsity_metrics={
                "total_block_pairs": total_pairs,
                "active_block_pairs": active_count,
                "skipped_block_pairs": skipped_count,
                "sparsity_percentage": round(sparsity_pct, 4),
                "verified_fraction": 1.0 if is_valid else 0.0,
            },
            non_interference_audit={
                "status": audit_status,
                "policy_enforced": policy_enforced,
                "forbidden_pairs": [list(p) for p in (forbidden_pairs or [])],
                "violations": violations,
            },
            verification={
                "valid": is_valid,
                "failing_constraint": fail_idx,
                "error_message": fail_err,
                "proof_time_ms": round(proof_time_ms, 3),
                "verification_time_ms": round(verify_time_ms, 3),
            },
        )

        return certificate

    def prove_from_router(
        self,
        router: DynamicTopologyRouter,
        x: torch.Tensor,
        block_size: int = 64,
        depth: Optional[int] = None,
        req_depth: int = 2,
        forbidden_pairs: Optional[List[Tuple[int, int]]] = None,
    ) -> ZKAttentionCertificate:
        """
        Intercept runtime routing tensor from DynamicTopologyRouter and generate proof certificate.
        """
        seq_len = x.shape[1]
        p = router.p
        effective_depth = depth if depth is not None else router.levels

        with torch.no_grad():
            assignments, _ = router(x)

        block_indices, _ = extract_block_indices_from_assignments(
            assignments=assignments,
            seq_len=seq_len,
            block_size=block_size,
            depth=effective_depth,
            p=p,
        )

        return self.prove_and_verify(
            block_indices=block_indices,
            p=p,
            depth=effective_depth,
            req_depth=req_depth,
            forbidden_pairs=forbidden_pairs,
            seq_len=seq_len,
            block_size=block_size,
        )

    def prove_from_attention(
        self,
        attn_layer: SurgicalLlamaAttention,
        hidden_states: torch.Tensor,
        block_size: int = 64,
        depth: Optional[int] = None,
        req_depth: int = 2,
        forbidden_pairs: Optional[List[Tuple[int, int]]] = None,
    ) -> ZKAttentionCertificate:
        """
        Intercept runtime routing tensor from SurgicalLlamaAttention and generate proof certificate.
        """
        seq_len = hidden_states.shape[1]
        p = attn_layer.p
        effective_depth = depth if depth is not None else attn_layer.router.levels

        with torch.no_grad():
            curr_assignments, _ = attn_layer.router(hidden_states)

        block_indices, _ = extract_block_indices_from_assignments(
            assignments=curr_assignments,
            seq_len=seq_len,
            block_size=block_size,
            depth=effective_depth,
            p=p,
        )

        return self.prove_and_verify(
            block_indices=block_indices,
            p=p,
            depth=effective_depth,
            req_depth=req_depth,
            forbidden_pairs=forbidden_pairs,
            seq_len=seq_len,
            block_size=block_size,
        )


# ============================================================================
# CLI Command Line Interface
# ============================================================================

def build_cli_parser() -> argparse.ArgumentParser:
    """Construct CLI argument parser for ZK attention prover."""
    parser = argparse.ArgumentParser(
        description="ZK-ML Runtime Attention Prover & Cryptographic Verifier (Alt-bn128 / BN254)",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--seq_len", type=int, default=512, help="Sequence length in tokens (e.g. 512, 2048)")
    parser.add_argument("--block_size", type=int, default=64, help="Block size in tokens")
    parser.add_argument("--depth", type=int, default=4, help="Tree depth D (number of base-p digits)")
    parser.add_argument("--req_depth", type=int, default=2, help="Required matching prefix depth r")
    parser.add_argument("--p", type=int, default=2, help="Tree arity base p (e.g. 2 for binary tree)")
    parser.add_argument("--embed_dim", type=int, default=128, help="Token embedding dimension")
    parser.add_argument("--output", type=str, default=None, help="Optional output JSON path for saving certificate")
    parser.add_argument("--audit-safety", action="store_true", help="Enable non-interference safety audit")
    parser.add_argument("--forbidden-pairs", type=str, default=None, help="JSON list of forbidden block index pairs, e.g. '[[0, 2], [1, 3]]'")
    parser.add_argument("--tamper-mask", action="store_true", help="Deliberately tamper with routing mask to verify soundness failure")
    parser.add_argument("--tamper-depth", action="store_true", help="Deliberately alter required depth without updating witness")
    parser.add_argument("--quiet", action="store_true", help="Suppress certificate pretty printing")
    return parser


def main(args_list: Optional[Sequence[str]] = None) -> int:
    """CLI entry point for ZK attention prover."""
    parser = build_cli_parser()
    args = parser.parse_args(args_list)

    # 1. Run DynamicTopologyRouter to capture honest runtime routing assignments
    num_blocks = math.ceil(args.seq_len / args.block_size)
    router, x, assignments = simulate_runtime_routing(
        seq_len=args.seq_len,
        embed_dim=args.embed_dim,
        num_heads=1,
        p=args.p,
    )

    block_indices, block_digits = extract_block_indices_from_assignments(
        assignments=assignments,
        seq_len=args.seq_len,
        block_size=args.block_size,
        depth=args.depth,
        p=args.p,
    )

    # Parse forbidden pairs
    forbidden_pairs: Optional[List[Tuple[int, int]]] = None
    if args.forbidden_pairs:
        try:
            parsed = json.loads(args.forbidden_pairs)
            forbidden_pairs = [tuple(pair) for pair in parsed]
        except Exception as e:
            print(f"Error parsing --forbidden-pairs: {e}", file=sys.stderr)
            return 1
    elif args.audit_safety:
        # Default safety policy: check isolation between opposite branches at root
        # Block with MSB 0 vs Block with MSB 1
        b_left = None
        b_right = None
        for i, digits in enumerate(block_digits):
            if digits[0] == 0 and b_left is None:
                b_left = i
            elif digits[0] == 1 and b_right is None:
                b_right = i
        if b_left is not None and b_right is not None:
            forbidden_pairs = [(b_left, b_right)]

    prover = ZKAttentionProver()

    if args.tamper_mask:
        # Tamper demonstration: generate circuit, then alter witness mask
        builder = PAdicLCAConstraintBuilder()
        system, b_vars, m_vars = builder.build_block_routing_system(
            num_blocks=num_blocks,
            p=args.p,
            depth=args.depth,
            req_depth=args.req_depth,
            forbidden_pairs=forbidden_pairs,
        )
        witness = builder.generate_block_routing_witness(
            block_indices=block_indices,
            p=args.p,
            depth=args.depth,
            req_depth=args.req_depth,
        )
        # Flip first off-diagonal mask
        target_pair = (0, 1) if num_blocks > 1 else (0, 0)
        target_wire = m_vars[target_pair]
        witness[target_wire] = 1 - witness.get(target_wire, 0)
        is_valid, fail_idx, fail_err = system.verify_witness(witness)
        print(f"[TAMPER TEST] Modified mask for pair {target_pair}. Verification result: Valid={is_valid}, Failed Constraint #{fail_idx}: {fail_err}")
        return 0 if not is_valid else 1

    if args.tamper_depth:
        # Tamper demonstration: verify with different required depth
        builder = PAdicLCAConstraintBuilder()
        system, _, _ = builder.build_block_routing_system(
            num_blocks=num_blocks,
            p=args.p,
            depth=args.depth,
            req_depth=args.req_depth + 1,  # Altered depth
        )
        witness = builder.generate_block_routing_witness(
            block_indices=block_indices,
            p=args.p,
            depth=args.depth,
            req_depth=args.req_depth,  # Old witness
        )
        is_valid, fail_idx, fail_err = system.verify_witness(witness)
        print(f"[TAMPER TEST] Altered circuit depth requirement to {args.req_depth + 1}. Verification result: Valid={is_valid}, Failed Constraint #{fail_idx}: {fail_err}")
        return 0 if not is_valid else 1

    # Normal honest proof generation & verification
    certificate = prover.prove_and_verify(
        block_indices=block_indices,
        p=args.p,
        depth=args.depth,
        req_depth=args.req_depth,
        forbidden_pairs=forbidden_pairs,
        seq_len=args.seq_len,
        block_size=args.block_size,
    )

    if not args.quiet:
        certificate.pretty_print()

    if args.output:
        out_path = Path(args.output)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(certificate.to_json(), encoding="utf-8")
        print(f"Certificate saved to {out_path.resolve()}")

    return 0 if certificate.verification["valid"] else 1


if __name__ == "__main__":
    sys.exit(main())
