import Mathlib.Data.Complex.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.Polynomial.Basic
import Mathlib.FieldTheory.RatFunc.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FinCases
import Formalization.Dynamics.CircleSpectrumAutomata

open Matrix Polynomial

def collatzAutomaton : AffineAutomaton 2 where
  a := 1
  B := (Finset.univ : Finset (ZMod (2 : ℕ+)))

noncomputable def collatzMatrix : Matrix (ZMod (2 : ℕ+)) (ZMod (2 : ℕ+)) ℂ :=
  collatzAutomaton.transitionMatrix

lemma collatzMatrix_apply (x y : ZMod (2 : ℕ+)) : collatzMatrix x y = 1 := by
  unfold collatzMatrix collatzAutomaton AffineAutomaton.transitionMatrix
  dsimp
  have h_single : (∑ b : ZMod (2 : ℕ+), if y = 1 * x + b then (1 : ℂ) else 0) = 1 := by
    rw [Finset.sum_eq_single (y - 1 * x)]
    · have h_eq : 1 * x + (y - 1 * x) = y := by ring
      simp only [h_eq, ite_true]
    · intro b _ hb
      have h_ne : ¬(y = 1 * x + b) := by
        intro h
        apply hb
        calc b = 1 * x + b - 1 * x := by ring
          _ = y - 1 * x := by rw [h]
      simp only [h_ne, ite_false]
    · intro h
      exact (h (Finset.mem_univ _)).elim
  exact h_single

def zmodTwoEquivFinTwo : ZMod (2 : ℕ+) ≃ Fin 2 where
  toFun x := match x with
    | 0 => 0
    | 1 => 1
  invFun i := match i with
    | 0 => 0
    | 1 => 1
  left_inv := by intro x; fin_cases x <;> rfl
  right_inv := by intro i; fin_cases i <;> rfl

noncomputable def collatzMatrixPoly : Matrix (ZMod (2 : ℕ+)) (ZMod (2 : ℕ+)) (Polynomial ℂ) :=
  collatzMatrix.map Polynomial.C

noncomputable def collatzCharDet : Polynomial ℂ :=
  Matrix.det ((1 : Matrix (ZMod (2 : ℕ+)) (ZMod (2 : ℕ+)) (Polynomial ℂ)) - (Polynomial.X : Polynomial ℂ) • collatzMatrixPoly)

lemma collatzCharDet_eq : collatzCharDet = 1 - 2 * Polynomial.X := by
  unfold collatzCharDet collatzMatrixPoly
  rw [← Matrix.det_reindex_self zmodTwoEquivFinTwo]
  rw [Matrix.det_fin_two]
  change ((1 : Matrix (ZMod (2 : ℕ+)) (ZMod (2 : ℕ+)) (Polynomial ℂ)) 0 0 - X * Polynomial.C (collatzMatrix 0 0)) *
         ((1 : Matrix (ZMod (2 : ℕ+)) (ZMod (2 : ℕ+)) (Polynomial ℂ)) 1 1 - X * Polynomial.C (collatzMatrix 1 1)) -
         ((1 : Matrix (ZMod (2 : ℕ+)) (ZMod (2 : ℕ+)) (Polynomial ℂ)) 0 1 - X * Polynomial.C (collatzMatrix 0 1)) *
         ((1 : Matrix (ZMod (2 : ℕ+)) (ZMod (2 : ℕ+)) (Polynomial ℂ)) 1 0 - X * Polynomial.C (collatzMatrix 1 0)) = 1 - 2 * Polynomial.X
  rw [collatzMatrix_apply 0 0, collatzMatrix_apply 1 1, collatzMatrix_apply 0 1, collatzMatrix_apply 1 0]
  have h01 : (1 : Matrix (ZMod (2 : ℕ+)) (ZMod (2 : ℕ+)) (Polynomial ℂ)) 0 1 = 0 := rfl
  have h10 : (1 : Matrix (ZMod (2 : ℕ+)) (ZMod (2 : ℕ+)) (Polynomial ℂ)) 1 0 = 0 := rfl
  have h00 : (1 : Matrix (ZMod (2 : ℕ+)) (ZMod (2 : ℕ+)) (Polynomial ℂ)) 0 0 = 1 := rfl
  have h11 : (1 : Matrix (ZMod (2 : ℕ+)) (ZMod (2 : ℕ+)) (Polynomial ℂ)) 1 1 = 1 := rfl
  rw [h00, h11, h01, h10, Polynomial.C_1]
  ring

noncomputable def collatzZeta : RatFunc ℂ :=
  algebraMap (Polynomial ℂ) (RatFunc ℂ) 1 / algebraMap (Polynomial ℂ) (RatFunc ℂ) collatzCharDet

theorem collatz_zeta_rationality :
    collatzZeta = algebraMap (Polynomial ℂ) (RatFunc ℂ) 1 / algebraMap (Polynomial ℂ) (RatFunc ℂ) (1 - 2 * Polynomial.X) := by
  unfold collatzZeta
  rw [collatzCharDet_eq]
