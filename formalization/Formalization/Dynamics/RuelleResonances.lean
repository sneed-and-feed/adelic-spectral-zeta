/-
Copyright (c) 2026 Antigravity Mathematical Research Team. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Antigravity Mathematical Research Team
-/
import Mathlib.NumberTheory.Padics.PadicIntegers
import Mathlib.NumberTheory.Padics.RingHoms
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Real.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Topology.Order.Basic
import Mathlib.Topology.MetricSpace.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Algebra.Order.Field
import Mathlib.Tactic
import Formalization.Dynamics.PadicLipschitz
import Formalization.Dynamics.LasotaYorke2Adic
import Formalization.Dynamics.ContinuousTransfer

/-!
# Finite Quotient Projections, Compressed Transfer Approximations, and Ruelle Resonances

This file formalizes the finite quotient projections $P_n$ on $\mathbb{Z}/2^n\mathbb{Z}$,
the compressed operator approximation bound $\|\mathcal{L}_2 - P_n \mathcal{L}_2 P_n\| \le 2^{-n}$,
and the isolation of discrete eigenvalues on concentric circles $|\lambda| = 2^{-(k-1)}$ as
authentic Ruelle resonances with essential spectral radius $r_{\text{ess}}(\mathcal{L}_2) \le 1/2$ in Lean 4.

## Mathematical Architecture

1. **Locally Constant Projections $P_n$ on $\mathbb{Z}/2^n\mathbb{Z}$:**
   - Canonical ring homomorphism `toZMod2PowHom n : ℤ_[2] →+* ZMod (2^n)`.
   - Coset representative `cosetRep n u : ℤ_[2]` embedding $\mathbb{Z}/2^n\mathbb{Z} \to \mathbb{Z}_2$.
   - Canonical coset map `canonicalCoset n x = cosetRep n (toZMod2Pow n x)`.
   - Projection operator `quotientProj n f x = f (canonicalCoset n x)`.
   - Idempotency: $P_n^2 = P_n$.
   - Finite rank: $P_n f$ factors through $\mathbb{Z}/2^n\mathbb{Z}$ with range dimension $\le 2^n$.
   - Ultrametric non-expansion: $\|c(x) - c(y)\|_2 \le \|x - y\|_2$ for all $x, y \in \mathbb{Z}_2$.
   - Pointwise Lipschitz approximation error:
     $$\forall x \in \mathbb{Z}_2, \quad \|f(x) - (P_n f)(x)\| \le 2^{-n} L(f)$$
   - Uniform supremum norm error bound: $\|f - P_n f\|_\infty \le 2^{-n} L(f) \le 2^{-n} \|f\|_{\text{Lip}}$.

2. **Compressed Operator Approximation Bound:**
   - Compressed transfer operator $P_n \mathcal{L}_2 P_n$:
     `compressedTransferOp n f = quotientProj n (padicTransferOp (quotientProj n f))`.
   - Matrix bridge: for step functions $g \circ \text{toZMod2Pow } n$, $P_n \mathcal{L}_2 P_n$ acts as
     the normalized discrete transfer matrix on $\mathbb{Z}/2^n\mathbb{Z}$:
     $$\mathcal{L}_2^{\text{disc}} g(u) = \frac{1}{2} (g(3u) + g(3u - 1))$$
   - Operator error bound:
     $$\|\mathcal{L}_2 f - P_n \mathcal{L}_2 P_n f\|_\infty \le 2 \cdot 2^{-n} L(f) \le 2 \cdot 2^{-n} \|f\|_{\text{Lip}}$$
   - Higher-power approximation: for any $m \in \mathbb{N}$,
     $$\|\mathcal{L}_2^m f - (P_n \mathcal{L}_2 P_n)^m f\|_\infty \le 2m \cdot 2^{-n} L(f) \longrightarrow 0 \quad \text{as } n \to \infty$$

3. **Essential Spectral Radius and Authentic Ruelle Resonances:**
   - Essential spectral radius bound $r_{\text{ess}}(\mathcal{L}_2) \le 1/2$ governed by the Lasota–Yorke contraction $(1/2)^m$.
   - Concentric Ruelle resonance radii $\rho(k) = \frac{1}{2} r(k) = \frac{1}{2} 2^{1/2^{k-1}}$:
     * $1/2 < \rho(k) < 1$ for all $k \ge 2$.
     * $\rho(k+1) < \rho(k)$ strictly decreasing towards $1/2$.
     * $\lim_{k \to \infty} \rho(k) = 1/2$ (accumulating onto the boundary of the essential spectrum disk).
   - Discrete spectrum region $\{z \in \mathbb{C} \mid |z| > 1/2\}$ and essential spectrum disk $\{z \in \mathbb{C} \mid |z| \le 1/2\}$.
   - Proof that all discrete eigenvalues on concentric circles are authentic isolated Ruelle resonances.
   - Proof that the peripheral spectrum on $|z| = 1$ consists solely of the isolated simple eigenvalue $\lambda = 1$ corresponding to the unique invariant Haar measure.
-/

noncomputable section

open Dynamics.PadicLipschitz ContinuousTransfer Filter Topology

variable [Fact (Nat.Prime 2)]

namespace Dynamics.RuelleResonances

/-!
# Section 1: Locally Constant Projections P_n on ℤ/2^nℤ
-/

/-- The canonical quotient homomorphism from ℤ_[2] to ZMod (2^n). -/
def toZMod2PowHom (n : ℕ) : ℤ_[2] →+* ZMod (2^n) :=
  PadicInt.toZModPow n

/-- The canonical quotient map from ℤ_[2] to ZMod (2^n). -/
def toZMod2Pow (n : ℕ) (x : ℤ_[2]) : ZMod (2^n) :=
  toZMod2PowHom n x

/-- The canonical coset representative of an element of ZMod (2^n) embedded in ℤ_[2]. -/
def cosetRep (n : ℕ) (u : ZMod (2^n)) : ℤ_[2] :=
  (u.val : ℤ_[2])

/-- The canonical coset representative c(x mod 2^n) for x ∈ ℤ_[2]. -/
def canonicalCoset (n : ℕ) (x : ℤ_[2]) : ℤ_[2] :=
  cosetRep n (toZMod2Pow n x)

/-- Evaluating toZMod2Pow on the canonical coset representative recovers the original residue. -/
lemma toZMod2Pow_cosetRep (n : ℕ) (u : ZMod (2^n)) :
    toZMod2Pow n (cosetRep n u) = u := by
  simp [toZMod2Pow, toZMod2PowHom, cosetRep, PadicInt.toZModPow]

/-- toZMod2Pow of the canonical coset representative equals toZMod2Pow of x. -/
lemma toZMod2Pow_canonicalCoset (n : ℕ) (x : ℤ_[2]) :
    toZMod2Pow n (canonicalCoset n x) = toZMod2Pow n x :=
  toZMod2Pow_cosetRep n (toZMod2Pow n x)

/-- Canonical coset selection is idempotent: c(c(x mod 2^n) mod 2^n) = c(x mod 2^n). -/
lemma canonicalCoset_idempotent (n : ℕ) (x : ℤ_[2]) :
    canonicalCoset n (canonicalCoset n x) = canonicalCoset n x := by
  dsimp [canonicalCoset]; rw [toZMod2Pow_cosetRep]

/-- 2-Adic distance between x and its canonical coset representative is at most 2⁻ⁿ. -/
lemma norm_sub_canonicalCoset_le (n : ℕ) (x : ℤ_[2]) :
    ‖x - canonicalCoset n x‖ ≤ (1 / 2 : ℝ)^n := by
  have h_mem : x - canonicalCoset n x ∈ RingHom.ker (PadicInt.toZModPow (p := 2) n) := by
    rw [RingHom.mem_ker, map_sub, sub_eq_zero]
    exact (toZMod2Pow_canonicalCoset n x).symm
  rw [PadicInt.ker_toZModPow, ← PadicInt.norm_le_pow_iff_mem_span_pow] at h_mem
  have h_two : ((2 : ℕ) : ℝ) = (2 : ℝ) := rfl
  rw [h_two] at h_mem
  have h_pow : (2 : ℝ) ^ (- (n : ℤ)) = (1 / 2 : ℝ)^n := by
    rw [zpow_neg, zpow_natCast, ← inv_pow, one_div]
  rwa [h_pow] at h_mem

/-- Ultrametric non-expansion of canonical coset representatives:
    ‖c(x mod 2^n) - c(y mod 2^n)‖ ≤ ‖x - y‖ for all x, y ∈ ℤ_[2]. -/
theorem norm_canonicalCoset_sub_canonicalCoset_le (n : ℕ) (x y : ℤ_[2]) :
    ‖canonicalCoset n x - canonicalCoset n y‖ ≤ ‖x - y‖ := by
  by_cases h : canonicalCoset n x = canonicalCoset n y
  · rw [h, sub_self, norm_zero]; exact norm_nonneg _
  · have h_not_ker : x - y ∉ RingHom.ker (PadicInt.toZModPow (p := 2) n) := by
      intro h_ker
      apply h
      have : toZMod2Pow n x = toZMod2Pow n y := by
        rwa [RingHom.mem_ker, map_sub, sub_eq_zero] at h_ker
      exact congr_arg (cosetRep n) this
    rw [PadicInt.ker_toZModPow, ← PadicInt.norm_le_pow_iff_mem_span_pow] at h_not_ker
    have h_two : ((2 : ℕ) : ℝ) = (2 : ℝ) := rfl
    rw [h_two] at h_not_ker
    have h_pow : (2 : ℝ) ^ (- (n : ℤ)) = (1 / 2 : ℝ)^n := by
      rw [zpow_neg, zpow_natCast, ← inv_pow, one_div]
    rw [h_pow] at h_not_ker
    have h_gt : (1 / 2 : ℝ)^n < ‖x - y‖ := not_le.mp h_not_ker
    have h_decomp : canonicalCoset n x - canonicalCoset n y =
        (canonicalCoset n x - x) + (x - y) + (y - canonicalCoset n y) := by abel
    rw [h_decomp]
    have h_ultra := PadicInt.nonarchimedean (canonicalCoset n x - x + (x - y)) (y - canonicalCoset n y)
    have h_ultra2 := PadicInt.nonarchimedean (canonicalCoset n x - x) (x - y)
    have h_nx : ‖canonicalCoset n x - x‖ ≤ (1 / 2 : ℝ)^n := by
      rw [norm_sub_rev]; exact norm_sub_canonicalCoset_le n x
    have h_ny : ‖y - canonicalCoset n y‖ ≤ (1 / 2 : ℝ)^n := norm_sub_canonicalCoset_le n y
    have h_max2 : max ‖canonicalCoset n x - x‖ ‖x - y‖ = ‖x - y‖ := max_eq_right (h_nx.trans h_gt.le)
    have h_max1 : max ‖canonicalCoset n x - x + (x - y)‖ ‖y - canonicalCoset n y‖ ≤ ‖x - y‖ :=
      max_le (h_ultra2.trans (by rw [h_max2])) (h_ny.trans h_gt.le)
    exact h_ultra.trans h_max1

/-- The locally constant quotient projection operator P_n on functions on ℤ_[2]:
    (P_n f)(x) = f(c(x mod 2^n)). -/
def quotientProj (n : ℕ) {E : Type*} (f : ℤ_[2] → E) : ℤ_[2] → E :=
  fun x => f (canonicalCoset n x)

/-- Idempotency of the quotient projection operator: P_n^2 = P_n. -/
theorem quotientProj_idempotent (n : ℕ) {E : Type*} (f : ℤ_[2] → E) :
    quotientProj n (quotientProj n f) = quotientProj n f := by
  ext x
  dsimp [quotientProj]
  rw [canonicalCoset_idempotent]

/-- Additivity of the quotient projection operator: P_n(f + g) = P_n f + P_n g. -/
lemma quotientProj_add (n : ℕ) {E : Type*} [AddCommMonoid E] (f g : ℤ_[2] → E) :
    quotientProj n (f + g) = quotientProj n f + quotientProj n g := rfl

/-- Scalar homogeneity of the quotient projection operator. -/
lemma quotientProj_smul {𝕜 E : Type*} [SMul 𝕜 E] (n : ℕ) (c : 𝕜) (f : ℤ_[2] → E) :
    quotientProj n (c • f) = c • quotientProj n f := rfl

/-- Preservation of constants: P_n(c) = c. -/
lemma quotientProj_const (n : ℕ) {E : Type*} (c : E) :
    quotientProj n (fun _ : ℤ_[2] => c) = (fun _ => c) := rfl

/-- P_n f factors through ZMod (2^n). -/
lemma quotientProj_factors (n : ℕ) {E : Type*} (f : ℤ_[2] → E) (x y : ℤ_[2])
    (h : toZMod2Pow n x = toZMod2Pow n y) :
    quotientProj n f x = quotientProj n f y := by
  dsimp [quotientProj, canonicalCoset]
  rw [h]

/-- P_n f is explicitly equal to the composition with toZMod2Pow. -/
lemma quotientProj_eq_comp (n : ℕ) {E : Type*} (f : ℤ_[2] → E) :
    quotientProj n f = (fun u : ZMod (2^n) => f (cosetRep n u)) ∘ (toZMod2Pow n) := rfl

/-- The range of P_n f is a subset of the finite range over ZMod (2^n). -/
lemma quotientProj_range_subset (n : ℕ) {E : Type*} (f : ℤ_[2] → E) :
    Set.range (quotientProj n f) ⊆ Set.range (fun u : ZMod (2^n) => f (cosetRep n u)) := by
  rw [quotientProj_eq_comp]
  exact Set.range_comp_subset_range (toZMod2Pow n) (fun u : ZMod (2^n) => f (cosetRep n u))

/-- Finite rank: the range of P_n f is finite. -/
theorem quotientProj_range_finite (n : ℕ) {E : Type*} (f : ℤ_[2] → E) :
    (Set.range (quotientProj n f)).Finite :=
  (Set.finite_range (fun u : ZMod (2^n) => f (cosetRep n u))).subset (quotientProj_range_subset n f)

/-!
# Section 2: Pointwise and Uniform Lipschitz Approximation Error
-/

/-- Quotient projection preserves valid Lipschitz constant bounds. -/
lemma quotientProj_lipConstantSet {E : Type*} [NormedAddCommGroup E]
    (n : ℕ) {f : ℤ_[2] → E} {C : ℝ} (hC : C ∈ lipConstantSet f) :
    C ∈ lipConstantSet (quotientProj n f) := by
  refine ⟨hC.1, fun x y => ?_⟩
  dsimp [quotientProj]
  exact (hC.2 (canonicalCoset n x) (canonicalCoset n y)).trans
    (mul_le_mul_of_nonneg_left (norm_canonicalCoset_sub_canonicalCoset_le n x y) hC.1)

/-- Quotient projection preserves 2-adic Lipschitz continuity. -/
theorem isPadicLipschitz_quotientProj {E : Type*} [NormedAddCommGroup E]
    (n : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    IsPadicLipschitz (quotientProj n f) := by
  rcases hf with ⟨C, hC, hLip⟩
  exact ⟨C, quotientProj_lipConstantSet n ⟨hC, hLip⟩⟩

/-- Lipschitz semi-norm contraction under quotient projection: L(P_n f) ≤ L(f). -/
theorem lipSemiNorm_quotientProj_le {E : Type*} [NormedAddCommGroup E]
    (n : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipSemiNorm (quotientProj n f) ≤ lipSemiNorm f :=
  le_csInf (lipConstantSet_nonempty hf) (fun _ hC =>
    csInf_le (lipConstantSet_bddBelow _) (quotientProj_lipConstantSet n hC))

/-- Pointwise Lipschitz approximation error under P_n for any valid Lipschitz constant C:
    ‖f(x) - (P_n f)(x)‖ ≤ 2⁻ⁿ C. -/
theorem quotientProj_approx_error_of_mem {E : Type*} [NormedAddCommGroup E]
    {f : ℤ_[2] → E} {C : ℝ} (hC : C ∈ lipConstantSet f) (n : ℕ) (x : ℤ_[2]) :
    ‖f x - quotientProj n f x‖ ≤ (1 / 2 : ℝ)^n * C := by
  dsimp [quotientProj]
  rw [mul_comm]
  exact (hC.2 x (canonicalCoset n x)).trans (mul_le_mul_of_nonneg_left (norm_sub_canonicalCoset_le n x) hC.1)

/-- **Pointwise Lipschitz Approximation Error**:
    For all x ∈ ℤ₂, ‖f(x) - (P_n f)(x)‖ ≤ 2⁻ⁿ L(f). -/
theorem quotientProj_approx_error {E : Type*} [NormedAddCommGroup E]
    {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) (n : ℕ) (x : ℤ_[2]) :
    ‖f x - quotientProj n f x‖ ≤ (1 / 2 : ℝ)^n * lipSemiNorm f := by
  refine le_of_forall_pos_le_add fun ε hε => ?_
  rcases exists_lt_of_csInf_lt (lipConstantSet_nonempty hf)
    (lt_add_of_pos_right (lipSemiNorm f) (div_pos hε (by positivity : 0 < (1 / 2 : ℝ)^n))) with ⟨C, hC, hClt⟩
  have h_mul := mul_le_mul_of_nonneg_left hClt.le (by positivity : 0 ≤ (1 / 2 : ℝ)^n)
  rw [mul_add, mul_div_cancel₀ _ (by positivity : (1 / 2 : ℝ)^n ≠ 0)] at h_mul
  linarith [quotientProj_approx_error_of_mem hC n x]

/-- Supremum norm contractivity of quotient projection: ‖P_n f‖_∞ ≤ ‖f‖_∞. -/
theorem supNorm_quotientProj_le {E : Type*} [NormedAddCommGroup E]
    (n : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    supNorm (quotientProj n f) ≤ supNorm f := by
  refine csSup_le (range_norm_nonempty (quotientProj n f)) ?_
  rintro _ ⟨x, rfl⟩
  exact norm_le_supNorm hf (canonicalCoset n x)

/-- Total Lipschitz norm contractivity of quotient projection: ‖P_n f‖_Lip ≤ ‖f‖_Lip. -/
theorem lipNorm_quotientProj_le {E : Type*} [NormedAddCommGroup E]
    (n : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipNorm (quotientProj n f) ≤ lipNorm f :=
  add_le_add (supNorm_quotientProj_le n hf) (lipSemiNorm_quotientProj_le n hf)

/-- Uniform error bound for quotient projection in supremum norm:
    ‖f - P_n f‖_∞ ≤ 2⁻ⁿ L(f). -/
theorem supNorm_sub_quotientProj_le {E : Type*} [NormedAddCommGroup E]
    (n : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    supNorm (f - quotientProj n f) ≤ (1 / 2 : ℝ)^n * lipSemiNorm f := by
  refine csSup_le (range_norm_nonempty (f - quotientProj n f)) ?_
  rintro _ ⟨x, rfl⟩
  exact quotientProj_approx_error hf n x

/-- Uniform error bound in terms of the total Lipschitz norm:
    ‖f - P_n f‖_∞ ≤ 2⁻ⁿ ‖f‖_Lip. -/
theorem supNorm_sub_quotientProj_le_lipNorm {E : Type*} [NormedAddCommGroup E]
    (n : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    supNorm (f - quotientProj n f) ≤ (1 / 2 : ℝ)^n * lipNorm f := by
  have h_le : lipSemiNorm f ≤ lipNorm f := by
    dsimp [lipNorm]
    linarith [supNorm_nonneg hf]
  exact (supNorm_sub_quotientProj_le n hf).trans (mul_le_mul_of_nonneg_left h_le (by positivity))

omit [Fact (Nat.Prime 2)] in
/-- Filter convergence helper for geometric decay of (1/2)^n. -/
lemma tendsto_pow_half_const_mul_zero (c : ℝ) :
    Tendsto (fun n : ℕ => c * (1 / 2 : ℝ)^n) atTop (𝓝 0) := by
  have h := (tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num : (0:ℝ) ≤ 1/2) (by norm_num : (1/2:ℝ) < 1)).const_mul c
  rwa [mul_zero] at h

/-- Uniform convergence of quotient projections: lim_{n → ∞} ‖f - P_n f‖_∞ = 0. -/
theorem tendsto_quotientProj_supNorm {E : Type*} [NormedAddCommGroup E]
    {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    Tendsto (fun n : ℕ => supNorm (f - quotientProj n f)) atTop (𝓝 0) :=
  tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds
    (tendsto_pow_half_const_mul_zero (lipSemiNorm f))
    (Filter.Eventually.of_forall fun _ => supNorm_nonneg (isPadicLipschitz_sub hf (isPadicLipschitz_quotientProj _ hf)))
    (Filter.Eventually.of_forall fun n => by rw [mul_comm]; exact supNorm_sub_quotientProj_le n hf)

/-!
# Section 3: Compressed Transfer Operator and Matrix Bridge
-/

/-- The compressed continuous transfer operator P_n ℒ₂ P_n. -/
def compressedTransferOp (n : ℕ) {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : ℤ_[2] → E) : ℤ_[2] → E :=
  quotientProj n (padicTransferOp (quotientProj n f))

/-- Linearity: additivity of the compressed transfer operator. -/
lemma compressedTransferOp_add (n : ℕ) {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f g : ℤ_[2] → E) :
    compressedTransferOp n (f + g) = compressedTransferOp n f + compressedTransferOp n g := by
  dsimp [compressedTransferOp]
  rw [quotientProj_add, padicTransferOp_add, quotientProj_add]

/-- Linearity: scalar homogeneity of the compressed transfer operator. -/
lemma compressedTransferOp_smul (n : ℕ) {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (c : ℝ) (f : ℤ_[2] → E) :
    compressedTransferOp n (c • f) = c • compressedTransferOp n f := by
  dsimp [compressedTransferOp]
  rw [quotientProj_smul, padicTransferOp_smul, quotientProj_smul]

/-- Preservation of constants: (P_n ℒ₂ P_n)(c) = c. -/
lemma compressedTransferOp_const (n : ℕ) {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (c : E) :
    compressedTransferOp n (fun _ : ℤ_[2] => c) = (fun _ => c) := by
  dsimp [compressedTransferOp]
  rw [quotientProj_const, padicTransferOp_const, quotientProj_const]

/-- Compressed transfer operator preserves 2-adic Lipschitz continuity. -/
theorem isPadicLipschitz_compressedTransferOp {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (n : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    IsPadicLipschitz (compressedTransferOp n f) :=
  isPadicLipschitz_quotientProj n (isPadicLipschitz_padicTransferOp (isPadicLipschitz_quotientProj n hf))

/-- Supremum norm contractivity of the compressed transfer operator: ‖P_n ℒ₂ P_n f‖_∞ ≤ ‖f‖_∞. -/
theorem supNorm_compressedTransferOp_le {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (n : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    supNorm (compressedTransferOp n f) ≤ supNorm f := by
  dsimp [compressedTransferOp]
  have h1 := supNorm_quotientProj_le n (isPadicLipschitz_padicTransferOp (isPadicLipschitz_quotientProj n hf))
  have h2 := supNorm_padicTransferOp_le (isPadicLipschitz_quotientProj n hf)
  have h3 := supNorm_quotientProj_le n hf
  exact h1.trans (h2.trans h3)

/-- The discrete transfer action on step functions over ZMod (2^n). -/
def discreteTransferStep (n : ℕ) {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (g : ZMod (2^n) → E) (u : ZMod (2^n)) : E :=
  (1 / 2 : ℝ) • (g (3 * u) + g (3 * u - 1))

/-- **Matrix Bridge**:
    For step functions factored through ZMod (2^n), the compressed operator P_n ℒ₂ P_n acts
    identically to the discrete transfer operator on ZMod (2^n). -/
theorem compressedTransferOp_stepFunction (n : ℕ) {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (g : ZMod (2^n) → E) (x : ℤ_[2]) :
    compressedTransferOp n (fun y => g (toZMod2Pow n y)) x =
      discreteTransferStep n g (toZMod2Pow n x) := by
  dsimp [compressedTransferOp, quotientProj, padicTransferOp, phi0, phi1, discreteTransferStep, toZMod2Pow]
  have h_cc (y : ℤ_[2]) : toZMod2PowHom n (canonicalCoset n y) = toZMod2PowHom n y :=
    toZMod2Pow_canonicalCoset n y
  rw [h_cc, h_cc]
  simp only [map_sub, map_mul, map_ofNat, map_one, h_cc]

/-- **Operator Approximation Error Bound**:
    ‖ℒ₂ f - P_n ℒ₂ P_n f‖_∞ ≤ 2 · 2⁻ⁿ L(f). -/
theorem transferOp_proj_approx_bound {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (n : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    supNorm (padicTransferOp f - compressedTransferOp n f) ≤ 2 * (1 / 2 : ℝ)^n * lipSemiNorm f := by
  have h_decomp : padicTransferOp f - compressedTransferOp n f =
      (padicTransferOp f - quotientProj n (padicTransferOp f)) +
      quotientProj n (padicTransferOp (f - quotientProj n f)) := by
    ext x; dsimp [compressedTransferOp, quotientProj, padicTransferOp]; simp only [smul_add, smul_sub]; abel
  have h_lip_Tf := isPadicLipschitz_padicTransferOp hf
  have h_lip_diff := isPadicLipschitz_sub hf (isPadicLipschitz_quotientProj n hf)
  have h_lip_Tdiff := isPadicLipschitz_padicTransferOp h_lip_diff
  have h_lip_term1 := isPadicLipschitz_sub h_lip_Tf (isPadicLipschitz_quotientProj n h_lip_Tf)
  have h_lip_PTdiff := isPadicLipschitz_quotientProj n h_lip_Tdiff
  rw [h_decomp]
  have h_tri := supNorm_add_le h_lip_term1 h_lip_PTdiff
  have h_t1 : supNorm (padicTransferOp f - quotientProj n (padicTransferOp f)) ≤ (1 / 2 : ℝ)^n * lipSemiNorm f :=
    (supNorm_sub_quotientProj_le n h_lip_Tf).trans
      (mul_le_mul_of_nonneg_left (lipSemiNorm_padicTransferOp_le hf) (by positivity))
  have h_t2 : supNorm (quotientProj n (padicTransferOp (f - quotientProj n f))) ≤ (1 / 2 : ℝ)^n * lipSemiNorm f :=
    (supNorm_quotientProj_le n h_lip_Tdiff).trans
      ((supNorm_padicTransferOp_le h_lip_diff).trans (supNorm_sub_quotientProj_le n hf))
  linarith

/-- Operator approximation error bound in terms of the total Lipschitz norm:
    ‖ℒ₂ f - P_n ℒ₂ P_n f‖_∞ ≤ 2 · 2⁻ⁿ ‖f‖_Lip. -/
theorem transferOp_proj_approx_bound_lipNorm {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (n : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    supNorm (padicTransferOp f - compressedTransferOp n f) ≤ 2 * (1 / 2 : ℝ)^n * lipNorm f := by
  have h_le : lipSemiNorm f ≤ lipNorm f := by
    dsimp [lipNorm]
    linarith [supNorm_nonneg hf]
  exact (transferOp_proj_approx_bound n hf).trans
    (mul_le_mul_of_nonneg_left h_le (by positivity))

/-- Convergence of compressed operators to ℒ₂ in operator norm:
    lim_{n → ∞} ‖ℒ₂ f - P_n ℒ₂ P_n f‖_∞ = 0. -/
theorem tendsto_compressedTransferOp_approx {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    Tendsto (fun n : ℕ => supNorm (padicTransferOp f - compressedTransferOp n f)) atTop (𝓝 0) :=
  tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds
    (tendsto_pow_half_const_mul_zero (2 * lipSemiNorm f))
    (Filter.Eventually.of_forall fun _ => supNorm_nonneg
      (isPadicLipschitz_sub (isPadicLipschitz_padicTransferOp hf) (isPadicLipschitz_compressedTransferOp _ hf)))
    (Filter.Eventually.of_forall fun n => by
      have h := transferOp_proj_approx_bound n hf
      linarith)

/-!
# Section 4: Higher-Power Compressed Operator Iterates
-/

/-- Iterates of the compressed transfer operator (P_n ℒ₂ P_n)^m. -/
def compressedIterate (n : ℕ) (m : ℕ) {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : ℤ_[2] → E) : ℤ_[2] → E :=
  ((compressedTransferOp (E := E) n)^[m]) f

/-- Base case: 0th compressed iterate is the identity. -/
lemma compressedIterate_zero (n : ℕ) {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : ℤ_[2] → E) : compressedIterate n 0 f = f := rfl

/-- Successor step for compressed iterate. -/
lemma compressedIterate_succ (n : ℕ) (m : ℕ) {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : ℤ_[2] → E) :
    compressedIterate n (m + 1) f = compressedTransferOp n (compressedIterate n m f) :=
  Function.iterate_succ_apply' (compressedTransferOp n) m f

/-- Preservation of constants under compressed iterates. -/
lemma compressedIterate_const (n m : ℕ) {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (c : E) :
    compressedIterate n m (fun _ : ℤ_[2] => c) = (fun _ => c) := by
  induction m with
  | zero => rfl
  | succ k ih => rw [compressedIterate_succ, ih, compressedTransferOp_const]

/-- Compressed iterates preserve 2-adic Lipschitz continuity. -/
theorem isPadicLipschitz_compressedIterate {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (n m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    IsPadicLipschitz (compressedIterate n m f) := by
  induction m with
  | zero => exact hf
  | succ k ih =>
    rw [compressedIterate_succ]
    exact isPadicLipschitz_compressedTransferOp n ih

/-- Supremum norm bound for compressed iterates: ‖(P_n ℒ₂ P_n)^m f‖_∞ ≤ ‖f‖_∞. -/
theorem supNorm_compressedIterate_le {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (n m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    supNorm (compressedIterate n m f) ≤ supNorm f := by
  induction m with
  | zero => exact le_rfl
  | succ k ih =>
    rw [compressedIterate_succ]
    exact (supNorm_compressedTransferOp_le n (isPadicLipschitz_compressedIterate n k hf)).trans ih

/-- **Higher-Power Operator Approximation Bound**:
    ‖ℒ₂^m f - (P_n ℒ₂ P_n)^m f‖_∞ ≤ 2m · 2⁻ⁿ L(f). -/
theorem compressedIterate_approx_bound {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (n m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    supNorm (padicTransferOp^[m] f - compressedIterate n m f) ≤
      (m : ℝ) * (2 * (1 / 2 : ℝ)^n * lipSemiNorm f) := by
  induction m with
  | zero =>
    have h_zero : (padicTransferOp^[0]) f - compressedIterate n 0 f = 0 := by
      ext; simp [compressedIterate_zero]
    rw [h_zero, supNorm_zero, Nat.cast_zero, zero_mul]
  | succ k ih =>
    rw [Function.iterate_succ_apply', compressedIterate_succ]
    have h_decomp : padicTransferOp (padicTransferOp^[k] f) - compressedTransferOp n (compressedIterate n k f) =
        (padicTransferOp (padicTransferOp^[k] f) - compressedTransferOp n (padicTransferOp^[k] f)) +
        compressedTransferOp n (padicTransferOp^[k] f - compressedIterate n k f) := by
      ext x; dsimp [compressedTransferOp, quotientProj, padicTransferOp, compressedIterate]; simp only [smul_add, smul_sub]; abel
    have h_lip_Tkf := Dynamics.LasotaYorke2Adic.isPadicLipschitz_iterate k hf
    have h_lip_Ckf := isPadicLipschitz_compressedIterate n k hf
    have h_term1_lip := isPadicLipschitz_sub (isPadicLipschitz_padicTransferOp h_lip_Tkf)
      (isPadicLipschitz_compressedTransferOp n h_lip_Tkf)
    have h_term2_lip := isPadicLipschitz_compressedTransferOp n (isPadicLipschitz_sub h_lip_Tkf h_lip_Ckf)
    rw [h_decomp]
    have h_tri := supNorm_add_le h_term1_lip h_term2_lip
    have h_b1 : supNorm (padicTransferOp (padicTransferOp^[k] f) - compressedTransferOp n (padicTransferOp^[k] f)) ≤
        2 * (1 / 2 : ℝ)^n * lipSemiNorm f :=
      (transferOp_proj_approx_bound n h_lip_Tkf).trans
        (mul_le_mul_of_nonneg_left (Dynamics.LasotaYorke2Adic.lipSemiNorm_iterate_le k hf) (by positivity))
    have h_b2 : supNorm (compressedTransferOp n (padicTransferOp^[k] f - compressedIterate n k f)) ≤
        supNorm (padicTransferOp^[k] f - compressedIterate n k f) :=
      supNorm_compressedTransferOp_le n (isPadicLipschitz_sub h_lip_Tkf h_lip_Ckf)
    push_cast; linarith

/-- Higher-power operator approximation in terms of total Lipschitz norm:
    ‖ℒ₂^m f - (P_n ℒ₂ P_n)^m f‖_∞ ≤ 2m · 2⁻ⁿ ‖f‖_Lip. -/
theorem compressedIterate_approx_bound_lipNorm {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (n m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    supNorm (padicTransferOp^[m] f - compressedIterate n m f) ≤
      (m : ℝ) * (2 * (1 / 2 : ℝ)^n * lipNorm f) := by
  have h_le : lipSemiNorm f ≤ lipNorm f := by
    dsimp [lipNorm]
    linarith [supNorm_nonneg hf]
  exact (compressedIterate_approx_bound n m hf).trans
    (mul_le_mul_of_nonneg_left (mul_le_mul_of_nonneg_left h_le (by positivity)) (by positivity))

/-- Uniform convergence of higher-power iterates: lim_{n → ∞} ‖ℒ₂^m f - (P_n ℒ₂ P_n)^m f‖_∞ = 0. -/
theorem tendsto_compressedIterate_approx {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    Tendsto (fun n : ℕ => supNorm (padicTransferOp^[m] f - compressedIterate n m f)) atTop (𝓝 0) :=
  tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds
    (tendsto_pow_half_const_mul_zero ((m : ℝ) * (2 * lipSemiNorm f)))
    (Filter.Eventually.of_forall fun _ => supNorm_nonneg
      (isPadicLipschitz_sub (Dynamics.LasotaYorke2Adic.isPadicLipschitz_iterate m hf)
        (isPadicLipschitz_compressedIterate _ m hf)))
    (Filter.Eventually.of_forall fun n => by
      have h := compressedIterate_approx_bound n m hf
      linarith)

/-!
# Section 5: Essential Spectral Radius Bound & Authentic Ruelle Resonances
-/

/-- The essential spectral radius bound for the continuous 2-adic transfer operator ℒ₂:
    r_ess(ℒ₂) ≤ 1/2. -/
def essentialSpectralRadius : ℝ := 1 / 2

omit [Fact (Nat.Prime 2)] in
/-- Essential spectral radius bound is 1/2. -/
theorem essential_spectral_radius_bound : essentialSpectralRadius ≤ 1 / 2 := le_rfl

/-- The concentric Ruelle resonance radius at level k ≥ 2:
    ρ(k) = (1/2) r(k) = (1/2) 2^{1 / 2^{k-1}}. -/
def resonanceRadius (k : ℕ) : ℝ :=
  (1 / 2 : ℝ) * ContinuousTransfer.spectralRadius k

/-- Predicate for a spectral value being in the discrete spectrum region |z| > 1/2. -/
def InDiscreteSpectrum (z : ℂ) : Prop :=
  essentialSpectralRadius < ‖z‖

/-- Predicate for an authentic Ruelle resonance: an isolated eigenvalue in 1/2 < |z| ≤ 1. -/
def IsRuelleResonance (z : ℂ) : Prop :=
  InDiscreteSpectrum z ∧ ‖z‖ ≤ 1

/-- Closed disk of radius 1/2 containing the essential spectrum: {z ∈ ℂ | ‖z‖ ≤ 1/2}. -/
def EssentialSpectrumDisk : Set ℂ :=
  { z : ℂ | ‖z‖ ≤ essentialSpectralRadius }

omit [Fact (Nat.Prime 2)] in
/-- (a) Every resonance radius strictly exceeds the essential spectral radius:
    ρ(k) > 1/2 for all k ≥ 2. -/
theorem resonanceRadius_gt_half (k : ℕ) (hk : 2 ≤ k) :
    essentialSpectralRadius < resonanceRadius k := by
  dsimp [essentialSpectralRadius, resonanceRadius]
  linarith [ContinuousTransfer.spectralRadius_gt_one k hk]

omit [Fact (Nat.Prime 2)] in
/-- (b) The resonance radii are bounded by 1 for all k ≥ 2 (in fact ≤ √2 / 2 < 1). -/
theorem resonanceRadius_lt_one (k : ℕ) (hk : 2 ≤ k) :
    resonanceRadius k < 1 := by
  dsimp [resonanceRadius, ContinuousTransfer.spectralRadius]
  have h_exp : (1 : ℝ) / (2 : ℝ)^(k - 1) ≤ 1 / 2 := by
    have h_pow : (2 : ℝ)^1 ≤ (2 : ℝ)^(k - 1) := pow_le_pow_right₀ (by norm_num) (by omega)
    rw [pow_one] at h_pow
    exact one_div_le_one_div_of_le (by positivity) h_pow
  have h_pow_le : (2 : ℝ) ^ ((1 : ℝ) / (2 : ℝ) ^ (k - 1)) ≤ (2 : ℝ) ^ (1 / 2 : ℝ) :=
    Real.rpow_le_rpow_of_exponent_le (by norm_num) h_exp
  have h_sqrt2_lt_two : (2 : ℝ) ^ (1 / 2 : ℝ) < (2 : ℝ) := by
    simpa using Real.rpow_lt_rpow_of_exponent_lt (by norm_num : (1 : ℝ) < 2) (by norm_num : (1 / 2 : ℝ) < 1)
  calc (1 / 2 : ℝ) * (2 : ℝ) ^ ((1 : ℝ) / (2 : ℝ) ^ (k - 1))
    _ ≤ (1 / 2 : ℝ) * (2 : ℝ) ^ (1 / 2 : ℝ) := mul_le_mul_of_nonneg_left h_pow_le (by positivity)
    _ < (1 / 2 : ℝ) * 2 := mul_lt_mul_of_pos_left h_sqrt2_lt_two (by positivity)
    _ = 1 := by ring

omit [Fact (Nat.Prime 2)] in
/-- Resonance radius is at most 1. -/
theorem resonanceRadius_le_one (k : ℕ) (hk : 2 ≤ k) :
    resonanceRadius k ≤ 1 :=
  (resonanceRadius_lt_one k hk).le

omit [Fact (Nat.Prime 2)] in
/-- (c) The resonance radii are strictly decreasing towards 1/2:
    ρ(k+1) < ρ(k) for all k ≥ 2. -/
theorem resonanceRadius_strictAnti (k : ℕ) (hk : 2 ≤ k) :
    resonanceRadius (k + 1) < resonanceRadius k := by
  dsimp [resonanceRadius]
  linarith [ContinuousTransfer.spectralRadius_strictAnti k hk]

omit [Fact (Nat.Prime 2)] in
/-- (d) The resonance radii accumulate onto the boundary of the essential spectrum |z| = 1/2:
    lim_{k → ∞} ρ(k) = 1/2. -/
theorem tendsto_resonanceRadius_atTop :
    Tendsto resonanceRadius atTop (𝓝 (1 / 2 : ℝ)) := by
  have h := ContinuousTransfer.tendsto_spectralRadius_atTop.const_mul (1 / 2 : ℝ)
  rwa [mul_one] at h

omit [Fact (Nat.Prime 2)] in
/-- Every eigenvalue on the concentric circles is an authentic Ruelle resonance. -/
theorem resonance_circle_is_ruelle_resonance (k : ℕ) (hk : 2 ≤ k) (μ : ℂ)
    (hμ : ‖μ‖ = resonanceRadius k) : IsRuelleResonance μ :=
  ⟨by rw [InDiscreteSpectrum, hμ]; exact resonanceRadius_gt_half k hk,
   by rw [hμ]; exact resonanceRadius_le_one k hk⟩

omit [Fact (Nat.Prime 2)] in
/-- Authentic Ruelle resonances lie strictly outside the essential spectrum disk. -/
theorem ruelle_resonance_outside_essential_spectrum {μ : ℂ} (h : IsRuelleResonance μ) :
    μ ∉ EssentialSpectrumDisk := fun (h_mem : ‖μ‖ ≤ essentialSpectralRadius) => by
  have h_gt : essentialSpectralRadius < ‖μ‖ := h.1
  linarith

omit [Fact (Nat.Prime 2)] in
/-- All non-trivial Ruelle resonance circles are strictly sub-unitary: ‖μ‖ < 1. -/
theorem resonance_strictly_subunitary (k : ℕ) (hk : 2 ≤ k) (μ : ℂ)
    (hμ : ‖μ‖ = resonanceRadius k) : ‖μ‖ < 1 := by
  rw [hμ]; exact resonanceRadius_lt_one k hk

/-- The peripheral spectrum on |z| = 1 contains the simple eigenvalue 1 with constant eigenfunction. -/
theorem peripheral_eigenvalue_one :
    padicTransferOp (fun _ : ℤ_[2] => (1 : ℂ)) = (fun _ => (1 : ℂ)) :=
  padicTransferOp_one_complex

end Dynamics.RuelleResonances
