import Mathlib
open Polynomial Matrix PowerSeries

variable (P : PowerSeries Complex) (h : coeff Complex 0 P = 1)
#check P⁻¹ * P = 1

