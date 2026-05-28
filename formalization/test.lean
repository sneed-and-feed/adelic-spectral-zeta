import Mathlib

example (F : Type _) [Field F] (μ : F) (l : ℕ) : (-μ)^(2*l) = μ^(2*l) := by
  rw [pow_mul, neg_sq, ←pow_mul]
