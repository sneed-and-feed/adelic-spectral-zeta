import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

/-!
# Undirected Spectral Gap Collapse Exponent α

This file formalizes the exact closed-form algebraic expressions and fundamental
properties of the undirected spectral gap collapse exponent:
  α = 3/2 - log₂(1 + √2) = 1 + log₂(2 - √2) = log₂(4 - 2√2)

## Main Definitions
- `silverRatio`: The fundamental silver ratio δ_S = 1 + √2.
- `baseUndirectedGap`: The base undirected gap Δ₀ = 4 - 2√2 at level n = 2.
- `directedSpectralGap`: The directed Collatz spectral gap Δ(D) = 2 - √2.
- `log2`: Base-2 logarithm for real numbers.
- `undirectedGapExponent`: The exponent α = 3/2 - log₂(1 + √2).

## Main Theorems
- `undirectedGapExponent_eq_one_add_log2_directedGap`: α = 1 + log₂(2 - √2).
- `undirectedGapExponent_eq_log2_baseGap`: α = log₂(4 - 2√2).
- `undirectedGapExponent_eq_log2_ratio`: α = log₂((2√2) / (1 + √2)).
- `undirectedGapExponent_eq_three_halves_sub_log2_silverRatio`: α = 3/2 - log₂(1 + √2).
- `baseUndirectedGap_eq_two_mul_directedSpectralGap`: Δ₀ = 2 * Δ(D).
- `directedSpectralGap_mul_silverRatio`: (2 - √2)(1 + √2) = √2.
- `directedSpectralGap_eq_sqrt_two_div_silverRatio`: Δ(D) = √2 / (1 + √2).
- `baseUndirectedGap_eq_two_sqrt_two_div_silverRatio`: Δ₀ = 2√2 / (1 + √2).
- `two_rpow_undirectedGapExponent`: 2^α = 4 - 2√2.
- `two_rpow_undirectedGapExponent_mul_silverRatio`: 2^α * (1 + √2) = 2√2.
- `two_rpow_undirectedGapExponent_div_two`: 2^α / 2 = 2 - √2.
- `undirectedGapExponent_pos`: 0 < α.
- `undirectedGapExponent_lt_half`: α < 1/2.
- `undirectedGapExponent_lt_one`: α < 1.
-/

noncomputable section

open Real

/-- The fundamental Silver Ratio δ_S = 1 + √2. -/
def silverRatio : ℝ := 1 + Real.sqrt 2

/-- The base undirected spectral gap Δ₀ = 4 - 2√2 at level n = 2. -/
def baseUndirectedGap : ℝ := 4 - 2 * Real.sqrt 2

/-- The scale-invariant directed Collatz spectral gap Δ(D) = 2 - √2. -/
def directedSpectralGap : ℝ := 2 - Real.sqrt 2

/-- The base-2 logarithm on ℝ defined via natural logarithm. -/
def log2 (x : ℝ) : ℝ := Real.log x / Real.log 2

/-- The undirected gap collapse exponent α = 3/2 - log₂(1 + √2). -/
def undirectedGapExponent : ℝ := 3 / 2 - log2 silverRatio

/-! ### Basic Positivity and Ordering Lemmas -/

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

lemma silverRatio_pos : 0 < silverRatio := by
  dsimp [silverRatio]
  linarith [sqrt_two_pos]

lemma baseUndirectedGap_pos : 0 < baseUndirectedGap := by
  dsimp [baseUndirectedGap]
  linarith [two_sqrt_two_lt_four]

lemma directedSpectralGap_pos : 0 < directedSpectralGap := by
  dsimp [directedSpectralGap]
  linarith [sqrt_two_lt_two]

lemma log_two_pos : 0 < Real.log 2 := by
  have : (1 : ℝ) < 2 := by norm_num
  exact Real.log_pos this

lemma log_two_ne_zero : Real.log 2 ≠ 0 :=
  ne_of_gt log_two_pos

/-! ### Algebraic Identities -/

/-- Factoring: 4 - 2√2 = 2 * (2 - √2). -/
theorem baseUndirectedGap_eq_two_mul_directedSpectralGap :
    baseUndirectedGap = 2 * directedSpectralGap := by
  dsimp [baseUndirectedGap, directedSpectralGap]
  ring

/-- Silver ratio duality: (2 - √2)(1 + √2) = √2. -/
theorem directedSpectralGap_mul_silverRatio :
    directedSpectralGap * silverRatio = Real.sqrt 2 := by
  dsimp [directedSpectralGap, silverRatio]
  have h : Real.sqrt 2 * Real.sqrt 2 = 2 := sqrt_two_mul_self
  linear_combination -h

/-- The directed gap expressed as √2 / (1 + √2). -/
theorem directedSpectralGap_eq_sqrt_two_div_silverRatio :
    directedSpectralGap = Real.sqrt 2 / silverRatio := by
  have h := directedSpectralGap_mul_silverRatio
  have hpos := silverRatio_pos.ne'
  exact eq_div_of_mul_eq hpos h

/-- The base undirected gap expressed as 2√2 / (1 + √2). -/
theorem baseUndirectedGap_eq_two_sqrt_two_div_silverRatio :
    baseUndirectedGap = (2 * Real.sqrt 2) / silverRatio := by
  rw [baseUndirectedGap_eq_two_mul_directedSpectralGap, directedSpectralGap_eq_sqrt_two_div_silverRatio]
  ring

/-! ### Logarithm Properties for log₂ -/

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

/-! ### The Master Equivalence of α Expressions -/

/-- Theorem: α = log₂(4 - 2√2). -/
theorem undirectedGapExponent_eq_log2_baseGap :
    undirectedGapExponent = log2 baseUndirectedGap := by
  dsimp [undirectedGapExponent]
  rw [baseUndirectedGap_eq_two_sqrt_two_div_silverRatio]
  have hnum : 0 < 2 * Real.sqrt 2 := by linarith [sqrt_two_pos]
  rw [log2_div hnum silverRatio_pos, log2_two_sqrt_two]

/-- Theorem: α = 1 + log₂(2 - √2). -/
theorem undirectedGapExponent_eq_one_add_log2_directedGap :
    undirectedGapExponent = 1 + log2 directedSpectralGap := by
  rw [undirectedGapExponent_eq_log2_baseGap]
  rw [baseUndirectedGap_eq_two_mul_directedSpectralGap]
  have h2 : (0 : ℝ) < 2 := by norm_num
  rw [log2_mul h2 directedSpectralGap_pos, log2_two]

/-- Theorem: α = log₂((2√2) / (1 + √2)). -/
theorem undirectedGapExponent_eq_log2_ratio :
    undirectedGapExponent = log2 ((2 * Real.sqrt 2) / (1 + Real.sqrt 2)) := by
  rw [undirectedGapExponent_eq_log2_baseGap]
  exact congr_arg log2 baseUndirectedGap_eq_two_sqrt_two_div_silverRatio

/-- Theorem: α = 3/2 - log₂(1 + √2). -/
theorem undirectedGapExponent_eq_three_halves_sub_log2_silverRatio :
    undirectedGapExponent = 3 / 2 - log2 (1 + Real.sqrt 2) :=
  rfl

/-! ### Power and Exponential Action -/

/-- The fundamental 2-adic scaling action: 2^α = 4 - 2√2 = Δ₀. -/
theorem two_rpow_undirectedGapExponent :
    (2 : ℝ) ^ undirectedGapExponent = baseUndirectedGap := by
  have h2 : (0 : ℝ) < 2 := by norm_num
  rw [Real.rpow_def_of_pos h2]
  have h_exp : Real.log 2 * undirectedGapExponent = Real.log baseUndirectedGap := by
    rw [undirectedGapExponent_eq_log2_baseGap]
    dsimp [log2]
    have hne := log_two_ne_zero
    field_simp
  rw [h_exp, Real.exp_log baseUndirectedGap_pos]

/-- Renormalization product: 2^α * (1 + √2) = 2√2. -/
theorem two_rpow_undirectedGapExponent_mul_silverRatio :
    (2 : ℝ) ^ undirectedGapExponent * silverRatio = 2 * Real.sqrt 2 := by
  rw [two_rpow_undirectedGapExponent]
  rw [baseUndirectedGap_eq_two_sqrt_two_div_silverRatio]
  have hpos := silverRatio_pos.ne'
  field_simp

/-- Directed-undirected connection: 2^α / 2 = 2 - √2 = Δ(D). -/
theorem two_rpow_undirectedGapExponent_div_two :
    (2 : ℝ) ^ undirectedGapExponent / 2 = directedSpectralGap := by
  rw [two_rpow_undirectedGapExponent, baseUndirectedGap_eq_two_mul_directedSpectralGap]
  ring

/-! ### Bounds on the Gap Exponent α -/

/-- α > 0 since 4 - 2√2 > 1. -/
theorem undirectedGapExponent_pos : 0 < undirectedGapExponent := by
  rw [undirectedGapExponent_eq_log2_baseGap]
  dsimp [log2]
  apply div_pos _ log_two_pos
  apply Real.log_pos
  dsimp [baseUndirectedGap]
  -- We need 4 - 2√2 > 1 ↔ 3 > 2√2 ↔ 9 > 8
  have h8 : (2 * Real.sqrt 2) ^ 2 = 8 := by
    calc (2 * Real.sqrt 2) ^ 2 = 4 * (Real.sqrt 2) ^ 2 := by ring
      _ = 4 * 2 := by rw [sqrt_two_sq]
      _ = 8 := by norm_num
  have h9 : (3 : ℝ) ^ 2 = 9 := by norm_num
  have h_lt : 2 * Real.sqrt 2 < 3 := by
    have h_sq_lt : (2 * Real.sqrt 2) ^ 2 < (3 : ℝ) ^ 2 := by rw [h8, h9]; norm_num
    have h_sq := Real.sqrt_lt_sqrt (by linarith [sqrt_two_pos]) h_sq_lt
    have h_lhs : Real.sqrt ((2 * Real.sqrt 2) ^ 2) = 2 * Real.sqrt 2 := Real.sqrt_sq (by linarith [sqrt_two_pos])
    have h_rhs : Real.sqrt ((3 : ℝ) ^ 2) = 3 := Real.sqrt_sq (by norm_num)
    rwa [h_lhs, h_rhs] at h_sq
  linarith

/-- α < 1/2 since 4 - 2√2 < √2 ↔ 4 < 3√2 ↔ 16 < 18. -/
theorem undirectedGapExponent_lt_half : undirectedGapExponent < 1 / 2 := by
  rw [undirectedGapExponent_eq_log2_baseGap]
  dsimp [log2]
  have h_eq : (1 / 2 : ℝ) = (Real.log 2 / 2) / Real.log 2 := by
    field_simp
  rw [h_eq]
  apply (div_lt_div_right log_two_pos).mpr
  have h_sqrt2 : Real.log 2 / 2 = Real.log (Real.sqrt 2) := (Real.log_sqrt (by norm_num)).symm
  rw [h_sqrt2]
  apply Real.log_lt_log baseUndirectedGap_pos
  dsimp [baseUndirectedGap]
  -- We need 4 - 2√2 < √2 ↔ 4 < 3√2 ↔ 16 < 18
  have h18 : (3 * Real.sqrt 2) ^ 2 = 18 := by
    calc (3 * Real.sqrt 2) ^ 2 = 9 * (Real.sqrt 2) ^ 2 := by ring
      _ = 9 * 2 := by rw [sqrt_two_sq]
      _ = 18 := by norm_num
  have h16 : (4 : ℝ) ^ 2 = 16 := by norm_num
  have h_lt : (4 : ℝ) < 3 * Real.sqrt 2 := by
    have h_sq_lt : (4 : ℝ) ^ 2 < (3 * Real.sqrt 2) ^ 2 := by rw [h16, h18]; norm_num
    have h_sq := Real.sqrt_lt_sqrt (by norm_num) h_sq_lt
    have h_lhs : Real.sqrt ((4 : ℝ) ^ 2) = 4 := Real.sqrt_sq (by norm_num)
    have h_rhs : Real.sqrt ((3 * Real.sqrt 2) ^ 2) = 3 * Real.sqrt 2 := Real.sqrt_sq (by linarith [sqrt_two_pos])
    rwa [h_lhs, h_rhs] at h_sq
  linarith

/-- α < 1 since α < 1/2 < 1. -/
theorem undirectedGapExponent_lt_one : undirectedGapExponent < 1 := by
  have : (1 / 2 : ℝ) < 1 := by norm_num
  exact undirectedGapExponent_lt_half.trans this

end
