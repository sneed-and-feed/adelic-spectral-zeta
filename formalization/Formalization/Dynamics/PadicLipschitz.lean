/-
Copyright (c) 2026 Antigravity Mathematical Research Team. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Antigravity Mathematical Research Team
-/
import Mathlib.NumberTheory.Padics.PadicIntegers
import Mathlib.Topology.MetricSpace.Isometry
import Mathlib.Analysis.Normed.Module.Basic
import Mathlib.Data.Complex.Basic
import Mathlib.Tactic
import Formalization.Dynamics.ContinuousTransfer

/-!
# 2-Adic Lipschitz Space and Continuous Transfer Operator

This file formalizes the Banach space of Lipschitz continuous functions $\text{Lip}(\mathbb{Z}_2, E)$
over the compact ring of 2-adic integers $\mathbb{Z}_2$ for a normed space $E$ (such as $\mathbb{C}$ or $\mathbb{R}$),
equipped with the supremum norm, the 2-adic ultrametric Lipschitz semi-norm, and the total Lipschitz norm.
It establishes the action of the affine branches $\phi_0(x) = 3x$ and $\phi_1(x) = 3x - 1$, and formalizes the
normalized continuous 2-adic transfer operator $\mathcal{L}_2$:
$$(\mathcal{L}_2 f)(x) = \frac{1}{2} (f(3x) + f(3x - 1))$$
proving its linearity, preservation of constants, supremum norm contractivity, and Lipschitz invariance.

## Mathematical Overview
1. **2-Adic Ultrametric Geometry:**
   The 2-adic metric $d_2(x, y) = \|x - y\|_2$ satisfies the strong triangle inequality:
   $$d_2(x, z) \le \max(d_2(x, y), d_2(y, z))$$
   The branches $\phi_0(x) = 3x$ and $\phi_1(x) = 3x - 1$ are isometric homeomorphisms of $\mathbb{Z}_2$
   preserving all pairwise distances: $d_2(\phi_i(x), \phi_i(y)) = d_2(x, y)$ for $i \in \{0, 1\}$.

2. **Lipschitz Spaces $\text{Lip}(\mathbb{Z}_2, E)$:**
   A function $f : \mathbb{Z}_2 \to E$ is 2-adic Lipschitz if there exists $C \ge 0$ such that
   $$\|f(x) - f(y)\| \le C \cdot \|x - y\|_2 \quad \forall x, y \in \mathbb{Z}_2$$
   The Lipschitz semi-norm is the minimal such constant:
   $$L(f) = \inf \{ C \ge 0 \mid \forall x y, \|f(x) - f(y)\| \le C \|x - y\|_2 \}$$
   The total Lipschitz norm is $\|f\|_{\text{Lip}} = \|f\|_\infty + L(f)$.

3. **Normalized Continuous Transfer Operator $\mathcal{L}_2$:**
   $$\mathcal{L}_2 f(x) = \frac{1}{2} (f(3x) + f(3x - 1))$$
   - $\mathcal{L}_2(\mathbf{1}) = \mathbf{1}$
   - $\|\mathcal{L}_2 f\|_\infty \le \|f\|_\infty$
   - $L(\mathcal{L}_2 f) \le L(f)$
   - $\|\mathcal{L}_2 f\|_{\text{Lip}} \le \|f\|_{\text{Lip}}$
-/

noncomputable section

open ContinuousTransfer

variable [Fact (Nat.Prime 2)]

namespace Dynamics.PadicLipschitz

/-!
# Section 1: 2-Adic Metric and Ultrametric Geometry on ℤ₂
-/

/-- The 2-adic metric distance on ℤ_[2]. -/
def dist2 (x y : ℤ_[2]) : ℝ := dist x y

/-- The 2-adic distance is given by the 2-adic valuation norm of the difference. -/
lemma dist2_eq_norm (x y : ℤ_[2]) : dist2 x y = ‖x - y‖ := dist_eq_norm_sub x y

/-- Non-negativity of the 2-adic distance. -/
lemma dist2_nonneg (x y : ℤ_[2]) : 0 ≤ dist2 x y := dist_nonneg

/-- Self-distance is zero. -/
lemma dist2_self (x : ℤ_[2]) : dist2 x x = 0 := dist_self x

/-- Symmetry of the 2-adic distance. -/
lemma dist2_comm (x y : ℤ_[2]) : dist2 x y = dist2 y x := dist_comm x y

/-- Diameter bound: any two 2-adic integers have distance at most 1. -/
lemma dist2_le_one (x y : ℤ_[2]) : dist2 x y ≤ 1 :=
  PadicInt.norm_le_one (x - y)

/-- Ultrametric strong triangle inequality for the 2-adic norm. -/
lemma norm_ultrametric (x y : ℤ_[2]) : ‖x + y‖ ≤ max ‖x‖ ‖y‖ :=
  PadicInt.nonarchimedean x y

/-- Ultrametric strong triangle inequality for differences. -/
lemma norm_sub_ultrametric (x y z : ℤ_[2]) : ‖x - z‖ ≤ max ‖x - y‖ ‖y - z‖ := by
  rw [← sub_add_sub_cancel x y z]
  exact PadicInt.nonarchimedean (x - y) (y - z)

/-- Ultrametric strong triangle inequality for the 2-adic distance:
    d₂(x, z) ≤ max(d₂(x, y), d₂(y, z)). -/
theorem dist2_ultrametric (x y z : ℤ_[2]) : dist2 x z ≤ max (dist2 x y) (dist2 y z) :=
  norm_sub_ultrametric x y z

/-- Branch scaling for ϕ₀(x) = 3x: d₂(ϕ₀(x), ϕ₀(y)) = d₂(x, y). -/
theorem dist2_phi0 (x y : ℤ_[2]) : dist2 (phi0 x) (phi0 y) = dist2 x y :=
  isometry_phi0.dist_eq x y

/-- Branch scaling for ϕ₁(x) = 3x - 1: d₂(ϕ₁(x), ϕ₁(y)) = d₂(x, y). -/
theorem dist2_phi1 (x y : ℤ_[2]) : dist2 (phi1 x) (phi1 y) = dist2 x y :=
  isometry_phi1.dist_eq x y

/-- Branch difference norm preservation for ϕ₀. -/
theorem norm_sub_phi0 (x y : ℤ_[2]) : ‖phi0 x - phi0 y‖ = ‖x - y‖ :=
  isometry_phi0.dist_eq x y

/-- Branch difference norm preservation for ϕ₁. -/
theorem norm_sub_phi1 (x y : ℤ_[2]) : ‖phi1 x - phi1 y‖ = ‖x - y‖ :=
  isometry_phi1.dist_eq x y

/-!
# Section 2: The Space of 2-Adic Lipschitz Functions
-/

/-- Predicate asserting that a function f : ℤ_[2] → E is Lipschitz continuous. -/
def IsPadicLipschitz {E : Type*} [NormedAddCommGroup E] (f : ℤ_[2] → E) : Prop :=
  ∃ C : ℝ, 0 ≤ C ∧ ∀ x y : ℤ_[2], ‖f x - f y‖ ≤ C * ‖x - y‖

/-- Bundled 2-adic Lipschitz map structure with an explicit Lipschitz constant. -/
structure LipMap (E : Type*) [NormedAddCommGroup E] where
  toFun : ℤ_[2] → E
  lip_const : ℝ
  lip_const_nonneg : 0 ≤ lip_const
  dist_le_lip : ∀ x y : ℤ_[2], ‖toFun x - toFun y‖ ≤ lip_const * ‖x - y‖

instance (E : Type*) [NormedAddCommGroup E] : CoeFun (LipMap E) (fun _ => ℤ_[2] → E) where
  coe := LipMap.toFun

/-- Any bundled LipMap satisfies the IsPadicLipschitz predicate. -/
lemma LipMap.isPadicLipschitz {E : Type*} [NormedAddCommGroup E] (f : LipMap E) :
    IsPadicLipschitz f.toFun :=
  ⟨f.lip_const, f.lip_const_nonneg, f.dist_le_lip⟩

/-- Constant functions are 2-adic Lipschitz with constant 0. -/
lemma isPadicLipschitz_const {E : Type*} [NormedAddCommGroup E] (c : E) :
    IsPadicLipschitz (fun _ : ℤ_[2] => c) :=
  ⟨0, le_rfl, fun _ _ => by simp⟩

/-- Bundled constant Lipschitz map. -/
def LipMap.const {E : Type*} [NormedAddCommGroup E] (c : E) : LipMap E where
  toFun := fun _ => c
  lip_const := 0
  lip_const_nonneg := le_rfl
  dist_le_lip _ _ := by simp

/-- The sum of two 2-adic Lipschitz functions is 2-adic Lipschitz. -/
lemma isPadicLipschitz_add {E : Type*} [NormedAddCommGroup E] {f g : ℤ_[2] → E}
    (hf : IsPadicLipschitz f) (hg : IsPadicLipschitz g) :
    IsPadicLipschitz (f + g) := by
  rcases hf with ⟨Cf, hCf, hf⟩
  rcases hg with ⟨Cg, hCg, hg⟩
  refine ⟨Cf + Cg, add_nonneg hCf hCg, fun x y => ?_⟩
  rw [Pi.add_apply, Pi.add_apply, add_sub_add_comm]
  linarith [norm_add_le (f x - f y) (g x - g y), hf x y, hg x y]

/-- Bundled addition of Lipschitz maps. -/
def LipMap.add {E : Type*} [NormedAddCommGroup E] (f g : LipMap E) : LipMap E where
  toFun := f.toFun + g.toFun
  lip_const := f.lip_const + g.lip_const
  lip_const_nonneg := add_nonneg f.lip_const_nonneg g.lip_const_nonneg
  dist_le_lip x y := by
    rw [Pi.add_apply, Pi.add_apply, add_sub_add_comm]
    linarith [norm_add_le (f.toFun x - f.toFun y) (g.toFun x - g.toFun y),
      f.dist_le_lip x y, g.dist_le_lip x y]

/-- The negation of a 2-adic Lipschitz function is 2-adic Lipschitz. -/
lemma isPadicLipschitz_neg {E : Type*} [NormedAddCommGroup E] {f : ℤ_[2] → E}
    (hf : IsPadicLipschitz f) : IsPadicLipschitz (-f) := by
  rcases hf with ⟨C, hC, hf⟩
  refine ⟨C, hC, fun x y => ?_⟩
  rw [Pi.neg_apply, Pi.neg_apply, neg_sub_neg, norm_sub_rev]
  exact hf x y

/-- Bundled negation of a Lipschitz map. -/
def LipMap.neg {E : Type*} [NormedAddCommGroup E] (f : LipMap E) : LipMap E where
  toFun := -f.toFun
  lip_const := f.lip_const
  lip_const_nonneg := f.lip_const_nonneg
  dist_le_lip x y := by
    rw [Pi.neg_apply, Pi.neg_apply, neg_sub_neg, norm_sub_rev]
    exact f.dist_le_lip x y

/-- The difference of two 2-adic Lipschitz functions is 2-adic Lipschitz. -/
lemma isPadicLipschitz_sub {E : Type*} [NormedAddCommGroup E] {f g : ℤ_[2] → E}
    (hf : IsPadicLipschitz f) (hg : IsPadicLipschitz g) :
    IsPadicLipschitz (f - g) := by
  rw [sub_eq_add_neg]
  exact isPadicLipschitz_add hf (isPadicLipschitz_neg hg)

/-- Scalar multiplication preserves 2-adic Lipschitz continuity over any normed field. -/
lemma isPadicLipschitz_smul_field {𝕜 E : Type*} [NormedField 𝕜] [NormedAddCommGroup E] [NormedSpace 𝕜 E]
    (c : 𝕜) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    IsPadicLipschitz (c • f) := by
  rcases hf with ⟨Cf, hCf, hf⟩
  refine ⟨‖c‖ * Cf, mul_nonneg (norm_nonneg c) hCf, fun x y => ?_⟩
  rw [Pi.smul_apply, Pi.smul_apply, ← smul_sub, norm_smul, mul_assoc]
  exact mul_le_mul_of_nonneg_left (hf x y) (norm_nonneg c)

/-- Real scalar multiplication preserves 2-adic Lipschitz continuity. -/
lemma isPadicLipschitz_smul {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (c : ℝ) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    IsPadicLipschitz (c • f) :=
  isPadicLipschitz_smul_field c hf

/-- Bundled scalar multiplication for LipMap. -/
def LipMap.smulField {𝕜 E : Type*} [NormedField 𝕜] [NormedAddCommGroup E] [NormedSpace 𝕜 E]
    (c : 𝕜) (f : LipMap E) : LipMap E where
  toFun := c • f.toFun
  lip_const := ‖c‖ * f.lip_const
  lip_const_nonneg := mul_nonneg (norm_nonneg c) f.lip_const_nonneg
  dist_le_lip x y := by
    rw [Pi.smul_apply, Pi.smul_apply, ← smul_sub, norm_smul, mul_assoc]
    exact mul_le_mul_of_nonneg_left (f.dist_le_lip x y) (norm_nonneg c)

/-- The submodule of 2-adic Lipschitz functions over a normed field 𝕜. -/
def padicLipschitzSubmodule (𝕜 : Type*) (E : Type*) [NormedField 𝕜] [NormedAddCommGroup E] [NormedSpace 𝕜 E] :
    Submodule 𝕜 (ℤ_[2] → E) where
  carrier := { f | IsPadicLipschitz f }
  zero_mem' := isPadicLipschitz_const 0
  add_mem' hf hg := isPadicLipschitz_add hf hg
  smul_mem' c _ hf := isPadicLipschitz_smul_field c hf

/-- The real vector space of 2-adic Lipschitz functions Lip(ℤ₂, E). -/
abbrev PadicLipschitzSpace (E : Type*) [NormedAddCommGroup E] [NormedSpace ℝ E] :=
  padicLipschitzSubmodule ℝ E

/-- The complex vector space of 2-adic Lipschitz functions Lip(ℤ₂, ℂ). -/
abbrev PadicLipschitzComplex :=
  padicLipschitzSubmodule ℂ ℂ

/-- The real vector space of 2-adic Lipschitz functions Lip(ℤ₂, ℝ). -/
abbrev PadicLipschitzReal :=
  padicLipschitzSubmodule ℝ ℝ

/-!
# Section 3: Norms on the Lipschitz Space
-/

/-- Bound on function values: every 2-adic Lipschitz function has a bounded range. -/
lemma bddAbove_range_norm {E : Type*} [NormedAddCommGroup E] {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    BddAbove (Set.range (fun x => ‖f x‖)) := by
  rcases hf with ⟨C, hC, hLip⟩
  refine ⟨‖f 0‖ + C, ?_⟩
  rintro _ ⟨x, rfl⟩
  dsimp
  have h : f x = f 0 + (f x - f 0) := by abel
  rw [h]
  have h1 : ‖x - 0‖ ≤ 1 := by rw [sub_zero]; exact PadicInt.norm_le_one x
  have h2 := mul_le_mul_of_nonneg_left h1 hC
  rw [mul_one] at h2
  linarith [norm_add_le (f 0) (f x - f 0), hLip x 0]

/-- The range of norms is non-empty. -/
lemma range_norm_nonempty {E : Type*} [NormedAddCommGroup E] (f : ℤ_[2] → E) :
    (Set.range (fun x => ‖f x‖)).Nonempty :=
  ⟨‖f 0‖, Set.mem_range_self 0⟩

/-- The supremum norm ‖f‖_∞ of a function on ℤ_[2]. -/
def supNorm {E : Type*} [NormedAddCommGroup E] (f : ℤ_[2] → E) : ℝ :=
  sSup (Set.range (fun x => ‖f x‖))

/-- Pointwise bound by the supremum norm for Lipschitz functions. -/
lemma norm_le_supNorm {E : Type*} [NormedAddCommGroup E] {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) (x : ℤ_[2]) :
    ‖f x‖ ≤ supNorm f :=
  le_csSup (bddAbove_range_norm hf) (Set.mem_range_self x)

/-- Non-negativity of the supremum norm. -/
lemma supNorm_nonneg {E : Type*} [NormedAddCommGroup E] {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    0 ≤ supNorm f :=
  (norm_nonneg (f 0)).trans (norm_le_supNorm hf 0)

/-- Supremum norm of a constant function. -/
lemma supNorm_const {E : Type*} [NormedAddCommGroup E] (c : E) :
    supNorm (fun _ : ℤ_[2] => c) = ‖c‖ := by
  simp only [supNorm, Set.range_const, csSup_singleton]

/-- Supremum norm of the zero function is 0. -/
lemma supNorm_zero {E : Type*} [NormedAddCommGroup E] :
    supNorm (0 : ℤ_[2] → E) = 0 := by
  have : (0 : ℤ_[2] → E) = (fun _ => 0) := rfl
  rw [this, supNorm_const, norm_zero]

/-- Triangle inequality for the supremum norm. -/
lemma supNorm_add_le {E : Type*} [NormedAddCommGroup E] {f g : ℤ_[2] → E}
    (hf : IsPadicLipschitz f) (hg : IsPadicLipschitz g) :
    supNorm (f + g) ≤ supNorm f + supNorm g := by
  refine csSup_le (range_norm_nonempty (f + g)) ?_
  rintro _ ⟨x, rfl⟩
  exact (norm_add_le (f x) (g x)).trans (add_le_add (norm_le_supNorm hf x) (norm_le_supNorm hg x))

/-- Homogeneity of the supremum norm under scalar multiplication. -/
lemma supNorm_smul_le {𝕜 E : Type*} [NormedField 𝕜] [NormedAddCommGroup E] [NormedSpace 𝕜 E]
    (c : 𝕜) {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    supNorm (c • f) ≤ ‖c‖ * supNorm f := by
  refine csSup_le (range_norm_nonempty (c • f)) ?_
  rintro _ ⟨x, rfl⟩
  dsimp
  rw [norm_smul]
  exact mul_le_mul_of_nonneg_left (norm_le_supNorm hf x) (norm_nonneg c)

/-- The set of valid Lipschitz constants for a function f. -/
def lipConstantSet {E : Type*} [NormedAddCommGroup E] (f : ℤ_[2] → E) : Set ℝ :=
  { C : ℝ | 0 ≤ C ∧ ∀ x y : ℤ_[2], ‖f x - f y‖ ≤ C * ‖x - y‖ }

/-- The Lipschitz semi-norm L(f) is the infimum of all valid Lipschitz constants. -/
def lipSemiNorm {E : Type*} [NormedAddCommGroup E] (f : ℤ_[2] → E) : ℝ :=
  sInf (lipConstantSet f)

/-- If f is Lipschitz, its set of Lipschitz constants is non-empty. -/
lemma lipConstantSet_nonempty {E : Type*} [NormedAddCommGroup E] {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    (lipConstantSet f).Nonempty :=
  hf

/-- The set of Lipschitz constants is bounded below by 0. -/
lemma lipConstantSet_bddBelow {E : Type*} [NormedAddCommGroup E] (f : ℤ_[2] → E) :
    BddBelow (lipConstantSet f) :=
  ⟨0, fun _ hC => hC.1⟩

/-- Non-negativity of the Lipschitz semi-norm. -/
lemma lipSemiNorm_nonneg {E : Type*} [NormedAddCommGroup E] {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    0 ≤ lipSemiNorm f :=
  le_csInf (lipConstantSet_nonempty hf) (fun _ hC => hC.1)

/-- The Lipschitz semi-norm of a constant function is zero. -/
lemma lipSemiNorm_const {E : Type*} [NormedAddCommGroup E] (c : E) :
    lipSemiNorm (fun _ : ℤ_[2] => c) = 0 := by
  have h0 : (0 : ℝ) ∈ lipConstantSet (fun _ : ℤ_[2] => c) := ⟨le_rfl, fun _ _ => by simp⟩
  exact le_antisymm (csInf_le (lipConstantSet_bddBelow _) h0)
    (le_csInf ⟨0, h0⟩ (fun _ hC => hC.1))

/-- Upper bound on lipSemiNorm by any valid Lipschitz constant. -/
lemma lipSemiNorm_le_of_mem {E : Type*} [NormedAddCommGroup E] {f : ℤ_[2] → E} {C : ℝ}
    (hC : C ∈ lipConstantSet f) : lipSemiNorm f ≤ C :=
  csInf_le (lipConstantSet_bddBelow f) hC

/-- Any constant in lipConstantSet yields a Lipschitz bound. -/
lemma lip_le_of_mem {E : Type*} [NormedAddCommGroup E] {f : ℤ_[2] → E} {C : ℝ}
    (hC : C ∈ lipConstantSet f) (x y : ℤ_[2]) : ‖f x - f y‖ ≤ C * ‖x - y‖ :=
  hC.2 x y

/-- The total Lipschitz norm ‖f‖_Lip = ‖f‖_∞ + L(f). -/
def lipNorm {E : Type*} [NormedAddCommGroup E] (f : ℤ_[2] → E) : ℝ :=
  supNorm f + lipSemiNorm f

/-- Non-negativity of the total Lipschitz norm. -/
lemma lipNorm_nonneg {E : Type*} [NormedAddCommGroup E] {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    0 ≤ lipNorm f :=
  add_nonneg (supNorm_nonneg hf) (lipSemiNorm_nonneg hf)

/-- Total Lipschitz norm of a constant function. -/
lemma lipNorm_const {E : Type*} [NormedAddCommGroup E] (c : E) :
    lipNorm (fun _ : ℤ_[2] => c) = ‖c‖ := by
  simp [lipNorm, supNorm_const, lipSemiNorm_const]

/-- Total Lipschitz norm of the zero function is 0. -/
lemma lipNorm_zero {E : Type*} [NormedAddCommGroup E] :
    lipNorm (0 : ℤ_[2] → E) = 0 := by
  have : (0 : ℤ_[2] → E) = (fun _ => 0) := rfl
  rw [this, lipNorm_const, norm_zero]

/-!
# Section 4: Continuous Normalized Transfer Operator ℒ₂
-/

/-- The normalized continuous 2-adic transfer operator ℒ₂:
    (ℒ₂ f)(x) = (1/2) (f(3x) + f(3x - 1)). -/
def padicTransferOp {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] (f : ℤ_[2] → E) : ℤ_[2] → E :=
  fun x => (1 / 2 : ℝ) • (f (phi0 x) + f (phi1 x))

/-- Pointwise evaluation of the transfer operator. -/
lemma padicTransferOp_apply {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : ℤ_[2] → E) (x : ℤ_[2]) :
    padicTransferOp f x = (1 / 2 : ℝ) • (f (phi0 x) + f (phi1 x)) := rfl

/-- Linearity: additivity of the transfer operator. -/
lemma padicTransferOp_add {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] (f g : ℤ_[2] → E) :
    padicTransferOp (f + g) = padicTransferOp f + padicTransferOp g := by
  ext x
  simp only [padicTransferOp, Pi.add_apply, add_add_add_comm, smul_add]

/-- Linearity: scalar homogeneity of the transfer operator. -/
lemma padicTransferOp_smul {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] (c : ℝ) (f : ℤ_[2] → E) :
    padicTransferOp (c • f) = c • padicTransferOp f := by
  ext x
  dsimp [padicTransferOp]
  rw [← smul_add, smul_comm]

/-- Preservation of constants: ℒ₂(c) = c. -/
lemma padicTransferOp_const {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] (c : E) :
    padicTransferOp (fun _ : ℤ_[2] => c) = (fun _ => c) := by
  ext x
  dsimp [padicTransferOp]
  rw [← two_smul ℝ c, ← mul_smul]
  norm_num

/-- Normalized Markov property on the real constant function 1: ℒ₂(1) = 1. -/
theorem padicTransferOp_one_real :
    padicTransferOp (fun _ : ℤ_[2] => (1 : ℝ)) = (fun _ => 1) :=
  padicTransferOp_const 1

/-- Normalized Markov property on the complex constant function 1: ℒ₂(1) = 1. -/
theorem padicTransferOp_one_complex :
    padicTransferOp (fun _ : ℤ_[2] => (1 : ℂ)) = (fun _ => 1) :=
  padicTransferOp_const 1

/-- Transfer operator preserves the set of Lipschitz constants. -/
lemma padicTransferOp_lipConstantSet {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : ℤ_[2] → E} {C : ℝ} (hC : C ∈ lipConstantSet f) :
    C ∈ lipConstantSet (padicTransferOp f) := by
  refine ⟨hC.1, fun x y => ?_⟩
  dsimp [padicTransferOp]
  have h_sub : (1 / 2 : ℝ) • (f (phi0 x) + f (phi1 x)) - (1 / 2 : ℝ) • (f (phi0 y) + f (phi1 y)) =
      (1 / 2 : ℝ) • ((f (phi0 x) - f (phi0 y)) + (f (phi1 x) - f (phi1 y))) := by
    rw [← smul_sub, add_sub_add_comm]
  rw [h_sub, norm_smul, Real.norm_of_nonneg (by norm_num)]
  have h0 : ‖f (phi0 x) - f (phi0 y)‖ ≤ C * ‖x - y‖ := by
    simpa [norm_sub_phi0] using hC.2 (phi0 x) (phi0 y)
  have h1 : ‖f (phi1 x) - f (phi1 y)‖ ≤ C * ‖x - y‖ := by
    simpa [norm_sub_phi1] using hC.2 (phi1 x) (phi1 y)
  linarith [norm_add_le (f (phi0 x) - f (phi0 y)) (f (phi1 x) - f (phi1 y))]

/-- Preservation of 2-adic Lipschitz continuity: ℒ₂ f is Lipschitz whenever f is Lipschitz. -/
theorem isPadicLipschitz_padicTransferOp {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    IsPadicLipschitz (padicTransferOp f) := by
  rcases hf with ⟨C, hC, hLip⟩
  exact ⟨C, padicTransferOp_lipConstantSet ⟨hC, hLip⟩⟩

/-- Bundled transfer operator on LipMap. -/
def LipMap.transferOp {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] (f : LipMap E) : LipMap E where
  toFun := padicTransferOp f.toFun
  lip_const := f.lip_const
  lip_const_nonneg := f.lip_const_nonneg
  dist_le_lip := (padicTransferOp_lipConstantSet ⟨f.lip_const_nonneg, f.dist_le_lip⟩).2

/-- ℒ₂ as a real linear map on the function space (ℤ_[2] → E). -/
def padicTransferOpLM (E : Type*) [NormedAddCommGroup E] [NormedSpace ℝ E] :
    (ℤ_[2] → E) →ₗ[ℝ] (ℤ_[2] → E) where
  toFun := padicTransferOp
  map_add' := padicTransferOp_add
  map_smul' := padicTransferOp_smul

/-- ℒ₂ as a real linear map on the Lipschitz subspace Lip(ℤ₂, E). -/
def padicTransferOpLipLM (E : Type*) [NormedAddCommGroup E] [NormedSpace ℝ E] :
    PadicLipschitzSpace E →ₗ[ℝ] PadicLipschitzSpace E where
  toFun f := ⟨padicTransferOp f.1, isPadicLipschitz_padicTransferOp f.2⟩
  map_add' f g := Subtype.ext (padicTransferOp_add f.1 g.1)
  map_smul' c f := Subtype.ext (padicTransferOp_smul c f.1)

/-!
# Section 5: Contractivity and Lipschitz Invariance
-/

/-- Lipschitz semi-norm contraction: L(ℒ₂ f) ≤ L(f). -/
theorem lipSemiNorm_padicTransferOp_le {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipSemiNorm (padicTransferOp f) ≤ lipSemiNorm f :=
  le_csInf (lipConstantSet_nonempty hf) (fun _ hC =>
    csInf_le (lipConstantSet_bddBelow _) (padicTransferOp_lipConstantSet (E := E) hC))

/-- Pointwise norm bound for the transfer operator: ‖(ℒ₂ f)(x)‖ ≤ ‖f‖_∞. -/
lemma norm_padicTransferOp_apply_le {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) (x : ℤ_[2]) :
    ‖padicTransferOp f x‖ ≤ supNorm f := by
  dsimp [padicTransferOp]
  rw [norm_smul, Real.norm_of_nonneg (by norm_num)]
  linarith [norm_add_le (f (phi0 x)) (f (phi1 x)),
    norm_le_supNorm hf (phi0 x), norm_le_supNorm hf (phi1 x)]

/-- Supremum norm contractivity: ‖ℒ₂ f‖_∞ ≤ ‖f‖_∞. -/
theorem supNorm_padicTransferOp_le {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    supNorm (padicTransferOp f) ≤ supNorm f := by
  refine csSup_le (range_norm_nonempty (padicTransferOp f)) ?_
  rintro _ ⟨x, rfl⟩
  exact norm_padicTransferOp_apply_le hf x

/-- Total Lipschitz norm contractivity: ‖ℒ₂ f‖_Lip ≤ ‖f‖_Lip. -/
theorem lipNorm_padicTransferOp_le {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : ℤ_[2] → E} (hf : IsPadicLipschitz f) :
    lipNorm (padicTransferOp f) ≤ lipNorm f :=
  add_le_add (supNorm_padicTransferOp_le hf) (lipSemiNorm_padicTransferOp_le hf)

/-- Complex transfer operator specialization: ‖ℒ₂ f‖_Lip ≤ ‖f‖_Lip for f : ℤ_[2] → ℂ. -/
theorem lipNorm_padicTransferOp_complex_le {f : ℤ_[2] → ℂ} (hf : IsPadicLipschitz f) :
    lipNorm (padicTransferOp f) ≤ lipNorm f :=
  lipNorm_padicTransferOp_le hf

/-- Real transfer operator specialization: ‖ℒ₂ f‖_Lip ≤ ‖f‖_Lip for f : ℤ_[2] → ℝ. -/
theorem lipNorm_padicTransferOp_real_le {f : ℤ_[2] → ℝ} (hf : IsPadicLipschitz f) :
    lipNorm (padicTransferOp f) ≤ lipNorm f :=
  lipNorm_padicTransferOp_le hf

end Dynamics.PadicLipschitz
