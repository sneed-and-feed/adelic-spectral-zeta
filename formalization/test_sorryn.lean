import Mathlib
import Mathlib.Algebra.Order.Ring.Defs

open PowerSeries

def divisor_sum_11 (n : ℕ) : ℤ :=
  (Finset.filter (fun d => n % d = 0) (Finset.Icc 1 n)).sum (fun d => (d : ℤ) ^ 11)

noncomputable def E_12 : PowerSeries ℚ :=
  PowerSeries.mk fun n => if n = 0 then 1 else (65520 / 691) * (divisor_sum_11 n : ℚ)

noncomputable def Delta_Q : PowerSeries ℚ :=
  PowerSeries.mk fun n => (1 : ℚ) -- just dummy

example (n : ℕ) (hn : n > 0) (a b : ℚ) : 
  coeff ℚ n (a • E_12 + b • Delta_Q) = a * ((65520 / 691) * (divisor_sum_11 n : ℚ)) + b * (1 : ℚ) := by
  simp [E_12, Delta_Q, ne_of_gt hn]
