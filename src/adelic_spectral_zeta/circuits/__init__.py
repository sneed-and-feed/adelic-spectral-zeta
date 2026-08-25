"""
Circuits and Zero-Knowledge R1CS Constraints for p-Adic LCA Routing and Non-Interference.

Provides:
- R1CSSystem: Pure Python algebraic R1CS compiler over prime fields (BN254, BLS12-381, Goldilocks, Mersenne-31).
- LinearCombination: Sparse linear combination arithmetic over F_r.
- PAdicLCAConstraintBuilder: Constraint generator for base-p digit extraction, LCA prefix matching, and non-interference.
- Field constants: BN254_R, BLS12_381_R, GOLDILOCKS_P, M31_P.
"""

from .padic_r1cs import (
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

__all__ = [
    "BN254_R",
    "BLS12_381_R",
    "GOLDILOCKS_P",
    "M31_P",
    "mod_inv",
    "VariableKind",
    "Variable",
    "LinearCombination",
    "Constraint",
    "R1CSSystem",
    "PAdicLCAConstraintBuilder",
]
