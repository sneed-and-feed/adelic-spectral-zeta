import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.SchurComplement
import Formalization.IharaZeta

open Matrix
open scoped Matrix

variable {V : Type*} [Fintype V] [DecidableEq V]
variable (G : SimpleGraph V) [DecidableRel G.Adj]
variable (R : Type*) [CommRing R]

lemma sourceMatrix_mul_sourceMatrix_transpose :
    Dart.sourceMatrix G R * (Dart.sourceMatrix G R).transpose = Matrix.diagonal (fun v => (G.degree v : R)) := by
  ext u v
  simp only [Matrix.mul_apply, Matrix.transpose_apply, Dart.sourceMatrix, Matrix.diagonal_apply]
  have h_sum : (∑ x : G.Dart, (if u = x.fst then (1 : R) else 0) * (if v = x.fst then (1 : R) else 0)) =
               ∑ x : G.Dart, if u = x.fst ∧ v = x.fst then (1 : R) else 0 := by
    apply Finset.sum_congr rfl
    intro x _
    by_cases h1 : u = x.fst <;> by_cases h2 : v = x.fst <;> simp [h1, h2]
  rw [h_sum]
  by_cases h : u = v
  · rw [if_pos h]
    have h_eq : (∑ x : G.Dart, if u = x.fst ∧ v = x.fst then (1 : R) else 0) =
                ∑ x : G.Dart, if u = x.fst then (1 : R) else 0 := by
      apply Finset.sum_congr rfl
      intro x _
      rw [h]
      simp
    rw [h_eq]
    have e : {x : G.Dart // u = x.fst} ≃ G.neighborSet u :=
    { toFun := fun x => ⟨x.val.snd, by
        have hh : G.Adj x.val.fst x.val.snd := x.val.adj
        rw [← x.property] at hh
        exact hh⟩,
      invFun := fun y => ⟨SimpleGraph.Dart.mk (u, y.val) y.property, rfl⟩,
      left_inv := fun x => by
        ext
        · exact x.property
        · rfl,
      right_inv := fun y => by
        apply Subtype.ext
        rfl }
    have h1 : (∑ x : G.Dart, if u = x.fst then (1 : R) else 0) =
              (Finset.filter (fun x : G.Dart => u = x.fst) Finset.univ).card := by
      simp [Finset.sum_boole]
    rw [h1]
    have h2 : (Finset.filter (fun x : G.Dart => u = x.fst) Finset.univ).card = Fintype.card {x : G.Dart // u = x.fst} := by
      exact Eq.symm (Fintype.card_subtype fun x : G.Dart => u = x.fst)
    rw [h2]
    have h3 : Fintype.card {x : G.Dart // u = x.fst} = Fintype.card (G.neighborSet u) :=
      Fintype.card_congr e
    rw [h3]
    have h4 : Fintype.card (G.neighborSet u) = G.degree u :=
      SimpleGraph.card_neighborSet_eq_degree G u
    rw [h4]
  · rw [if_neg h]
    apply Finset.sum_eq_zero
    intro x _
    have h_false : ¬(u = x.fst ∧ v = x.fst) := by
      intro ⟨h1, h2⟩
      rw [h1, ←h2] at h
      exact h rfl
    rw [if_neg h_false]

lemma targetMatrix_transpose_mul_sourceMatrix :
    (Dart.targetMatrix G R).transpose * Dart.sourceMatrix G R = HashimotoMatrix G R + Dart.involutionMatrix G R := by
  ext u v
  simp only [Matrix.mul_apply, Matrix.transpose_apply, Dart.sourceMatrix, Dart.targetMatrix, HashimotoMatrix, Dart.involutionMatrix, Matrix.add_apply]
  have h_sum : (∑ x : V, (if x = u.snd then (1 : R) else 0) * (if x = v.fst then (1 : R) else 0)) =
               if u.snd = v.fst then (1 : R) else 0 := by
    by_cases hh : u.snd = v.fst
    · rw [if_pos hh]
      have h_eq2 : (∑ x : V, (if x = u.snd then (1 : R) else 0) * if x = v.fst then 1 else 0) = ∑ x : V, if x = u.snd then (1 : R) else 0 := by
        apply Finset.sum_congr rfl
        intro x _
        by_cases hx : x = u.snd
        · rw [if_pos hx]
          have h_x_v : x = v.fst := by rw [hx, hh]
          rw [if_pos h_x_v, mul_one]
        · rw [if_neg hx, zero_mul]
      rw [h_eq2]
      rw [Finset.sum_eq_single u.snd]
      · simp
      · intro b _ hb
        rw [if_neg hb]
      · intro h_not_in
        exfalso
        exact h_not_in (Finset.mem_univ _)
    · rw [if_neg hh]
      apply Finset.sum_eq_zero
      intro x _
      by_cases hx : x = u.snd
      · rw [if_pos hx]
        have h_x_v : x ≠ v.fst := by
          intro h_v
          rw [hx] at h_v
          exact hh h_v
        rw [if_neg h_x_v, mul_zero]
      · rw [if_neg hx, zero_mul]
  rw [h_sum]
  by_cases h1 : u.snd = v.fst
  · rw [if_pos h1]
    by_cases h2 : v = u.symm
    · have h_not : ¬(u.snd = v.fst ∧ v ≠ u.symm) := by
        intro ⟨_, h_neq⟩
        exact h_neq h2
      rw [if_neg h_not, if_pos h2, zero_add]
    · have h_and : u.snd = v.fst ∧ v ≠ u.symm := ⟨h1, h2⟩
      rw [if_pos h_and, if_neg h2, add_zero]
  · rw [if_neg h1]
    have h_not : ¬(u.snd = v.fst ∧ v ≠ u.symm) := by
      intro ⟨h_a, _⟩
      exact h1 h_a
    rw [if_neg h_not]
    have h_not2 : ¬(v = u.symm) := by
      intro h_v
      rw [h_v] at h1
      have h3 : u.symm.fst = u.snd := rfl
      rw [h3] at h1
      exact h1 rfl
    rw [if_neg h_not2, zero_add]

lemma involutionMatrix_mul_targetMatrix_transpose :
    Dart.involutionMatrix G R * (Dart.targetMatrix G R).transpose = (Dart.sourceMatrix G R).transpose := by
  ext u v
  simp only [Matrix.mul_apply, Matrix.transpose_apply, Dart.involutionMatrix, Dart.targetMatrix, Dart.sourceMatrix]
  have h_sum : (∑ x : G.Dart, (if x = u.symm then (1 : R) else 0) * (if v = x.snd then (1 : R) else 0)) =
               if v = u.symm.snd then (1 : R) else 0 := by
    rw [Finset.sum_eq_single u.symm]
    · by_cases h : v = u.symm.snd
      · rw [if_pos rfl, if_pos h, mul_one]
      · rw [if_pos rfl, if_neg h, mul_zero]
    · intro b _ hb
      rw [if_neg hb, zero_mul]
    · intro h_not_in
      exfalso
      exact h_not_in (Finset.mem_univ _)
  rw [h_sum]
  have h_symm : u.symm.snd = u.fst := rfl
  rw [h_symm]
