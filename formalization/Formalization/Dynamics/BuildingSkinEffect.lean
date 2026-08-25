/-
Copyright (c) 2026 Adelic Spectral Zeta Research Group. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Adelic Spectral Zeta Research Group
-/
import Mathlib.Data.Real.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity
import Formalization.Buildings.BuildingPGL3

/-!
# Higher-Rank Non-Hermitian Skin Effect & Multifractal Dimensions on Ã₂ Buildings

This module formalizes:
1. **Higher-Rank Non-Hermitian Directed Transfer Operators on Apartment Lattices**:
   - Directed hopping on the triangular apartment lattice `ℤ × ℤ`.
   - Asymmetric directional weights `q₁, q₂ > 1`.
   - Non-Hermitian transfer operator `H_NH(q₁, q₂)`.

2. **Generalized Brillouin Zone (GBZ) Radii**:
   - GBZ deformation radii: `r₁ = 1 / √q₁`, `r₂ = 1 / √q₂`.
   - Verification that `0 < rᵢ < 1` for `qᵢ > 1`.

3. **Similarity Transformation Restoring Bulk Hermiticity**:
   - Diagonal similarity gauge `S(r₁, r₂)` and inverse `S⁻¹(r₁, r₂)`.
   - **Main Theorem**: `S⁻¹ ∘ H_NH ∘ S = H_Herm`, restoring full bulk Hermiticity.

4. **Skin Mode Localization Lengths**:
   - Boundary wall decay rates `κᵢ = (1/2) ln(qᵢ)`.
   - Condensation localization lengths `ξᵢ = 2 / ln(qᵢ)`.
   - Proof of exact reciprocal duality: `κᵢ · ξᵢ = 1` and `ξᵢ > 0`.

5. **Multifractal Participation Dimension**:
   - Boundary Hausdorff dimension `D_q(p) = ln(p) / ln(p² + p + 1)`.
   - Exact mathematical bounds: `0 < D_q(p) < 1/2 < 1` for all `p ≥ 2`.

All theorems are formally verified with **zero sorrys** and **zero custom axioms**.
-/

namespace BuildingSkinEffect

-- ============================================================================
-- Section 1: Non-Hermitian Directed Transfer Operators on Ã₂ Apartments
-- ============================================================================

/-- Higher-Rank Directed Non-Hermitian Transfer Operator on the apartment lattice ℤ × ℤ:
    `(H_NH f)(m, n) = q₁ f(m+1, n) + f(m-1, n) + q₂ f(m, n+1) + f(m, n-1)`. -/
noncomputable def directedTransferOp (q1 q2 : ℝ) (f : ℤ × ℤ → ℝ) : ℤ × ℤ → ℝ :=
  fun ⟨m, n⟩ => q1 * f (m + 1, n) + f (m - 1, n) + q2 * f (m, n + 1) + f (m, n - 1)

/-- Symmetrized Hermitian Transfer Operator with effective hopping amplitudes:
    `(H_Herm f)(m, n) = sq₁ (f(m+1, n) + f(m-1, n)) + sq₂ (f(m, n+1) + f(m, n-1))`. -/
noncomputable def hermitianTransferOp (sq1 sq2 : ℝ) (f : ℤ × ℤ → ℝ) : ℤ × ℤ → ℝ :=
  fun ⟨m, n⟩ => sq1 * (f (m + 1, n) + f (m - 1, n)) + sq2 * (f (m, n + 1) + f (m, n - 1))

-- ============================================================================
-- Section 2: Generalized Brillouin Zone (GBZ) & Similarity Transformation
-- ============================================================================

/-- Generalized Brillouin Zone (GBZ) deformation radius along root direction i:
    `r(q) = 1 / √q`. -/
noncomputable def gbzRadius (q : ℝ) : ℝ :=
  1 / Real.sqrt q

/-- The GBZ radius lies strictly in (0, 1) for asymmetric weights q > 1. -/
theorem gbzRadius_pos_lt_one (q : ℝ) (hq : q > 1) :
    0 < gbzRadius q ∧ gbzRadius q < 1 := by
  dsimp [gbzRadius]
  have hsq : 1 < Real.sqrt q := by rw [← Real.sqrt_one]; exact Real.sqrt_lt_sqrt (by linarith) hq
  exact ⟨by positivity, (div_lt_one₀ (by positivity)).mpr hsq⟩

/-- Similarity gauge transformation acting on lattice functions:
    `(S f)(m, n) = r₁ᵐ r₂ⁿ f(m, n)`. -/
noncomputable def similarityGauge (r1 r2 : ℝ) (f : ℤ × ℤ → ℝ) : ℤ × ℤ → ℝ :=
  fun ⟨m, n⟩ => (r1 ^ m) * (r2 ^ n) * f (m, n)

/-- Inverse similarity gauge transformation:
    `(S⁻¹ g)(m, n) = r₁⁻ᵐ r₂⁻ⁿ g(m, n)`. -/
noncomputable def similarityGaugeInv (r1 r2 : ℝ) (g : ℤ × ℤ → ℝ) : ℤ × ℤ → ℝ :=
  fun ⟨m, n⟩ => (r1 ^ (-m)) * (r2 ^ (-n)) * g (m, n)

/-- **Main Theorem (Similarity Transformation Restores Bulk Hermiticity)**:
    Under the diagonal GBZ similarity transformation `S`, the non-Hermitian directed
    operator `H_NH(q₁, q₂)` is exactly mapped to the symmetric Hermitian operator `H_Herm(1/r₁, 1/r₂)`. -/
theorem similarity_restores_hermiticity (q1 q2 r1 r2 : ℝ)
    (hr1_ne : r1 ≠ 0) (hr2_ne : r2 ≠ 0)
    (hq1_r1 : q1 * r1 = 1 / r1) (hq2_r2 : q2 * r2 = 1 / r2)
    (f : ℤ × ℤ → ℝ) (m n : ℤ) :
    similarityGaugeInv r1 r2 (directedTransferOp q1 q2 (similarityGauge r1 r2 f)) (m, n) =
      (1 / r1) * (f (m + 1, n) + f (m - 1, n)) + (1 / r2) * (f (m, n + 1) + f (m, n - 1)) := by
  dsimp [similarityGaugeInv, directedTransferOp, similarityGauge]
  have hr1_m1 : r1 ^ (m + 1) = r1 ^ m * r1 := zpow_add_one₀ hr1_ne m
  have hr1_sub1 : r1 ^ (m - 1) = r1 ^ m * (1 / r1) := by
    rw [sub_eq_add_neg, zpow_add₀ hr1_ne, zpow_neg_one, one_div]
  have hr2_n1 : r2 ^ (n + 1) = r2 ^ n * r2 := zpow_add_one₀ hr2_ne n
  have hr2_sub1 : r2 ^ (n - 1) = r2 ^ n * (1 / r2) := by
    rw [sub_eq_add_neg, zpow_add₀ hr2_ne, zpow_neg_one, one_div]
  have hr1_c : r1 ^ (-m) * r1 ^ m = 1 := by rw [← zpow_add₀ hr1_ne, neg_add_cancel, zpow_zero]
  have hr2_c : r2 ^ (-n) * r2 ^ n = 1 := by rw [← zpow_add₀ hr2_ne, neg_add_cancel, zpow_zero]
  rw [hr1_m1, hr1_sub1, hr2_n1, hr2_sub1]
  calc
    r1 ^ (-m) * r2 ^ (-n) *
      (q1 * (r1 ^ m * r1 * r2 ^ n * f (m + 1, n)) +
        r1 ^ m * (1 / r1) * r2 ^ n * f (m - 1, n) +
        q2 * (r1 ^ m * (r2 ^ n * r2) * f (m, n + 1)) +
        r1 ^ m * (r2 ^ n * (1 / r2)) * f (m, n - 1))
      = (r1 ^ (-m) * r1 ^ m) * (r2 ^ (-n) * r2 ^ n) *
        ((q1 * r1) * f (m + 1, n) + (1 / r1) * f (m - 1, n) + (q2 * r2) * f (m, n + 1) + (1 / r2) * f (m, n - 1)) := by ring
    _ = (1 / r1) * (f (m + 1, n) + f (m - 1, n)) + (1 / r2) * (f (m, n + 1) + f (m, n - 1)) := by
      rw [hr1_c, hr2_c, hq1_r1, hq2_r2]; ring

-- ============================================================================
-- Section 3: Skin Mode Localization Lengths
-- ============================================================================

/-- Boundary wall exponential decay rate `κ(q) = (1/2) ln(q)`. -/
noncomputable def skinDecayRate (q : ℝ) : ℝ :=
  (1 / 2) * Real.log q

/-- Skin mode condensation localization length `ξ(q) = 2 / ln(q)`. -/
noncomputable def skinLocalizationLength (q : ℝ) : ℝ :=
  2 / Real.log q

/-- The skin decay rate is strictly positive for asymmetric hopping q > 1. -/
theorem skinDecayRate_pos (q : ℝ) (hq : q > 1) :
    skinDecayRate q > 0 := by
  dsimp [skinDecayRate]
  have : Real.log q > 0 := Real.log_pos hq
  positivity

/-- The skin localization length is strictly positive for q > 1. -/
theorem skinLocalizationLength_pos (q : ℝ) (hq : q > 1) :
    skinLocalizationLength q > 0 := by
  dsimp [skinLocalizationLength]
  have : Real.log q > 0 := Real.log_pos hq
  positivity

/-- **Theorem (Reciprocal Duality of Skin Decay and Localization Length)**:
    `κ(q) · ξ(q) = 1` for all `q > 1`. -/
theorem skinDecay_localization_product (q : ℝ) (hq : q > 1) :
    skinDecayRate q * skinLocalizationLength q = 1 := by
  dsimp [skinDecayRate, skinLocalizationLength]
  have : Real.log q ≠ 0 := by have := Real.log_pos hq; linarith
  field_simp

-- ============================================================================
-- Section 4: Multifractal Hausdorff Dimension on Ã₂ Boundaries
-- ============================================================================

/-- Multifractal Hausdorff / participation dimension of skin mode condensation
    on the Ã₂ building boundary with branching degree p:
    `D_q(p) = ln(p) / ln(p² + p + 1)`. -/
noncomputable def hausdorffDimension (p : ℝ) : ℝ :=
  Real.log p / Real.log (p^2 + p + 1)

/-- Positivity of the multifractal participation dimension for all p ≥ 2. -/
theorem hausdorffDimension_pos (p : ℝ) (hp : p ≥ 2) :
    hausdorffDimension p > 0 := by
  dsimp [hausdorffDimension]
  have : Real.log p > 0 := Real.log_pos (by linarith)
  have : Real.log (p^2 + p + 1) > 0 := Real.log_pos (by nlinarith)
  positivity

/-- **Theorem (Upper Bound D_q(p) < 1)**:
    The multifractal participation dimension is strictly less than 1 for all p ≥ 2. -/
theorem hausdorffDimension_lt_one (p : ℝ) (hp : p ≥ 2) :
    hausdorffDimension p < 1 := by
  dsimp [hausdorffDimension]
  have hlog_quad : Real.log (p^2 + p + 1) > 0 := Real.log_pos (by nlinarith)
  rw [div_lt_one₀ hlog_quad]
  exact Real.log_lt_log (by linarith) (by nlinarith)

/-- **Theorem (Strong Boundary Condensation Bound D_q(p) < 1/2)**:
    Due to the quadratic volume branching `p² + p + 1 > p²` on Ã₂ building boundaries,
    the multifractal participation dimension strictly satisfies `D_q(p) < 1/2` for all `p ≥ 2`. -/
theorem hausdorffDimension_lt_half (p : ℝ) (hp : p ≥ 2) :
    hausdorffDimension p < 1 / 2 := by
  dsimp [hausdorffDimension]
  have hlog_quad : Real.log (p^2 + p + 1) > 0 := Real.log_pos (by nlinarith)
  have hlog_sq_eq : Real.log (p^2) = 2 * Real.log p := Real.log_pow p 2
  have hlog_sq : Real.log (p^2) < Real.log (p^2 + p + 1) := Real.log_lt_log (by positivity) (by linarith)
  rw [hlog_sq_eq] at hlog_sq
  rw [div_lt_iff₀ hlog_quad]
  linarith

/-- **Theorem (Complete Multifractal Dimension Bounds)**:
    For any prime branching degree `p ≥ 2`, the participation dimension strictly satisfies:
    `0 < D_q(p) < 1/2 < 1`. -/
theorem hausdorffDimension_bounds (p : ℝ) (hp : p ≥ 2) :
    0 < hausdorffDimension p ∧ hausdorffDimension p < 1 / 2 :=
  ⟨hausdorffDimension_pos p hp, hausdorffDimension_lt_half p hp⟩

end BuildingSkinEffect
