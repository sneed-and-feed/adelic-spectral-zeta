import Mathlib
open Polynomial Matrix
variable {V : Type*} [Fintype V] [DecidableEq V]
variable (G : SimpleGraph V) [DecidableRel G.Adj]
variable (d : ℕ) (h_reg : G.IsRegularOfDegree d)
variable (R : Type*) [CommRing R]

noncomputable def HashimotoMatrix : Matrix G.Dart G.Dart R := fun d₁ d₂ => if d₁.snd = d₂.fst ∧ d₂ ≠ d₁.symm then 1 else 0
noncomputable def Dart.sourceMatrix : Matrix V G.Dart R := fun v e => if v = e.fst then 1 else 0
noncomputable def Dart.targetMatrix : Matrix V G.Dart R := fun v e => if v = e.snd then 1 else 0
noncomputable def Dart.involutionMatrix : Matrix G.Dart G.Dart R := fun d₁ d₂ => if d₂ = d₁.symm then 1 else 0

lemma involutionMatrix_sq :
    Dart.involutionMatrix G R * Dart.involutionMatrix G R = 1 := by
  ext d1 d2
  simp only [Matrix.mul_apply, Dart.involutionMatrix, Matrix.one_apply]
  have : (∑ x : G.Dart, (if x = d1.symm then (1 : R) else 0) * if d2 = x.symm then 1 else 0) =
         ∑ x : G.Dart, if x = d1.symm ∧ d2 = x.symm then (1 : R) else 0 := by
    apply Finset.sum_congr rfl; intro x _; simp [← ite_and]
  rw [this]
  by_cases h : d1 = d2
  · simp [h]
    have h_eq : (∑ x : G.Dart, if x = d1.symm ∧ d1 = x.symm then (1 : R) else 0) = ∑ x : G.Dart, if x = d1.symm then (1 : R) else 0 := by
      apply Finset.sum_congr rfl; intro x _
      have : x = d1.symm ↔ d1 = x.symm := by
        constructor <;> intro hx <;> rw [hx, SimpleGraph.Dart.symm_symm]
      aesop
    rw [h_eq, Finset.sum_eq_single d1.symm]
    · simp
    · aesop
    · simp
  · simp [h]
    apply Finset.sum_eq_zero
    intro x _
    have h_false : ¬(x = d1.symm ∧ d2 = x.symm) := by
      intro ⟨h1, h2⟩
      rw [h1] at h2
      rw [SimpleGraph.Dart.symm_symm] at h2
      exact h h2.symm
    rw [if_neg h_false]
