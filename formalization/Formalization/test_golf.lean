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
  sorry

