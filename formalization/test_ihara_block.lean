import Mathlib

open Polynomial Matrix

variable {V : Type*} [Fintype V] [DecidableEq V]
variable (G : SimpleGraph V) [DecidableRel G.Adj]
variable (d : ℕ) (h_reg : G.IsRegularOfDegree d)
variable (R : Type*) [CommRing R]

noncomputable def Dart.sourceMatrix : Matrix V G.Dart R :=
  fun v e => if v = e.fst then 1 else 0

noncomputable def Dart.targetMatrix : Matrix V G.Dart R :=
  fun v e => if v = e.snd then 1 else 0

noncomputable def Dart.involutionMatrix : Matrix G.Dart G.Dart R :=
  fun d₁ d₂ => if d₂ = d₁.symm then 1 else 0

noncomputable def HashimotoMatrix : Matrix G.Dart G.Dart R :=
  fun d₁ d₂ => if d₁.snd = d₂.fst ∧ d₂ ≠ d₁.symm then 1 else 0

-- Assuming the identities are proven:
variable (h_ST : Dart.sourceMatrix G R * (Dart.targetMatrix G R).transpose = G.adjMatrix R)
variable (h_SS : Dart.sourceMatrix G R * (Dart.sourceMatrix G R).transpose = Matrix.diagonal (fun v => (G.degree v : R)))
variable (h_TT : Dart.targetMatrix G R * (Dart.targetMatrix G R).transpose = Matrix.diagonal (fun v => (G.degree v : R)))
variable (h_TS : (Dart.targetMatrix G R).transpose * Dart.sourceMatrix G R = HashimotoMatrix G R + Dart.involutionMatrix G R)
variable (h_JT : Dart.involutionMatrix G R * (Dart.targetMatrix G R).transpose = (Dart.sourceMatrix G R).transpose)
variable (h_J2 : Dart.involutionMatrix G R * Dart.involutionMatrix G R = 1)

noncomputable def M1 : Matrix (V ⊕ G.Dart) (V ⊕ G.Dart) R[X] :=
  Matrix.fromBlocks
    (1 : Matrix V V R[X])
    ((X : R[X]) • (Dart.sourceMatrix G R).map (algebraMap R R[X]))
    ((X : R[X]) • ((Dart.targetMatrix G R).transpose).map (algebraMap R R[X]))
    ((1 : Matrix G.Dart G.Dart R[X]) + (X : R[X]) • (Dart.involutionMatrix G R).map (algebraMap R R[X]))

lemma det_M1_eval1 :
    M1 G R = Matrix.fromBlocks 1 0 0 1 := by
  sorry
