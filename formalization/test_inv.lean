import Mathlib
open Polynomial Matrix PowerSeries

variable (P : PowerSeries Complex) (h : P.coeff 0 = 1)
#check P⁻¹ * P = 1

