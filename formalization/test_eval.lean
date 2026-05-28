import Mathlib

open Matrix

def M : Matrix (Fin 2) (Fin 2) ℤ :=
  !![1, -1;
     -1, -1]

lemma trace_M_sq : Matrix.trace (M * M) = 4 := by decide
