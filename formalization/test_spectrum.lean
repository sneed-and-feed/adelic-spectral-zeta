import Mathlib.LinearAlgebra.Matrix.Spectrum
import Mathlib.LinearAlgebra.Matrix.Gershgorin

open Matrix

lemma hasEigenvalue_eigenvalues {n : Type*} [Fintype n] [DecidableEq n] {A : Matrix n n ℝ}
    (hA : A.IsHermitian) (j : n) :
    Module.End.HasEigenvalue (Matrix.toLin' A) (hA.eigenvalues j) := by
  rw [Module.End.HasEigenvalue, Submodule.ne_bot_iff]
  use (hA.eigenvectorBasis j : n → ℝ)
  constructor
  · rw [Module.End.mem_eigenspace_iff, toLin'_apply]
    exact hA.mulVec_eigenvectorBasis j
  · intro h
    have h_ne := hA.eigenvectorBasis.toBasis.ne_zero j
    exact h_ne h

lemma eigenvalue_bound_of_gershgorin {n : Type*} [Fintype n] [DecidableEq n] {A : Matrix n n ℝ}
    (hA : A.IsHermitian) (j : n) (B : ℝ)
    (h_row : ∀ i, ∑ k, ‖A i k‖ ≤ B) :
    (hA.eigenvalues j) ∈ Set.Icc (-B) B := by
  have h_eig := hasEigenvalue_eigenvalues hA j
  have h_ball := eigenvalue_mem_ball h_eig
  rcases h_ball with ⟨k, hk⟩
  rw [mem_closedBall_iff_norm'] at hk
  have h_symm : ‖A k k - hA.eigenvalues j‖ = ‖hA.eigenvalues j - A k k‖ := norm_sub_rev _ _
  rw [h_symm] at hk
  have h1 : ‖hA.eigenvalues j‖ - ‖A k k‖ ≤ ‖hA.eigenvalues j - A k k‖ := norm_sub_norm_le _ _
  have h2 : ‖hA.eigenvalues j‖ ≤ ‖A k k‖ + ∑ y ∈ Finset.univ.erase k, ‖A k y‖ := by linarith
  have h3 : ‖A k k‖ + ∑ y ∈ Finset.univ.erase k, ‖A k y‖ = ∑ y, ‖A k y‖ := by
    exact Finset.add_sum_erase (s := Finset.univ) (f := fun y => ‖A k y‖) (h := Finset.mem_univ k)
  have hk2 : ‖hA.eigenvalues j‖ ≤ B := h2.trans (by rw [h3]; exact h_row k)
  rw [Real.norm_eq_abs, abs_le] at hk2
  exact hk2
