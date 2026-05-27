import Mathlib
import Formalization.RamanujanTau
open PowerSeries
lemma tau_one : tau 1 = 1 := by
  dsimp [tau]
  rw [coeff_succ_X_mul, ramanujan_trunc]
  -- \prod (1 - X^(n+1))^24
  sorry
