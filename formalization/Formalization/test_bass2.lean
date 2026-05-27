import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.SchurComplement
import Formalization.IharaZeta

open Matrix
open scoped Matrix

variable {V : Type*} [Fintype V] [DecidableEq V]
variable (G : SimpleGraph V) [DecidableRel G.Adj]
variable (R : Type*) [CommRing R]

lemma target_mul_target :
    Dart.targetMatrix G R * (Dart.targetMatrix G R).transpose = Matrix.diagonal (fun v => (G.degree v : R)) := by
  ext u v
  simp only [Matrix.mul_apply, Matrix.transpose_apply, Dart.targetMatrix, Matrix.diagonal_apply]
  have h_sum : (∑ x : G.Dart, (if u = x.snd then (1 : R) else 0) * (if v = x.snd then (1 : R) else 0)) =
               ∑ x : G.Dart, if u = x.snd ∧ v = x.snd then (1 : R) else 0 := by
    apply Finset.sum_congr rfl
    intro x _
    by_cases h1 : u = x.snd <;> by_cases h2 : v = x.snd <;> simp [h1, h2]
  rw [h_sum]
  by_cases h : u = v
  · rw [if_pos h]
    have h_eq : (∑ x : G.Dart, if u = x.snd ∧ v = x.snd then (1 : R) else 0) =
                ∑ x : G.Dart, if u = x.snd then (1 : R) else 0 := by
      apply Finset.sum_congr rfl
      intro x _
      rw [h]
      simp
    rw [h_eq]
    -- Need to map x to x.symm which has u = x.symm.fst
    have e : {x : G.Dart // u = x.snd} ≃ G.neighborSet u :=
    { toFun := fun x => ⟨x.val.fst, by
        have hh : G.Adj x.val.fst x.val.snd := x.val.adj
        rw [← x.property] at hh
        exact G.symm hh⟩,
      invFun := fun y => ⟨SimpleGraph.Dart.mk (y.val, u) y.property.symm, rfl⟩,
      left_inv := fun x => by
        ext
        · rfl
        · exact x.property
      right_inv := fun y => by
        apply Subtype.ext
        rfl }
    have h1 : (∑ x : G.Dart, if u = x.snd then (1 : R) else 0) =
              (Finset.filter (fun x : G.Dart => u = x.snd) Finset.univ).card := by
      simp [Finset.sum_boole]
    rw [h1]
    have h2 : (Finset.filter (fun x : G.Dart => u = x.snd) Finset.univ).card = Fintype.card {x : G.Dart // u = x.snd} := by
      exact Eq.symm (Fintype.card_subtype fun x : G.Dart => u = x.snd)
    rw [h2]
    have h3 : Fintype.card {x : G.Dart // u = x.snd} = Fintype.card (G.neighborSet u) :=
      Fintype.card_congr e
    rw [h3]
    have h4 : Fintype.card (G.neighborSet u) = G.degree u :=
      SimpleGraph.card_neighborSet_eq_degree G u
    rw [h4]
  · rw [if_neg h]
    apply Finset.sum_eq_zero
    intro x _
    have h_false : ¬(u = x.snd ∧ v = x.snd) := by
      intro ⟨h1, h2⟩
      rw [h1, ←h2] at h
      exact h rfl
    rw [if_neg h_false]

lemma involution_sq :
    Dart.involutionMatrix G R * Dart.involutionMatrix G R = 1 := by
  ext d1 d2
  simp only [Matrix.mul_apply, Dart.involutionMatrix, Matrix.one_apply]
  have h_sum : (∑ x : G.Dart, (if x = d1.symm then (1 : R) else 0) * (if d2 = x.symm then (1 : R) else 0)) =
               ∑ x : G.Dart, if x = d1.symm ∧ d2 = x.symm then (1 : R) else 0 := by
    apply Finset.sum_congr rfl
    intro x _
    by_cases h1 : x = d1.symm <;> by_cases h2 : d2 = x.symm <;> simp [h1, h2]
  rw [h_sum]
  by_cases h : d1 = d2
  · rw [if_pos h]
    have h_eq : (∑ x : G.Dart, if x = d1.symm ∧ d2 = x.symm then (1 : R) else 0) =
                ∑ x : G.Dart, if x = d1.symm then (1 : R) else 0 := by
      apply Finset.sum_congr rfl
      intro x _
      rw [h]
      have : d2 = x.symm ↔ x = d2.symm := by
        constructor
        · intro hx
          rw [hx, SimpleGraph.Dart.symm_symm]
        · intro hx
          rw [hx, SimpleGraph.Dart.symm_symm]
      simp [this]
    rw [h_eq]
    rw [Finset.sum_eq_single d1.symm]
    · simp
    · intro b _ hb
      rw [if_neg hb]
    · intro h'
      simp at h'
  · rw [if_neg h]
    apply Finset.sum_eq_zero
    intro x _
    have h_false : ¬(x = d1.symm ∧ d2 = x.symm) := by
      intro ⟨h1, h2⟩
      rw [h1] at h2
      rw [SimpleGraph.Dart.symm_symm] at h2
      exact h h2.symm
    rw [if_neg h_false]
