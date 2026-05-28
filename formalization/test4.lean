import Mathlib

variable (A B C D : Matrix (ZMod 2) (ZMod 2) ℂ)

lemma test : Matrix.kronecker A B * Matrix.kronecker C D = Matrix.kronecker (A * C) (B * D) := by
  rw [← Matrix.mul_kronecker_mul]
