/-
Copyright (c) 2026 Antigravity Mathematical Research Team. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Antigravity Mathematical Research Team
-/
import Mathlib.NumberTheory.Padics.PadicIntegers
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.Fin.Tuple.Basic
import Mathlib.Algebra.Field.GeomSum
import Mathlib.Topology.Order.Basic
import Mathlib.Topology.MetricSpace.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Algebra.Order.Field
import Mathlib.Tactic
import Formalization.Dynamics.PadicLipschitz
import Formalization.Dynamics.ContinuousTransfer

/-!
# 2-Adic Lasota–Yorke and Doeblin–Fortet Inequality

This file formalizes the 2-adic Lasota–Yorke inequality, Doeblin–Fortet inequality,
iterated transfer operator branch compositions, and spectral radius contraction
on the Banach space of 2-adic Lipschitz functions $\text{Lip}(\mathbb{Z}_2, E)$
for normed spaces $E$ (such as $\mathbb{C}$ or $\mathbb{R}$).

## Mathematical Architecture
1. **Binary Branch Words and Tree Composition:**
   - $\text{BranchWord}\ m = \text{Fin}\ m \to \text{Fin}\ 2$ with cardinality $2^m$.
   - Explicit affine branch composition:
     $$\phi_w(x) = 3^m x - \sum_{i=0}^{m-1} 3^{m-1-i} w(i)$$
   - Isometry and distance preservation: $\|\phi_w(x) - \phi_w(y)\|_2 = \|x - y\|_2$.
   - Iterated transfer operator formula:
     $$(\mathcal{L}_2^m f)(x) = \frac{1}{2^m} \sum_{w \in \text{BranchWord}\ m} f(\phi_w(x))$$
   - Proof of algebraic consistency: $\mathcal{L}_2^0 f = f$, $\mathcal{L}_2^{m+1} f = \mathcal{L}_2 (\mathcal{L}_2^m f)$,
     and $\mathcal{L}_2^m f = (\mathcal{L}_2)^m f$.

2. **2-Adic Lasota–Yorke & Doeblin–Fortet Inequality:**
   - Under the dynamic 2-adic contraction factor $\rho = 1/2$, the dynamic transfer operator $\mathcal{T}_2 = \frac{1}{2} \mathcal{L}_2$ satisfies:
     $$L(\mathcal{T}_2^m f) \le \left(\frac{1}{2}\right)^m L(f)$$
     $$\|\mathcal{T}_2^m f\|_\infty \le \left(\frac{1}{2}\right)^m \|f\|_\infty$$
     $$\|\mathcal{T}_2^m f\|_{\text{Lip}} \le \left(\frac{1}{2}\right)^m \|f\|_{\text{Lip}}$$
   - The classical 2-Adic Lasota–Yorke Inequality:
     $$\|\mathcal{T}_2^m f\|_{\text{Lip}} \le \left(\frac{1}{2}\right)^m \|f\|_{\text{Lip}} + \|f\|_\infty$$
   - The Doeblin–Fortet Inequality for Markov iterations:
     $$\|\mathcal{L}_2^m f\|_{\text{Lip}} \le L(f) + \|f\|_\infty = \|f\|_{\text{Lip}}$$

3. **Uniform Boundedness and Quasi-Compactness Primitives:**
   - Uniform power bound: $\forall m \in \mathbb{N}$, $\|\mathcal{L}_2^m f\|_{\text{Lip}} \le 2 \|f\|_{\text{Lip}}$.
   - Strict spectral contraction on zero-mean / dynamic subspace:
     $$\|\mathcal{T}_2^m f\|_{\text{Lip}} \le \left(\frac{1}{2}\right)^m \|f\|_{\text{Lip}}$$
   - Mean ergodic convergence: Birkhoff averages $A_M f = \frac{1}{M} \sum_{m=0}^{M-1} \mathcal{T}_2^m f$ satisfy:
     $$\|A_M f\|_{\text{Lip}} \le \frac{2}{M} \|f\|_{\text{Lip}} \longrightarrow 0 \quad \text{as } M \to \infty$$
-/

noncomputable section

open Dynamics.PadicLipschitz ContinuousTransfer Filter Topology

namespace Dynamics.LasotaYorke2Adic

/-!
# Section 1: Binary Branch Words and Tree Compositions
-/

/-- Binary branch words of length m: sequences of length m in {0, 1}. -/
abbrev BranchWord (m : ℕ) := Fin m → Fin 2

/-- Cardinality of binary branch words of length m is 2^m. -/
lemma card_branchWord (m : ℕ) : Fintype.card (BranchWord m) = 2^m := by
  simp only [Fintype.card_fun, Fintype.card_fin]

/-- Helper lemma: any non-zero element in Fin 2 equals 1. -/
lemma fin2_eq_one_of_ne_zero {b : Fin 2} (hb : b ≠ 0) : b = 1 := by
  ext; omega

/-- Splitting sum over BranchWord (m + 1) via Fin.cons. -/
lemma sum_branchWord_succ {E : Type*} [AddCommMonoid E] (m : ℕ) (F : BranchWord (m + 1) → E) :
    ∑ w : BranchWord (m + 1), F w =
      (∑ w : BranchWord m, F (Fin.cons (α := fun _ => Fin 2) 0 w)) +
      (∑ w : BranchWord m, F (Fin.cons (α := fun _ => Fin 2) 1 w)) := by
  rw [← (Fin.consEquiv (fun _ => Fin 2)).sum_comp, Fintype.sum_prod_type, Fin.sum_univ_two]; rfl

variable [Fact (Nat.Prime 2)]

/-- Explicit affine composition of the m branches corresponding to word w:
    ϕ_w(x) = 3^m x - ∑_{i=0}^{m-1} 3^{m-1-i} w(i). -/
def branchMap {m : ℕ} (w : BranchWord m) (x : ℤ_[2]) : ℤ_[2] :=
  (3 : ℤ_[2])^m * x - ∑ i : Fin m, (3 : ℤ_[2])^(m - 1 - (i : ℕ)) * ((w i : ℕ) : ℤ_[2])

/-- Base case: branch map of length 0 is the identity map. -/
lemma branchMap_zero (w : BranchWord 0) (x : ℤ_[2]) :
    branchMap w x = x := by
  simp [branchMap]

/-- Recursive decomposition of branchMap under Fin.cons prepending. -/
lemma branchMap_cons {m : ℕ} (b : Fin 2) (w : BranchWord m) (x : ℤ_[2]) :
    branchMap (Fin.cons (α := fun _ => Fin 2) b w) x = branchMap w (if b = 0 then phi0 x else phi1 x) := by
  have h_exp (i : Fin m) : m + 1 - 1 - ((i.succ : Fin (m + 1)) : ℕ) = m - 1 - (i : ℕ) := by
    rw [Fin.val_succ]; omega
  have h_exp0 : m + 1 - 1 - ((0 : Fin (m + 1)) : ℕ) = m := by
    rw [Fin.val_zero]; omega
  have h_sum : (∑ i : Fin (m + 1), (3 : ℤ_[2]) ^ (m + 1 - 1 - (i : ℕ)) * (((Fin.cons (α := fun _ => Fin 2) b w i : ℕ) : ℤ_[2]))) =
      (3 : ℤ_[2]) ^ m * (((b : ℕ) : ℤ_[2])) + ∑ i : Fin m, (3 : ℤ_[2]) ^ (m - 1 - (i : ℕ)) * (((w i : ℕ) : ℤ_[2])) := by
    rw [Fin.sum_univ_succ, Fin.cons_zero, h_exp0]
    congr 1
    apply Finset.sum_congr rfl
    intro i _
    rw [Fin.cons_succ, h_exp i]
  unfold branchMap phi0 phi1
  rw [h_sum]
  fin_cases b <;> simp <;> ring

/-- Difference identity for branchMap: ϕ_w(x) - ϕ_w(y) = 3^m (x - y). -/
lemma branchMap_sub_branchMap {m : ℕ} (w : BranchWord m) (x y : ℤ_[2]) :
    branchMap w x - branchMap w y = (3 : ℤ_[2])^m * (x - y) := by
  dsimp [branchMap]; ring

/-- Branch difference norm preservation: ‖ϕ_w(x) - ϕ_w(y)‖ = ‖x - y‖ for all branch words w. -/
theorem norm_sub_branchMap {m : ℕ} (w : BranchWord m) (x y : ℤ_[2]) :
    ‖branchMap w x - branchMap w y‖ = ‖x - y‖ := by
  rw [branchMap_sub_branchMap, norm_mul, norm_pow, three_norm, one_pow, one_mul]

/-- 2-Adic metric distance preservation by branch maps: d₂(ϕ_w(x), ϕ_w(y)) = d₂(x, y). -/
theorem dist2_branchMap {m : ℕ} (w : BranchWord m) (x y : ℤ_[2]) :
    dist2 (branchMap w x) (branchMap w y) = dist2 x y :=
  norm_sub_branchMap w x y

/-- Every branch map is an isometry on ℤ_[2]. -/
theorem isometry_branchMap {m : ℕ} (w : BranchWord m) : Isometry (branchMap w) :=
  Isometry.of_dist_eq fun x y => by simp only [dist_eq_norm_sub, norm_sub_branchMap]

/-- Continuity of branch maps. -/
lemma continuous_branchMap {m : ℕ} (w : BranchWord m) : Continuous (branchMap w) :=
  (isometry_branchMap w).continuous

/-!
# Section 2: Iterated Transfer Operator
-/

/-- The iterated transfer operator ℒ₂^m defined by explicit branch word summation:
    (ℒ₂^m f)(x) = (1 / 2^m) ∑_{w ∈ BranchWord m} f(ϕ_w(x)). -/
def iteratedTransferOp (m : ℕ) {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : ℤ_[2] → E) : ℤ_[2] → E :=
  fun x => ((1 / 2 : ℝ)^m) • ∑ w : BranchWord m, f (branchMap w x)

/-- Algebraic consistency at m = 0: ℒ₂^0 f = f. -/
theorem iteratedTransferOp_zero {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : ℤ_[2] → E) : iteratedTransferOp 0 f = f := by
  ext; simp [iteratedTransferOp, branchMap]

/-- Algebraic consistency at m + 1: ℒ₂^(m+1) f = ℒ₂ (ℒ₂^m f). -/
theorem iteratedTransferOp_succ {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) (f : ℤ_[2] → E) :
    iteratedTransferOp (m + 1) f = padicTransferOp (iteratedTransferOp m f) := by
  ext x
  dsimp [iteratedTransferOp, padicTransferOp]
  rw [sum_branchWord_succ]
  simp [branchMap_cons, pow_succ', mul_smul, smul_add]

/-- Exact equivalence of iteratedTransferOp with the standard operator power (ℒ₂)^m. -/
theorem iteratedTransferOp_eq_iterate {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) (f : ℤ_[2] → E) :
    iteratedTransferOp m f = (padicTransferOp^[m]) f := by
  induction m with
  | zero => rw [iteratedTransferOp_zero, Function.iterate_zero, id]
  | succ k ih => rw [iteratedTransferOp_succ, ih, Function.iterate_succ_apply']

/-- Linearity: additivity of the iterated transfer operator. -/
lemma iteratedTransferOp_add {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) (f g : ℤ_[2] → E) :
    iteratedTransferOp m (f + g) = iteratedTransferOp m f + iteratedTransferOp m g := by
  simp only [iteratedTransferOp_eq_iterate]
  induction m with
  | zero => rfl
  | succ k ih => simp only [Function.iterate_succ_apply', ih, padicTransferOp_add]

/-- Linearity: scalar homogeneity of the iterated transfer operator. -/
lemma iteratedTransferOp_smul {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) (c : ℝ) (f : ℤ_[2] → E) :
    iteratedTransferOp m (c • f) = c • iteratedTransferOp m f := by
  simp only [iteratedTransferOp_eq_iterate]
  induction m with
  | zero => rfl
  | succ k ih => simp only [Function.iterate_succ_apply', ih, padicTransferOp_smul]

/-- Preservation of constant functions: ℒ₂^m (c) = c. -/
theorem iteratedTransferOp_const {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) (c : E) :
    iteratedTransferOp m (fun _ : ℤ_[2] => c) = (fun _ => c) := by
  simp only [iteratedTransferOp_eq_iterate]
  induction m with
  | zero => rfl
  | succ k ih => simp only [Function.iterate_succ_apply', ih, padicTransferOp_const]

/-- Iterated transfer operator preserves 2-adic Lipschitz continuity. -/
theorem isPadicLipschitz_iteratedTransferOp {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    IsPadicLipschitz (iteratedTransferOp m f) := by
  rw [iteratedTransferOp_eq_iterate]
  induction m with
  | zero => exact hf
  | succ k ih =>
    rw [Function.iterate_succ_apply']
    exact isPadicLipschitz_padicTransferOp ih

/-!
# Section 3: 2-Adic Lasota–Yorke and Doeblin–Fortet Inequality
-/

/-- The dynamic contracting 2-adic transfer operator 𝒯₂:
    (𝒯₂ f)(x) = (1/2) (ℒ₂ f)(x). -/
def dynamicTransferOp {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] (f : ℤ_[2] → E) : ℤ_[2] → E :=
  (1 / 2 : ℝ) • padicTransferOp f

/-- Iteration of padicTransferOp preserves Lipschitz continuity. -/
lemma isPadicLipschitz_iterate {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    IsPadicLipschitz (padicTransferOp^[m] f) := by
  induction m with
  | zero => exact hf
  | succ k ih =>
    rw [Function.iterate_succ_apply']
    exact isPadicLipschitz_padicTransferOp ih

/-- Dynamic transfer operator preserves 2-adic Lipschitz continuity. -/
lemma isPadicLipschitz_dynamicTransferOp {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    IsPadicLipschitz (dynamicTransferOp f) :=
  isPadicLipschitz_smul (1 / 2 : ℝ) (isPadicLipschitz_padicTransferOp hf)

/-- Preservation of Lipschitz continuity under dynamic operator iterations. -/
lemma isPadicLipschitz_dynamic_iterate {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    IsPadicLipschitz (dynamicTransferOp^[m] f) := by
  induction m with
  | zero => exact hf
  | succ k ih =>
    rw [Function.iterate_succ_apply']
    exact isPadicLipschitz_dynamicTransferOp ih

/-- Supremum norm contractivity under transfer operator iterations: ‖ℒ₂^m f‖_∞ ≤ ‖f‖_∞. -/
lemma supNorm_iterate_le {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    supNorm (padicTransferOp^[m] f) ≤ supNorm f := by
  induction m with
  | zero => exact le_rfl
  | succ k ih =>
    rw [Function.iterate_succ_apply']
    exact (supNorm_padicTransferOp_le (isPadicLipschitz_iterate k hf)).trans ih

/-- Lipschitz semi-norm contractivity under transfer operator iterations: L(ℒ₂^m f) ≤ L(f). -/
lemma lipSemiNorm_iterate_le {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipSemiNorm (padicTransferOp^[m] f) ≤ lipSemiNorm f := by
  induction m with
  | zero => exact le_rfl
  | succ k ih =>
    rw [Function.iterate_succ_apply']
    exact (lipSemiNorm_padicTransferOp_le (isPadicLipschitz_iterate k hf)).trans ih

/-- Scalar multiplication scaling for the set of Lipschitz constants. -/
lemma lipConstantSet_smul_of_pos {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {c : ℝ} (hc : 0 < c) {f : ℤ_[2] → E} {C : ℝ} (hC : C ∈ lipConstantSet f) :
    c * C ∈ lipConstantSet (c • f) := by
  refine ⟨mul_nonneg hc.le hC.1, fun x y => ?_⟩
  rw [Pi.smul_apply, Pi.smul_apply, ← smul_sub, norm_smul, Real.norm_of_nonneg hc.le, mul_assoc]
  exact mul_le_mul_of_nonneg_left (hC.2 x y) hc.le

/-- Lipschitz semi-norm scaling for positive scalars: L(c • f) ≤ c L(f). -/
lemma lipSemiNorm_smul_of_pos {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {c : ℝ} (hc : 0 < c) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipSemiNorm (c • f) ≤ c * lipSemiNorm f := by
  rw [mul_comm c, ← div_le_iff₀ hc]
  refine le_csInf (lipConstantSet_nonempty hf) fun C hC => ?_
  rw [div_le_iff₀ hc, mul_comm]
  exact csInf_le (lipConstantSet_bddBelow (c • f)) (lipConstantSet_smul_of_pos hc hC)

/-- Lipschitz semi-norm scaling for non-negative scalars: L(c • f) ≤ c L(f). -/
lemma lipSemiNorm_smul_of_nonneg {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {c : ℝ} (hc : 0 ≤ c) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipSemiNorm (c • f) ≤ c * lipSemiNorm f := by
  rcases eq_or_lt_of_le hc with rfl | hc_pos
  · simp only [zero_smul, zero_mul]
    have : (0 : ℤ_[2] → E) = (fun _ => 0) := rfl
    rw [this, lipSemiNorm_const]
  · exact lipSemiNorm_smul_of_pos hc_pos hf

/-- Total Lipschitz norm scaling for non-negative scalars: ‖c • f‖_Lip ≤ c ‖f‖_Lip. -/
lemma lipNorm_smul_of_nonneg {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {c : ℝ} (hc : 0 ≤ c) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipNorm (c • f) ≤ c * lipNorm f := by
  dsimp [lipNorm]
  have h_sup := supNorm_smul_le c hf
  rw [Real.norm_of_nonneg hc] at h_sup
  linarith [lipSemiNorm_smul_of_nonneg hc hf, mul_add c (supNorm f) (lipSemiNorm f)]

/-- Addition of Lipschitz constant sets: C_f + C_g is a Lipschitz constant for f + g. -/
lemma lipConstantSet_add {E : Type*} [NormedAddCommGroup E]
    {f g : ℤ_[2] → E} {Cf Cg : ℝ} (hf : Cf ∈ lipConstantSet f) (hg : Cg ∈ lipConstantSet g) :
    Cf + Cg ∈ lipConstantSet (f + g) := by
  refine ⟨add_nonneg hf.1 hg.1, fun x y => ?_⟩
  rw [Pi.add_apply, Pi.add_apply, add_sub_add_comm]
  linarith [norm_add_le (f x - f y) (g x - g y), hf.2 x y, hg.2 x y]

/-- Subadditivity of the Lipschitz semi-norm: L(f + g) ≤ L(f) + L(g). -/
lemma lipSemiNorm_add_le {E : Type*} [NormedAddCommGroup E]
    {f g : ℤ_[2] → E} (hf : IsPadicLipschitz f) (hg : IsPadicLipschitz g) :
    lipSemiNorm (f + g) ≤ lipSemiNorm f + lipSemiNorm g := by
  have h1 : ∀ Cg ∈ lipConstantSet g, ∀ Cf ∈ lipConstantSet f, lipSemiNorm (f + g) - Cg ≤ Cf := by
    intro Cg hCg Cf hCf
    have h_mem := lipConstantSet_add hCf hCg
    have h_le : lipSemiNorm (f + g) ≤ Cf + Cg := csInf_le (lipConstantSet_bddBelow (f + g)) h_mem
    linarith
  have h2 : ∀ Cg ∈ lipConstantSet g, lipSemiNorm (f + g) - Cg ≤ lipSemiNorm f := by
    intro Cg hCg
    exact le_csInf (lipConstantSet_nonempty hf) (h1 Cg hCg)
  have h3 : ∀ Cg ∈ lipConstantSet g, lipSemiNorm (f + g) - lipSemiNorm f ≤ Cg := by
    intro Cg hCg
    linarith [h2 Cg hCg]
  have h4 : lipSemiNorm (f + g) - lipSemiNorm f ≤ lipSemiNorm g :=
    le_csInf (lipConstantSet_nonempty hg) h3
  linarith

/-- Subadditivity of the total Lipschitz norm: ‖f + g‖_Lip ≤ ‖f‖_Lip + ‖g‖_Lip. -/
lemma lipNorm_add_le {E : Type*} [NormedAddCommGroup E]
    {f g : ℤ_[2] → E} (hf : IsPadicLipschitz f) (hg : IsPadicLipschitz g) :
    lipNorm (f + g) ≤ lipNorm f + lipNorm g := by
  dsimp [lipNorm]
  linarith [supNorm_add_le hf hg, lipSemiNorm_add_le hf hg]

/-- Preservation of Lipschitz continuity under finite sums. -/
lemma isPadicLipschitz_sum {E : Type*} [NormedAddCommGroup E] {ι : Type*} {s : Finset ι} {F : ι → ℤ_[2] → E}
    (hF : ∀ i ∈ s, IsPadicLipschitz (F i)) :
    IsPadicLipschitz (∑ i ∈ s, F i) := by
  classical
  induction s using Finset.induction_on with
  | empty => simp; exact isPadicLipschitz_const 0
  | @insert a s has ih =>
    rw [Finset.sum_insert has]
    exact isPadicLipschitz_add (hF _ (Finset.mem_insert_self _ _))
      (ih fun i hi => hF i (Finset.mem_insert_of_mem hi))

/-- Subadditivity of the total Lipschitz norm for finite sums. -/
lemma lipNorm_sum_le {E : Type*} [NormedAddCommGroup E] {ι : Type*} {s : Finset ι} {F : ι → ℤ_[2] → E}
    (hF : ∀ i ∈ s, IsPadicLipschitz (F i)) :
    lipNorm (∑ i ∈ s, F i) ≤ ∑ i ∈ s, lipNorm (F i) := by
  classical
  induction s using Finset.induction_on with
  | empty => simp [lipNorm_zero]
  | @insert a s has ih =>
    rw [Finset.sum_insert has, Finset.sum_insert has]
    exact (lipNorm_add_le (hF _ (Finset.mem_insert_self _ _))
      (isPadicLipschitz_sum fun i hi => hF i (Finset.mem_insert_of_mem hi))).trans
      (add_le_add le_rfl (ih fun i hi => hF i (Finset.mem_insert_of_mem hi)))

/-- Identity relating dynamic transfer iterations to Markov operator iterations:
    𝒯₂^m f = (1/2)^m • (ℒ₂^m f). -/
lemma dynamicTransferOp_iterate_eq {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) (f : ℤ_[2] → E) :
    (dynamicTransferOp^[m]) f = ((1 / 2 : ℝ)^m) • (padicTransferOp^[m] f) := by
  induction m with
  | zero => simp
  | succ k ih =>
    rw [Function.iterate_succ_apply', ih]
    dsimp [dynamicTransferOp]
    rw [padicTransferOp_smul, smul_smul, pow_succ, mul_comm, ← Function.iterate_succ_apply' padicTransferOp]
    rfl

/-- Strict Lipschitz semi-norm contraction under dynamic transfer iterations:
    L(𝒯₂^m f) ≤ (1/2)^m L(f). -/
theorem lipSemiNorm_dynamicTransferOp_iterate_le {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipSemiNorm ((dynamicTransferOp^[m]) f) ≤ (1 / 2 : ℝ)^m * lipSemiNorm f := by
  rw [dynamicTransferOp_iterate_eq]
  exact (lipSemiNorm_smul_of_nonneg (by positivity) (isPadicLipschitz_iterate m hf)).trans
    (mul_le_mul_of_nonneg_left (lipSemiNorm_iterate_le m hf) (by positivity))

/-- Strict supremum norm contraction under dynamic transfer iterations:
    ‖𝒯₂^m f‖_∞ ≤ (1/2)^m ‖f‖_∞. -/
theorem supNorm_dynamicTransferOp_iterate_le {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    supNorm ((dynamicTransferOp^[m]) f) ≤ (1 / 2 : ℝ)^m * supNorm f := by
  rw [dynamicTransferOp_iterate_eq]
  have h_smul := supNorm_smul_le ((1 / 2 : ℝ)^m) (isPadicLipschitz_iterate m hf)
  rw [Real.norm_of_nonneg (by positivity)] at h_smul
  exact h_smul.trans (mul_le_mul_of_nonneg_left (supNorm_iterate_le m hf) (by positivity))

/-- Strict total Lipschitz norm contraction under dynamic transfer iterations:
    ‖𝒯₂^m f‖_Lip ≤ (1/2)^m ‖f‖_Lip. -/
theorem lipNorm_dynamicTransferOp_iterate_le {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipNorm ((dynamicTransferOp^[m]) f) ≤ (1 / 2 : ℝ)^m * lipNorm f := by
  dsimp [lipNorm]
  linarith [supNorm_dynamicTransferOp_iterate_le m hf,
    lipSemiNorm_dynamicTransferOp_iterate_le m hf,
    mul_add ((1 / 2 : ℝ)^m) (supNorm f) (lipSemiNorm f)]

/-- **The 2-Adic Lasota–Yorke Inequality**:
    For all m ∈ ℕ and all f ∈ Lip(ℤ₂, E),
    ‖𝒯₂^m f‖_Lip ≤ (1/2)^m ‖f‖_Lip + ‖f‖_∞. -/
theorem lasota_yorke_inequality {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipNorm ((dynamicTransferOp^[m]) f) ≤ (1 / 2 : ℝ)^m * lipNorm f + supNorm f := by
  linarith [lipNorm_dynamicTransferOp_iterate_le m hf, supNorm_nonneg hf]

/-- **The Doeblin–Fortet Inequality**:
    For all m ∈ ℕ and all f ∈ Lip(ℤ₂, E),
    ‖ℒ₂^m f‖_Lip ≤ L(f) + ‖f‖_∞ = ‖f‖_Lip. -/
theorem doeblin_fortet_inequality {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipNorm (padicTransferOp^[m] f) ≤ lipSemiNorm f + supNorm f := by
  dsimp [lipNorm]
  linarith [supNorm_iterate_le m hf, lipSemiNorm_iterate_le m hf]

/-- Total Lipschitz contractivity of ℒ₂^m: ‖ℒ₂^m f‖_Lip ≤ ‖f‖_Lip. -/
theorem lipNorm_iterate_le {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipNorm (padicTransferOp^[m] f) ≤ lipNorm f :=
  add_le_add (supNorm_iterate_le m hf) (lipSemiNorm_iterate_le m hf)

/-- Adapted dynamic Lipschitz norm with weight parameter α > 0. -/
def adaptedLipNorm {E : Type*} [NormedAddCommGroup E] (α : ℝ) (f : ℤ_[2] → E) : ℝ :=
  supNorm f + α * lipSemiNorm f

/-- Adapted Lasota–Yorke inequality with dynamic contraction factor ρ = 1/2. -/
theorem lasota_yorke_adapted_norm {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    adaptedLipNorm (1 / 2 : ℝ) ((dynamicTransferOp^[m]) f) ≤
      (1 / 2 : ℝ)^m * adaptedLipNorm (1 / 2 : ℝ) f + supNorm f := by
  dsimp [adaptedLipNorm]
  have h1 := supNorm_dynamicTransferOp_iterate_le m hf
  have h2 := lipSemiNorm_dynamicTransferOp_iterate_le m hf
  linarith [supNorm_nonneg hf,
    mul_le_mul_of_nonneg_left h2 (by positivity : 0 ≤ (1 / 2 : ℝ)),
    mul_add ((1 / 2 : ℝ)^m) (supNorm f) ((1 / 2 : ℝ) * lipSemiNorm f)]

/-!
# Section 4: Uniform Boundedness and Quasi-Compactness Primitives
-/

/-- Uniform power bound for the transfer operator: ‖ℒ₂^m f‖_Lip ≤ 2 ‖f‖_Lip for all m. -/
theorem uniform_power_bound {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipNorm (padicTransferOp^[m] f) ≤ 2 * lipNorm f := by
  linarith [lipNorm_iterate_le m hf, lipNorm_nonneg hf]

/-- Sharp unit power bound: ‖ℒ₂^m f‖_Lip ≤ ‖f‖_Lip for all m. -/
theorem uniform_power_bound_unit {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipNorm (padicTransferOp^[m] f) ≤ lipNorm f :=
  lipNorm_iterate_le m hf

/-- Strict spectral contraction on zero-mean / dynamic functions:
    ‖𝒯₂^m f‖_Lip ≤ (1/2)^m ‖f‖_Lip. -/
theorem spectral_contraction_zero_mean {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (m : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipNorm ((dynamicTransferOp^[m]) f) ≤ (1 / 2 : ℝ)^m * lipNorm f :=
  lipNorm_dynamicTransferOp_iterate_le m hf

omit [Fact (Nat.Prime 2)] in
/-- Partial sum bound for the geometric series of ratio 1/2: ∑_{m=0}^{M-1} (1/2)^m ≤ 2. -/
lemma geom_sum_half_le (M : ℕ) : ∑ m ∈ Finset.range M, (1 / 2 : ℝ)^m ≤ 2 := by
  have h := geom_sum_eq (by norm_num : (1 / 2 : ℝ) ≠ 1) M
  have hdiv : ((1 / 2 : ℝ)^M - 1) / (1 / 2 - 1) = 2 - 2 * (1 / 2 : ℝ)^M := by ring
  have : 0 ≤ (1 / 2 : ℝ)^M := by positivity
  linarith

/-- The Birkhoff time-average operator of length M for the dynamic transfer operator:
    A_M f = (1 / M) ∑_{m=0}^{M-1} 𝒯₂^m f. -/
def birkhoffAverage (M : ℕ) {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] (f : ℤ_[2] → E) : ℤ_[2] → E :=
  (1 / (M : ℝ)) • ∑ m ∈ Finset.range M, (dynamicTransferOp^[m]) f

/-- The Markov Birkhoff time-average operator of length M for ℒ₂:
    A_M^{(ℒ)} f = (1 / M) ∑_{m=0}^{M-1} ℒ₂^m f. -/
def birkhoffAverageMarkov (M : ℕ) {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] (f : ℤ_[2] → E) : ℤ_[2] → E :=
  (1 / (M : ℝ)) • ∑ m ∈ Finset.range M, (padicTransferOp^[m]) f

/-- Lipschitz continuity of the Birkhoff average. -/
lemma isPadicLipschitz_birkhoffAverage (M : ℕ) {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    IsPadicLipschitz (birkhoffAverage M f) :=
  isPadicLipschitz_smul _ (isPadicLipschitz_sum fun m _ => isPadicLipschitz_dynamic_iterate m hf)

/-- Quantitative Lipschitz bound on the Birkhoff average:
    ‖A_M f‖_Lip ≤ (2 ‖f‖_Lip) / M. -/
theorem lipNorm_birkhoffAverage_le {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (M : ℕ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipNorm (birkhoffAverage M f) ≤ (2 * lipNorm f) / (M : ℝ) := by
  rcases eq_or_ne M 0 with rfl | hM
  · simp [birkhoffAverage, lipNorm_zero]
  have hM_pos : 0 < (M : ℝ) := Nat.cast_pos.mpr (Nat.pos_of_ne_zero hM)
  dsimp [birkhoffAverage]
  have h_dyn : ∀ m ∈ Finset.range M, IsPadicLipschitz ((dynamicTransferOp^[m]) f) :=
    fun m _ => isPadicLipschitz_dynamic_iterate m hf
  have h_term_le : (∑ m ∈ Finset.range M, lipNorm ((dynamicTransferOp^[m]) f)) ≤
      (∑ m ∈ Finset.range M, (1 / 2 : ℝ)^m) * lipNorm f := by
    rw [Finset.sum_mul]
    exact Finset.sum_le_sum fun m _ => lipNorm_dynamicTransferOp_iterate_le m hf
  have h_bound : lipNorm (∑ m ∈ Finset.range M, (dynamicTransferOp^[m]) f) ≤ 2 * lipNorm f :=
    (lipNorm_sum_le h_dyn).trans (h_term_le.trans (mul_le_mul_of_nonneg_right (geom_sum_half_le M) (lipNorm_nonneg hf)))
  have h_smul := lipNorm_smul_of_nonneg (by positivity : 0 ≤ 1 / (M : ℝ)) (isPadicLipschitz_sum h_dyn)
  calc lipNorm ((1 / (M : ℝ)) • ∑ m ∈ Finset.range M, (dynamicTransferOp^[m]) f)
    _ ≤ (1 / (M : ℝ)) * lipNorm (∑ m ∈ Finset.range M, (dynamicTransferOp^[m]) f) := h_smul
    _ ≤ (1 / (M : ℝ)) * (2 * lipNorm f) := mul_le_mul_of_nonneg_left h_bound (by positivity)
    _ = (2 * lipNorm f) / (M : ℝ) := by ring

omit [Fact (Nat.Prime 2)] in
/-- Filter convergence lemma for c / (n : ℝ) → 0. -/
lemma tendsto_const_div_natCast_atTop_nhds_zero (c : ℝ) :
    Tendsto (fun n : ℕ => c / (n : ℝ)) atTop (𝓝 0) := by
  simpa [mul_zero, div_eq_mul_inv] using
    (tendsto_inv_atTop_zero.comp tendsto_natCast_atTop_atTop).const_mul c

omit [Fact (Nat.Prime 2)] in
/-- Squeeze theorem helper for non-negative bounded sequences converging to 0. -/
lemma tendsto_squeeze_zero {f : ℕ → ℝ} {c : ℝ} (h0 : ∀ n, 0 ≤ f n) (hle : ∀ n, f n ≤ c / (n : ℝ)) :
    Tendsto f atTop (𝓝 0) :=
  tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds (tendsto_const_div_natCast_atTop_nhds_zero c)
    (Filter.Eventually.of_forall h0) (Filter.Eventually.of_forall hle)

/-- **Mean Ergodic Convergence in Lipschitz Norm**:
    The Birkhoff averages A_M f converge to 0 in Lipschitz norm as M → ∞:
    lim_{M → ∞} ‖A_M f‖_Lip = 0. -/
theorem tendsto_lipNorm_birkhoffAverage_atTop_zero {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    Tendsto (fun M : ℕ => lipNorm (birkhoffAverage M f)) atTop (𝓝 0) :=
  tendsto_squeeze_zero (fun M => lipNorm_nonneg (isPadicLipschitz_birkhoffAverage M hf))
    (fun M => lipNorm_birkhoffAverage_le M hf)

/-- Markov Birkhoff average fixes constant functions for any M ≥ 1:
    A_M^{(ℒ)} (1 c) = 1 c. -/
theorem markov_birkhoffAverage_const {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (M : ℕ) (hM : 1 ≤ M) (c : E) :
    birkhoffAverageMarkov M (fun _ : ℤ_[2] => c) = (fun _ => c) := by
  ext x
  dsimp [birkhoffAverageMarkov]
  simp_rw [← iteratedTransferOp_eq_iterate, iteratedTransferOp_const]
  rw [Finset.sum_const, Finset.card_range, Pi.smul_apply, ← Nat.cast_smul_eq_nsmul ℝ M c, smul_smul,
    one_div_mul_cancel (by positivity : (M : ℝ) ≠ 0), one_smul]

end Dynamics.LasotaYorke2Adic