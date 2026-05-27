import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.SchurComplement
import Formalization.IharaZeta

open Matrix
open scoped Matrix

variable {V : Type*} [Fintype V] [DecidableEq V]
variable (G : SimpleGraph V) [DecidableRel G.Adj]
variable (R : Type*) [CommRing R]
variable (u : R)

noncomputable def M_Bass : Matrix (V ⊕ G.Dart) (V ⊕ G.Dart) R :=
  fromBlocks 1 (u • Dart.sourceMatrix G R)
             (Dart.targetMatrix G R).transpose (1 + u • Dart.involutionMatrix G R)

noncomputable def N_Bass : Matrix (V ⊕ G.Dart) (V ⊕ G.Dart) R :=
  fromBlocks ((1 - u^2) • 1) 0
             0 (1 - u • Dart.involutionMatrix G R)

noncomputable def K_Bass : Matrix (V ⊕ G.Dart) (V ⊕ G.Dart) R :=
  fromBlocks ((1 - u^2) • 1) (u • Dart.sourceMatrix G R - u^2 • Dart.targetMatrix G R)
             ((1 - u^2) • (Dart.targetMatrix G R).transpose) ((1 - u^2) • 1)

noncomputable def L_Bass : Matrix (V ⊕ G.Dart) (V ⊕ G.Dart) R :=
  fromBlocks 1 0
             (- (Dart.targetMatrix G R).transpose) 1

noncomputable def KL_Bass : Matrix (V ⊕ G.Dart) (V ⊕ G.Dart) R :=
  fromBlocks (1 - u • G.adjMatrix R + u^2 • (Matrix.diagonal (fun v => (G.degree v : R)) - 1))
             (u • Dart.sourceMatrix G R - u^2 • Dart.targetMatrix G R)
             0 ((1 - u^2) • 1)

lemma M_Bass_mul_N_Bass : M_Bass G R u * N_Bass G R u = K_Bass G R u := by
  sorry

lemma K_Bass_mul_L_Bass : K_Bass G R u * L_Bass G R = KL_Bass G R u := by
  sorry

-- Main Bass theorem (Polynomial version)
theorem ihara_bass_polynomial :
    det (1 - u • HashimotoMatrix G R) * det (1 - u • Dart.involutionMatrix G R) * (1 - u^2)^(Fintype.card V) =
    det (1 - u • G.adjMatrix R + u^2 • (Matrix.diagonal (fun v => (G.degree v : R)) - 1)) * (1 - u^2)^(Fintype.card G.Dart) := by
  sorry
