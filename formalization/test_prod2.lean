import Mathlib
import Mathlib.RingTheory.RootsOfUnity.Basic
import Mathlib.RingTheory.Polynomial.Cyclotomic.Eval

open Polynomial Finset

variable {F : Type _} [Field F] {n : ℕ} (zeta : F) (hzeta : IsPrimitiveRoot zeta (2^n))

lemma test3 (hn : 2 ≤ n) : 
  ∏ x ∈ {x : ZMod (2^n) | Odd x.val}.toFinset, (1 + zeta ^ (-x).val) = ∏ x ∈ {x : ZMod (2^n) | Odd x.val}.toFinset, (1 + zeta ^ x.val) := by
  refine prod_bij (fun x _ => -x) ?_ ?_ ?_ ?_
  · intro x hx
    simp only [Set.mem_toFinset, Set.mem_setOf_eq] at hx ⊢
    -- proof that Odd (-x).val
    sorry
  · intro x hx y hy eq1
    exact neg_inj.mp eq1
  · intro y hy
    use -y
    constructor
    · simp only [Set.mem_toFinset, Set.mem_setOf_eq] at hy ⊢
      sorry
    · exact neg_neg y
  · intro x _
    simp
