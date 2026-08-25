"""
Pure Algebraic R1CS Constraint Generator for p-Adic Tree LCA Routing and Non-Interference.

This module implements a pure algebraic Rank-1 Constraint System (R1CS) compiler
over configurable prime fields (defaulting to the BN254 / Alt-bn128 scalar field).
It provides formal constraint generation, witness computation, and verification for:
1. Base-p digit decomposition and limb range validation.
2. Lowest Common Ancestor (LCA) prefix matching on Bruhat-Tits / p-adic trees.
3. Multi-block / multi-head attention routing matrices.
4. Non-interference algebraic security guards enforcing isolation between partitions.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
import math
from typing import Any, Dict, List, Optional, Sequence, Set, Tuple, Union


# ============================================================================
# Prime Field Constants
# ============================================================================

# BN254 / Alt-bn128 scalar field modulus (Circom / snarkjs default)
BN254_R: int = 21888242871839275222246405745257275088548364400416034343698204186575808495617

# BLS12-381 scalar field modulus
BLS12_381_R: int = 5243587517512619047944774050818596583769055250052763782260365869993859290073

# Goldilocks prime modulus (2^64 - 2^32 + 1)
GOLDILOCKS_P: int = 18446744069414584321

# Mersenne-31 prime modulus (2^31 - 1)
M31_P: int = 2147483647


def mod_inv(val: int, modulus: int) -> int:
    """Compute the modular multiplicative inverse using Fermat's Little Theorem.
    
    Args:
        val: Element to invert.
        modulus: Prime modulus.
        
    Returns:
        Modular inverse in [1, modulus - 1].
        
    Raises:
        ZeroDivisionError: If val % modulus == 0.
    """
    v = val % modulus
    if v == 0:
        raise ZeroDivisionError("Cannot invert zero in prime field")
    return pow(v, modulus - 2, modulus)


# ============================================================================
# R1CS Algebraic Primitives
# ============================================================================

class VariableKind(str, Enum):
    """Classification of variable wires in the R1CS circuit."""
    ONE = "one"
    PUBLIC_INPUT = "public_input"
    PRIVATE_INPUT = "private_input"
    INTERMEDIATE = "intermediate"
    OUTPUT = "output"


@dataclass(frozen=True)
class Variable:
    """Represents an allocated wire/variable in the R1CS system."""
    index: int
    name: str
    kind: VariableKind = VariableKind.INTERMEDIATE

    def __repr__(self) -> str:
        return f"Var({self.index}, '{self.name}', {self.kind.value})"


class LinearCombination:
    """Sparse linear combination of variables over a prime field F_r.
    
    Represents an expression sum_{i} c_i * w_i (mod r).
    """

    def __init__(
        self,
        terms: Optional[Dict[int, int]] = None,
        field_modulus: int = BN254_R,
    ) -> None:
        self.field_modulus = field_modulus
        self.terms: Dict[int, int] = {}
        if terms:
            for var_idx, coeff in terms.items():
                c = coeff % self.field_modulus
                if c != 0:
                    self.terms[var_idx] = c

    @classmethod
    def from_var(
        cls,
        var_idx: int,
        coeff: int = 1,
        field_modulus: int = BN254_R,
    ) -> LinearCombination:
        """Create a linear combination with a single variable term."""
        return cls({var_idx: coeff}, field_modulus=field_modulus)

    @classmethod
    def from_constant(
        cls,
        val: int,
        field_modulus: int = BN254_R,
        one_var: int = 0,
    ) -> LinearCombination:
        """Create a constant linear combination (coeff * ONE wire)."""
        return cls({one_var: val}, field_modulus=field_modulus)

    def add_term(self, var_idx: int, coeff: int) -> LinearCombination:
        """Add a term to the linear combination in-place and return self."""
        new_coeff = (self.terms.get(var_idx, 0) + coeff) % self.field_modulus
        if new_coeff == 0:
            self.terms.pop(var_idx, None)
        else:
            self.terms[var_idx] = new_coeff
        return self

    def evaluate(self, witness: Union[Sequence[int], Dict[int, int]]) -> int:
        """Evaluate the linear combination against a witness assignment."""
        r = self.field_modulus
        total = 0
        if isinstance(witness, dict):
            for var_idx, coeff in self.terms.items():
                val = witness.get(var_idx, 0) % r
                total = (total + coeff * val) % r
        else:
            for var_idx, coeff in self.terms.items():
                val = witness[var_idx] % r
                total = (total + coeff * val) % r
        return total

    def is_zero(self) -> bool:
        """Check if the linear combination is identically zero."""
        return len(self.terms) == 0

    def copy(self) -> LinearCombination:
        """Return a deep copy of the linear combination."""
        return LinearCombination(dict(self.terms), field_modulus=self.field_modulus)

    def __add__(self, other: Union[LinearCombination, int, Variable]) -> LinearCombination:
        res = self.copy()
        if isinstance(other, LinearCombination):
            if other.field_modulus != self.field_modulus:
                raise ValueError("Field moduli must match for LC addition")
            for var_idx, coeff in other.terms.items():
                res.add_term(var_idx, coeff)
        elif isinstance(other, int):
            res.add_term(0, other)
        elif isinstance(other, Variable):
            res.add_term(other.index, 1)
        else:
            return NotImplemented
        return res

    def __radd__(self, other: Union[int, Variable]) -> LinearCombination:
        return self.__add__(other)

    def __sub__(self, other: Union[LinearCombination, int, Variable]) -> LinearCombination:
        res = self.copy()
        if isinstance(other, LinearCombination):
            if other.field_modulus != self.field_modulus:
                raise ValueError("Field moduli must match for LC subtraction")
            for var_idx, coeff in other.terms.items():
                res.add_term(var_idx, -coeff)
        elif isinstance(other, int):
            res.add_term(0, -other)
        elif isinstance(other, Variable):
            res.add_term(other.index, -1)
        else:
            return NotImplemented
        return res

    def __rsub__(self, other: Union[int, Variable]) -> LinearCombination:
        neg = -self
        return neg.__add__(other)

    def __neg__(self) -> LinearCombination:
        res = LinearCombination(field_modulus=self.field_modulus)
        for var_idx, coeff in self.terms.items():
            res.terms[var_idx] = (-coeff) % self.field_modulus
        return res

    def __mul__(self, scalar: int) -> LinearCombination:
        if not isinstance(scalar, int):
            return NotImplemented
        res = LinearCombination(field_modulus=self.field_modulus)
        s = scalar % self.field_modulus
        if s != 0:
            for var_idx, coeff in self.terms.items():
                res.terms[var_idx] = (coeff * s) % self.field_modulus
        return res

    def __rmul__(self, scalar: int) -> LinearCombination:
        return self.__mul__(scalar)

    def __repr__(self) -> str:
        if not self.terms:
            return "LC(0)"
        parts = []
        for v, c in sorted(self.terms.items()):
            if v == 0:
                parts.append(f"{c}")
            else:
                parts.append(f"{c}*w[{v}]" if c != 1 else f"w[{v}]")
        return "LC(" + " + ".join(parts) + ")"


@dataclass
class Constraint:
    """Rank-1 constraint (A · w) * (B · w) == (C · w) (mod r)."""
    a: LinearCombination
    b: LinearCombination
    c: LinearCombination
    comment: str = ""

    def evaluate_residual(self, witness: Union[Sequence[int], Dict[int, int]], field_modulus: int) -> int:
        """Compute ((A · w) * (B · w) - (C · w)) mod r."""
        val_a = self.a.evaluate(witness)
        val_b = self.b.evaluate(witness)
        val_c = self.c.evaluate(witness)
        return (val_a * val_b - val_c) % field_modulus

    def is_satisfied(self, witness: Union[Sequence[int], Dict[int, int]], field_modulus: int) -> bool:
        """Check if the constraint is satisfied by the given witness."""
        return self.evaluate_residual(witness, field_modulus) == 0


# ============================================================================
# R1CS System
# ============================================================================

class R1CSSystem:
    """Manages variables, linear combinations, and constraints for an R1CS circuit."""

    def __init__(self, field_modulus: int = BN254_R) -> None:
        self.field_modulus: int = field_modulus
        self.variables: List[Variable] = []
        self.var_name_to_idx: Dict[str, int] = {}
        self.constraints: List[Constraint] = []

        # Wire 0 is always the constant ONE wire
        self._allocate_one_wire()

    def _allocate_one_wire(self) -> None:
        one_var = Variable(index=0, name="ONE", kind=VariableKind.ONE)
        self.variables.append(one_var)
        self.var_name_to_idx["ONE"] = 0

    @property
    def num_variables(self) -> int:
        """Total number of allocated variables (including ONE wire)."""
        return len(self.variables)

    @property
    def num_constraints(self) -> int:
        """Total number of R1CS constraints."""
        return len(self.constraints)

    @property
    def public_inputs(self) -> List[int]:
        """Indices of public input variables."""
        return [v.index for v in self.variables if v.kind == VariableKind.PUBLIC_INPUT]

    @property
    def private_inputs(self) -> List[int]:
        """Indices of private input variables."""
        return [v.index for v in self.variables if v.kind == VariableKind.PRIVATE_INPUT]

    @property
    def intermediate_vars(self) -> List[int]:
        """Indices of intermediate witness variables."""
        return [v.index for v in self.variables if v.kind == VariableKind.INTERMEDIATE]

    @property
    def output_vars(self) -> List[int]:
        """Indices of circuit output variables."""
        return [v.index for v in self.variables if v.kind == VariableKind.OUTPUT]

    def allocate_var(
        self,
        name: Optional[str] = None,
        kind: Union[VariableKind, str] = VariableKind.INTERMEDIATE,
    ) -> int:
        """Allocate a new wire variable in the circuit.
        
        Args:
            name: Optional unique identifier. If omitted, auto-generated.
            kind: Variable role (public_input, private_input, intermediate, output).
            
        Returns:
            The integer index of the newly allocated variable.
        """
        idx = len(self.variables)
        if isinstance(kind, str):
            kind = VariableKind(kind)

        if name is None:
            name = f"wire_{idx}"
        elif name in self.var_name_to_idx:
            name = f"{name}_{idx}"

        var = Variable(index=idx, name=name, kind=kind)
        self.variables.append(var)
        self.var_name_to_idx[name] = idx
        return idx

    def allocate_vars(
        self,
        count: int,
        prefix: str = "wire",
        kind: Union[VariableKind, str] = VariableKind.INTERMEDIATE,
    ) -> List[int]:
        """Allocate multiple variables with a common naming prefix."""
        return [self.allocate_var(f"{prefix}_{i}", kind=kind) for i in range(count)]

    def to_lc(
        self,
        item: Union[LinearCombination, Dict[int, int], int, Variable],
    ) -> LinearCombination:
        """Convert a variable, dictionary, or integer constant to a LinearCombination."""
        if isinstance(item, LinearCombination):
            return item
        if isinstance(item, Variable):
            return LinearCombination.from_var(item.index, 1, self.field_modulus)
        if isinstance(item, int):
            return LinearCombination.from_constant(item, self.field_modulus, one_var=0)
        if isinstance(item, dict):
            return LinearCombination(item, self.field_modulus)
        raise TypeError(f"Cannot convert type {type(item)} to LinearCombination")

    def add_constraint(
        self,
        a: Union[LinearCombination, Dict[int, int], int, Variable],
        b: Union[LinearCombination, Dict[int, int], int, Variable],
        c: Union[LinearCombination, Dict[int, int], int, Variable],
        comment: str = "",
    ) -> int:
        """Add a rank-1 constraint (A · w) * (B · w) == (C · w) to the system.
        
        Args:
            a: Left linear combination.
            b: Right linear combination.
            c: Output linear combination.
            comment: Optional descriptive annotation for debugging.
            
        Returns:
            The 0-based index of the added constraint.
        """
        lc_a = self.to_lc(a)
        lc_b = self.to_lc(b)
        lc_c = self.to_lc(c)
        c_idx = len(self.constraints)
        self.constraints.append(Constraint(a=lc_a, b=lc_b, c=lc_c, comment=comment))
        return c_idx

    def get_matrices(self) -> Tuple[List[Dict[int, int]], List[Dict[int, int]], List[Dict[int, int]]]:
        """Return sparse matrix representations for A, B, C constraint matrices."""
        matrix_a = [dict(c.a.terms) for c in self.constraints]
        matrix_b = [dict(c.b.terms) for c in self.constraints]
        matrix_c = [dict(c.c.terms) for c in self.constraints]
        return matrix_a, matrix_b, matrix_c

    def get_dense_matrices(self) -> Tuple[List[List[int]], List[List[int]], List[List[int]]]:
        """Return dense 2D integer matrices for A, B, C (size M x N)."""
        m = len(self.constraints)
        n = len(self.variables)
        dense_a = [[0] * n for _ in range(m)]
        dense_b = [[0] * n for _ in range(m)]
        dense_c = [[0] * n for _ in range(m)]

        for i, c in enumerate(self.constraints):
            for v, coeff in c.a.terms.items():
                dense_a[i][v] = coeff
            for v, coeff in c.b.terms.items():
                dense_b[i][v] = coeff
            for v, coeff in c.c.terms.items():
                dense_c[i][v] = coeff

        return dense_a, dense_b, dense_c

    def compile_witness_vector(self, witness_map: Dict[int, int]) -> List[int]:
        """Compile a sparse or partial witness dictionary into a full ordered vector w."""
        r = self.field_modulus
        w = [0] * len(self.variables)
        w[0] = 1  # ONE wire is always 1

        for idx, val in witness_map.items():
            if 0 <= idx < len(w):
                w[idx] = val % r

        return w

    def verify_witness(
        self,
        witness: Union[Sequence[int], Dict[int, int]],
    ) -> Tuple[bool, Optional[int], Optional[str]]:
        """Verify if all constraints (A · w) * (B · w) == (C · w) are satisfied.
        
        Args:
            witness: Complete witness vector or mapping of variable indices to values.
            
        Returns:
            Tuple (is_valid, failing_constraint_index, error_message).
        """
        # Ensure ONE wire is 1
        if isinstance(witness, dict):
            if witness.get(0, 1) % self.field_modulus != 1:
                return False, None, f"Wire 0 (ONE) must equal 1, got {witness.get(0)}"
        else:
            if len(witness) < len(self.variables):
                return False, None, f"Witness length ({len(witness)}) < variable count ({len(self.variables)})"
            if witness[0] % self.field_modulus != 1:
                return False, None, f"Wire 0 (ONE) must equal 1, got {witness[0]}"

        for idx, constraint in enumerate(self.constraints):
            residual = constraint.evaluate_residual(witness, self.field_modulus)
            if residual != 0:
                val_a = constraint.a.evaluate(witness)
                val_b = constraint.b.evaluate(witness)
                val_c = constraint.c.evaluate(witness)
                comment = f" [{constraint.comment}]" if constraint.comment else ""
                err = (
                    f"Constraint #{idx}{comment} violated: "
                    f"(A · w = {val_a}) * (B · w = {val_b}) = {(val_a * val_b) % self.field_modulus} != "
                    f"(C · w = {val_c}) (residual: {residual})"
                )
                return False, idx, err

        return True, None, None

    def is_satisfied(self, witness: Union[Sequence[int], Dict[int, int]]) -> bool:
        """Return True if witness satisfies all constraints, False otherwise."""
        valid, _, _ = self.verify_witness(witness)
        return valid

    def summary(self) -> str:
        """Return a formatted statistical summary of the R1CS circuit."""
        return (
            f"R1CSSystem Summary:\n"
            f"  Field Modulus:       {self.field_modulus}\n"
            f"  Total Variables:     {self.num_variables}\n"
            f"  - Public Inputs:     {len(self.public_inputs)}\n"
            f"  - Private Inputs:    {len(self.private_inputs)}\n"
            f"  - Intermediate:      {len(self.intermediate_vars)}\n"
            f"  - Outputs:           {len(self.output_vars)}\n"
            f"  Total Constraints:   {self.num_constraints}"
        )


# ============================================================================
# p-Adic LCA & Routing Constraint Builder
# ============================================================================

class PAdicLCAConstraintBuilder:
    """High-level builder for p-adic tree arithmetic, LCA prefix routing, and safety."""

    def __init__(
        self,
        field_modulus: int = BN254_R,
        system: Optional[R1CSSystem] = None,
    ) -> None:
        self.field_modulus = field_modulus
        self.system = system if system is not None else R1CSSystem(field_modulus=field_modulus)

    def add_digit_decomposition(
        self,
        val_var: int,
        p: int,
        depth: int,
        msb_first: bool = True,
        name_prefix: str = "digit",
    ) -> List[int]:
        """Add base-p digit decomposition constraints for a node or block index.
        
        Given a value variable `val_var` representing an index in [0, p^depth - 1],
        allocates `depth` digit variables d_0, ..., d_{depth-1} and enforces:
        1. Range constraint: each d_k in {0, 1, ..., p - 1}.
        2. Reconstruction constraint: sum_{k} d_k * p^{weight} == val_var.
        
        Args:
            val_var: Variable index of the composite node value.
            p: Tree branching arity (prime base p >= 2).
            depth: Depth D of the p-adic tree.
            msb_first: If True, d_0 is root branch (weight p^{D-1}) down to d_{D-1} leaf branch (weight p^0).
            name_prefix: Prefix for naming allocated digit variables.
            
        Returns:
            List of variable indices for the extracted digits [d_0, ..., d_{depth-1}].
        """
        digit_vars = self.system.allocate_vars(depth, prefix=name_prefix, kind=VariableKind.INTERMEDIATE)

        # 1. Enforce range constraints on each digit: d_k in {0, 1, ..., p - 1}
        for k, d_var in enumerate(digit_vars):
            self._add_digit_range_constraint(d_var, p, comment_suffix=f"{name_prefix}_{k}")

        # 2. Linear combination reconstruction constraint: sum(weights * digits) == val_var
        recon_lc = LinearCombination(field_modulus=self.field_modulus)
        for k, d_var in enumerate(digit_vars):
            if msb_first:
                weight = p ** (depth - 1 - k)
            else:
                weight = p ** k
            recon_lc.add_term(d_var, weight)

        # Constraint: (sum weights * d_k) * 1 == val_var
        self.system.add_constraint(
            a=recon_lc,
            b=LinearCombination.from_constant(1, self.field_modulus),
            c=LinearCombination.from_var(val_var, 1, self.field_modulus),
            comment=f"Reconstruct {name_prefix} from base-{p} digits",
        )

        return digit_vars

    def _add_digit_range_constraint(
        self,
        d_var: int,
        p: int,
        comment_suffix: str = "",
    ) -> None:
        """Algebraically enforce d_var in {0, 1, ..., p - 1} using polynomial vanishing."""
        if p <= 1:
            raise ValueError(f"Prime arity p must be >= 2, got {p}")

        if p == 2:
            # Boolean constraint: d * (1 - d) == 0  <=>  d * (d - 1) == 0
            d_lc = LinearCombination.from_var(d_var, 1, self.field_modulus)
            one_minus_d = LinearCombination.from_constant(1, self.field_modulus) - d_lc
            self.system.add_constraint(
                a=d_lc,
                b=one_minus_d,
                c=LinearCombination(field_modulus=self.field_modulus),
                comment=f"Boolean check {comment_suffix}",
            )
            return

        # For general small p (e.g. 3, 5, 7), enforce prod_{j=0}^{p-1} (d - j) == 0
        d_lc = LinearCombination.from_var(d_var, 1, self.field_modulus)
        d_minus_0 = d_lc
        d_minus_1 = d_lc - 1

        if p == 3:
            # acc_1 = (d - 0) * (d - 1)
            acc_1 = self.system.allocate_var(f"range_{comment_suffix}_acc1", kind=VariableKind.INTERMEDIATE)
            self.system.add_constraint(
                a=d_minus_0,
                b=d_minus_1,
                c=LinearCombination.from_var(acc_1, 1, self.field_modulus),
                comment=f"Range step 1 {comment_suffix}",
            )
            # acc_1 * (d - 2) == 0
            d_minus_2 = d_lc - 2
            self.system.add_constraint(
                a=LinearCombination.from_var(acc_1, 1, self.field_modulus),
                b=d_minus_2,
                c=LinearCombination(field_modulus=self.field_modulus),
                comment=f"Range step 2 (final) {comment_suffix}",
            )
        else:
            # Generic chain for p > 3
            current_prod_var = self.system.allocate_var(f"range_{comment_suffix}_acc1", kind=VariableKind.INTERMEDIATE)
            self.system.add_constraint(
                a=d_minus_0,
                b=d_minus_1,
                c=LinearCombination.from_var(current_prod_var, 1, self.field_modulus),
                comment=f"Range step 1 {comment_suffix}",
            )
            for j in range(2, p - 1):
                next_prod_var = self.system.allocate_var(f"range_{comment_suffix}_acc{j}", kind=VariableKind.INTERMEDIATE)
                d_minus_j = d_lc - j
                self.system.add_constraint(
                    a=LinearCombination.from_var(current_prod_var, 1, self.field_modulus),
                    b=d_minus_j,
                    c=LinearCombination.from_var(next_prod_var, 1, self.field_modulus),
                    comment=f"Range step {j} {comment_suffix}",
                )
                current_prod_var = next_prod_var

            # Final term must equal 0
            d_minus_last = d_lc - (p - 1)
            self.system.add_constraint(
                a=LinearCombination.from_var(current_prod_var, 1, self.field_modulus),
                b=d_minus_last,
                c=LinearCombination(field_modulus=self.field_modulus),
                comment=f"Range final {comment_suffix} (root vanishing)",
            )

    def add_prefix_equality(
        self,
        u_digits: List[int],
        v_digits: List[int],
        req_depth: int,
        name_prefix: str = "lca",
    ) -> Dict[str, Any]:
        """Enforce prefix equality up to `req_depth` digits between two tree paths.
        
        For each level k in [0, req_depth - 1]:
        1. Delta_k = u_k - v_k.
        2. Equality indicator eq_k in {0, 1} and inverse witness inv_k:
           - Delta_k * eq_k == 0
           - Delta_k * inv_k == 1 - eq_k
        3. Cumulative prefix product mask:
           - mask_0 = eq_0
           - mask_k = mask_{k-1} * eq_k  (for k >= 1)
           
        Args:
            u_digits: Digit variable indices for path u.
            v_digits: Digit variable indices for path v.
            req_depth: Number of prefix levels to compare (0 <= req_depth <= len(u_digits)).
            name_prefix: Variable naming prefix.
            
        Returns:
            Dictionary containing:
                "eq_vars": list of per-level equality indicator variables [eq_0, ..., eq_{req_depth-1}]
                "inv_vars": list of inverse witness variables [inv_0, ..., inv_{req_depth-1}]
                "prefix_masks": cumulative mask variables at each step
                "mask_var": final scalar output wire (1 if prefix matches of length req_depth, else 0)
        """
        if req_depth < 0 or req_depth > min(len(u_digits), len(v_digits)):
            raise ValueError(f"req_depth={req_depth} exceeds digit count {len(u_digits)}")

        if req_depth == 0:
            # Empty prefix always matches (constant 1)
            one_lc = LinearCombination.from_constant(1, self.field_modulus)
            mask_var = self.system.allocate_var(f"{name_prefix}_mask_0", kind=VariableKind.OUTPUT)
            self.system.add_constraint(
                a=LinearCombination.from_var(mask_var, 1, self.field_modulus),
                b=LinearCombination.from_constant(1, self.field_modulus),
                c=one_lc,
                comment=f"Trivial prefix depth 0 {name_prefix}",
            )
            return {
                "eq_vars": [],
                "inv_vars": [],
                "prefix_masks": [mask_var],
                "mask_var": mask_var,
            }

        eq_vars: List[int] = []
        inv_vars: List[int] = []
        prefix_masks: List[int] = []

        for k in range(req_depth):
            u_var = u_digits[k]
            v_var = v_digits[k]

            # Delta_k = u_k - v_k
            delta_lc = LinearCombination.from_var(u_var, 1, self.field_modulus) - LinearCombination.from_var(v_var, 1, self.field_modulus)

            eq_k = self.system.allocate_var(f"{name_prefix}_eq_{k}", kind=VariableKind.INTERMEDIATE)
            inv_k = self.system.allocate_var(f"{name_prefix}_inv_{k}", kind=VariableKind.INTERMEDIATE)
            eq_vars.append(eq_k)
            inv_vars.append(inv_k)

            eq_lc = LinearCombination.from_var(eq_k, 1, self.field_modulus)
            inv_lc = LinearCombination.from_var(inv_k, 1, self.field_modulus)

            # Constraint 1: Delta_k * eq_k == 0
            self.system.add_constraint(
                a=delta_lc,
                b=eq_lc,
                c=LinearCombination(field_modulus=self.field_modulus),
                comment=f"Zero-check 1: delta_{k} * eq_{k} == 0 ({name_prefix})",
            )

            # Constraint 2: Delta_k * inv_k == 1 - eq_k
            one_minus_eq = LinearCombination.from_constant(1, self.field_modulus) - eq_lc
            self.system.add_constraint(
                a=delta_lc,
                b=inv_lc,
                c=one_minus_eq,
                comment=f"Zero-check 2: delta_{k} * inv_{k} == 1 - eq_{k} ({name_prefix})",
            )

        # Cumulative prefix product: mask_k = mask_{k-1} * eq_k
        cum_mask_0 = eq_vars[0]
        prefix_masks.append(cum_mask_0)

        for k in range(1, req_depth):
            step_mask = self.system.allocate_var(f"{name_prefix}_cum_mask_{k}", kind=VariableKind.INTERMEDIATE)
            prev_mask_lc = LinearCombination.from_var(prefix_masks[-1], 1, self.field_modulus)
            curr_eq_lc = LinearCombination.from_var(eq_vars[k], 1, self.field_modulus)

            # Constraint: prev_mask * eq_k == step_mask
            self.system.add_constraint(
                a=prev_mask_lc,
                b=curr_eq_lc,
                c=LinearCombination.from_var(step_mask, 1, self.field_modulus),
                comment=f"Prefix cumprod step {k} ({name_prefix})",
            )
            prefix_masks.append(step_mask)

        final_mask_var = prefix_masks[-1]

        return {
            "eq_vars": eq_vars,
            "inv_vars": inv_vars,
            "prefix_masks": prefix_masks,
            "mask_var": final_mask_var,
        }

    def add_non_interference_constraint(
        self,
        mask_var: int,
        forbidden: bool = True,
        comment: str = "Non-interference safety guard",
    ) -> int:
        """Enforce non-interference safety: forbidden connection must have mask_var == 0.
        
        Args:
            mask_var: Variable representing the LCA connection status (1 = connected, 0 = isolated).
            forbidden: If True, strictly enforces mask_var == 0.
                       If False, enforces mask_var == 1 (mandatory connection).
            comment: Optional constraint comment.
            
        Returns:
            Constraint index in the R1CS system.
        """
        expected_val = 0 if forbidden else 1
        return self.system.add_constraint(
            a=LinearCombination.from_var(mask_var, 1, self.field_modulus),
            b=LinearCombination.from_constant(1, self.field_modulus),
            c=LinearCombination.from_constant(expected_val, self.field_modulus),
            comment=f"{comment} (expected: {expected_val})",
        )

    def build_pairwise_lca_system(
        self,
        p: int,
        depth: int,
        req_depth: int,
        forbidden: Optional[bool] = None,
    ) -> Tuple[R1CSSystem, int, int, int]:
        """Construct a complete R1CS circuit verifying LCA routing for a pair of tokens (u, v).
        
        Args:
            p: Tree branching factor.
            depth: Full tree depth D.
            req_depth: Required LCA prefix depth.
            forbidden: If specified (True or False), adds non-interference constraint.
            
        Returns:
            Tuple of (system, u_var, v_var, mask_var).
        """
        u_var = self.system.allocate_var("u_idx", kind=VariableKind.PUBLIC_INPUT)
        v_var = self.system.allocate_var("v_idx", kind=VariableKind.PUBLIC_INPUT)

        u_digits = self.add_digit_decomposition(u_var, p, depth, msb_first=True, name_prefix="u_digit")
        v_digits = self.add_digit_decomposition(v_var, p, depth, msb_first=True, name_prefix="v_digit")

        lca_res = self.add_prefix_equality(u_digits, v_digits, req_depth, name_prefix="pair_lca")
        mask_var = lca_res["mask_var"]

        if forbidden is not None:
            self.add_non_interference_constraint(mask_var, forbidden=forbidden)

        return self.system, u_var, v_var, mask_var

    def build_block_routing_system(
        self,
        num_blocks: int,
        p: int,
        depth: int,
        req_depth: int,
        forbidden_pairs: Optional[List[Tuple[int, int]]] = None,
    ) -> Tuple[R1CSSystem, List[int], Dict[Tuple[int, int], int]]:
        """Construct a complete block-routing R1CS circuit for multi-head attention.
        
        Args:
            num_blocks: Number of sequence / token blocks N.
            p: Tree arity.
            depth: Tree depth D.
            req_depth: Common ancestor depth required for attention.
            forbidden_pairs: List of block index pairs (i, j) forbidden from attending.
            
        Returns:
            Tuple of:
                - system: complete R1CSSystem
                - block_vars: list of allocated block input variables [B_0, ..., B_{N-1}]
                - routing_mask_vars: map (i, j) -> mask variable index
        """
        block_vars = [
            self.system.allocate_var(f"block_{i}", kind=VariableKind.PUBLIC_INPUT)
            for i in range(num_blocks)
        ]

        # Decompose each block into tree digits
        block_digits: List[List[int]] = []
        for i, b_var in enumerate(block_vars):
            digits = self.add_digit_decomposition(
                b_var, p, depth, msb_first=True, name_prefix=f"b{i}_digit"
            )
            block_digits.append(digits)

        # Compute routing masks for all unique pairs (i, j)
        routing_mask_vars: Dict[Tuple[int, int], int] = {}
        for i in range(num_blocks):
            for j in range(num_blocks):
                if i == j:
                    # Self-routing is always 1 (trivial match)
                    self_mask = self.system.allocate_var(f"mask_{i}_{j}", kind=VariableKind.OUTPUT)
                    self.system.add_constraint(
                        a=LinearCombination.from_var(self_mask, 1, self.field_modulus),
                        b=LinearCombination.from_constant(1, self.field_modulus),
                        c=LinearCombination.from_constant(1, self.field_modulus),
                        comment=f"Self-routing identity ({i},{j})",
                    )
                    routing_mask_vars[(i, j)] = self_mask
                elif (j, i) in routing_mask_vars:
                    # Symmetric routing
                    routing_mask_vars[(i, j)] = routing_mask_vars[(j, i)]
                else:
                    lca_res = self.add_prefix_equality(
                        block_digits[i],
                        block_digits[j],
                        req_depth,
                        name_prefix=f"route_{i}_{j}",
                    )
                    m_var = lca_res["mask_var"]
                    routing_mask_vars[(i, j)] = m_var

        # Apply non-interference constraints to forbidden block pairs
        if forbidden_pairs:
            for u_idx, v_idx in forbidden_pairs:
                if (u_idx, v_idx) in routing_mask_vars:
                    m_var = routing_mask_vars[(u_idx, v_idx)]
                    self.add_non_interference_constraint(
                        m_var,
                        forbidden=True,
                        comment=f"Safety guard for forbidden pair ({u_idx}, {v_idx})",
                    )

        return self.system, block_vars, routing_mask_vars

    # ========================================================================
    # Witness Generation & Verification
    # ========================================================================

    def generate_witness(
        self,
        u_idx: int,
        v_idx: int,
        p: int,
        depth: int,
        req_depth: int,
        msb_first: bool = True,
        forbidden: Optional[bool] = None,
    ) -> Dict[int, int]:
        """Compute the full algebraic witness assignment for a pairwise LCA circuit.
        
        Args:
            u_idx: Discrete index of node u in [0, p^depth - 1].
            v_idx: Discrete index of node v in [0, p^depth - 1].
            p: Tree branching factor.
            depth: Full tree depth D.
            req_depth: Required LCA prefix depth.
            msb_first: Digit ordering (MSB at index 0).
            forbidden: If specified, validates non-interference expectation.
            
        Returns:
            Dictionary mapping every variable index to its field element value in F_r.
        """
        r = self.field_modulus
        w: Dict[int, int] = {0: 1}  # ONE wire

        # 1. Extract digits for u and v
        u_digits_val = self._extract_digits(u_idx, p, depth, msb_first)
        v_digits_val = self._extract_digits(v_idx, p, depth, msb_first)

        u_var = self.system.var_name_to_idx.get("u_idx", 1)
        v_var = self.system.var_name_to_idx.get("v_idx", 2)
        w[u_var] = u_idx % r
        w[v_var] = v_idx % r

        # Digits for u
        for k in range(depth):
            d_name = f"u_digit_{k}"
            if d_name in self.system.var_name_to_idx:
                d_idx = self.system.var_name_to_idx[d_name]
                d_val = u_digits_val[k]
                w[d_idx] = d_val % r
                self._populate_range_witness(w, d_idx, d_val, p, f"range_u_digit_{k}")

        # Digits for v
        for k in range(depth):
            d_name = f"v_digit_{k}"
            if d_name in self.system.var_name_to_idx:
                d_idx = self.system.var_name_to_idx[d_name]
                d_val = v_digits_val[k]
                w[d_idx] = d_val % r
                self._populate_range_witness(w, d_idx, d_val, p, f"range_v_digit_{k}")

        # LCA Prefix Equality & Inverse Wires
        if req_depth == 0:
            mask_0_name = "pair_lca_mask_0"
            if mask_0_name in self.system.var_name_to_idx:
                w[self.system.var_name_to_idx[mask_0_name]] = 1
        else:
            cum_mask = 1
            for k in range(req_depth):
                u_d = u_digits_val[k]
                v_d = v_digits_val[k]
                delta = (u_d - v_d) % r

                eq_k = 1 if delta == 0 else 0
                inv_k = 0 if delta == 0 else mod_inv(delta, r)

                eq_var_name = f"pair_lca_eq_{k}"
                inv_var_name = f"pair_lca_inv_{k}"

                if eq_var_name in self.system.var_name_to_idx:
                    w[self.system.var_name_to_idx[eq_var_name]] = eq_k
                if inv_var_name in self.system.var_name_to_idx:
                    w[self.system.var_name_to_idx[inv_var_name]] = inv_k

                cum_mask = (cum_mask * eq_k) % r
                if k > 0:
                    cum_var_name = f"pair_lca_cum_mask_{k}"
                    if cum_var_name in self.system.var_name_to_idx:
                        w[self.system.var_name_to_idx[cum_var_name]] = cum_mask

        return w

    def generate_block_routing_witness(
        self,
        block_indices: List[int],
        p: int,
        depth: int,
        req_depth: int,
        msb_first: bool = True,
    ) -> Dict[int, int]:
        """Compute full witness for an N-block attention routing circuit.
        
        Args:
            block_indices: List of N block IDs [B_0, ..., B_{N-1}].
            p: Tree branching factor.
            depth: Tree depth D.
            req_depth: Common ancestor depth required for attention.
            msb_first: Digit ordering (MSB at index 0).
            
        Returns:
            Dictionary mapping every variable index to its field element value in F_r.
        """
        r = self.field_modulus
        w: Dict[int, int] = {0: 1}  # ONE wire
        num_blocks = len(block_indices)

        # 1. Assign block input variables and digit decompositions
        all_block_digits: List[List[int]] = []
        for i, b_idx in enumerate(block_indices):
            b_var_name = f"block_{i}"
            if b_var_name in self.system.var_name_to_idx:
                w[self.system.var_name_to_idx[b_var_name]] = b_idx % r

            digits_val = self._extract_digits(b_idx, p, depth, msb_first)
            all_block_digits.append(digits_val)

            for k in range(depth):
                d_name = f"b{i}_digit_{k}"
                if d_name in self.system.var_name_to_idx:
                    d_var = self.system.var_name_to_idx[d_name]
                    d_val = digits_val[k]
                    w[d_var] = d_val % r
                    self._populate_range_witness(w, d_var, d_val, p, f"range_b{i}_digit_{k}")

        # 2. Pairwise prefix routing masks
        for i in range(num_blocks):
            for j in range(num_blocks):
                if i == j:
                    self_mask_name = f"mask_{i}_{j}"
                    if self_mask_name in self.system.var_name_to_idx:
                        w[self.system.var_name_to_idx[self_mask_name]] = 1
                elif i < j:
                    prefix = f"route_{i}_{j}"
                    if req_depth == 0:
                        mask_0_name = f"{prefix}_mask_0"
                        if mask_0_name in self.system.var_name_to_idx:
                            w[self.system.var_name_to_idx[mask_0_name]] = 1
                    else:
                        cum_mask = 1
                        for k in range(req_depth):
                            u_d = all_block_digits[i][k]
                            v_d = all_block_digits[j][k]
                            delta = (u_d - v_d) % r

                            eq_k = 1 if delta == 0 else 0
                            inv_k = 0 if delta == 0 else mod_inv(delta, r)

                            eq_name = f"{prefix}_eq_{k}"
                            inv_name = f"{prefix}_inv_{k}"
                            if eq_name in self.system.var_name_to_idx:
                                w[self.system.var_name_to_idx[eq_name]] = eq_k
                            if inv_name in self.system.var_name_to_idx:
                                w[self.system.var_name_to_idx[inv_name]] = inv_k

                            cum_mask = (cum_mask * eq_k) % r
                            if k > 0:
                                cum_name = f"{prefix}_cum_mask_{k}"
                                if cum_name in self.system.var_name_to_idx:
                                    w[self.system.var_name_to_idx[cum_name]] = cum_mask

        return w

    def verify_witness(
        self,
        witness: Union[Sequence[int], Dict[int, int]],
    ) -> Tuple[bool, Optional[int], Optional[str]]:
        """Verify witness against all constraints in the builder's system."""
        return self.system.verify_witness(witness)

    # ------------------------------------------------------------------------
    # Private Helpers
    # ------------------------------------------------------------------------

    @staticmethod
    def _extract_digits(val: int, p: int, depth: int, msb_first: bool = True) -> List[int]:
        """Extract base-p digits for integer val in [0, p^depth - 1]."""
        digits = []
        rem = val
        for _ in range(depth):
            digits.append(rem % p)
            rem //= p

        if msb_first:
            digits.reverse()
        return digits

    def _populate_range_witness(
        self,
        w: Dict[int, int],
        d_var: int,
        d_val: int,
        p: int,
        prefix: str,
    ) -> None:
        """Populate intermediate polynomial accumulator wires for range checks."""
        r = self.field_modulus
        if p <= 2:
            return

        # acc_1 = (d - 0) * (d - 1)
        acc_1_name = f"{prefix}_acc1"
        if acc_1_name in self.system.var_name_to_idx:
            acc_1_val = ((d_val - 0) * (d_val - 1)) % r
            w[self.system.var_name_to_idx[acc_1_name]] = acc_1_val

            curr_val = acc_1_val
            for j in range(2, p - 1):
                acc_j_name = f"{prefix}_acc{j}"
                if acc_j_name in self.system.var_name_to_idx:
                    curr_val = (curr_val * (d_val - j)) % r
                    w[self.system.var_name_to_idx[acc_j_name]] = curr_val


# ============================================================================
# Self-Contained Verification / Module Entry
# ============================================================================

if __name__ == "__main__":
    print("=== P-Adic R1CS Verification Test ===")
    
    # Test 1: Pairwise LCA (p=2, depth=4, req_depth=2)
    # Tree nodes: u = 10 (binary 1010), v = 11 (binary 1011), w = 12 (binary 1100)
    # u and v share prefix '10' (length 2) -> LCA depth >= 2 -> mask should be 1
    # u and w share prefix '1' (length 1)  -> LCA depth < 2  -> mask should be 0
    p = 2
    depth = 4
    req_depth = 2

    # Case A: (u, v) should match
    builder_match = PAdicLCAConstraintBuilder()
    sys_match, u_v, v_v, m_v = builder_match.build_pairwise_lca_system(p, depth, req_depth)
    w_match = builder_match.generate_witness(10, 11, p, depth, req_depth)
    valid, fail_idx, err = sys_match.verify_witness(w_match)
    assert valid, f"Match witness failed: {err}"
    assert w_match[m_v] == 1, f"Expected mask=1, got {w_match[m_v]}"
    print(f"[PASS] Match witness (u=10, v=11) verified. Mask={w_match[m_v]}")

    # Case B: (u, w) should not match
    builder_mismatch = PAdicLCAConstraintBuilder()
    sys_mismatch, u_v2, v_v2, m_v2 = builder_mismatch.build_pairwise_lca_system(p, depth, req_depth)
    w_mismatch = builder_mismatch.generate_witness(10, 12, p, depth, req_depth)
    valid, fail_idx, err = sys_mismatch.verify_witness(w_mismatch)
    assert valid, f"Mismatch witness failed: {err}"
    assert w_mismatch[m_v2] == 0, f"Expected mask=0, got {w_mismatch[m_v2]}"
    print(f"[PASS] Mismatch witness (u=10, w=12) verified. Mask={w_mismatch[m_v2]}")

    # Case C: Non-interference enforcement
    # Forbidden pair (10, 11): should FAIL because mask == 1 but constraint demands mask == 0
    builder_forbidden = PAdicLCAConstraintBuilder()
    sys_forbidden, _, _, _ = builder_forbidden.build_pairwise_lca_system(p, depth, req_depth, forbidden=True)
    w_forb_bad = builder_forbidden.generate_witness(10, 11, p, depth, req_depth)
    valid, fail_idx, _ = sys_forbidden.verify_witness(w_forb_bad)
    assert not valid, "Forbidden pair (10, 11) should have been rejected!"
    print(f"[PASS] Non-interference security guard correctly rejected forbidden connection (constraint #{fail_idx} failed).")

    # Forbidden pair (10, 12): should SUCCEED because mask == 0 satisfying non-interference
    builder_forbidden2 = PAdicLCAConstraintBuilder()
    sys_forbidden2, _, _, _ = builder_forbidden2.build_pairwise_lca_system(p, depth, req_depth, forbidden=True)
    w_forb_good = builder_forbidden2.generate_witness(10, 12, p, depth, req_depth)
    valid, _, err = sys_forbidden2.verify_witness(w_forb_good)
    assert valid, f"Valid non-interfering pair rejected: {err}"
    print(f"[PASS] Non-interference security guard allowed isolated pair (u=10, w=12).")

    # Test 2: Multi-block Attention Routing System (p=3, depth=3, req_depth=2, 4 blocks)
    p3 = 3
    d3 = 3
    req3 = 2
    blocks = [0, 1, 3, 9]
    forbidden_list = [(0, 2), (1, 3)]
    
    routing_builder = PAdicLCAConstraintBuilder()
    route_sys, b_vars, mask_vars = routing_builder.build_block_routing_system(
        num_blocks=len(blocks), p=p3, depth=d3, req_depth=req3, forbidden_pairs=forbidden_list
    )
    w_route = routing_builder.generate_block_routing_witness(blocks, p3, d3, req3)
    valid, fail_idx, err = route_sys.verify_witness(w_route)
    assert valid, f"Block routing witness failed: {err}"
    print(f"[PASS] Multi-block routing system verified! {route_sys.summary()}")
    print("All R1CS verification checks passed successfully.")
