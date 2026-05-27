import Mathlib
open PowerSeries
def X_series : PowerSeries ℤ := X
def ramanujan_trunc (N : ℕ) : PowerSeries ℤ :=
  (Finset.range N).prod (fun n => (1 - (X_series ^ (n + 1))) ^ 24)
def tau (n : ℕ) : ℤ :=
  coeff ℤ n (X_series * ramanujan_trunc n)
