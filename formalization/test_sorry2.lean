import Mathlib
import Mathlib.Algebra.Order.Ring.Defs

open PowerSeries

def divisor_sum_11 (n : ℕ) : ℤ :=
  (Finset.filter (fun d => n % d = 0) (Finset.Icc 1 n)).sum (fun d => (d : ℤ) ^ 11)

noncomputable def E_12 : PowerSeries ℚ :=
  PowerSeries.mk fun n => if n = 0 then 1 else (65520 / 691) * (divisor_sum_11 n : ℚ)

noncomputable def Delta_Q : PowerSeries ℚ :=
  PowerSeries.mk fun n => (1 : ℚ)

example (a b : ℚ) (tau_zero : coeff ℚ 0 Delta_Q = 0) : 
  coeff ℚ 0 (a • E_12 + b • Delta_Q) = a * 1 + b * 0 := by
  simp [E_12, tau_zero]
