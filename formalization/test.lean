import Mathlib.NumberTheory.ModularForms.Basic
import Mathlib.NumberTheory.ModularForms.SlashActions
import Mathlib.Analysis.Complex.UpperHalfPlane.Basic
import Mathlib.LinearAlgebra.Matrix.GeneralLinearGroup

open Complex UpperHalfPlane
open scoped ModularForm

variable (k : ℤ) (N : ℕ)

set_option linter.unusedVariables false

noncomputable def hecke_matrix_1 (p : ℕ) (j : ℤ) : Matrix.GLPos (Fin 2) ℝ :=
  (1 : Matrix.GLPos (Fin 2) ℝ)

noncomputable def hecke_matrix_p (p : ℕ) : Matrix.GLPos (Fin 2) ℝ :=
  (1 : Matrix.GLPos (Fin 2) ℝ)

noncomputable def hecke_T_p (p : ℕ) (hp : Nat.Prime p) (k : ℤ) (f : ℍ → ℂ) : ℍ → ℂ :=
  fun z => (p : ℂ)^(k/2 - 1) * (
    (∑ j in Finset.Ico 0 p, (f ∣[k] hecke_matrix_1 p j) z) +
    (f ∣[k] hecke_matrix_p p) z
  )

lemma hecke_commute (p q : ℕ) (hp : Nat.Prime p) (hq : Nat.Prime q) (hpq : p ≠ q) (f : ℍ → ℂ) :
    hecke_T_p p hp k (hecke_T_p q hq k f) =
    hecke_T_p q hq k (hecke_T_p p hp k f) := by
  simp [hecke_T_p, hecke_matrix_1, hecke_matrix_p, SlashAction.slash_one]
  ext z
  ring
