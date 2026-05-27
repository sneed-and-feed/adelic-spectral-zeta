import Mathlib.Data.ZMod.Basic
import Mathlib.RingTheory.RootsOfUnity.Basic
import Mathlib.RingTheory.Polynomial.Cyclotomic.Eval
import Mathlib.Algebra.BigOperators.Group.Finset
import Mathlib.Algebra.BigOperators.Ring

open Polynomial
open Finset

variable {F : Type _} [Field F]

lemma neg_mem_primitive_roots (n : ℕ) (hn : 2 ≤ n) {μ : F} (hμ : μ ∈ primitiveRoots (2^n) F) :
  -μ ∈ primitiveRoots (2^n) F := by
  have hz : IsPrimitiveRoot μ (2^n) := (mem_primitiveRoots (by positivity)).mp hμ
  have h1 : -μ = μ ^ (1 + 2^(n-1)) := by
    have h2 : μ ^ (2^(n-1)) = -1 := by
      -- we can use IsPrimitiveRoot.pow_eq_neg_one
      -- or just IsPrimitiveRoot.pow_two_pow_sub_one or something?
      sorry
    calc
      -μ = μ * -1 := by ring
      _ = μ * μ ^ (2^(n-1)) := by rw [h2]
      _ = μ ^ 1 * μ ^ (2^(n-1)) := by rw [pow_one]
      _ = μ ^ (1 + 2^(n-1)) := by rw [← pow_add]
  rw [h1]
  apply (mem_primitiveRoots (by positivity)).mpr
  apply IsPrimitiveRoot.pow_of_coprime hz
  -- need to show gcd(1 + 2^{n-1}, 2^n) = 1
  sorry
