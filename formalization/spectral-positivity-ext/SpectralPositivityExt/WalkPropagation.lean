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

def supportGraph (A : Matrix n n ℝ) (h_symm : ∀ i j, A i j = A j i) : SimpleGraph n where
  Adj i j := 0 < A i j ∧ i ≠ j
  symm := by
    intro i j h
    exact ⟨by rw [h_symm j i]; exact h.1, h.2.symm⟩
  loopless := by intro i h; exact h.2 rfl

lemma matrix_pow_nonneg {A : Matrix n n ℝ} (hA_nn : ∀ i j, 0 ≤ A i j) (k : ℕ) :
    ∀ i j, 0 ≤ (A ^ k) i j := by
  induction k with
  | zero =>
    intro i j
    by_cases h : i = j
    · rw [h, pow_zero, one_apply_eq]
      exact zero_le_one
    · rw [pow_zero, one_apply_ne h]
  | succ k ih =>
    intro i j
    rw [pow_succ', mul_apply]
    apply Finset.sum_nonneg
    intro x _
    exact mul_nonneg (hA_nn i x) (ih x j)

lemma matrix_pow_pos_of_walk {A : Matrix n n ℝ}
    (hA_symm : ∀ i j, A i j = A j i) (hA_nn : ∀ i j, 0 ≤ A i j)
    {i j : n} (w : SimpleGraph.Walk (supportGraph A hA_symm) i j) :
    0 < (A ^ w.length) i j := by
  induction w with
  | nil =>
    simp only [SimpleGraph.Walk.length_nil, pow_zero, one_apply_eq]
    exact zero_lt_one
  | cons h w_rest ih =>
    rename_i u v w
    rw [SimpleGraph.Walk.length_cons, pow_succ', mul_apply]
    have h_pos : 0 < A u v := h.1
    have h_term : 0 < A u v * (A ^ w_rest.length) v w := mul_pos h_pos ih
    have h_nonneg : ∀ k ∈ Finset.univ, 0 ≤ A u k * (A ^ w_rest.length) k w := by
      intro k _
      apply mul_nonneg (hA_nn _ _)
      exact matrix_pow_nonneg hA_nn w_rest.length k w
    exact Finset.sum_pos' h_nonneg ⟨v, Finset.mem_univ v, h_term⟩

lemma B_matrix_pow_ge_A_pow {A : Matrix n n ℝ} (hA_nn : ∀ i j, 0 ≤ A i j) (k : ℕ) :
    ∀ i j, (A ^ k) i j ≤ ((A + 1) ^ k) i j := by
  induction k with
  | zero =>
    intro i j
    rfl
  | succ k ih =>
    intro i j
    rw [pow_succ', pow_succ', mul_apply, mul_apply]
    apply Finset.sum_le_sum
    intro l _
    have h1 : A i l ≤ (A + 1) i l := by
      by_cases hil : i = l
      · rw [hil, add_apply, one_apply_eq]
        exact le_add_of_nonneg_right zero_le_one
      · rw [add_apply, one_apply_ne hil, add_zero]
    have h2 : (A ^ k) l j ≤ ((A + 1) ^ k) l j := ih l j
    have h3 : 0 ≤ (A ^ k) l j := matrix_pow_nonneg hA_nn k l j
    have hA1_nn : ∀ x y, 0 ≤ (A + 1) x y := fun x y => by
      by_cases h : x = y
      · rw [h, add_apply, one_apply_eq]
        exact add_nonneg (hA_nn y y) zero_le_one
      · rw [add_apply, one_apply_ne h, add_zero]
        exact hA_nn x y
    exact mul_le_mul h1 h2 h3 (hA1_nn i l)

end Matrix
