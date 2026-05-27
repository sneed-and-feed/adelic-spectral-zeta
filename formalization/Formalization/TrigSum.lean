import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Algebra.BigOperators.Group.Finset
import Mathlib.Data.Finset.Interval
import Mathlib.Data.Real.Basic

open Finset BigOperators
open Real

lemma sin_cos_telescope_term (L : ℝ) (j : ℝ) :
    2 * sin (Real.pi / (L + 1)) * cos (Real.pi * (2 * j + 3) / (L + 1)) =
    sin (Real.pi * (2 * j + 4) / (L + 1)) - sin (Real.pi * (2 * j + 2) / (L + 1)) := by
  have h1 : Real.pi * (2 * j + 4) / (L + 1) = Real.pi * (2 * j + 3) / (L + 1) + Real.pi / (L + 1) := by ring
  have h2 : Real.pi * (2 * j + 2) / (L + 1) = Real.pi * (2 * j + 3) / (L + 1) - Real.pi / (L + 1) := by ring
  rw [h1, h2]
  rw [Real.sin_add, Real.sin_sub]
  ring

lemma cos_sum_telescope_real (L : ℝ) (n : ℕ) :
    Finset.sum (range n) (fun (j : ℕ) => 2 * sin (Real.pi / (L + 1)) * cos (Real.pi * (2 * (j : ℝ) + 3) / (L + 1))) =
    sin (Real.pi * (2 * (n : ℝ) + 2) / (L + 1)) - sin (Real.pi * 2 / (L + 1)) := by
  induction n with
  | zero =>
    simp
  | succ n ih =>
    rw [sum_range_succ, ih]
    have hterm := sin_cos_telescope_term L (n : ℝ)
    have hn : ((n + 1 : ℕ) : ℝ) = (n : ℝ) + 1 := Nat.cast_add_one n
    have harg : Real.pi * (2 * ((n + 1 : ℕ) : ℝ) + 2) / (L + 1) = Real.pi * (2 * (n : ℝ) + 4) / (L + 1) := by
      rw [hn]
      ring
    rw [harg]
    linarith

lemma cos_sum_telescope (L : ℕ) (hL : L ≥ 1) :
    Finset.sum (range (L - 1)) (fun (j : ℕ) => 2 * sin (Real.pi / ((L : ℝ) + 1)) * cos (Real.pi * (2 * (j : ℝ) + 3) / ((L : ℝ) + 1))) =
    sin (Real.pi * (2 * (L : ℝ)) / ((L : ℝ) + 1)) - sin (Real.pi * 2 / ((L : ℝ) + 1)) := by
  have h := cos_sum_telescope_real (L : ℝ) (L - 1)
  have hn : ((L - 1 : ℕ) : ℝ) = (L : ℝ) - 1 := by
    rw [Nat.cast_sub hL, Nat.cast_one]
  have harg : Real.pi * (2 * ((L - 1 : ℕ) : ℝ) + 2) / ((L : ℝ) + 1) = Real.pi * (2 * (L : ℝ)) / ((L : ℝ) + 1) := by
    rw [hn]
    ring
  rw [harg] at h
  exact h
