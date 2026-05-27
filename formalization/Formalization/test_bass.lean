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

lemma M_Bass_mul_N_Bass : M_Bass G R u * N_Bass G R u = K_Bass G R u := by
  dsimp [M_Bass, N_Bass, K_Bass]
  rw [fromBlocks_multiply]
  ext (i|i) (j|j)
  · simp
  · simp only [fromBlocks_apply₁₂, mul_zero, zero_add, mul_sub, mul_one, Matrix.mul_smul, sourceMatrix_mul_involutionMatrix]
    rw [sub_eq_add_neg, sub_eq_add_neg, ←smul_neg]
    congr 1
    rw [smul_smul, pow_two]
  · simp [Matrix.mul_smul, smul_eq_mul, mul_comm]
  · simp only [fromBlocks_apply₂₂, mul_zero, zero_add, add_mul, one_mul, mul_sub, Matrix.mul_smul, involutionMatrix_sq, smul_smul]
    have : (1 : Matrix G.Dart G.Dart R) i j - (u^2 • 1 : Matrix G.Dart G.Dart R) i j = ((1 - u^2) • 1 : Matrix G.Dart G.Dart R) i j := by
      simp only [Matrix.sub_apply, Matrix.one_apply, Matrix.smul_apply, smul_eq_mul]
      by_cases h : i = j
      · simp [h, sub_mul]
      · simp [h]
    rw [this]
    congr 1
    simp only [Matrix.add_apply, Matrix.sub_apply, Matrix.smul_apply, Matrix.one_apply, smul_eq_mul]
    by_cases h : i = j
    · simp [h, pow_two]
    · simp [h]
