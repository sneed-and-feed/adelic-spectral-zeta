"""
Unit Tests for Pure Algebraic R1CS Compiler and p-Adic LCA Routing Builder.
"""

import sys
import unittest
from pathlib import Path

# Add src to path
src_dir = Path(__file__).resolve().parent.parent / "src"
if str(src_dir) not in sys.path:
    sys.path.insert(0, str(src_dir))

from adelic_spectral_zeta.circuits.padic_r1cs import (
    BN254_R,
    BLS12_381_R,
    GOLDILOCKS_P,
    M31_P,
    mod_inv,
    VariableKind,
    Variable,
    LinearCombination,
    Constraint,
    R1CSSystem,
    PAdicLCAConstraintBuilder,
)


class TestR1CSPrimitives(unittest.TestCase):
    """Test fundamental linear combination, constraint, and field arithmetic operations."""

    def test_mod_inv(self):
        r = BN254_R
        self.assertEqual(mod_inv(1, r), 1)
        self.assertEqual(mod_inv(2, r), (r + 1) // 2)
        inv_7 = mod_inv(7, r)
        self.assertEqual((7 * inv_7) % r, 1)

        with self.assertRaises(ZeroDivisionError):
            mod_inv(0, r)

    def test_linear_combination_arithmetic(self):
        r = BN254_R
        lc1 = LinearCombination.from_var(1, 3, r) + 5
        lc2 = LinearCombination.from_var(2, 4, r) - 2
        lc3 = lc1 + lc2

        # lc3 = 3*w[1] + 4*w[2] + 3
        witness = {0: 1, 1: 10, 2: 20}
        # 3*10 + 4*20 + 3 = 30 + 80 + 3 = 113
        self.assertEqual(lc3.evaluate(witness), 113)

        # Scalar multiplication
        lc4 = lc3 * 2
        self.assertEqual(lc4.evaluate(witness), 226)

        # Negation
        lc5 = -lc3
        self.assertEqual(lc5.evaluate(witness), (r - 113) % r)

    def test_r1cs_system_basic_verification(self):
        # Circuit for x * y = z
        sys = R1CSSystem(field_modulus=BN254_R)
        x = sys.allocate_var("x", kind=VariableKind.PUBLIC_INPUT)
        y = sys.allocate_var("y", kind=VariableKind.PUBLIC_INPUT)
        z = sys.allocate_var("z", kind=VariableKind.OUTPUT)

        sys.add_constraint(
            a=LinearCombination.from_var(x, 1),
            b=LinearCombination.from_var(y, 1),
            c=LinearCombination.from_var(z, 1),
            comment="x * y = z",
        )

        valid_witness = {0: 1, x: 7, y: 6, z: 42}
        self.assertTrue(sys.is_satisfied(valid_witness))

        invalid_witness = {0: 1, x: 7, y: 6, z: 43}
        self.assertFalse(sys.is_satisfied(invalid_witness))
        valid, fail_idx, err = sys.verify_witness(invalid_witness)
        self.assertFalse(valid)
        self.assertEqual(fail_idx, 0)


class TestPAdicLCAConstraintBuilder(unittest.TestCase):
    """Test base-p digit extraction, prefix equality, and LCA routing systems."""

    def test_binary_digit_decomposition(self):
        # p=2, depth=4, val = 13 (binary 1101 -> d0=1, d1=1, d2=0, d3=1)
        p = 2
        depth = 4
        val = 13

        builder = PAdicLCAConstraintBuilder(field_modulus=BN254_R)
        v_var = builder.system.allocate_var("val", kind=VariableKind.PUBLIC_INPUT)
        digits = builder.add_digit_decomposition(v_var, p=p, depth=depth, msb_first=True)

        w = {0: 1, v_var: val}
        expected_digits = [1, 1, 0, 1]
        for d_var, exp_d in zip(digits, expected_digits):
            w[d_var] = exp_d

        self.assertTrue(builder.system.is_satisfied(w))

        # Test invalid limb range (d0 = 2 not in {0, 1})
        w_invalid = dict(w)
        w_invalid[digits[0]] = 2
        self.assertFalse(builder.system.is_satisfied(w_invalid))

    def test_ternary_digit_decomposition(self):
        # p=3, depth=3, val = 19 (ternary 201 -> 2*9 + 0*3 + 1*1 = 19)
        p = 3
        depth = 3
        val = 19

        builder = PAdicLCAConstraintBuilder(field_modulus=BN254_R)
        v_var = builder.system.allocate_var("val", kind=VariableKind.PUBLIC_INPUT)
        digits = builder.add_digit_decomposition(v_var, p=p, depth=depth, msb_first=True, name_prefix="digit")

        w = {0: 1, v_var: val}
        expected_digits = [2, 0, 1]
        for k, (d_var, exp_d) in enumerate(zip(digits, expected_digits)):
            w[d_var] = exp_d
            builder._populate_range_witness(w, d_var, exp_d, p, f"range_digit_{k}")

        self.assertTrue(builder.system.is_satisfied(w))

    def test_pairwise_lca_binary_tree(self):
        # Tree depth D=4, base p=2, req_depth=3
        # Node 12: 1100
        # Node 13: 1101 -> shares 110 prefix (len 3) -> match = 1
        # Node 14: 1110 -> shares 11 prefix (len 2 < 3) -> match = 0
        p = 2
        depth = 4
        req_depth = 3

        # Match case
        builder_match = PAdicLCAConstraintBuilder()
        sys_m, u_v, v_v, mask_m = builder_match.build_pairwise_lca_system(p, depth, req_depth)
        w_m = builder_match.generate_witness(12, 13, p, depth, req_depth)
        self.assertTrue(sys_m.is_satisfied(w_m))
        self.assertEqual(w_m[mask_m], 1)

        # Mismatch case
        builder_mism = PAdicLCAConstraintBuilder()
        sys_x, u_v2, v_v2, mask_x = builder_mism.build_pairwise_lca_system(p, depth, req_depth)
        w_x = builder_mism.generate_witness(12, 14, p, depth, req_depth)
        self.assertTrue(sys_x.is_satisfied(w_x))
        self.assertEqual(w_x[mask_x], 0)

    def test_non_interference_safety(self):
        # Forbidden pair u=12, v=13 (connected) must fail non-interference
        p = 2
        depth = 4
        req_depth = 3

        builder = PAdicLCAConstraintBuilder()
        sys, _, _, _ = builder.build_pairwise_lca_system(p, depth, req_depth, forbidden=True)
        w_bad = builder.generate_witness(12, 13, p, depth, req_depth)
        self.assertFalse(sys.is_satisfied(w_bad))

        # Forbidden pair u=12, v=14 (not connected) must pass non-interference
        builder2 = PAdicLCAConstraintBuilder()
        sys2, _, _, _ = builder2.build_pairwise_lca_system(p, depth, req_depth, forbidden=True)
        w_good = builder2.generate_witness(12, 14, p, depth, req_depth)
        self.assertTrue(sys2.is_satisfied(w_good))

    def test_block_routing_attention_matrix(self):
        # 4 blocks: indices 0, 1, 2, 3 corresponding to tree node IDs [0, 1, 4, 6]
        # Binary representations:
        # Block 0 (ID 0) -> 000
        # Block 1 (ID 1) -> 001 (shares '00' with Block 0 -> route(0,1)=1)
        # Block 2 (ID 4) -> 100 (shares nothing with 0 -> route(0,2)=0)
        # Block 3 (ID 6) -> 110 (shares '1' with Block 2 len 1 < 2 -> route(2,3)=0)
        blocks = [0, 1, 4, 6]
        p = 2
        depth = 3
        req_depth = 2

        builder = PAdicLCAConstraintBuilder()
        route_sys, b_vars, mask_vars = builder.build_block_routing_system(
            num_blocks=len(blocks),
            p=p,
            depth=depth,
            req_depth=req_depth,
            forbidden_pairs=[(0, 2)],  # (Block 0, Block 2) has mask=0, so non-interference holds
        )

        w = builder.generate_block_routing_witness(blocks, p, depth, req_depth)
        self.assertTrue(route_sys.is_satisfied(w))

        # Verify specific attention routes
        self.assertEqual(w[mask_vars[(0, 0)]], 1)  # self
        self.assertEqual(w[mask_vars[(0, 1)]], 1)  # common prefix '00'
        self.assertEqual(w[mask_vars[(0, 2)]], 0)  # prefix '00' vs '10'
        self.assertEqual(w[mask_vars[(2, 3)]], 0)  # prefix '10' vs '11' (len 1 < 2)


if __name__ == "__main__":
    unittest.main()
