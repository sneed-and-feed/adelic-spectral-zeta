import Mathlib

variable (A B : Matrix (ZMod 2) (ZMod 2) ℂ)
variable (C D : Matrix (ZMod 2) (ZMod 2) ℂ)

#check Matrix.mul_kronecker_mul A C B D
