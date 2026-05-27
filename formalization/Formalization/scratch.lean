import Mathlib.Data.Complex.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Algebra.BigOperators.Group.Finset
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Finset.Interval
import Mathlib.Data.Real.Basic

open Finset BigOperators
open Real

lemma sin_mul_cos_add (x y : ℝ) : 2 * sin x * cos y = sin (x - y) + sin (x + y) := by
  have h1 : sin (x + y) = sin x * cos y + cos x * sin y := sin_add x y
  have h2 : sin (x - y) = sin x * cos y - cos x * sin y := sin_sub x y
  linarith

noncomputable def u_val (L : ℕ) (j : ℤ) : ℝ := sin (Real.pi * (j + 1) / (L + 1))

lemma u_val_recurrence (L : ℕ) (j : ℤ) :
    2 * u_val L j * cos (Real.pi / (L + 1)) = u_val L (j - 1) + u_val L (j + 1) := by
  unfold u_val
  have h := sin_mul_cos_add (Real.pi * (j + 1) / (L + 1)) (Real.pi / (L + 1))
  have hc1 : ((j - 1 : ℤ) : ℝ) + 1 = (j : ℝ) := by push_cast; ring
  have hc2 : ((j + 1 : ℤ) : ℝ) + 1 = (j : ℝ) + 2 := by push_cast; ring
  have h1 : Real.pi * (j + 1) / (L + 1) - Real.pi / (L + 1) = Real.pi * (j : ℝ) / (L + 1) := by ring
  have h2 : Real.pi * (j + 1) / (L + 1) + Real.pi / (L + 1) = Real.pi * ((j : ℝ) + 2) / (L + 1) := by ring
  rw [h1, h2] at h
  rw [hc1, hc2]
  exact h

lemma u_val_neg_one (L : ℕ) : u_val L (-1) = 0 := by
  unfold u_val
  have h : ((-1 : ℤ) : ℝ) + 1 = 0 := by norm_num
  rw [h]
  simp

lemma u_val_L (L : ℕ) : u_val L L = 0 := by
  unfold u_val
  have h : Real.pi * ((L : ℤ) + 1) / (L + 1) = Real.pi := by
    have h1 : ((L : ℤ) : ℝ) + 1 = (L : ℝ) + 1 := by push_cast; ring
    rw [h1]
    have h2 : (L : ℝ) + 1 ≠ 0 := by positivity
    rw [mul_div_cancel_right₀ _ h2]
  rw [h, sin_pi]

lemma sum_u_mul_u_minus_one (L : ℕ) (hL : L ≥ 2) :
    Finset.sum (range L) (fun j => u_val L j * u_val L (j - 1)) =
    Finset.sum (range (L - 1)) (fun j => u_val L j * u_val L (j + 1)) := by
  have hl : L = L - 1 + 1 := by omega
  nth_rw 1 [hl]
  rw [sum_range_succ']
  have hz2 : u_val L ↑(0 : ℕ) * u_val L (↑(0 : ℕ) - 1) = 0 := by
    have h_neg : (↑(0 : ℕ) : ℤ) - 1 = -1 := by norm_num
    rw [h_neg, u_val_neg_one L, mul_zero]
  rw [hz2, add_zero]
  apply sum_congr rfl
  intro x _
  have hx_sub : ((x + 1 : ℕ) : ℤ) - 1 = (x : ℤ) := by push_cast; ring
  have hx_add : ((x + 1 : ℕ) : ℤ) = (x : ℤ) + 1 := by push_cast; ring
  rw [hx_sub, hx_add]
  ring

lemma sum_u_mul_u_plus_one (L : ℕ) (hL : L ≥ 2) :
    Finset.sum (range L) (fun j => u_val L j * u_val L (j + 1)) =
    Finset.sum (range (L - 1)) (fun j => u_val L j * u_val L (j + 1)) := by
  have hl : L = L - 1 + 1 := by omega
  nth_rw 1 [hl]
  rw [sum_range_succ]
  have hz : u_val L ↑(L - 1) * u_val L (↑(L - 1) + 1) = 0 := by
    have h_plus : ((L - 1 : ℕ) : ℤ) + 1 = (L : ℤ) := by push_cast; omega
    rw [h_plus, u_val_L L, mul_zero]
  rw [hz, add_zero]

lemma sum_u_mul_u_shift (L : ℕ) (hL : L ≥ 2) :
    Finset.sum (range L) (fun (j : ℕ) => u_val L j * u_val L (j + 1)) * 2 =
    2 * cos (Real.pi / (L + 1)) * Finset.sum (range L) (fun (j : ℕ) => u_val L j ^ 2) := by
  have h1 : 2 * cos (Real.pi / (L + 1)) * Finset.sum (range L) (fun (j : ℕ) => u_val L j ^ 2) =
      Finset.sum (range L) (fun (j : ℕ) => u_val L j * (2 * u_val L j * cos (Real.pi / (L + 1)))) := by
    rw [mul_sum]
    apply sum_congr rfl
    intro x _
    ring
  rw [h1]
  have h2 : Finset.sum (range L) (fun j => u_val L j * (2 * u_val L j * cos (Real.pi / (L + 1)))) =
      Finset.sum (range L) (fun j => u_val L j * (u_val L (j - 1) + u_val L (j + 1))) := by
    apply sum_congr rfl
    intro j _
    rw [u_val_recurrence]
  rw [h2]
  have h3 : Finset.sum (range L) (fun j => u_val L j * (u_val L (j - 1) + u_val L (j + 1))) =
      Finset.sum (range L) (fun j => u_val L j * u_val L (j - 1)) +
      Finset.sum (range L) (fun j => u_val L j * u_val L (j + 1)) := by
    have h_add : (fun j : ℕ => u_val L j * (u_val L (j - 1) + u_val L (j + 1))) =
        (fun j : ℕ => u_val L j * u_val L (j - 1) + u_val L j * u_val L (j + 1)) := by
      ext j
      ring
    rw [h_add, sum_add_distrib]
  rw [h3]
  rw [sum_u_mul_u_minus_one L hL, sum_u_mul_u_plus_one L hL]
  ring
