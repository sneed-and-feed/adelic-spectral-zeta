import Mathlib
import Mathlib.LinearAlgebra.Matrix.Charpoly.Basic

open Matrix Polynomial Finset
open scoped Polynomial

variable {R : Type*} [CommRing R] {L : ℕ} [NeZero L] (W : ZMod L → R)

def shiftMatrix (n : ℕ) (W : Fin n → R) : Matrix (Fin n) (Fin n) R :=
  fun i j => if (i : ℕ) = (j : ℕ) + 1 then W j else 0

lemma charmatrix_shiftMatrix_submatrix (n : ℕ) (W : Fin (n + 1) → R) :
    (charmatrix (shiftMatrix (n + 1) W)).submatrix Fin.succ Fin.succ =
      charmatrix (shiftMatrix n (fun x => W (Fin.succ x))) := by
  ext i j
  simp only [charmatrix, Matrix.submatrix_apply, Matrix.sub_apply, Matrix.diagonal_apply,
    Matrix.map_apply, shiftMatrix, Fin.ext_iff, Fin.val_succ, add_left_cancel_iff]
  congr 1
  by_cases h : (i : ℕ) = (j : ℕ)
  · simp [h]
  · simp [h]

lemma charpoly_shiftMatrix (n : ℕ) (W : Fin n → R) :
    (shiftMatrix n W).charpoly = X ^ n := by
  induction n with
  | zero => 
    rw [Matrix.charpoly, Matrix.det_fin_zero, pow_zero]
  | succ n ih =>
    rw [Matrix.charpoly, Matrix.det_succ_row_zero, Finset.sum_eq_single 0]
    · simp [charmatrix_shiftMatrix_submatrix, ih]
      ring
    · intro b _ hb
      simp [charmatrix, shiftMatrix, hb.symm, Matrix.diagonal]
    · simp

noncomputable def upperBidiagonal (n : ℕ) (W : Fin n → R) : Matrix (Fin n) (Fin n) (Polynomial R) :=
  fun i j => if (i : ℕ) = (j : ℕ) then - C (W j) else if (i : ℕ) + 1 = (j : ℕ) then X else 0

lemma upperBidiagonal_submatrix (n : ℕ) (W : Fin (n + 1) → R) :
    ((upperBidiagonal (n + 1) W).submatrix Fin.succ Fin.succ) =
      upperBidiagonal n (fun x => W (Fin.succ x)) := by
  ext i j
  simp only [upperBidiagonal, Matrix.submatrix_apply, Fin.ext_iff, Fin.val_succ, add_left_cancel_iff]
  by_cases h : (i : ℕ) = (j : ℕ)
  · simp [h]
  · simp [h]

lemma det_upperBidiagonal (n : ℕ) (W : Fin n → R) :
    (upperBidiagonal n W).det = ∏ i : Fin n, - C (W i) := by
  induction n with
  | zero => exact Matrix.det_fin_zero
  | succ n ih =>
    rw [Matrix.det_succ_column_zero, Finset.sum_eq_single 0]
    · rw [upperBidiagonal_submatrix, ih]
      rw [Fin.prod_univ_succ]
      ring
    · intro b _ hb
      have h1 : (b : ℕ) ≠ 0 := by exact Fin.val_ne_of_ne hb
      have h2 : (b : ℕ) + 1 ≠ 0 := Nat.succ_ne_zero _
      simp [upperBidiagonal, h1, h2]
    · simp
