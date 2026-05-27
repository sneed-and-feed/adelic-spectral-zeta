import Mathlib
import Formalization.RamanujanTau

open PowerSeries

lemma tau_one : tau 1 = 1 := by
  dsimp [tau, ramanujan_trunc, X_series]
  -- we want coeff ℤ 1 (X * prod_{n=0}^0 ...)
  -- which is coeff ℤ 1 (X * 1)
  -- wait, Finset.range 1 is {0}, so n = 0, meaning (1 - X^1)^24
  -- Wait! ramanujan_trunc 1 is (1 - X)^24.
  -- X * ramanujan_trunc 1 is X * (1 - X)^24.
  -- coeff ℤ 1 of that is the constant term of (1 - X)^24, which is 1.
  sorry
