import Mathlib
import Formalization.CircleSpectrumAutomata

open Matrix Polynomial

def collatzAutomaton : AffineAutomaton 2 where
  a := 1
  B := {0, 1}

noncomputable def collatzMatrix : Matrix (ZMod 2) (ZMod 2) ℂ :=
  collatzAutomaton.transitionMatrix

lemma collatzMatrix_apply (x y : ZMod 2) : collatzMatrix x y = 1 := by
  unfold collatzMatrix collatzAutomaton AffineAutomaton.transitionMatrix
  dsimp
  revert x y; intro x y
  fin_cases x <;> fin_cases y <;> (
    rw [Finset.sum_pair (by decide)]
    norm_num
  )

noncomputable def collatzMatrixPoly : Matrix (ZMod 2) (ZMod 2) (Polynomial ℂ) :=
  collatzMatrix.map Polynomial.C

noncomputable def collatzCharDet : Polynomial ℂ :=
  Matrix.det ((1 : Matrix (ZMod 2) (ZMod 2) (Polynomial ℂ)) - (Polynomial.X : Polynomial ℂ) • collatzMatrixPoly)

lemma collatzCharDet_eq : collatzCharDet = 1 - 2 * Polynomial.X := by
  unfold collatzCharDet collatzMatrixPoly
  rw [Matrix.det_fin_two]
  dsimp [Matrix.sub_apply, Matrix.smul_apply, Matrix.one_apply, Matrix.map_apply]
  simp [collatzMatrix_apply]
  ring

noncomputable def collatzZeta : RatFunc ℂ :=
  algebraMap (Polynomial ℂ) (RatFunc ℂ) 1 / algebraMap (Polynomial ℂ) (RatFunc ℂ) collatzCharDet

theorem collatz_zeta_rationality :
    collatzZeta = algebraMap (Polynomial ℂ) (RatFunc ℂ) 1 / algebraMap (Polynomial ℂ) (RatFunc ℂ) (1 - 2 * Polynomial.X) := by
  unfold collatzZeta
  rw [collatzCharDet_eq]

