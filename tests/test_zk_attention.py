"""
Comprehensive PyTest Suite for ZK-ML Attention Runtime Prover & Algebraic R1CS Pipeline.

Tests include:
1. Correctness of witness generation from PyTorch routing tensors.
2. Positive verification on honest LLM attention routing traces across topologies.
3. Soundness & Tampering Rejection:
   - Altering attention mask entries M_{i,j}.
   - Altering required matching depth r.
   - Forging digit decompositions or range limbs.
   - Forging inverse witnesses.
   - Unauthorized cross-branch attention violating non-interference policy.
4. Performance & Scalability for N=2048, B=64 in milliseconds.
5. Determinism and sensitivity of cryptographic SHA-256 commitments.
6. CLI tool integration and certificate serialization.
"""

from __future__ import annotations

import json
from pathlib import Path
import sys
import tempfile
import time
from typing import List, Tuple

import pytest
import torch

# Add src and tools to sys.path
_PROJ_ROOT = Path(__file__).resolve().parent.parent
_SRC_DIR = _PROJ_ROOT / "src"
_TOOLS_DIR = _PROJ_ROOT / "tools"
for p in [str(_PROJ_ROOT), str(_SRC_DIR), str(_TOOLS_DIR)]:
    if p not in sys.path:
        sys.path.insert(0, p)

from adelic_spectral_zeta.circuits.padic_r1cs import (
    BN254_R,
    PAdicLCAConstraintBuilder,
    R1CSSystem,
    VariableKind,
)
from llama_surgery.surgery import SurgicalLlamaAttention
from llama_surgery.topology import DynamicTopologyRouter
from zk_attention_prover import (
    ZKAttentionCertificate,
    ZKAttentionProver,
    compute_block_indices_hash,
    compute_root_hash,
    compute_routing_matrix_hash,
    compute_witness_digest,
    extract_block_indices_from_assignments,
    main as cli_main,
    simulate_runtime_routing,
)


# ============================================================================
# 1. Witness Generation Correctness Tests
# ============================================================================

class TestWitnessGenerationCorrectness:
    """Test translation from PyTorch routing assignments to algebraic witness vectors."""

    def test_extract_block_indices_from_assignments(self):
        """Test extraction of block branch digits and integer reconstruction."""
        # Create controlled assignments: 4 blocks, depth 3, p=2
        # Block 0: [0, 0, 0] -> val 0
        # Block 1: [0, 0, 1] -> val 1
        # Block 2: [1, 0, 0] -> val 4
        # Block 3: [1, 1, 1] -> val 7
        seq_len = 256
        block_size = 64
        depth = 3
        p = 2

        # Shape: (batch=1, heads=1, seq_len=256, levels=3, p=2)
        assignments = torch.zeros((1, 1, seq_len, depth, p))
        block_patterns = [
            [0, 0, 0],
            [0, 0, 1],
            [1, 0, 0],
            [1, 1, 1],
        ]
        for b_idx, pat in enumerate(block_patterns):
            start = b_idx * block_size
            end = start + block_size
            for lvl, digit in enumerate(pat):
                assignments[0, 0, start:end, lvl, digit] = 1.0

        block_indices, block_digits = extract_block_indices_from_assignments(
            assignments=assignments,
            seq_len=seq_len,
            block_size=block_size,
            depth=depth,
            p=p,
        )

        assert block_indices == [0, 1, 4, 7]
        assert block_digits == block_patterns

    def test_algebraic_witness_wire_assignments(self):
        """Verify that all R1CS wires (digits, eq indicators, masks) receive mathematically valid values."""
        block_indices = [0, 1, 4, 6]  # [000, 001, 100, 110]
        p = 2
        depth = 3
        req_depth = 2

        builder = PAdicLCAConstraintBuilder()
        system, b_vars, mask_vars = builder.build_block_routing_system(
            num_blocks=len(block_indices),
            p=p,
            depth=depth,
            req_depth=req_depth,
        )
        witness = builder.generate_block_routing_witness(
            block_indices=block_indices,
            p=p,
            depth=depth,
            req_depth=req_depth,
        )

        # 1. ONE wire is 1
        assert witness[0] == 1

        # 2. Block input variables match block_indices
        for i, b_val in enumerate(block_indices):
            assert witness[b_vars[i]] == b_val

        # 3. Digit variables match binary decomposition
        for i, b_val in enumerate(block_indices):
            expected_digits = PAdicLCAConstraintBuilder._extract_digits(b_val, p, depth, msb_first=True)
            for k, exp_d in enumerate(expected_digits):
                d_name = f"b{i}_digit_{k}"
                d_idx = system.var_name_to_idx[d_name]
                assert witness[d_idx] == exp_d

        # 4. Check routing mask variables
        # Pair (0, 1): 000 vs 001 -> prefix '00' (len 2) matches req_depth 2 -> mask = 1
        assert witness[mask_vars[(0, 1)]] == 1
        # Pair (0, 2): 000 vs 100 -> prefix mismatch at depth 0 -> mask = 0
        assert witness[mask_vars[(0, 2)]] == 0
        # Pair (2, 3): 100 vs 110 -> prefix '1' (len 1 < 2) -> mask = 0
        assert witness[mask_vars[(2, 3)]] == 0
        # Self-routing (0, 0): identity -> mask = 1
        assert witness[mask_vars[(0, 0)]] == 1

        # 5. Full circuit verification
        is_valid, fail_idx, err = system.verify_witness(witness)
        assert is_valid, f"Verification failed at constraint #{fail_idx}: {err}"


# ============================================================================
# 2. Positive Verification on Honest LLM Attention Traces
# ============================================================================

class TestHonestLLMRoutingVerification:
    """Test end-to-end positive verification on realistic PyTorch model routing traces."""

    @pytest.mark.parametrize(
        "seq_len,block_size,depth,req_depth,p",
        [
            (128, 32, 3, 2, 2),    # 4 blocks, binary
            (256, 64, 3, 1, 2),    # 4 blocks, binary, req_depth=1
            (512, 64, 4, 2, 2),    # 8 blocks, binary
            (512, 32, 4, 3, 2),    # 16 blocks, binary
            (243, 27, 3, 2, 3),    # 9 blocks, ternary tree (p=3)
            (128, 128, 3, 2, 2),   # 1 block edge case
        ],
    )
    def test_honest_routing_traces_pass(self, seq_len, block_size, depth, req_depth, p):
        """Verify that honest traces from DynamicTopologyRouter always pass R1CS verification."""
        router, x, assignments = simulate_runtime_routing(
            seq_len=seq_len,
            embed_dim=64,
            num_heads=1,
            p=p,
            seed=1337,
        )

        prover = ZKAttentionProver()
        cert = prover.prove_from_router(
            router=router,
            x=x,
            block_size=block_size,
            depth=depth,
            req_depth=req_depth,
        )

        assert cert.verification["valid"] is True
        assert cert.verification["failing_constraint"] is None
        assert cert.verification["error_message"] is None
        assert cert.sparsity_metrics["verified_fraction"] == 1.0
        assert cert.sparsity_metrics["total_block_pairs"] == cert.routing_metadata["num_blocks"] ** 2

    def test_surgical_llama_attention_runtime_hook(self):
        """Verify that routing captured from SurgicalLlamaAttention passes verification."""
        # Simple configuration mock for SurgicalLlamaAttention
        class MockConfig:
            hidden_size = 64
            num_attention_heads = 2
            num_key_value_heads = 2
            max_position_embeddings = 512
            attention_dropout = 0.0
            surgical_p = 2
            surgical_tau = 1.0

        attn = SurgicalLlamaAttention(MockConfig(), layer_idx=0)
        attn.eval()

        hidden_states = torch.randn(1, 256, 64)
        prover = ZKAttentionProver()

        cert = prover.prove_from_attention(
            attn_layer=attn,
            hidden_states=hidden_states,
            block_size=64,
            depth=3,
            req_depth=2,
        )

        assert cert.verification["valid"] is True
        assert cert.routing_metadata["num_blocks"] == 4


# ============================================================================
# 3. Soundness & Tampering Rejection Tests (Negative Verification)
# ============================================================================

class TestSoundnessAndTamperingRejection:
    """Rigorous tests ensuring any tampering with masks, depth, or witness wires is rejected."""

    def test_tampering_active_attention_mask_fails(self):
        """Soundness: Forcing M_{i,j}=0 when tokens share required prefix triggers constraint failure."""
        # Blocks 0 and 1 both share prefix '00' (depth 2) -> honest mask is 1
        block_indices = [0, 1]  # 000 vs 001
        p = 2
        depth = 3
        req_depth = 2

        builder = PAdicLCAConstraintBuilder()
        system, b_vars, mask_vars = builder.build_block_routing_system(
            num_blocks=2, p=p, depth=depth, req_depth=req_depth
        )
        witness = builder.generate_block_routing_witness(block_indices, p, depth, req_depth)

        # Confirm honest witness passes
        assert system.is_satisfied(witness)

        # TAMPER: Force M_{0,1} = 0 (forging an omitted attention route)
        mask_0_1_var = mask_vars[(0, 1)]
        tampered_witness = dict(witness)
        tampered_witness[mask_0_1_var] = 0

        is_valid, fail_idx, err = system.verify_witness(tampered_witness)
        assert not is_valid
        assert fail_idx is not None
        assert "violated" in err.lower()

    def test_tampering_inactive_attention_mask_fails(self):
        """Soundness: Forcing M_{i,j}=1 when tokens do NOT share prefix triggers constraint failure."""
        # Block 0 (000) and Block 2 (100) have different root branches -> honest mask is 0
        block_indices = [0, 4]
        p = 2
        depth = 3
        req_depth = 2

        builder = PAdicLCAConstraintBuilder()
        system, b_vars, mask_vars = builder.build_block_routing_system(
            num_blocks=2, p=p, depth=depth, req_depth=req_depth
        )
        witness = builder.generate_block_routing_witness(block_indices, p, depth, req_depth)

        assert system.is_satisfied(witness)

        # TAMPER: Force M_{0,1} = 1 (forging unauthorized attention connection)
        mask_0_1_var = mask_vars[(0, 1)]
        tampered_witness = dict(witness)
        tampered_witness[mask_0_1_var] = 1

        is_valid, fail_idx, err = system.verify_witness(tampered_witness)
        assert not is_valid
        assert fail_idx is not None

    def test_altering_required_depth_without_witness_fails(self):
        """Soundness: Changing required depth r without updating the witness triggers constraint failure."""
        # Block 0 (000) and Block 1 (001) match up to depth 2, but differ at depth 3
        block_indices = [0, 1]
        p = 2
        depth = 3

        # Witness generated for req_depth = 2 (mask = 1)
        builder_r2 = PAdicLCAConstraintBuilder()
        builder_r2.build_block_routing_system(num_blocks=2, p=p, depth=depth, req_depth=2)
        witness_r2 = builder_r2.generate_block_routing_witness(block_indices, p, depth, req_depth=2)

        # System built for req_depth = 3 (requires all 3 digits to match)
        builder_r3 = PAdicLCAConstraintBuilder()
        system_r3, _, _ = builder_r3.build_block_routing_system(num_blocks=2, p=p, depth=depth, req_depth=3)

        # Verifying r2 witness against r3 system must fail
        is_valid, fail_idx, err = system_r3.verify_witness(witness_r2)
        assert not is_valid

    def test_tampering_digit_range_fails(self):
        """Soundness: Setting a binary digit to non-boolean value (e.g. 2) fails range polynomial."""
        block_indices = [3]  # binary 011
        p = 2
        depth = 3

        builder = PAdicLCAConstraintBuilder()
        system, b_vars, _ = builder.build_block_routing_system(num_blocks=1, p=p, depth=depth, req_depth=1)
        witness = builder.generate_block_routing_witness(block_indices, p, depth, req_depth=1)

        assert system.is_satisfied(witness)

        # TAMPER: Set digit 0 to 2 (violates d * (1 - d) == 0)
        d0_var = system.var_name_to_idx["b0_digit_0"]
        tampered_witness = dict(witness)
        tampered_witness[d0_var] = 2

        is_valid, fail_idx, err = system.verify_witness(tampered_witness)
        assert not is_valid
        assert "Boolean check" in system.constraints[fail_idx].comment or "Range" in system.constraints[fail_idx].comment

    def test_tampering_block_index_reconstruction_fails(self):
        """Soundness: Altering the public block value without altering digits fails reconstruction check."""
        block_indices = [5]  # binary 101
        p = 2
        depth = 3

        builder = PAdicLCAConstraintBuilder()
        system, b_vars, _ = builder.build_block_routing_system(num_blocks=1, p=p, depth=depth, req_depth=1)
        witness = builder.generate_block_routing_witness(block_indices, p, depth, req_depth=1)

        # TAMPER: Public block input wire changed to 6
        tampered_witness = dict(witness)
        tampered_witness[b_vars[0]] = 6

        is_valid, fail_idx, err = system.verify_witness(tampered_witness)
        assert not is_valid
        assert "Reconstruct" in system.constraints[fail_idx].comment

    def test_unauthorized_cross_branch_attention_fails_safety_guard(self):
        """Safety Policy: Cross-branch connection forbidden by policy is rejected when route exists."""
        # Block 0 (000) and Block 1 (001) share prefix '00' (req_depth=2 -> M_{0,1} = 1)
        # Security policy forbids Block 0 from attending to Block 1
        block_indices = [0, 1]
        p = 2
        depth = 3
        req_depth = 2
        forbidden_policy = [(0, 1)]

        prover = ZKAttentionProver()
        cert = prover.prove_and_verify(
            block_indices=block_indices,
            p=p,
            depth=depth,
            req_depth=req_depth,
            forbidden_pairs=forbidden_policy,
        )

        # Must fail because M_{0,1} == 1 violates safety guard M_{0,1} * 1 == 0
        assert cert.verification["valid"] is False
        assert cert.non_interference_audit["status"] == "VIOLATION_DETECTED"
        assert [0, 1] in cert.non_interference_audit["violations"]

    def test_authorized_isolation_passes_safety_guard(self):
        """Safety Policy: Cross-branch isolation policy succeeds when tokens do not attend."""
        # Block 0 (000) and Block 2 (100) do NOT share prefix (M_{0,1} = 0)
        # Security policy forbids Block 0 from attending to Block 2
        block_indices = [0, 4]  # IDs 0 and 4 in binary
        p = 2
        depth = 3
        req_depth = 2
        forbidden_policy = [(0, 1)]

        prover = ZKAttentionProver()
        cert = prover.prove_and_verify(
            block_indices=block_indices,
            p=p,
            depth=depth,
            req_depth=req_depth,
            forbidden_pairs=forbidden_policy,
        )

        assert cert.verification["valid"] is True
        assert cert.non_interference_audit["status"] == "PASSED"
        assert len(cert.non_interference_audit["violations"]) == 0


# ============================================================================
# 4. Performance & Scalability Benchmark
# ============================================================================

class TestPerformanceAndScalability:
    """Benchmark proof generation and R1CS verification speed for realistic context lengths."""

    def test_scalability_2048_tokens_32_blocks(self):
        """Performance: Prove and verify N=2048, B=64 (32 blocks, ~2704 constraints) in milliseconds."""
        seq_len = 2048
        block_size = 64
        num_blocks = seq_len // block_size  # 32 blocks
        depth = 5  # 2^5 = 32 leaves
        req_depth = 2
        p = 2

        # Deterministic 32 block IDs in [0, 31]
        block_indices = list(range(num_blocks))

        prover = ZKAttentionProver()
        t0 = time.perf_counter()
        cert = prover.prove_and_verify(
            block_indices=block_indices,
            p=p,
            depth=depth,
            req_depth=req_depth,
            seq_len=seq_len,
            block_size=block_size,
        )
        total_time_ms = (time.perf_counter() - t0) * 1000.0

        assert cert.verification["valid"] is True
        assert cert.circuit_metadata["num_constraints"] > 2000
        assert cert.routing_metadata["num_blocks"] == 32
        
        # Verify verification time is fast (< 250ms on CPU)
        assert cert.verification["verification_time_ms"] < 250.0
        assert total_time_ms < 500.0


# ============================================================================
# 5. Cryptographic Commitments & Digest Integrity
# ============================================================================

class TestCryptographicCommitments:
    """Verify deterministic SHA-256 root commitments and collision resistance."""

    def test_commitment_determinism(self):
        """Identical routing traces produce bit-for-bit identical root commitments."""
        block_indices = [0, 1, 4, 6]
        prover = ZKAttentionProver()

        cert1 = prover.prove_and_verify(block_indices, p=2, depth=3, req_depth=2)
        cert2 = prover.prove_and_verify(block_indices, p=2, depth=3, req_depth=2)

        assert cert1.cryptographic_commitments["routing_matrix_sha256"] == cert2.cryptographic_commitments["routing_matrix_sha256"]
        assert cert1.cryptographic_commitments["block_indices_sha256"] == cert2.cryptographic_commitments["block_indices_sha256"]
        assert cert1.cryptographic_commitments["witness_digest_sha256"] == cert2.cryptographic_commitments["witness_digest_sha256"]
        assert cert1.cryptographic_commitments["root_hash"] == cert2.cryptographic_commitments["root_hash"]

    def test_commitment_sensitivity(self):
        """Changing one block index alters the root commitment."""
        prover = ZKAttentionProver()
        cert1 = prover.prove_and_verify([0, 1, 4, 6], p=2, depth=3, req_depth=2)
        cert2 = prover.prove_and_verify([0, 1, 4, 7], p=2, depth=3, req_depth=2)

        assert cert1.cryptographic_commitments["root_hash"] != cert2.cryptographic_commitments["root_hash"]

    def test_certificate_json_roundtrip(self):
        """Certificate correctly serializes to JSON and parses back with all fields preserved."""
        prover = ZKAttentionProver()
        cert = prover.prove_and_verify([0, 2, 5], p=2, depth=3, req_depth=2)

        json_str = cert.to_json()
        data = json.loads(json_str)

        assert data["certificate_id"].startswith("ZK-ATTN-")
        assert data["verification"]["valid"] is True
        assert "root_hash" in data["cryptographic_commitments"]
        assert "sparsity_percentage" in data["sparsity_metrics"]


# ============================================================================
# 6. CLI Tooling & Integration
# ============================================================================

class TestCLIProverTool:
    """Test CLI execution and command-line arguments."""

    def test_cli_prover_execution_basic(self):
        """Test standard CLI invocation with default flags."""
        ret = cli_main(["--seq_len", "256", "--block_size", "64", "--depth", "3", "--req_depth", "2", "--quiet"])
        assert ret == 0

    def test_cli_prover_with_output_file(self):
        """Test CLI saving certificate to a temporary JSON file."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            out_file = Path(tmp_dir) / "cert.json"
            ret = cli_main([
                "--seq_len", "512",
                "--block_size", "64",
                "--depth", "4",
                "--req_depth", "2",
                "--output", str(out_file),
                "--quiet",
            ])
            assert ret == 0
            assert out_file.exists()

            content = json.loads(out_file.read_text(encoding="utf-8"))
            assert content["verification"]["valid"] is True
            assert content["routing_metadata"]["num_blocks"] == 8

    def test_cli_prover_tamper_flags(self):
        """Test CLI tamper rejection flags return 0 (confirming detection of failure)."""
        ret_mask = cli_main(["--seq_len", "256", "--block_size", "64", "--tamper-mask", "--quiet"])
        assert ret_mask == 0

        ret_depth = cli_main(["--seq_len", "256", "--block_size", "64", "--tamper-depth", "--quiet"])
        assert ret_depth == 0
