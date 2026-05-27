import Mathlib.Data.Matrix.Basic
import Mathlib.Combinatorics.SimpleGraph.Basic
import Mathlib.Combinatorics.SimpleGraph.Connectivity
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Group.Abs
import Mathlib.LinearAlgebra.Matrix.Spectrum
import Mathlib.Analysis.InnerProductSpace.PiL2

open Matrix
open Classical

namespace Matrix

variable {n : Type _} [Fintype n] [DecidableEq n] [Nonempty n]

lemma abs_eigenvector_of_symmetric {B : Matrix n n ℝ} (hB_symm : ∀ i j, B i j = B j i)
    (hB_nn : ∀ i j, 0 ≤ B i j)
    (μ : ℝ) (hμ_pos : 0 < μ) (v : n → ℝ) (hv_pos : ∀ i, 0 < v i) (hv_eig : B.mulVec v = μ • v)
    (w : n → ℝ) (hw_eig : B.mulVec w = μ • w) :
    B.mulVec (|w|) = μ • (|w|) := by
  let abs_w := fun i => |w i|
  let u := fun i => (B.mulVec abs_w) i - μ * abs_w i
  have hu_nn : ∀ i, 0 ≤ u i := by
    intro i
    dsimp [u, abs_w, mulVec, dotProduct]
    rw [sub_nonneg]
    have hw_eq : μ * w i = ∑ j, B i j * w j := by
      have : (B.mulVec w) i = μ * w i := by rw [hw_eig, Pi.smul_apply, smul_eq_mul]
      exact this.symm
    have hw_abs : μ * |w i| = |μ * w i| := by
      rw [abs_mul, abs_of_pos hμ_pos]
    rw [hw_abs, hw_eq]
    exact le_trans (Finset.abs_sum_le_sum_abs _ _) (Finset.sum_le_sum fun j _ => by
      rw [abs_mul, abs_of_nonneg (hB_nn i j)])
  have h_dot : dotProduct v u = 0 := by
    dsimp [u, abs_w, mulVec, dotProduct]
    have h1 : ∑ i, v i * (∑ j, B i j * |w j| - μ * |w i|) = 
              ∑ i, v i * (∑ j, B i j * |w j|) - ∑ i, v i * (μ * |w i|) := by
      rw [←Finset.sum_sub_distrib]
      apply Finset.sum_congr rfl
      intro i _
      rw [mul_sub]
    rw [h1]
    have h2 : ∑ i, v i * (∑ j, B i j * |w j|) = ∑ j, (∑ i, v i * B i j) * |w j| := by
      have h2a : ∑ i, v i * (∑ j, B i j * |w j|) = ∑ i, ∑ j, v i * (B i j * |w j|) := by
        apply Finset.sum_congr rfl
        intro i _
        rw [Finset.mul_sum]
      have h2b : ∑ i, ∑ j, v i * (B i j * |w j|) = ∑ j, ∑ i, v i * (B i j * |w j|) := Finset.sum_comm
      have h2c : ∑ j, ∑ i, v i * (B i j * |w j|) = ∑ j, (∑ i, v i * B i j) * |w j| := by
        apply Finset.sum_congr rfl
        intro j _
        have h_assoc : ∑ i, v i * (B i j * |w j|) = ∑ i, (v i * B i j) * |w j| := by
          apply Finset.sum_congr rfl
          intro i _
          ring
        rw [h_assoc, ←Finset.sum_mul]
      rw [h2a, h2b, h2c]
    rw [h2]
    have h3 : ∀ j, ∑ i, v i * B i j = μ * v j := by
      intro j
      have : ∑ i, B j i * v i = μ * v j := by
        have h_eig := congr_fun hv_eig j
        exact h_eig
      rw [←this]
      apply Finset.sum_congr rfl
      intro i _
      rw [hB_symm j i, mul_comm]
    have h4 : ∑ j, (μ * v j) * |w j| - ∑ i, v i * (μ * |w i|) = 0 := by
      have : ∑ j, (μ * v j) * |w j| = ∑ i, v i * (μ * |w i|) := by
        apply Finset.sum_congr rfl
        intro x _
        ring
      rw [this, sub_self]
    have h_final : ∑ j, (∑ i, v i * B i j) * |w j| - ∑ i, v i * (μ * |w i|) = 0 := by
      have : ∑ j, (∑ i, v i * B i j) * |w j| = ∑ j, (μ * v j) * |w j| := by
        apply Finset.sum_congr rfl
        intro j _
        rw [h3 j]
      rw [this, h4]
    exact h_final
  have hu_zero : ∀ i, u i = 0 := by
    intro i
    by_contra h_nz
    have h_pos : 0 < u i := lt_of_le_of_ne (hu_nn i) (Ne.symm h_nz)
    have h_dot_pos : 0 < dotProduct v u := by
      apply Finset.sum_pos'
      · intro j _
        exact mul_nonneg (le_of_lt (hv_pos j)) (hu_nn j)
      · use i, Finset.mem_univ i
        exact mul_pos (hv_pos i) h_pos
    have h_dot_zero : dotProduct v u = 0 := h_dot
    rw [h_dot_zero] at h_dot_pos
    exact lt_irrefl 0 h_dot_pos
  ext i
  have := hu_zero i
  dsimp [u, abs_w] at this
  rw [Pi.smul_apply, smul_eq_mul]
  exact eq_of_sub_eq_zero this

lemma pf_eigenvalue_is_max {B : Matrix n n ℝ} (hB_symm : ∀ i j, B i j = B j i)
    (hB_nn : ∀ i j, 0 ≤ B i j)
    (μ : ℝ) (v : n → ℝ) (hv_pos : ∀ i, 0 < v i) (hv_eig : B.mulVec v = μ • v)
    (lam : ℝ) (w : n → ℝ) (hw_nonzero : w ≠ 0) (hw_eig : B.mulVec w = lam • w) :
    lam ≤ μ := by
  let abs_w := fun i => |w i|
  have h_w_abs_nn : ∀ i, 0 ≤ abs_w i := fun i => abs_nonneg _
  have h_ineq : ∀ i, |lam| * abs_w i ≤ (B.mulVec abs_w) i := by
    intro i
    have h_eq : lam * w i = (B.mulVec w) i := by rw [hw_eig, Pi.smul_apply, smul_eq_mul]
    have h_abs : |lam| * abs_w i = |(B.mulVec w) i| := by
      rw [←abs_mul, h_eq]
    rw [h_abs]
    dsimp [mulVec, dotProduct]
    exact le_trans (Finset.abs_sum_le_sum_abs _ _) (Finset.sum_le_sum fun j _ => by
      rw [abs_mul, abs_of_nonneg (hB_nn i j)])
  have h_dot1 : dotProduct v (fun i => |lam| * abs_w i) ≤ dotProduct v (B.mulVec abs_w) := by
    apply Finset.sum_le_sum
    intro i _
    exact mul_le_mul_of_nonneg_left (h_ineq i) (le_of_lt (hv_pos i))
  have h_dot2 : dotProduct v (B.mulVec abs_w) = μ * dotProduct v abs_w := by
    have h_symm_dot : dotProduct v (B.mulVec abs_w) = dotProduct (B.mulVec v) abs_w := by
      dsimp [mulVec, dotProduct]
      have : ∑ i, v i * ∑ j, B i j * abs_w j = ∑ i, ∑ j, v i * B i j * abs_w j := by
        apply Finset.sum_congr rfl
        intro i _
        rw [Finset.mul_sum]
        apply Finset.sum_congr rfl
        intro j _
        ring
      rw [this]
      have : ∑ i, ∑ j, v i * B i j * abs_w j = ∑ j, ∑ i, B j i * v i * abs_w j := by
        rw [Finset.sum_comm]
        apply Finset.sum_congr rfl
        intro j _
        apply Finset.sum_congr rfl
        intro i _
        rw [hB_symm i j]
        ring
      rw [this]
      apply Finset.sum_congr rfl
      intro i _
      rw [←Finset.sum_mul]
    rw [h_symm_dot, hv_eig]
    dsimp [dotProduct]
    have h_assoc : ∑ i, (μ * v i) * abs_w i = ∑ i, μ * (v i * abs_w i) := by
      apply Finset.sum_congr rfl
      intro i _
      ring
    rw [h_assoc, ←Finset.mul_sum]
  have h_dot3 : dotProduct v (fun i => |lam| * abs_w i) = |lam| * dotProduct v abs_w := by
    dsimp [dotProduct]
    have h_assoc : ∑ i, v i * (|lam| * abs_w i) = ∑ i, |lam| * (v i * abs_w i) := by
      apply Finset.sum_congr rfl
      intro i _
      ring
    rw [h_assoc, ←Finset.mul_sum]
  rw [h_dot3, h_dot2] at h_dot1
  have h_dot_pos : 0 < dotProduct v abs_w := by
    apply Finset.sum_pos'
    · intro j _
      exact mul_nonneg (le_of_lt (hv_pos j)) (h_w_abs_nn j)
    · have hw_pos_some : ∃ j, 0 < abs_w j := by
        by_contra h_all
        push_neg at h_all
        have hw_zero : w = 0 := by
          ext i
          have : abs_w i ≤ 0 := h_all i
          have : abs_w i = 0 := le_antisymm this (h_w_abs_nn i)
          exact abs_eq_zero.mp this
        exact hw_nonzero hw_zero
      obtain ⟨j, hj⟩ := hw_pos_some
      use j, Finset.mem_univ j
      exact mul_pos (hv_pos j) hj
  have h_le : |lam| ≤ μ := (mul_le_mul_right h_dot_pos).mp h_dot1
  exact le_trans (le_abs_self lam) h_le

end Matrix
