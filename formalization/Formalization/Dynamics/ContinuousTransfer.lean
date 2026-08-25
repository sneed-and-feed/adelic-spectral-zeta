/-
Copyright (c) 2026 Antigravity Mathematical Research Team. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Antigravity Mathematical Research Team
-/
import Mathlib.NumberTheory.Padics.PadicIntegers
import Mathlib.Topology.MetricSpace.Isometry
import Mathlib.Topology.ContinuousMap.Basic
import Mathlib.Topology.ContinuousMap.Algebra
import Mathlib.Topology.MetricSpace.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Pow.Continuity
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.MeasureTheory.Constructions.BorelSpace.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Formalization.Dynamics.SpectralCircle
import Formalization.Dynamics.DynamicalZetaFactorization

/-!
# Continuous 2-Adic Transfer Operator on C(ℤ₂) and L²(ℤ₂)

This file formalizes the continuous transfer operator $\mathcal{L}$ on the compact ring
of 2-adic integers $\mathbb{Z}_2$, its affine branch automorphisms, its conformal Gibbs
measure invariance, the concentric spectral circle radii sequence $r(n) = 2^{2^{-(n-1)}}$,
and its exact bridge to the discrete Collatz relation matrices and Fredholm determinant
factorizations.

## Mathematical Architecture
1. **Affine Continuous Branches on $\mathbb{Z}_2$:**
   $\phi_0(x) = 3x, \quad \phi_1(x) = 3x - 1$
   Since $3 \in \mathbb{Z}_2^\times$ with $|3|_2 = 1$, both branches are surjective isometries
   and topological homeomorphisms of $\mathbb{Z}_2$.

2. **Continuous Transfer Operator:**
   $(\mathcal{L} f)(x) = f(3x) + f(3x - 1)$
   acting as a linear operator on $C(\mathbb{Z}_2, \mathbb{R})$.
   The normalized Markov transfer operator is $\widetilde{\mathcal{L}} = \frac{1}{2} \mathcal{L}$,
   satisfying $\widetilde{\mathcal{L}} \mathbf{1} = \mathbf{1}$.

3. **Concentric Spectral Circle Radii Sequence:**
   $r(n) = 2^{1/2^{n-1}}$ for $n \ge 2$:
   - $r(n) > 1$ for all $n \ge 2$.
   - $r(n+1) < r(n)$ for all $n \ge 2$ (strictly decreasing towards the unit circle).
   - $\lim_{n \to \infty} r(n) = 1$ (accumulation onto the unit circle $S^1$).

4. **Conformal Gibbs Measure Invariance:**
   $\mathcal{L}^* \mu = 2\mu$, i.e. $\int_{\mathbb{Z}_2} (\mathcal{L} f) \, d\mu = 2 \int_{\mathbb{Z}_2} f \, d\mu$
   for any measure invariant under the branch homeomorphisms.

5. **Harmonic Bridge:**
   Equivalence of the spectral radius with `Formalization.Dynamics.SpectralCircle` eigenvalues
   and the root magnitude $(r(k))^{-1}$ of the cyclotomic Fredholm determinant factors
   `Formalization.Dynamics.DynamicalZetaFactorization`.
-/

noncomputable section

open Filter Topology MeasureTheory ContinuousMap CollatzDirMatrix

instance : Fact (Nat.Prime 2) := ⟨Nat.prime_two⟩

namespace ContinuousTransfer

/-!
# Section 1: 2-Adic Ring Foundations and Branch Transformations
-/

/-- The norm of 3 in the 2-adic integers is 1, so 3 is a 2-adic unit. -/
lemma three_norm : ‖(3 : ℤ_[2])‖ = 1 := by
  refine le_antisymm (PadicInt.norm_le_one 3) (not_lt.mp ?_)
  rw [show (3 : ℤ_[2]) = ((3 : ℤ) : ℤ_[2]) by norm_cast, PadicInt.norm_int_lt_one_iff_dvd]
  decide

/-- Left inverse identity for 3 in ℤ_[2]. -/
lemma three_inv_mul : PadicInt.inv 3 * (3 : ℤ_[2]) = 1 :=
  PadicInt.inv_mul three_norm

/-- Right inverse identity for 3 in ℤ_[2]. -/
lemma mul_three_inv : (3 : ℤ_[2]) * PadicInt.inv 3 = 1 := by
  rw [mul_comm, three_inv_mul]

/-- The first continuous affine branch: ϕ₀(x) = 3x. -/
def phi0 (x : ℤ_[2]) : ℤ_[2] := 3 * x

/-- The second continuous affine branch: ϕ₁(x) = 3x - 1. -/
def phi1 (x : ℤ_[2]) : ℤ_[2] := 3 * x - 1

/-- The inverse map for ϕ₀: ϕ₀⁻¹(x) = 3⁻¹ x. -/
def phi0_inv (x : ℤ_[2]) : ℤ_[2] := PadicInt.inv 3 * x

/-- The inverse map for ϕ₁: ϕ₁⁻¹(x) = 3⁻¹ (x + 1). -/
def phi1_inv (x : ℤ_[2]) : ℤ_[2] := PadicInt.inv 3 * (x + 1)

/-- ϕ₀⁻¹ is a left inverse of ϕ₀. -/
lemma phi0_left_inv (x : ℤ_[2]) : phi0_inv (phi0 x) = x := by
  dsimp [phi0, phi0_inv]
  rw [← mul_assoc, three_inv_mul, one_mul]

/-- ϕ₀⁻¹ is a right inverse of ϕ₀. -/
lemma phi0_right_inv (x : ℤ_[2]) : phi0 (phi0_inv x) = x := by
  dsimp [phi0, phi0_inv]
  rw [← mul_assoc, mul_three_inv, one_mul]

/-- ϕ₁⁻¹ is a left inverse of ϕ₁. -/
lemma phi1_left_inv (x : ℤ_[2]) : phi1_inv (phi1 x) = x := by
  dsimp [phi1, phi1_inv]
  rw [sub_add_cancel, ← mul_assoc, three_inv_mul, one_mul]

/-- ϕ₁⁻¹ is a right inverse of ϕ₁. -/
lemma phi1_right_inv (x : ℤ_[2]) : phi1 (phi1_inv x) = x := by
  dsimp [phi1, phi1_inv]
  rw [← mul_assoc, mul_three_inv, one_mul, add_sub_cancel_right]

/-- Continuity of the affine branch ϕ₀. -/
lemma continuous_phi0 : Continuous phi0 := continuous_const_mul 3

/-- Continuity of the affine branch ϕ₁. -/
lemma continuous_phi1 : Continuous phi1 := (continuous_const_mul 3).sub continuous_const

/-- Continuity of the inverse branch ϕ₀⁻¹. -/
lemma continuous_phi0_inv : Continuous phi0_inv := continuous_const_mul (PadicInt.inv 3)

/-- Continuity of the inverse branch ϕ₁⁻¹. -/
lemma continuous_phi1_inv : Continuous phi1_inv :=
  (continuous_const_mul (PadicInt.inv 3)).comp (continuous_id.add continuous_const)

/-- ϕ₀ as a continuous bundled map on ℤ_[2]. -/
def phi0Map : C(ℤ_[2], ℤ_[2]) := ⟨phi0, continuous_phi0⟩

/-- ϕ₁ as a continuous bundled map on ℤ_[2]. -/
def phi1Map : C(ℤ_[2], ℤ_[2]) := ⟨phi1, continuous_phi1⟩

/-- ϕ₀ is an isometry on ℤ_[2]. -/
lemma isometry_phi0 : Isometry phi0 :=
  Isometry.of_dist_eq fun x y => by
    simp [phi0, dist_eq_norm_sub, ← mul_sub, norm_mul, three_norm]

/-- ϕ₁ is an isometry on ℤ_[2]. -/
lemma isometry_phi1 : Isometry phi1 :=
  Isometry.of_dist_eq fun x y => by
    have h : (3 * x - 1) - (3 * y - 1) = 3 * (x - y) := by ring
    simp [phi1, dist_eq_norm_sub, h, norm_mul, three_norm]

/-- ϕ₀ is a homeomorphism of ℤ_[2]. -/
def homeo0 : ℤ_[2] ≃ₜ ℤ_[2] where
  toFun := phi0
  invFun := phi0_inv
  left_inv := phi0_left_inv
  right_inv := phi0_right_inv
  continuous_toFun := continuous_phi0
  continuous_invFun := continuous_phi0_inv

/-- ϕ₁ is a homeomorphism of ℤ_[2]. -/
def homeo1 : ℤ_[2] ≃ₜ ℤ_[2] where
  toFun := phi1
  invFun := phi1_inv
  left_inv := phi1_left_inv
  right_inv := phi1_right_inv
  continuous_toFun := continuous_phi1
  continuous_invFun := continuous_phi1_inv

/-- ϕ₀ is an isometric equivalence of ℤ_[2]. -/
def isom0 : ℤ_[2] ≃ᵢ ℤ_[2] where
  toFun := phi0
  invFun := phi0_inv
  left_inv := phi0_left_inv
  right_inv := phi0_right_inv
  isometry_toFun := isometry_phi0

/-- ϕ₁ is an isometric equivalence of ℤ_[2]. -/
def isom1 : ℤ_[2] ≃ᵢ ℤ_[2] where
  toFun := phi1
  invFun := phi1_inv
  left_inv := phi1_left_inv
  right_inv := phi1_right_inv
  isometry_toFun := isometry_phi1

/-!
# Section 2: Continuous Transfer Operator on C(ℤ_[2], ℝ)
-/

/-- The continuous transfer operator ℒ : C(ℤ_[2], ℝ) → C(ℤ_[2], ℝ) defined by
    (ℒ f)(x) = f(3x) + f(3x - 1). -/
def transferOp (f : C(ℤ_[2], ℝ)) : C(ℤ_[2], ℝ) :=
  f.comp phi0Map + f.comp phi1Map

@[simp]
lemma transferOp_apply (f : C(ℤ_[2], ℝ)) (x : ℤ_[2]) :
    transferOp f x = f (3 * x) + f (3 * x - 1) := rfl

/-- Transfer operator ℒ as a real linear map on C(ℤ_[2], ℝ). -/
def transferOpLM : C(ℤ_[2], ℝ) →ₗ[ℝ] C(ℤ_[2], ℝ) where
  toFun := transferOp
  map_add' f g := by ext; simp [transferOp]; ring
  map_smul' c f := by ext; simp [transferOp]

/-- Action on constant functions: ℒ(c) = 2c. -/
lemma transferOp_const (c : ℝ) :
    transferOp (ContinuousMap.const ℤ_[2] c) = ContinuousMap.const ℤ_[2] (2 * c) := by
  ext; simp [two_mul]

/-- Action on the constant function 1: ℒ(1) = 2. -/
lemma transferOp_one :
    transferOp (ContinuousMap.const ℤ_[2] 1) = ContinuousMap.const ℤ_[2] 2 := by
  simpa using transferOp_const 1

/-- The normalized Markov transfer operator: ℒ̃ = (1/2) ℒ. -/
def markovTransferOp (f : C(ℤ_[2], ℝ)) : C(ℤ_[2], ℝ) :=
  (1 / 2 : ℝ) • transferOp f

/-- The normalized Markov transfer operator as a linear map. -/
def markovTransferOpLM : C(ℤ_[2], ℝ) →ₗ[ℝ] C(ℤ_[2], ℝ) :=
  (1 / 2 : ℝ) • transferOpLM

/-- The normalized Markov operator preserves constants: ℒ̃(1) = 1. -/
lemma markovTransferOp_one :
    markovTransferOp (ContinuousMap.const ℤ_[2] 1) = ContinuousMap.const ℤ_[2] 1 := by
  ext; simp [markovTransferOp]; norm_num

/-- Pointwise positivity of the transfer operator: f ≥ 0 implies ℒ f ≥ 0. -/
lemma transferOp_nonneg {f : C(ℤ_[2], ℝ)} (hf : ∀ x, 0 ≤ f x) (x : ℤ_[2]) :
    0 ≤ transferOp f x :=
  add_nonneg (hf _) (hf _)

/-!
# Section 3: Concentric Spectral Circle Radii Sequence
-/

/-- The concentric spectral circle radii sequence:
    r(n) = 2^{1 / 2^{n-1}} for n ≥ 2. -/
def spectralRadius (n : ℕ) : ℝ := (2 : ℝ) ^ ((1 : ℝ) / (2 : ℝ) ^ (n - 1))

/-- (a) For all n ≥ 2, the spectral radius strictly exceeds 1: r(n) > 1. -/
theorem spectralRadius_gt_one (n : ℕ) (_hn : 2 ≤ n) : 1 < spectralRadius n := by
  dsimp [spectralRadius]
  rw [← Real.rpow_zero (2 : ℝ)]
  apply Real.rpow_lt_rpow_of_exponent_lt (by norm_num)
  positivity

/-- (b) The spectral radii are strictly decreasing towards the unit circle:
    r(n+1) < r(n) for all n ≥ 2. -/
theorem spectralRadius_strictAnti (n : ℕ) (_hn : 2 ≤ n) :
    spectralRadius (n + 1) < spectralRadius n := by
  apply Real.rpow_lt_rpow_of_exponent_lt (by norm_num)
  have : (2 : ℝ) ^ (n - 1) < (2 : ℝ) ^ n := pow_lt_pow_right₀ (by norm_num) (by omega)
  exact one_div_lt_one_div_of_lt (by positivity) this

/-- The exponent sequence 1 / 2^{n-1} converges to 0 as n → ∞. -/
lemma tendsto_exp_zero : Tendsto (fun n : ℕ => (1 : ℝ) / (2 : ℝ) ^ (n - 1)) atTop (𝓝 0) := by
  simp_rw [← one_div_pow]
  exact (tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num) (by norm_num)).comp (tendsto_sub_atTop_nat 1)

/-- (c) The spectral radii accumulate onto the unit circle S¹ as n → ∞:
    r(n) → 1 as n → ∞. -/
theorem tendsto_spectralRadius_atTop : Tendsto spectralRadius atTop (𝓝 1) := by
  have h := (Real.continuousAt_const_rpow (by norm_num : (2 : ℝ) ≠ 0)).tendsto.comp tendsto_exp_zero
  exact Real.rpow_zero (2 : ℝ) ▸ h

/-- Base sheet circle radius at n = 2: r(2) = √2. -/
theorem spectralRadius_two : spectralRadius 2 = Real.sqrt 2 := by
  dsimp [spectralRadius]
  rw [pow_one, Real.sqrt_eq_rpow]

/-- First cyclotomic circle radius at n = 3: r(3) = 2^{1/4} = ∜2. -/
theorem spectralRadius_three : spectralRadius 3 = (2 : ℝ) ^ ((1 : ℝ) / 4) := by
  dsimp [spectralRadius]
  norm_num

/-- Second cyclotomic circle radius at n = 4: r(4) = 2^{1/8}. -/
theorem spectralRadius_four : spectralRadius 4 = (2 : ℝ) ^ ((1 : ℝ) / 8) := by
  dsimp [spectralRadius]
  norm_num

/-!
# Section 4: Conformal Gibbs Measure and Functional Duality
-/

/-- A continuous functional ν on C(ℤ_[2], ℝ) is a Conformal Gibbs state of eigenvalue 2
    if ν(ℒ f) = 2 ν(f) for all continuous observables f. -/
def IsConformalGibbs (ν : C(ℤ_[2], ℝ) →ₗ[ℝ] ℝ) : Prop :=
  ∀ f : C(ℤ_[2], ℝ), ν (transferOpLM f) = 2 * ν f

/-- A functional ν is Markov-invariant if ν(ℒ̃ f) = ν(f). -/
def IsMarkovInvariant (ν : C(ℤ_[2], ℝ) →ₗ[ℝ] ℝ) : Prop :=
  ∀ f : C(ℤ_[2], ℝ), ν (markovTransferOpLM f) = ν f

/-- Equivalence of the conformal Gibbs eigenvalue equation and normalized Markov invariance. -/
theorem gibbs_iff_markov_invariant (ν : C(ℤ_[2], ℝ) →ₗ[ℝ] ℝ) :
    IsConformalGibbs ν ↔ IsMarkovInvariant ν := by
  simp only [IsConformalGibbs, IsMarkovInvariant, markovTransferOpLM, LinearMap.smul_apply,
    LinearMap.map_smul, smul_eq_mul]
  exact forall_congr' fun f => by constructor <;> intro h <;> linarith

/-- Invariance under both affine branches ϕ₀ and ϕ₁ implies the Conformal Gibbs property. -/
theorem gibbs_of_branch_invariance (ν : C(ℤ_[2], ℝ) →ₗ[ℝ] ℝ)
    (h0 : ∀ f : C(ℤ_[2], ℝ), ν (f.comp phi0Map) = ν f)
    (h1 : ∀ f : C(ℤ_[2], ℝ), ν (f.comp phi1Map) = ν f) :
    IsConformalGibbs ν := fun f => by
  dsimp [transferOpLM, transferOp]
  rw [map_add, h0, h1, two_mul]

/-- Measure-theoretic Conformal Gibbs property:
    Under Haar/branch-invariant measure μ, ∫ (ℒ f) dμ = 2 ∫ f dμ. -/
theorem measure_conformal_gibbs [MeasurableSpace ℤ_[2]] (μ : Measure ℤ_[2])
    (f : ℤ_[2] → ℝ)
    (hf0 : Integrable (fun x => f (3 * x)) μ)
    (hf1 : Integrable (fun x => f (3 * x - 1)) μ)
    (h0 : ∫ x, f (3 * x) ∂μ = ∫ x, f x ∂μ)
    (h1 : ∫ x, f (3 * x - 1) ∂μ = ∫ x, f x ∂μ) :
    ∫ x, (f (3 * x) + f (3 * x - 1)) ∂μ = 2 * ∫ x, f x ∂μ := by
  rw [integral_add hf0 hf1, h0, h1, two_mul]

/-!
# Section 5: Harmonic Bridge with SpectralCircle & DynamicalZetaFactorization
-/

/-- Equality of the spectral radius definition with the eigenvalue magnitude from SpectralCircle. -/
theorem spectral_circle_radius_eq_spectralRadius (n : ℕ) :
    (2 : ℝ) ^ ((1 : ℝ) / (2^(n-1) : ℝ)) = spectralRadius n := rfl

/-- Bridge to `Formalization.Dynamics.SpectralCircle.spectral_circle`:
    every non-trivial twisted eigenvalue μ has exact magnitude |μ| = r(n). -/
theorem spectral_circle_magnitude_eq (n : ℕ) (hn : n ≥ 3) (μ : ℂ)
    (hμ : μ ∈ spectrum ℂ (Matrix.map (twistedDirMatrix (show n ≥ 2 by omega)) (algebraMap ℚ ℂ))) :
    ‖μ‖ = spectralRadius n := by
  rw [← spectral_circle_radius_eq_spectralRadius]
  exact spectral_circle n hn μ hμ

/-- Bridge to `Formalization.Dynamics.DynamicalZetaFactorization`:
    the roots u of the k-th cyclotomic factor (1 + 2u^{2^{k-1}}) lie on the reciprocal circle
    of radius |u| = (r(k))⁻¹. -/
theorem cyclotomic_root_magnitude (k : ℕ) (u : ℂ)
    (hu : 1 + 2 * u ^ (2 ^ (k - 1)) = 0) :
    ‖u‖ = (spectralRadius k)⁻¹ := by
  have h1 : 2 * u ^ (2 ^ (k - 1)) = -1 := by linear_combination hu
  have h_norm : ‖u‖ ^ (2 ^ (k - 1)) = (2 : ℝ)⁻¹ := by
    have h := congr_arg norm h1
    simp only [norm_mul, norm_pow, Complex.norm_two, norm_neg, norm_one] at h
    linarith
  have h_exp : ((2 ^ (k - 1) : ℕ) : ℝ) * ((1 : ℝ) / (2 : ℝ) ^ (k - 1)) = 1 := by
    push_cast
    exact mul_one_div_cancel (by positivity)
  have h_u : ‖u‖ = ((2 : ℝ)⁻¹) ^ ((1 : ℝ) / (2 : ℝ) ^ (k - 1)) := by
    have hr := congr_arg (fun x : ℝ => x ^ ((1 : ℝ) / (2 : ℝ) ^ (k - 1))) h_norm
    rwa [← Real.rpow_natCast, ← Real.rpow_mul (norm_nonneg u), h_exp, Real.rpow_one] at hr
  rw [h_u, spectralRadius, ← Real.inv_rpow zero_le_two]

end ContinuousTransfer
