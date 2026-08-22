import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

/-!
# Properties of Base-2 Logarithms and Real Algebraic Bounds

This file defines the real base-2 logarithm `log2` and establishes fundamental identities
and algebraic bounds involving `√2` and logarithmic quotients.

## Main Definitions
- `log2`: Base-2 logarithm on `ℝ`, defined via `Real.log x / Real.log 2`.

## Main Results
- `log2_two`: `log2 2 = 1`.
- `log2_mul`: Logarithm of a product on positive reals: `log2 (x * y) = log2 x + log2 y`.
- `log2_div`: Logarithm of a quotient on positive reals: `log2 (x / y) = log2 x - log2 y`.
- `log2_sqrt_two`: `log2 (√2) = 1/2`.
- `log2_two_sqrt_two`: `log2 (2√2) = 3/2`.
- Elementary positivity and ordering lemmas for `√2` and `Real.log 2`.

## Tags
logarithm, log2, square root, real analysis
-/

noncomputable section

open Real

/-- The base-2 logarithm on ℝ defined via the natural logarithm. -/
def log2 (x : ℝ) : ℝ := Real.log x / Real.log 2

/-! ### Square Root of 2 Properties -/

lemma sqrt_two_pos : 0 < Real.sqrt 2 := by
  have : (0 : ℝ) < 2 := by norm_num
  exact Real.sqrt_pos.mpr this

lemma sqrt_two_nonneg : 0 ≤ Real.sqrt 2 :=
  le_of_lt sqrt_two_pos

lemma sqrt_two_sq : (Real.sqrt 2) ^ 2 = 2 := by
  have h : (0 : ℝ) ≤ 2 := by norm_num
  exact Real.sq_sqrt h

lemma sqrt_two_mul_self : Real.sqrt 2 * Real.sqrt 2 = 2 := by
  have h : (Real.sqrt 2) ^ 2 = Real.sqrt 2 * Real.sqrt 2 := sq (Real.sqrt 2)
  rw [← h, sqrt_two_sq]

lemma sqrt_two_lt_two : Real.sqrt 2 < 2 := by
  have h_lt : (2 : ℝ) < 4 := by norm_num
  have h_sqrt := Real.sqrt_lt_sqrt (by norm_num : (0 : ℝ) ≤ 2) h_lt
  have h4 : Real.sqrt 4 = 2 := by
    have h : (4 : ℝ) = 2 ^ 2 := by norm_num
    rw [h, Real.sqrt_sq (by norm_num)]
  rwa [h4] at h_sqrt

lemma two_sqrt_two_lt_four : 2 * Real.sqrt 2 < 4 := by
  linarith [sqrt_two_lt_two]

/-! ### Natural Logarithm of 2 Properties -/

lemma log_two_pos : 0 < Real.log 2 := by
  have : (1 : ℝ) < 2 := by norm_num
  exact Real.log_pos this

lemma log_two_ne_zero : Real.log 2 ≠ 0 :=
  ne_of_gt log_two_pos

/-! ### Base-2 Logarithm Properties -/

@[simp]
lemma log2_two : log2 2 = 1 := by
  dsimp [log2]
  exact div_self log_two_ne_zero

lemma log2_mul {x y : ℝ} (hx : 0 < x) (hy : 0 < y) :
    log2 (x * y) = log2 x + log2 y := by
  dsimp [log2]
  rw [Real.log_mul hx.ne' hy.ne', add_div]

lemma log2_div {x y : ℝ} (hx : 0 < x) (hy : 0 < y) :
    log2 (x / y) = log2 x - log2 y := by
  dsimp [log2]
  rw [Real.log_div hx.ne' hy.ne', sub_div]

lemma log2_sqrt_two : log2 (Real.sqrt 2) = 1 / 2 := by
  dsimp [log2]
  have h : Real.log (Real.sqrt 2) = Real.log 2 / 2 := by
    have h2 : (0 : ℝ) ≤ 2 := by norm_num
    rw [Real.log_sqrt h2]
  rw [h]
  field_simp
  ring

lemma log2_two_sqrt_two : log2 (2 * Real.sqrt 2) = 3 / 2 := by
  have h2 : (0 : ℝ) < 2 := by norm_num
  rw [log2_mul h2 sqrt_two_pos, log2_two, log2_sqrt_two]
  ring
