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
  simp only [M_Bass, N_Bass, K_Bass, fromBlocks_multiply]
  apply fromBlocks_inj.mpr
  refine ⟨?_, ?_, ?_, ?_⟩
  · simp
  · simp [Matrix.mul_sub, Matrix.mul_one, Matrix.smul_mul, Matrix.mul_smul, sourceMatrix_mul_involutionMatrix, smul_smul, sq]
  · simp
  · simp [Matrix.add_mul, Matrix.mul_sub, Matrix.mul_one, Matrix.one_mul, Matrix.smul_mul, Matrix.mul_smul, involutionMatrix_sq, smul_smul, sq]
    ext i j
    simp [Matrix.add_apply, Matrix.sub_apply, Matrix.smul_apply, Matrix.one_apply, sq, mul_comm]
    by_cases h : i = j <;> simp [h]
    ring

lemma K_Bass_mul_L_Bass : K_Bass G R u * L_Bass G R = KL_Bass G R u := by
  simp only [K_Bass, L_Bass, KL_Bass, fromBlocks_multiply]
  apply fromBlocks_inj.mpr
  refine ⟨?_, ?_, ?_, ?_⟩
  · simp [Matrix.sub_mul, Matrix.smul_mul, Matrix.mul_neg, sourceMatrix_mul_targetMatrix_transpose, targetMatrix_mul_targetMatrix_transpose]
    ext i j
    simp [Matrix.add_apply, Matrix.sub_apply, Matrix.smul_apply, Matrix.one_apply, Matrix.neg_apply, Matrix.diagonal_apply, sq, mul_comm]
    by_cases h : i = j <;> simp [h]
    ring
  · simp
  · simp [Matrix.mul_neg]
  · simp

lemma det_M_Bass : det (M_Bass G R u) = det (1 - u • HashimotoMatrix G R) := by
  have : Invertible (1 : Matrix V V R) := invertibleOne
  rw [M_Bass, det_fromBlocks₁₁ 1 _ _ _]
  simp [invOf_one, Matrix.mul_one, targetMatrix_transpose_mul_sourceMatrix, Matrix.smul_mul, Matrix.mul_smul, smul_smul, mul_add, sub_add_cancel_right, add_sub_cancel_right]

lemma det_N_Bass : det (N_Bass G R u) = (1 - u^2)^(Fintype.card V) * det (1 - u • Dart.involutionMatrix G R) := by
  rw [N_Bass, det_fromBlocks_zero₁₂]
  simp [det_smul]

lemma det_L_Bass : det (L_Bass G R) = 1 := by
  rw [L_Bass, det_fromBlocks_zero₁₂]
  simp

lemma det_KL_Bass : det (KL_Bass G R u) = det (1 - u • G.adjMatrix R + u^2 • (Matrix.diagonal (fun v => (G.degree v : R)) - 1)) * (1 - u^2)^(Fintype.card G.Dart) := by
  rw [KL_Bass, det_fromBlocks_zero₂₁]
  simp [det_smul]

-- Main Bass theorem (Polynomial version)
theorem ihara_bass_polynomial :
    det (1 - u • HashimotoMatrix G R) * det (1 - u • Dart.involutionMatrix G R) * (1 - u^2)^(Fintype.card V) =
    det (1 - u • G.adjMatrix R + u^2 • (Matrix.diagonal (fun v => (G.degree v : R)) - 1)) * (1 - u^2)^(Fintype.card G.Dart) := by
  have eq1 : M_Bass G R u * N_Bass G R u * L_Bass G R = KL_Bass G R u := by
    rw [M_Bass_mul_N_Bass, K_Bass_mul_L_Bass]
  have eq2 : det (M_Bass G R u * N_Bass G R u * L_Bass G R) = det (KL_Bass G R u) := by
    rw [eq1]
  rw [det_mul, det_mul, det_M_Bass, det_N_Bass, det_L_Bass, det_KL_Bass] at eq2
  ring_nf at eq2 ⊢
  exact eq2
