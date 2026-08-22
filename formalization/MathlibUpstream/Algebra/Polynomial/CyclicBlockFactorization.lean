import Mathlib.Algebra.Polynomial.Basic
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Algebra.Polynomial.BigOperators
import Mathlib.Algebra.BigOperators.Intervals

/-!
# Polynomial Cyclic Block Factorizations

This file formalizes general algebraic polynomial identities for the factorization of cyclic
block Fredholm determinants over an arbitrary commutative ring `R`.

## Main Results
- `cyclic_block_polynomial_prod`: For any cycle length `L` and weights `W₁, W₂ ∈ R`:
  `(1 - C W₁ * X ^ L) * (1 - C W₂ * X ^ L) = 1 - C (W₁ + W₂) * X ^ L + C (W₁ * W₂) * X ^ (2 * L)`.
- `cyclic_block_fredholm_product`: When `W₁ + W₂ = 0` and `W₁ * W₂ = c`, the product simplifies to
  `1 + C c * X ^ (2 * L)`.
- `cyclic_block_fredholm_two`: Specialization to `c = 2`:
  `(1 - C W₁ * X ^ L) * (1 - C W₂ * X ^ L) = 1 + 2 * X ^ (2 * L)`.

## Tags
polynomial, cyclic block, fredholm determinant, factorization
-/

open Polynomial Finset
open scoped Polynomial

variable {R : Type*} [CommRing R]

/-- The general algebraic expansion of a product of two cyclic block factors. -/
theorem cyclic_block_polynomial_prod (L : ℕ) (W1 W2 : R) :
    (1 - C W1 * X ^ L) * (1 - C W2 * X ^ L) =
    1 - C (W1 + W2) * X ^ L + C (W1 * W2) * X ^ (2 * L) := by
  have h_mul : (C W1 * X ^ L) * (C W2 * X ^ L) = C (W1 * W2) * X ^ (2 * L) := by
    calc (C W1 * X ^ L) * (C W2 * X ^ L)
      _ = (C W1 * C W2) * (X ^ L * X ^ L) := by ring
      _ = C (W1 * W2) * (X ^ L * X ^ L) := by rw [← map_mul]
      _ = C (W1 * W2) * X ^ (L + L) := by rw [← pow_add]
      _ = C (W1 * W2) * X ^ (2 * L) := by ring_nf
  have h_cross : (C W1 * X ^ L) + (C W2 * X ^ L) = C (W1 + W2) * X ^ L := by
    calc (C W1 * X ^ L) + (C W2 * X ^ L)
      _ = (C W1 + C W2) * X ^ L := by ring
      _ = C (W1 + W2) * X ^ L := by rw [← map_add]
  calc (1 - C W1 * X ^ L) * (1 - C W2 * X ^ L)
    _ = 1 - (C W1 * X ^ L + C W2 * X ^ L) + (C W1 * X ^ L) * (C W2 * X ^ L) := by ring
    _ = 1 - C (W1 + W2) * X ^ L + C (W1 * W2) * X ^ (2 * L) := by rw [h_cross, h_mul]

/-- When the sum of cyclic weights vanishes and their product equals `c`, the product of
    their characteristic polynomial factors collapses to `1 + C c * X ^ (2 * L)`. -/
theorem cyclic_block_fredholm_product (L : ℕ) (W1 W2 : R) (c : R)
    (h_sum : W1 + W2 = 0) (h_prod : W1 * W2 = c) :
    (1 - C W1 * X ^ L) * (1 - C W2 * X ^ L) = 1 + C c * X ^ (2 * L) := by
  rw [cyclic_block_polynomial_prod, h_sum, h_prod, map_zero, zero_mul, sub_zero]

/-- Instantiation of the cyclic block identity for weight product `2`. -/
theorem cyclic_block_fredholm_two (L : ℕ) (W1 W2 : R)
    (h_sum : W1 + W2 = 0) (h_prod : W1 * W2 = 2) :
    (1 - C W1 * X ^ L) * (1 - C W2 * X ^ L) = (1 + 2 * X ^ (2 * L) : Polynomial R) := by
  rw [cyclic_block_fredholm_product L W1 W2 2 h_sum h_prod]
  have h2 : C (2 : R) = (2 : Polynomial R) := by simp only [map_ofNat]
  rw [h2]
