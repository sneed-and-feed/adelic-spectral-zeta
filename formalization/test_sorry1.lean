import Mathlib
import Mathlib.Algebra.Order.Ring.Defs

open PowerSeries

example (F_int : PowerSeries ℤ) (hF_0 : coeff ℤ 0 F_int = 1) : 
  coeff ℚ 0 (PowerSeries.map (algebraMap ℤ ℚ) F_int) = 1 := by
  simp [hF_0]
