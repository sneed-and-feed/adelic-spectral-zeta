import Formalization.Dynamics.CollatzRelMatrix

open Matrix

/-- 
The Tai Chi Mallard Theorem / Straight Circles Topology Conjecture:

Empirical computation verifies that for all n ≥ 3, the twisted directed block
matrix raised to the 2^(n-1) power is exactly -2 * I.
At n = 2, the microscopic topology evaluates to +2 * I.
-/
def TwistedBlockPowConjecture (n : ℕ) (_hn3 : n ≥ 3) : Prop :=
  (CollatzDirMatrix.twistedDirMatrix (by omega)) ^ (2^(n-1)) = -2 * (1 : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) ℚ)
