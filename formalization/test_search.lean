import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Says

lemma test_div (a b c : ℝ) (hc : 0 < c) (h : a ≤ b * c) : a / c ≤ b := by
  exact?
