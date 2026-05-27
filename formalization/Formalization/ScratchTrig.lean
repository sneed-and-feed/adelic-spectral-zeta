import Mathlib.Data.Complex.Basic
import Mathlib.Data.Complex.Exponential
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Algebra.Group.AddChar
import Mathlib.LinearAlgebra.Matrix.Spectrum

open Real

lemma sum_sin_mul_sin (L : ℕ) (j : ℕ) :
  2 * sin (pi * (j + 1) / (L + 1)) * sin (pi * (j + 2) / (L + 1)) =
  cos (pi / (L + 1)) - cos (pi * (2 * j + 3) / (L + 1)) := by
  have h := Real.cos_sub_cos (pi / (L + 1)) (pi * (2 * j + 3) / (L + 1))
  have h1 : (pi / (L + 1) + pi * (2 * j + 3) / (L + 1)) / 2 = pi * (j + 2) / (L + 1) := by ring
  have h2 : (pi / (L + 1) - pi * (2 * j + 3) / (L + 1)) / 2 = -(pi * (j + 1) / (L + 1)) := by ring
  rw [h1, h2] at h
  rw [Real.sin_neg] at h
  linarith
