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

lemma eigenvector_constant_sign_matrix {B : Matrix n n ℝ} (hB : ∀ i j, 0 < B i j)
    (μ : ℝ) (hμ : 0 < μ) (w : n → ℝ) (hw_nonzero : w ≠ 0)
    (hw_eig : B.mulVec w = μ • w) (h_abs_eig : B.mulVec (|w|) = μ • (|w|)) :
    (∀ i, 0 < w i) ∨ (∀ i, w i < 0) := by
  let z : n → ℝ := |w| - w
  have hz_nn : ∀ i, 0 ≤ z i := fun i => sub_nonneg.mpr (le_abs_self (w i))
  have hz_eig : B.mulVec z = μ • z := by
    rw [mulVec_sub, h_abs_eig, hw_eig, smul_sub]
  by_cases hz_zero : z = 0
  · left
    have hw_pos_some : ∃ j, 0 < w j := by
      by_contra h_all
      push_neg at h_all
      have hw_zero : w = 0 := by
        ext i
        have hz_i : z i = 0 := congr_fun hz_zero i
        have hw_abs : |w i| = w i := eq_of_sub_eq_zero hz_i
        have h_nonpos : w i ≤ 0 := h_all i
        exact le_antisymm h_nonpos (by rw [←hw_abs]; exact abs_nonneg _)
      exact hw_nonzero hw_zero
    have hw_eq_abs : w = |w| := by
      ext i
      have hz_i : z i = 0 := by rw [hz_zero]; rfl
      exact eq_of_sub_eq_zero hz_i |>.symm
    have h_B_w_pos : ∀ i, 0 < (B.mulVec w) i := by
      intro i
      dsimp [mulVec, dotProduct]
      have h_nn : ∀ j ∈ Finset.univ, 0 ≤ B i j * w j := by
        intro j _
        have hw_nn_j : 0 ≤ w j := by rw [hw_eq_abs]; exact abs_nonneg _
        exact mul_nonneg (le_of_lt (hB i j)) hw_nn_j
      obtain ⟨j, hj_pos⟩ := hw_pos_some
      have h_pos : 0 < B i j * w j := mul_pos (hB i j) hj_pos
      exact Finset.sum_pos' h_nn ⟨j, Finset.mem_univ j, h_pos⟩
    intro i
    have := h_B_w_pos i
    rw [hw_eig] at this
    exact pos_of_mul_pos_right this (le_of_lt hμ)
  · right
    have hz_pos_some : ∃ j, 0 < z j := by
      by_contra h_all
      push_neg at h_all
      apply hz_zero
      ext i
      exact le_antisymm (h_all i) (hz_nn i)
    have h_B_z_pos : ∀ i, 0 < (B.mulVec z) i := by
      intro i
      dsimp [mulVec, dotProduct]
      have h_nn : ∀ j ∈ Finset.univ, 0 ≤ B i j * z j := by
        intro j _
        exact mul_nonneg (le_of_lt (hB i j)) (hz_nn j)
      obtain ⟨j, hj_pos⟩ := hz_pos_some
      have h_pos : 0 < B i j * z j := mul_pos (hB i j) hj_pos
      exact Finset.sum_pos' h_nn ⟨j, Finset.mem_univ j, h_pos⟩
    intro i
    have := h_B_z_pos i
    rw [hz_eig] at this
    have hz_i_pos := pos_of_mul_pos_right this (le_of_lt hμ)
    have : |w i| - w i > 0 := hz_i_pos
    by_cases hwi : 0 ≤ w i
    · rw [abs_of_nonneg hwi] at this
      linarith
    · exact not_le.mp hwi

end Matrix
