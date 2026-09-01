import Mathlib.Data.Real.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Linarith

open scoped Matrix BigOperators

noncomputable section

namespace RoPE

/-!
# SO(2) Rotational Geometry of Rotary Position Embeddings (RoPE) and Coherence Analysis

This module formalizes the SO(2) rotational geometry of Rotary Position Embeddings (RoPE)
and the mathematical analysis of KV-cache condensation and token merging as documented in
`papers/llama_surgery.md` (Sections 4.11 and 4.12).

## Mathematical Overview

1. **SO(2) Rotations in 2D**:
   We model 2D embedding slices as elements of `EuclideanSpace ℝ (Fin 2)`.
   The 2D rotation operator $\mathcal{R}_\theta$ rotates vectors by angle $\theta$:
   $$\mathcal{R}_\theta \begin{pmatrix} x \\ y \end{pmatrix} = \begin{pmatrix} x \cos\theta - y \sin\theta \\ x \sin\theta + y \cos\theta \end{pmatrix}$$
   We verify that $\mathcal{R}_\theta$ satisfies group homomorphism properties:
   $\mathcal{R}_{\alpha + \beta} = \mathcal{R}_\alpha \circ \mathcal{R}_\beta$, $\mathcal{R}_0 = \mathrm{id}$,
   and is a linear isometry ($\|\mathcal{R}_\theta v\| = \|v\|$, $\langle \mathcal{R}_\theta u, \mathcal{R}_\theta v \rangle = \langle u, v \rangle$).

2. **Inner Product Shift & Relative Invariance**:
   RoPE projects positions into relative angular differences:
   $$\langle \mathcal{R}_\alpha u, \mathcal{R}_\beta v \rangle = \langle u, \mathcal{R}_{\beta - \alpha} v \rangle = \langle \mathcal{R}_{\alpha - \beta} u, v \rangle$$
   For query at position $m$ and key at position $n$:
   $$\langle \mathcal{R}_{m\theta} q, \mathcal{R}_{n\theta} k \rangle = \langle q, \mathcal{R}_{(n - m)\theta} k \rangle = \langle \mathcal{R}_{(m - n)\theta} q, k \rangle$$
   The Medoid-Value strategy selects the medoid anchor key $k_{\mathrm{medoid}}$ at position $n$,
   retaining exact relative positional shift $(m - n)\theta$.

3. **Key Arithmetic Non-Coherence / Attenuation**:
   Standard token merging algorithms average Key vectors over a cluster $S$:
   $$k_{\mathrm{avg}} = \frac{1}{|S|} \sum_{j \in S} \mathcal{R}_{\mathrm{pos}(j)\theta} k_j$$
   When keys are identical $k_j = k_0$, we prove:
   $$\|k_{\mathrm{avg}}\|^2 = \frac{\|k_0\|^2}{|S|^2} \sum_{i, j \in S} \cos((\mathrm{pos}(j) - \mathrm{pos}(i))\theta)$$
   - $\|k_{\mathrm{avg}}\| \le \|k_0\|$.
   - If positions differ non-trivially, $\|k_{\mathrm{avg}}\| < \|k_0\|$, so $k_{\mathrm{avg}} \notin \mathrm{SO}(2) \cdot k_0$.
   Hence, relative phase is corrupted and key arithmetic destroys RoPE coherence.

4. **Temporal Variance Correction**:
   To prevent temporal distortion without breaking rotational coherence, the Medoid Key is scaled
   by a synthetic decay factor $\gamma = \exp(-\lambda \cdot \mathrm{Var}(P_S)) \in (0, 1]$:
   $$k_{\mathrm{condensed}} = \gamma \cdot \mathcal{R}_{n_{\mathrm{medoid}}\theta} k_{\mathrm{medoid}}$$
   This preserves the pure rotational direction $\mathcal{R}_{n_{\mathrm{medoid}}\theta}$ while
   monotonically penalizing attention logits for temporally dispersed clusters.
-/

/-- Canonical 2D Euclidean vector space. -/
abbrev R2 := EuclideanSpace ℝ (Fin 2)

/-- 2D rotation matrix in SO(2). -/
def rotMatrix (θ : ℝ) : Matrix (Fin 2) (Fin 2) ℝ :=
  !![Real.cos θ, -Real.sin θ;
     Real.sin θ,  Real.cos θ]

/-- 2D rotation operator $\mathcal{R}_\theta$ on `EuclideanSpace ℝ (Fin 2)`. -/
def rot (θ : ℝ) (v : R2) : R2 :=
  WithLp.toLp 2 ![Real.cos θ * WithLp.ofLp v 0 - Real.sin θ * WithLp.ofLp v 1,
                  Real.sin θ * WithLp.ofLp v 0 + Real.cos θ * WithLp.ofLp v 1]

lemma rot_ofLp_zero (θ : ℝ) (v : R2) :
    WithLp.ofLp (rot θ v) 0 = Real.cos θ * WithLp.ofLp v 0 - Real.sin θ * WithLp.ofLp v 1 := rfl

lemma rot_ofLp_one (θ : ℝ) (v : R2) :
    WithLp.ofLp (rot θ v) 1 = Real.sin θ * WithLp.ofLp v 0 + Real.cos θ * WithLp.ofLp v 1 := rfl

/-- Extensionality principle for 2D Euclidean vectors. -/
lemma r2_ext {u v : R2} (h0 : WithLp.ofLp u 0 = WithLp.ofLp v 0) (h1 : WithLp.ofLp u 1 = WithLp.ofLp v 1) : u = v :=
  (WithLp.equiv 2 _).injective (funext fun i => by fin_cases i <;> assumption)

/-! ### Part 1: SO(2) Matrix Group Properties -/

lemma rotMatrix_transpose (θ : ℝ) :
    (rotMatrix θ)ᵀ = !![Real.cos θ, Real.sin θ; -Real.sin θ, Real.cos θ] := by
  ext i j; fin_cases i <;> fin_cases j <;> rfl

/-- $\mathcal{R}_0 = I$ in matrix form. -/
lemma rotMatrix_zero : rotMatrix 0 = 1 := by
  dsimp [rotMatrix]; simp [Matrix.one_fin_two]

/-- Angle addition for rotation matrices: $\mathcal{R}_{\alpha + \beta} = \mathcal{R}_\alpha \mathcal{R}_\beta$. -/
lemma rotMatrix_mul (α β : ℝ) : rotMatrix (α + β) = rotMatrix α * rotMatrix β := by
  dsimp [rotMatrix]; rw [Matrix.mul_fin_two]; simp only [Real.cos_add, Real.sin_add]
  ext i j; fin_cases i <;> fin_cases j <;> dsimp <;> ring

/-- Rotation matrices are orthogonal: $\mathcal{R}_\theta^T \mathcal{R}_\theta = I$. -/
lemma rotMatrix_transpose_mul_self (θ : ℝ) : (rotMatrix θ)ᵀ * rotMatrix θ = 1 := by
  rw [rotMatrix_transpose]; dsimp [rotMatrix]; rw [Matrix.mul_fin_two, Matrix.one_fin_two]
  ext i j; fin_cases i <;> fin_cases j <;> dsimp <;>
    (first | linear_combination (Real.cos_sq_add_sin_sq θ) | ring)

/-- Special orthogonal determinant: $\det(\mathcal{R}_\theta) = 1$. -/
lemma rotMatrix_det (θ : ℝ) : Matrix.det (rotMatrix θ) = 1 := by
  rw [Matrix.det_fin_two]; dsimp [rotMatrix]
  linear_combination (Real.cos_sq_add_sin_sq θ)

/-- The vector rotation matches matrix-vector multiplication $\mathcal{R}_\theta v = R(\theta) v$. -/
lemma rot_eq_mulVec (θ : ℝ) (v : R2) :
    rot θ v = WithLp.toLp 2 (rotMatrix θ *ᵥ WithLp.ofLp v) := by
  apply r2_ext <;> {
    dsimp [rot_ofLp_zero, rot_ofLp_one, rotMatrix, Matrix.mulVec, dotProduct]
    rw [Fin.sum_univ_two]; dsimp; try ring
  }

/-! ### Part 2: Vector Operator Algebraic Properties -/

/-- Identity rotation: $\mathcal{R}_0 v = v$. -/
@[simp]
lemma rot_zero (v : R2) : rot 0 v = v := by
  apply r2_ext
  · simp [rot_ofLp_zero]
  · simp [rot_ofLp_one]

/-- Angle addition: $\mathcal{R}_{\alpha + \beta} v = \mathcal{R}_\alpha (\mathcal{R}_\beta v)$. -/
lemma rot_add (α β : ℝ) (v : R2) : rot (α + β) v = rot α (rot β v) := by
  apply r2_ext
  · simp only [rot_ofLp_zero, rot_ofLp_one, Real.cos_add, Real.sin_add]
    ring
  · simp only [rot_ofLp_zero, rot_ofLp_one, Real.cos_add, Real.sin_add]
    ring

/-- Inverse rotation identity: $\mathcal{R}_{-\theta} (\mathcal{R}_\theta v) = v$. -/
@[simp]
lemma rot_neg (θ : ℝ) (v : R2) : rot (-θ) (rot θ v) = v := by
  rw [← rot_add, neg_add_cancel, rot_zero]

/-- Right inverse rotation identity: $\mathcal{R}_\theta (\mathcal{R}_{-\theta} v) = v$. -/
@[simp]
lemma rot_neg' (θ : ℝ) (v : R2) : rot θ (rot (-θ) v) = v := by
  rw [← rot_add, add_neg_cancel, rot_zero]

/-- Additivity of rotation: $\mathcal{R}_\theta (u + v) = \mathcal{R}_\theta u + \mathcal{R}_\theta v$. -/
lemma rot_add_vec (θ : ℝ) (u v : R2) : rot θ (u + v) = rot θ u + rot θ v := by
  apply r2_ext <;> { simp only [rot_ofLp_zero, rot_ofLp_one, PiLp.add_apply]; ring }

/-- Homogeneity / scalar linearity of rotation: $\mathcal{R}_\theta (c \cdot v) = c \cdot \mathcal{R}_\theta v$. -/
lemma rot_smul (θ : ℝ) (c : ℝ) (v : R2) : rot θ (c • v) = c • rot θ v := by
  apply r2_ext <;> { simp only [rot_ofLp_zero, rot_ofLp_one, PiLp.smul_apply]; ring }

/-- Rotation operator packaged as a linear map. -/
def rotLinear (θ : ℝ) : R2 →ₗ[ℝ] R2 where
  toFun := rot θ
  map_add' := rot_add_vec θ
  map_smul' := rot_smul θ

/-! ### Part 3: Isometry and Inner Product Invariance -/

/-- Explicit formula for real 2D Euclidean inner product. -/
lemma inner_euclidean (u v : R2) :
    @inner ℝ R2 _ u v = WithLp.ofLp u 0 * WithLp.ofLp v 0 + WithLp.ofLp u 1 * WithLp.ofLp v 1 := by
  simp [EuclideanSpace.inner_eq_star_dotProduct, dotProduct, Fin.sum_univ_two]; ring

/-- Inner product preservation under equal rotations: $\langle \mathcal{R}_\theta u, \mathcal{R}_\theta v \rangle = \langle u, v \rangle$. -/
@[simp]
lemma inner_rot_rot (θ : ℝ) (u v : R2) :
    @inner ℝ R2 _ (rot θ u) (rot θ v) = @inner ℝ R2 _ u v := by
  simp only [inner_euclidean, rot_ofLp_zero, rot_ofLp_one]
  linear_combination (u.ofLp 0 * v.ofLp 0 + u.ofLp 1 * v.ofLp 1) * (Real.cos_sq_add_sin_sq θ)

/-- Adjoint shift identity (right shift): $\langle \mathcal{R}_\alpha u, \mathcal{R}_\beta v \rangle = \langle u, \mathcal{R}_{\beta - \alpha} v \rangle$. -/
lemma inner_rot_rot_angles (α β : ℝ) (u v : R2) :
    @inner ℝ R2 _ (rot α u) (rot β v) = @inner ℝ R2 _ u (rot (β - α) v) := by
  rw [← inner_rot_rot (-α), rot_neg, ← rot_add, add_comm (-α), sub_eq_add_neg]

/-- Adjoint shift identity (left shift): $\langle \mathcal{R}_\alpha u, \mathcal{R}_\beta v \rangle = \langle \mathcal{R}_{\alpha - \beta} u, v \rangle$. -/
lemma inner_rot_rot_angles' (α β : ℝ) (u v : R2) :
    @inner ℝ R2 _ (rot α u) (rot β v) = @inner ℝ R2 _ (rot (α - β) u) v := by
  rw [← inner_rot_rot (-β), rot_neg, ← rot_add, add_comm (-β), sub_eq_add_neg]

/-- Self inner product rotated: $\langle k_0, \mathcal{R}_\phi k_0 \rangle = \|k_0\|^2 \cos\phi$. -/
lemma inner_self_rot (ϕ : ℝ) (k₀ : R2) :
    @inner ℝ R2 _ k₀ (rot ϕ k₀) = ‖k₀‖ ^ 2 * Real.cos ϕ := by
  simp only [inner_euclidean, rot_ofLp_zero, rot_ofLp_one, ← real_inner_self_eq_norm_sq]; ring

/-- Cross inner product of rotated identical keys: $\langle \mathcal{R}_\alpha k_0, \mathcal{R}_\beta k_0 \rangle = \|k_0\|^2 \cos(\beta - \alpha)$. -/
lemma inner_rot_rot_self (α β : ℝ) (k₀ : R2) :
    @inner ℝ R2 _ (rot α k₀) (rot β k₀) = ‖k₀‖ ^ 2 * Real.cos (β - α) := by
  rw [inner_rot_rot_angles, inner_self_rot]

/-- Norm squared preservation: $\|\mathcal{R}_\theta v\|^2 = \|v\|^2$. -/
@[simp]
lemma norm_sq_rot (θ : ℝ) (v : R2) : ‖rot θ v‖ ^ 2 = ‖v‖ ^ 2 := by
  rw [← real_inner_self_eq_norm_sq, ← real_inner_self_eq_norm_sq, inner_rot_rot]

/-- 2D rotation is an isometry: $\|\mathcal{R}_\theta v\| = \|v\|$. -/
@[simp]
theorem norm_rot (θ : ℝ) (v : R2) : ‖rot θ v‖ = ‖v‖ :=
  (sq_eq_sq₀ (norm_nonneg _) (norm_nonneg _)).mp (norm_sq_rot θ v)

/-! ### Part 4: Medoid Key RoPE Relative Angular Invariance -/

/--
**Medoid Key RoPE Invariance**:
Under RoPE rotation, the inner product between query at position $m$ and medoid key at position $n$
satisfies:
$$\langle \mathcal{R}_{m\theta} q, \mathcal{R}_{n\theta} k_{\mathrm{medoid}} \rangle =
  \langle q, \mathcal{R}_{(n - m)\theta} k_{\mathrm{medoid}} \rangle =
  \langle \mathcal{R}_{(m - n)\theta} q, k_{\mathrm{medoid}} \rangle$$
proving that the medoid key retains pure relative positional shift $(m - n)\theta$.
-/
theorem rope_medoid_relative_invariance (m n θ : ℝ) (q k_medoid : R2) :
    @inner ℝ R2 _ (rot (m * θ) q) (rot (n * θ) k_medoid) =
      @inner ℝ R2 _ q (rot ((n - m) * θ) k_medoid) ∧
    @inner ℝ R2 _ (rot (m * θ) q) (rot (n * θ) k_medoid) =
      @inner ℝ R2 _ (rot ((m - n) * θ) q) k_medoid :=
  ⟨by rw [inner_rot_rot_angles, sub_mul], by rw [inner_rot_rot_angles', sub_mul]⟩

/-! ### Part 5: Key Arithmetic Non-Coherence and Attenuation Theorem -/

variable {ι : Type*}

/-- Arithmetic mean of RoPE-rotated keys across a cluster $S$:
$$k_{\mathrm{avg}} = \frac{1}{|S|} \sum_{j \in S} \mathcal{R}_{\mathrm{pos}(j)\theta} k_j$$ -/
def keyAvg (S : Finset ι) (pos : ι → ℝ) (θ : ℝ) (k : ι → R2) : R2 :=
  ((S.card : ℝ)⁻¹) • ∑ j ∈ S, rot (pos j * θ) (k j)

/--
**Key Arithmetic Expansion**:
The attention dot product with an averaged key expands linearly into the mean of individual relative-position inner products:
$$\langle \mathcal{R}_{m\theta} q, k_{\mathrm{avg}} \rangle =
  \frac{1}{|S|} \sum_{j \in S} \langle q, \mathcal{R}_{(\mathrm{pos}(j) - m)\theta} k_j \rangle$$
-/
theorem key_arithmetic_expansion (S : Finset ι) (pos : ι → ℝ) (θ m : ℝ) (q : R2) (k : ι → R2) :
    @inner ℝ R2 _ (rot (m * θ) q) (keyAvg S pos θ k) =
      ((S.card : ℝ)⁻¹) * ∑ j ∈ S, @inner ℝ R2 _ q (rot ((pos j - m) * θ) (k j)) := by
  simp_rw [keyAvg, inner_smul_right, inner_sum, inner_rot_rot_angles, sub_mul]

/-- Double sum expansion of the inner product of rotated sums. -/
lemma sum_rot_inner_sum_rot (S : Finset ι) (pos : ι → ℝ) (θ : ℝ) (k₀ : R2) :
    @inner ℝ R2 _ (∑ i ∈ S, rot (pos i * θ) k₀) (∑ j ∈ S, rot (pos j * θ) k₀) =
      ‖k₀‖ ^ 2 * ∑ i ∈ S, ∑ j ∈ S, Real.cos ((pos j - pos i) * θ) := by
  simp_rw [sum_inner, inner_sum, inner_rot_rot_self, sub_mul, ← Finset.mul_sum]

/-- Exact norm squared of the averaged key vector. -/
lemma norm_sq_keyAvg_eq (S : Finset ι) (pos : ι → ℝ) (θ : ℝ) (k₀ : R2) :
    ‖keyAvg S pos θ (fun _ => k₀)‖ ^ 2 =
      ((S.card : ℝ)⁻¹ ^ 2 * ‖k₀‖ ^ 2) * ∑ i ∈ S, ∑ j ∈ S, Real.cos ((pos j - pos i) * θ) := by
  dsimp [keyAvg]
  rw [norm_smul, mul_pow, Real.norm_eq_abs, abs_inv,
    abs_of_nonneg (Nat.cast_nonneg _), ← real_inner_self_eq_norm_sq,
    sum_rot_inner_sum_rot]
  ring

/-- Upper bound on the cosine double sum by $|S|^2$. -/
lemma sum_cos_le_card_sq (S : Finset ι) (pos : ι → ℝ) (θ : ℝ) :
    (∑ i ∈ S, ∑ j ∈ S, Real.cos ((pos j - pos i) * θ)) ≤ (S.card : ℝ) ^ 2 := by
  have h1 (i : ι) : (∑ j ∈ S, Real.cos ((pos j - pos i) * θ)) ≤ (S.card : ℝ) := by
    simpa using Finset.sum_le_sum (fun j _ => Real.cos_le_one ((pos j - pos i) * θ))
  calc ∑ i ∈ S, ∑ j ∈ S, Real.cos ((pos j - pos i) * θ)
    _ ≤ ∑ i ∈ S, (S.card : ℝ) := Finset.sum_le_sum (fun i _ => h1 i)
    _ = (S.card : ℝ) ^ 2 := by simp [sq]

/-- Strict attenuation on the cosine double sum when at least one pair has non-identical phase. -/
lemma sum_cos_lt_card_sq (S : Finset ι) (pos : ι → ℝ) (θ : ℝ)
    (i₀ j₀ : ι) (hi₀ : i₀ ∈ S) (hj₀ : j₀ ∈ S)
    (h_cos : Real.cos ((pos j₀ - pos i₀) * θ) < 1) :
    (∑ i ∈ S, ∑ j ∈ S, Real.cos ((pos j - pos i) * θ)) < (S.card : ℝ) ^ 2 := by
  have h_inner (i : ι) : (∑ j ∈ S, Real.cos ((pos j - pos i) * θ)) ≤ (S.card : ℝ) := by
    simpa using Finset.sum_le_sum (fun j _ => Real.cos_le_one ((pos j - pos i) * θ))
  have h_inner_strict : (∑ j ∈ S, Real.cos ((pos j - pos i₀) * θ)) < (S.card : ℝ) := by
    simpa using Finset.sum_lt_sum (fun j _ => Real.cos_le_one ((pos j - pos i₀) * θ)) ⟨j₀, hj₀, h_cos⟩
  calc ∑ i ∈ S, ∑ j ∈ S, Real.cos ((pos j - pos i) * θ)
    _ < ∑ i ∈ S, (S.card : ℝ) := Finset.sum_lt_sum (fun i _ => h_inner i) ⟨i₀, hi₀, h_inner_strict⟩
    _ = (S.card : ℝ) ^ 2 := by simp [sq]

/--
**Key Arithmetic Norm Bound**:
The averaged key vector has norm bounded by $\|k_0\|$:
$$\|\bar{k}\| \le \|k_0\|$$
-/
theorem key_arithmetic_norm_le (S : Finset ι) (pos : ι → ℝ) (θ : ℝ) (k₀ : R2) :
    ‖keyAvg S pos θ (fun _ => k₀)‖ ≤ ‖k₀‖ := by
  rcases S.eq_empty_or_nonempty with rfl | hne
  · simp [keyAvg]
  · have hS_pos : 0 < (S.card : ℝ) := Nat.cast_pos.mpr hne.card_pos
    have h_bound : ‖keyAvg S pos θ (fun _ => k₀)‖ ^ 2 ≤ ‖k₀‖ ^ 2 := by
      rw [norm_sq_keyAvg_eq]
      calc (S.card : ℝ)⁻¹ ^ 2 * ‖k₀‖ ^ 2 * (∑ i ∈ S, ∑ j ∈ S, Real.cos ((pos j - pos i) * θ))
        _ ≤ (S.card : ℝ)⁻¹ ^ 2 * ‖k₀‖ ^ 2 * (S.card : ℝ) ^ 2 :=
          mul_le_mul_of_nonneg_left (sum_cos_le_card_sq S pos θ) (by positivity)
        _ = ‖k₀‖ ^ 2 := by
          rw [mul_right_comm, ← mul_pow, inv_mul_cancel₀ hS_pos.ne', one_pow, one_mul]
    exact (sq_le_sq₀ (norm_nonneg _) (norm_nonneg _)).mp h_bound

/--
**Key Arithmetic Strict Attenuation**:
When key positions in cluster $S$ are not identical, the averaged key vector strictly attenuates in norm:
$$\|\bar{k}\| < \|k_0\|$$
-/
theorem key_arithmetic_norm_lt (S : Finset ι) (pos : ι → ℝ) (θ : ℝ) (k₀ : R2)
    (hk₀ : k₀ ≠ 0) (i₀ j₀ : ι) (hi₀ : i₀ ∈ S) (hj₀ : j₀ ∈ S)
    (h_cos : Real.cos ((pos j₀ - pos i₀) * θ) < 1) :
    ‖keyAvg S pos θ (fun _ => k₀)‖ < ‖k₀‖ := by
  have hS_pos : 0 < (S.card : ℝ) := Nat.cast_pos.mpr (Finset.Nonempty.card_pos ⟨i₀, hi₀⟩)
  have h_bound : ‖keyAvg S pos θ (fun _ => k₀)‖ ^ 2 < ‖k₀‖ ^ 2 := by
    rw [norm_sq_keyAvg_eq]
    calc (S.card : ℝ)⁻¹ ^ 2 * ‖k₀‖ ^ 2 * (∑ i ∈ S, ∑ j ∈ S, Real.cos ((pos j - pos i) * θ))
      _ < (S.card : ℝ)⁻¹ ^ 2 * ‖k₀‖ ^ 2 * (S.card : ℝ) ^ 2 :=
        mul_lt_mul_of_pos_left (sum_cos_lt_card_sq S pos θ i₀ j₀ hi₀ hj₀ h_cos) (by positivity)
      _ = ‖k₀‖ ^ 2 := by
        rw [mul_right_comm, ← mul_pow, inv_mul_cancel₀ hS_pos.ne', one_pow, one_mul]
  exact (sq_lt_sq₀ (norm_nonneg _) (norm_nonneg _)).mp h_bound

/--
**SO(2) Orbit Non-Membership**:
Because every element of the SO(2) orbit $\mathrm{SO}(2) \cdot k_0$ has norm exactly $\|k_0\|$,
the attenuated key vector $\bar{k}$ does NOT belong to the orbit of $k_0$:
$$\bar{k} \notin \mathrm{SO}(2) \cdot k_0$$
-/
theorem key_arithmetic_not_in_so2_orbit (S : Finset ι) (pos : ι → ℝ) (θ : ℝ) (k₀ : R2)
    (hk₀ : k₀ ≠ 0) (i₀ j₀ : ι) (hi₀ : i₀ ∈ S) (hj₀ : j₀ ∈ S)
    (h_cos : Real.cos ((pos j₀ - pos i₀) * θ) < 1) :
    ∀ ϕ : ℝ, keyAvg S pos θ (fun _ => k₀) ≠ rot ϕ k₀ := by
  intro ϕ h_eq
  have h1 := congr_arg norm h_eq
  rw [norm_rot] at h1
  linarith [key_arithmetic_norm_lt S pos θ k₀ hk₀ i₀ j₀ hi₀ hj₀ h_cos]

/--
**Relative Phase Destruction**:
The averaged key cannot be represented as $\mathcal{R}_{n^*\theta} k_0$ for any single valid rotation without norm loss.
-/
theorem key_arithmetic_phase_destroyed (S : Finset ι) (pos : ι → ℝ) (θ : ℝ) (k₀ : R2)
    (hk₀ : k₀ ≠ 0) (i₀ j₀ : ι) (hi₀ : i₀ ∈ S) (hj₀ : j₀ ∈ S)
    (h_cos : Real.cos ((pos j₀ - pos i₀) * θ) < 1) :
    ¬ ∃ n_star : ℝ, keyAvg S pos θ (fun _ => k₀) = rot (n_star * θ) k₀ :=
  fun ⟨n_star, hn⟩ => key_arithmetic_not_in_so2_orbit S pos θ k₀ hk₀ i₀ j₀ hi₀ hj₀ h_cos (n_star * θ) hn

/-! ### Part 6: Temporal Variance Correction (Section 4.12) -/

/-- Mean sequence position of a token cluster $S$: $\mu = \frac{1}{|S|} \sum_{j \in S} \mathrm{pos}(j)$. -/
def meanPos (S : Finset ι) (pos : ι → ℝ) : ℝ :=
  ((S.card : ℝ)⁻¹) * ∑ j ∈ S, pos j

/-- Positional variance of a token cluster $S$: $\mathrm{Var}(P_S) = \frac{1}{|S|} \sum_{j \in S} (\mathrm{pos}(j) - \mu)^2$. -/
def varPos (S : Finset ι) (pos : ι → ℝ) : ℝ :=
  ((S.card : ℝ)⁻¹) * ∑ j ∈ S, (pos j - meanPos S pos) ^ 2

/-- Positional variance is always non-negative: $\mathrm{Var}(P_S) \ge 0$. -/
lemma varPos_nonneg (S : Finset ι) (pos : ι → ℝ) : 0 ≤ varPos S pos := by
  dsimp [varPos]; positivity

/--
Synthetic temporal decay multiplier:
$$\gamma = \exp(-\lambda \cdot \mathrm{Var}(P_S))$$
-/
def temporalGamma (decayRate var : ℝ) : ℝ :=
  Real.exp (-decayRate * var)

/-- The decay multiplier is strictly positive: $\gamma > 0$. -/
lemma temporalGamma_pos (decayRate var : ℝ) : 0 < temporalGamma decayRate var :=
  Real.exp_pos _

/-- For non-negative decay rate $\lambda \ge 0$ and non-negative variance, $\gamma \le 1$. -/
lemma temporalGamma_le_one (decayRate var : ℝ) (hdecay : 0 ≤ decayRate) (hvar : 0 ≤ var) :
    temporalGamma decayRate var ≤ 1 :=
  Real.exp_le_one_iff.mpr (by nlinarith)

/-- Condensed Medoid Key with Temporal Correction: $k_{\mathrm{condensed}} = \gamma \cdot \mathcal{R}_{n_{\mathrm{medoid}}\theta} k_{\mathrm{medoid}}$. -/
def condensedKey (γ : ℝ) (n_medoid θ : ℝ) (k_medoid : R2) : R2 :=
  γ • rot (n_medoid * θ) k_medoid

/--
**Attention Logit Scaling**:
The attention logit factors cleanly through the decay factor $\gamma$:
$$\langle \mathcal{R}_{m\theta} q, k_{\mathrm{condensed}} \rangle = \gamma \cdot \langle \mathcal{R}_{m\theta} q, \mathcal{R}_{n_{\mathrm{medoid}}\theta} k_{\mathrm{medoid}} \rangle$$
-/
theorem condensed_key_logit_scaling (γ : ℝ) (m n_medoid θ : ℝ) (q k_medoid : R2) :
    @inner ℝ R2 _ (rot (m * θ) q) (condensedKey γ n_medoid θ k_medoid) =
      γ * @inner ℝ R2 _ (rot (m * θ) q) (rot (n_medoid * θ) k_medoid) :=
  inner_smul_right ..

/--
**Relative Positional Logit Invariance under Temporal Correction**:
The condensed key simultaneously maintains pure relative angle $(n_{\mathrm{medoid}} - m)\theta$ and monotonic scaling by $\gamma$:
$$\langle \mathcal{R}_{m\theta} q, k_{\mathrm{condensed}} \rangle =
  \gamma \cdot \langle q, \mathcal{R}_{(n_{\mathrm{medoid}} - m)\theta} k_{\mathrm{medoid}} \rangle =
  \gamma \cdot \langle \mathcal{R}_{(m - n_{\mathrm{medoid}})\theta} q, k_{\mathrm{medoid}} \rangle$$
-/
theorem condensed_key_relative_invariance (γ : ℝ) (m n_medoid θ : ℝ) (q k_medoid : R2) :
    @inner ℝ R2 _ (rot (m * θ) q) (condensedKey γ n_medoid θ k_medoid) =
      γ * @inner ℝ R2 _ q (rot ((n_medoid - m) * θ) k_medoid) ∧
    @inner ℝ R2 _ (rot (m * θ) q) (condensedKey γ n_medoid θ k_medoid) =
      γ * @inner ℝ R2 _ (rot ((m - n_medoid) * θ) q) k_medoid :=
  ⟨by rw [condensed_key_logit_scaling, inner_rot_rot_angles, sub_mul],
   by rw [condensed_key_logit_scaling, inner_rot_rot_angles', sub_mul]⟩

/--
**Rotational Direction Preservation**:
The normalized direction of $k_{\mathrm{condensed}}$ is identically equal to $\mathcal{R}_{n_{\mathrm{medoid}}\theta} (k_{\mathrm{medoid}} / \|k_{\mathrm{medoid}}\|)$.
Scaling by $\gamma$ alters only magnitude, preserving exact geometric phase.
-/
theorem condensed_key_direction_preservation (γ : ℝ) (hγ : 0 < γ) (n_medoid θ : ℝ) (k_medoid : R2) :
    ‖condensedKey γ n_medoid θ k_medoid‖⁻¹ • condensedKey γ n_medoid θ k_medoid =
      ‖k_medoid‖⁻¹ • rot (n_medoid * θ) k_medoid := by
  dsimp [condensedKey]
  rw [norm_smul, norm_rot, Real.norm_eq_abs, abs_of_pos hγ, mul_inv, smul_smul,
    mul_right_comm, inv_mul_cancel₀ hγ.ne', one_mul]

/-- Monotonic decay of attention logit scaling with respect to positional variance. -/
theorem temporalGamma_monotone_variance (decayRate v1 v2 : ℝ)
    (hdecay : 0 ≤ decayRate) (hle : v1 ≤ v2) :
    temporalGamma decayRate v2 ≤ temporalGamma decayRate v1 :=
  Real.exp_le_exp.mpr (by nlinarith)

end RoPE
