import Mathlib.Data.ZMod.Basic

def cycle_one (n : ℕ) : Set (ZMod (2^n)) := {x | ∃ k : ℕ, x = 3^k}
def cycle_minus_one (n : ℕ) : Set (ZMod (2^n)) := {x | ∃ k : ℕ, x = -(3^k)}

/-- The 3-adic cycle decomposition proposition for odd residues in ZMod (2^n) -/
def OddResiduesDecomposition (n : ℕ) : Prop :=
  ∀ x : ZMod (2^n), (Even x.val) ∨ x ∈ cycle_one n ∨ x ∈ cycle_minus_one n
