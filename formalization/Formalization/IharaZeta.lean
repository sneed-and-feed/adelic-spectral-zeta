import Mathlib

open Polynomial Matrix

variable {V : Type*} [Fintype V] [DecidableEq V]
variable (G : SimpleGraph V) [DecidableRel G.Adj]
variable (d : ℕ) (h_reg : G.IsRegularOfDegree d)
variable (R : Type*) [CommRing R]

noncomputable def HashimotoMatrix : Matrix G.Dart G.Dart R :=
  fun d₁ d₂ => if d₁.snd = d₂.fst ∧ d₂ ≠ d₁.symm then 1 else 0

noncomputable def Dart.sourceMatrix : Matrix V G.Dart R :=
  fun v e => if v = e.fst then 1 else 0

noncomputable def Dart.targetMatrix : Matrix V G.Dart R :=
  fun v e => if v = e.snd then 1 else 0

noncomputable def Dart.involutionMatrix : Matrix G.Dart G.Dart R :=
  fun d₁ d₂ => if d₂ = d₁.symm then 1 else 0

lemma sourceMatrix_mul_targetMatrix_transpose :
    Dart.sourceMatrix G R * (Dart.targetMatrix G R).transpose = G.adjMatrix R := by
  ext u v
  simp only [Matrix.mul_apply, Matrix.transpose_apply, Dart.sourceMatrix, Dart.targetMatrix, SimpleGraph.adjMatrix_apply]
  have h_sum : (∑ x : G.Dart, (if u = x.fst then (1 : R) else 0) * (if v = x.snd then (1 : R) else 0)) =
               ∑ x : G.Dart, if u = x.fst ∧ v = x.snd then (1 : R) else 0 := by
    apply Finset.sum_congr rfl
    intro x _
    by_cases h1 : u = x.fst <;> by_cases h2 : v = x.snd <;> simp [h1, h2]
  rw [h_sum]
  by_cases h : G.Adj u v
  · rw [if_pos h]
    have h_eq : (∑ x : G.Dart, if u = x.fst ∧ v = x.snd then (1 : R) else 0) =
                ∑ x : G.Dart, if x = SimpleGraph.Dart.mk (u, v) h then (1 : R) else 0 := by
      apply Finset.sum_congr rfl
      intro x _
      have : u = x.fst ∧ v = x.snd ↔ x = SimpleGraph.Dart.mk (u, v) h := by
        constructor
        · intro ⟨h1, h2⟩
          ext
          · exact h1.symm
          · exact h2.symm
        · intro hx
          rw [hx]
          exact ⟨rfl, rfl⟩
      simp [this]
    rw [h_eq]
    rw [Finset.sum_eq_single (SimpleGraph.Dart.mk (u, v) h)]
    · simp
    · intro b _ hb
      rw [if_neg hb]
    · intro h'
      simp at h'
  · rw [if_neg h]
    apply Finset.sum_eq_zero
    intro x _
    have h_false : ¬(u = x.fst ∧ v = x.snd) := by
      intro ⟨h1, h2⟩
      have hadj := x.adj
      rw [←h1, ←h2] at hadj
      exact h hadj
    rw [if_neg h_false]

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

lemma targetMatrix_mul_targetMatrix_transpose :
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
    have e : {x : G.Dart // u = x.snd} ≃ G.neighborSet u :=
    { toFun := fun x => ⟨x.val.fst, by
        have hh : G.Adj x.val.fst x.val.snd := x.val.adj
        rw [← x.property] at hh
        exact G.symm hh⟩,
      invFun := fun y => ⟨SimpleGraph.Dart.mk (y.val, u) y.property.symm, rfl⟩,
      left_inv := fun x => by
        ext
        · rfl
        · exact x.property,
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

lemma sourceMatrix_mul_involutionMatrix :
    Dart.sourceMatrix G R * Dart.involutionMatrix G R = Dart.targetMatrix G R := by
  ext u v
  simp only [Matrix.mul_apply, Dart.sourceMatrix, Dart.involutionMatrix, Dart.targetMatrix]
  have h_sum : (∑ x : G.Dart, (if u = x.fst then (1 : R) else 0) * (if v = x.symm then (1 : R) else 0)) =
               ∑ x : G.Dart, if u = x.fst ∧ v = x.symm then (1 : R) else 0 := by
    apply Finset.sum_congr rfl
    intro x _
    by_cases h1 : u = x.fst <;> by_cases h2 : v = x.symm <;> simp [h1, h2]
  rw [h_sum]
  by_cases h : u = v.snd
  · rw [if_pos h]
    have h_eq : (∑ x : G.Dart, if u = x.fst ∧ v = x.symm then (1 : R) else 0) =
                ∑ x : G.Dart, if x = v.symm then (1 : R) else 0 := by
      apply Finset.sum_congr rfl
      intro x _
      have : u = x.fst ∧ v = x.symm ↔ x = v.symm := by
        constructor
        · intro ⟨h1, h2⟩
          have h3 : v.symm = x.symm.symm := by rw [h2]
          rw [SimpleGraph.Dart.symm_symm x] at h3
          exact h3.symm
        · intro hx
          rw [hx]
          exact ⟨h, (SimpleGraph.Dart.symm_symm v).symm⟩
      simp [this]
    rw [h_eq]
    rw [Finset.sum_eq_single v.symm]
    · simp
    · intro b _ hb
      rw [if_neg hb]
    · intro h'
      simp at h'
  · rw [if_neg h]
    apply Finset.sum_eq_zero
    intro x _
    have h_false : ¬(u = x.fst ∧ v = x.symm) := by
      intro ⟨h1, h2⟩
      have h3 : x.symm.fst = v.fst := by rw [←h2]
      have h4 : x.fst = x.symm.snd := by rfl
      rw [←h2] at h4
      rw [←h4] at h
      exact h h1
    rw [if_neg h_false]

lemma involutionMatrix_sq :
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

noncomputable def IharaZetaInvLHS : R[X] :=
  let u := (X : R[X])
  let T : Matrix G.Dart G.Dart R[X] := (HashimotoMatrix G R).map (algebraMap R R[X])
  let I := (1 : Matrix G.Dart G.Dart R[X])
  (I - u • T).det

noncomputable def IharaZetaInvRHS : R[X] :=
  let u := (X : R[X])
  let A : Matrix V V R[X] := (G.adjMatrix R).map (algebraMap R R[X])
  let I := (1 : Matrix V V R[X])
  let r_minus_1 := (d * Fintype.card V) / 2 - Fintype.card V
  (1 - u^2)^(r_minus_1) * (I - u • A + ((d - 1 : R[X]) * u^2) • I).det

theorem ihara_zeta_identity :
    IharaZetaInvLHS G R = IharaZetaInvRHS G d R := by
  sorry