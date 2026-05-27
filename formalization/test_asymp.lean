import Mathlib.Analysis.Asymptotics.Asymptotics
import Mathlib.Data.Real.Basic
open Asymptotics Filter

lemma bigo_const (f : ℕ → ℝ) (hf : ∀ d ≥ 1, f d ≥ 2) :
    IsBigO atTop (fun d : ℕ => (1 : ℝ) / (d : ℝ)^2) f := by
  apply IsBigO.of_bound 1
  filter_upwards [Ici_mem_atTop 1] with d hd
  have h1 : ‖(1 : ℝ) / (d : ℝ)^2‖ ≤ 1 := by
    rw [Real.norm_eq_abs, abs_div, abs_one, abs_of_nonneg (sq_nonneg _)]
    have : (d : ℝ) ≥ 1 := Nat.one_le_cast.mpr hd
    have hsq : (d : ℝ)^2 ≥ 1 := by nlinarith
    have h_pos : (d : ℝ)^2 > 0 := by linarith
    exact (div_le_iff h_pos).mpr (by linarith)
  have h2 : 1 * ‖f d‖ = ‖f d‖ := one_mul _
  rw [h2]
  have h3 : f d ≥ 2 := hf d hd
  have h4 : ‖f d‖ ≥ 2 := by
    rw [Real.norm_eq_abs, abs_of_nonneg (by linarith)]
    linarith
  linarith
