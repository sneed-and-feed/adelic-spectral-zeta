import Mathlib.Data.ZMod.Basic
import Mathlib.GroupTheory.SpecificGroups.Cyclic

/--
The cycle of 1 under multiplication by 3 modulo 2^n.
-/
def cycle_one (n : ℕ) : Set (ZMod (2^n)) :=
  {x | ∃ k : ℕ, x = 3^k}

/--
The cycle of -1 under multiplication by 3 modulo 2^n.
-/
def cycle_minus_one (n : ℕ) : Set (ZMod (2^n)) :=
  {x | ∃ k : ℕ, x = -(3^k)}

/--
For n ≥ 3, the odd residues are exactly the union of cycle_one and cycle_minus_one.
-/
lemma odd_residues_decomposition (n : ℕ) (hn : 3 ≤ n) :
  ∀ x : ZMod (2^n), (Even x.val) ∨ x ∈ cycle_one n ∨ x ∈ cycle_minus_one n := by
  sorry
