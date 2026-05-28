import Mathlib
import Formalization.CollatzRelMatrix

open Matrix

variable {n : ℕ} (hn : n ≥ 2)

/-- 
The Tai Chi Mallard Theorem (Straight Circles Topology)
The twisted directed block matrix raised to the 2^(n-1) power is exactly -2 * I.
This occurs because the state space partitions into exactly 2 disjoint cycles.
-/
theorem twistedPow_eq_neg_two :
  (CollatzDirMatrix.twistedDirMatrix hn) ^ (2^(n-1)) = -2 * (1 : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) ℚ) := by
  sorry
