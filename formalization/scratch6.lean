import Mathlib
import Formalization.RamanujanTau

open PowerSeries

lemma tau_two : tau 2 = -24 := by
  dsimp [tau, ramanujan_trunc]
  sorry
