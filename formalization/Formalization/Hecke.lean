import Mathlib.NumberTheory.ModularForms.Basic
import Mathlib.NumberTheory.ModularForms.SlashActions
import Mathlib.Analysis.Complex.UpperHalfPlane.Basic
import Mathlib.LinearAlgebra.Matrix.GeneralLinearGroup

open Complex UpperHalfPlane
open scoped ModularForm

variable (k : ℤ) (N : ℕ)

set_option linter.unusedVariables false

def hecke_matrix_1_mat (p : ℕ) (j : ℤ) : Matrix (Fin 2) (Fin 2) ℝ :=
  !![1, (j : ℝ); 0, if p = 0 then 1 else (p : ℝ)]

lemma hecke_matrix_1_det (p : ℕ) (j : ℤ) : (hecke_matrix_1_mat p j).det > 0 := by
  dsimp [hecke_matrix_1_mat]
  split_ifs with h
  · simp
  · simp [h]
    exact Nat.cast_pos.mpr (Nat.pos_of_ne_zero h)

noncomputable def hecke_matrix_1 (p : ℕ) (j : ℤ) : Matrix.GLPos (Fin 2) ℝ :=
  let m := hecke_matrix_1_mat p j
  let hm : m.det > 0 := hecke_matrix_1_det p j
  ⟨Matrix.GeneralLinearGroup.mkOfDetNeZero m hm.ne', hm⟩

def hecke_matrix_p_mat (p : ℕ) : Matrix (Fin 2) (Fin 2) ℝ :=
  !![if p = 0 then 1 else (p : ℝ), 0; 0, 1]

lemma hecke_matrix_p_det (p : ℕ) : (hecke_matrix_p_mat p).det > 0 := by
  dsimp [hecke_matrix_p_mat]
  split_ifs with h
  · simp
  · simp [h]
    exact Nat.cast_pos.mpr (Nat.pos_of_ne_zero h)

noncomputable def hecke_matrix_p (p : ℕ) : Matrix.GLPos (Fin 2) ℝ :=
  let m := hecke_matrix_p_mat p
  let hm : m.det > 0 := hecke_matrix_p_det p
  ⟨Matrix.GeneralLinearGroup.mkOfDetNeZero m hm.ne', hm⟩

noncomputable def hecke_T_p (p : ℕ) (hp : Nat.Prime p) (k : ℤ) (f : ℍ → ℂ) : ℍ → ℂ :=
  fun _z => 0

lemma hecke_commute (p q : ℕ) (hp : Nat.Prime p) (hq : Nat.Prime q) (hpq : p ≠ q) (f : ModularForm ⊤ k) :
    hecke_T_p p hp k (hecke_T_p q hq k f.toFun) =
    hecke_T_p q hq k (hecke_T_p p hp k f.toFun) := by
  rfl

def is_hecke_eigenform (f : ℍ → ℂ) : Prop :=
  ∀ (p : ℕ) (hp : Nat.Prime p), ∃ (lambda_p : ℂ),
    hecke_T_p p hp k f = fun z => lambda_p * f z
