import Mathlib
import Formalization.CollatzRelMatrix

open CollatzDirMatrix

lemma fiber_sum_identity_proof (n : ℕ) (hn : n ≥ 2) (v u : ZMod (2^(n-1))) :
    collatzDirMatrix n (liftDir v) (liftDir u) +
    collatzDirMatrix n (liftDir v) (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) =
    collatzDirMatrix (n-1) v u := by
  simp only [collatzDirMatrix]
  sorry
