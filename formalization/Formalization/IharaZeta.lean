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
  sorry

lemma sourceMatrix_mul_sourceMatrix_transpose :
    Dart.sourceMatrix G R * (Dart.sourceMatrix G R).transpose = Matrix.diagonal (fun v => (G.degree v : R)) := by
  sorry

lemma targetMatrix_mul_targetMatrix_transpose :
    Dart.targetMatrix G R * (Dart.targetMatrix G R).transpose = Matrix.diagonal (fun v => (G.degree v : R)) := by
  sorry

lemma targetMatrix_transpose_mul_sourceMatrix :
    (Dart.targetMatrix G R).transpose * Dart.sourceMatrix G R = HashimotoMatrix G R + Dart.involutionMatrix G R := by
  sorry

lemma involutionMatrix_mul_targetMatrix_transpose :
    Dart.involutionMatrix G R * (Dart.targetMatrix G R).transpose = (Dart.sourceMatrix G R).transpose := by
  sorry

lemma involutionMatrix_sq :
    Dart.involutionMatrix G R * Dart.involutionMatrix G R = 1 := by
  sorry

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
