import Mathlib

open Classical

lemma mod_cases (n : ℕ) (hn : n ≥ 2) (A B : ZMod (2^n)) :
  A.val % 2^(n-1) = B.val % 2^(n-1) ↔ A = B ∨ A = B + ((2^(n-1) : ℕ) : ZMod (2^n)) := by
  sorry
