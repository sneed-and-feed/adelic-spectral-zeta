import Mathlib.Combinatorics.SimpleGraph.Basic
import Mathlib.Combinatorics.SimpleGraph.Dart
import Mathlib.Combinatorics.SimpleGraph.AdjMatrix
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Algebra.Polynomial.AlgebraMap
import Formalization.Util.MatrixIndicator

open Polynomial Matrix

set_option linter.unusedSectionVars false

section IharaZeta

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

/-- Equivalence between the darts originating at `u` and the neighbors of `u`. -/
def dartSourceEquiv (u : V) : {x : G.Dart // u = x.fst} ≃ G.neighborSet u where
  toFun x := ⟨x.1.snd, by
    have hh := x.1.adj
    rw [← x.2] at hh
    exact hh⟩
  invFun y := ⟨SimpleGraph.Dart.mk (u, y.1) y.2, rfl⟩
  left_inv x := Subtype.ext (by ext <;> [exact x.2; rfl])
  right_inv y := Subtype.ext rfl

/-- Equivalence between the darts terminating at `u` and the neighbors of `u`. -/
def dartTargetEquiv (u : V) : {x : G.Dart // u = x.snd} ≃ G.neighborSet u where
  toFun x := ⟨x.1.fst, by
    have hh := x.1.adj
    rw [← x.2] at hh
    exact hh.symm⟩
  invFun y := ⟨SimpleGraph.Dart.mk (y.1, u) y.2.symm, rfl⟩
  left_inv x := Subtype.ext (by ext <;> [rfl; exact x.2])
  right_inv y := Subtype.ext rfl

lemma sourceMatrix_mul_targetMatrix_transpose :
    Dart.sourceMatrix G R * (Dart.targetMatrix G R).transpose = G.adjMatrix R := by
  ext u v
  simp only [Matrix.mul_apply, Matrix.transpose_apply, Dart.sourceMatrix, Dart.targetMatrix, SimpleGraph.adjMatrix_apply]
  rcases em (G.Adj u v) with h | h
  · rw [ite_eq_left h]
    have h_single : (∑ x : G.Dart, (if u = x.fst then (1 : R) else 0) * if v = x.snd then 1 else 0) =
        (if u = (SimpleGraph.Dart.mk (u, v) h).fst then (1 : R) else 0) * if v = (SimpleGraph.Dart.mk (u, v) h).snd then 1 else 0 := by
      refine Finset.sum_eq_single (SimpleGraph.Dart.mk (u, v) h) (fun b _ hb => ?_) (fun h' => (h' (Finset.mem_univ _)).elim)
      have : ¬(u = b.fst ∧ v = b.snd) := fun ⟨h1, h2⟩ => hb (by ext <;> [exact h1.symm; exact h2.symm])
      split_ifs <;> simp_all
    rw [h_single]
    simp
  · rw [ite_eq_right h]
    exact Finset.sum_eq_zero fun x _ => by
      have : ¬(u = x.fst ∧ v = x.snd) := fun ⟨h1, h2⟩ => h (h1 ▸ h2 ▸ x.adj)
      split_ifs <;> simp_all

lemma sourceMatrix_mul_sourceMatrix_transpose :
    Dart.sourceMatrix G R * (Dart.sourceMatrix G R).transpose = Matrix.diagonal (fun v => (G.degree v : R)) := by
  ext u v
  simp only [Matrix.mul_apply, Matrix.transpose_apply, Dart.sourceMatrix, Matrix.diagonal_apply]
  rcases eq_or_ne u v with rfl | hne
  · simp only [ite_true]
    have : (∑ x : G.Dart, (if u = x.fst then (1 : R) else 0) * if u = x.fst then 1 else 0) =
           ∑ x : G.Dart, if u = x.fst then (1 : R) else 0 :=
      Finset.sum_congr rfl fun x _ => by split_ifs <;> simp
    rw [this, Finset.sum_boole]
    rw [← Fintype.card_subtype, Fintype.card_congr (dartSourceEquiv G u), SimpleGraph.card_neighborSet_eq_degree]
  · rw [ite_eq_right hne]
    exact Finset.sum_eq_zero fun x _ => by split_ifs <;> simp_all

lemma targetMatrix_mul_targetMatrix_transpose :
    Dart.targetMatrix G R * (Dart.targetMatrix G R).transpose = Matrix.diagonal (fun v => (G.degree v : R)) := by
  ext u v
  simp only [Matrix.mul_apply, Matrix.transpose_apply, Dart.targetMatrix, Matrix.diagonal_apply]
  rcases eq_or_ne u v with rfl | hne
  · simp only [ite_true]
    have : (∑ x : G.Dart, (if u = x.snd then (1 : R) else 0) * if u = x.snd then 1 else 0) =
           ∑ x : G.Dart, if u = x.snd then (1 : R) else 0 :=
      Finset.sum_congr rfl fun x _ => by split_ifs <;> simp
    rw [this, Finset.sum_boole]
    rw [← Fintype.card_subtype, Fintype.card_congr (dartTargetEquiv G u), SimpleGraph.card_neighborSet_eq_degree]
  · rw [ite_eq_right hne]
    exact Finset.sum_eq_zero fun x _ => by split_ifs <;> simp_all

lemma targetMatrix_transpose_mul_sourceMatrix :
    (Dart.targetMatrix G R).transpose * Dart.sourceMatrix G R = HashimotoMatrix G R + Dart.involutionMatrix G R := by
  ext u v
  simp only [Matrix.mul_apply, Matrix.transpose_apply, Dart.sourceMatrix, Dart.targetMatrix,
    HashimotoMatrix, Dart.involutionMatrix, Matrix.add_apply]
  rw [sum_ite_eq_mul_ite_eq u.snd v.fst]
  rcases eq_or_ne v u.symm with rfl | h <;> simp [*]

lemma involutionMatrix_mul_targetMatrix_transpose :
    Dart.involutionMatrix G R * (Dart.targetMatrix G R).transpose = (Dart.sourceMatrix G R).transpose := by
  ext u v
  simp only [Matrix.mul_apply, Matrix.transpose_apply, Dart.involutionMatrix, Dart.targetMatrix, Dart.sourceMatrix]
  rw [Finset.sum_eq_single u.symm (fun b _ hb => by simp [hb]) (fun h => (h (Finset.mem_univ _)).elim)]
  simp

lemma sourceMatrix_mul_involutionMatrix :
    Dart.sourceMatrix G R * Dart.involutionMatrix G R = Dart.targetMatrix G R := by
  ext u v
  simp only [Matrix.mul_apply, Dart.sourceMatrix, Dart.involutionMatrix, Dart.targetMatrix]
  have h_eq (x : G.Dart) : (v = x.symm) ↔ (x = v.symm) :=
    ⟨fun h => by subst h; rw [SimpleGraph.Dart.symm_symm], fun h => by subst h; rw [SimpleGraph.Dart.symm_symm]⟩
  simp_rw [h_eq]
  rw [Finset.sum_eq_single v.symm (fun b _ hb => by simp [hb]) (fun h => (h (Finset.mem_univ _)).elim)]
  simp

lemma involutionMatrix_sq :
    Dart.involutionMatrix G R * Dart.involutionMatrix G R = 1 := by
  ext d1 d2
  simp only [Matrix.mul_apply, Dart.involutionMatrix, Matrix.one_apply]
  have h_eq (x : G.Dart) : (d2 = x.symm) ↔ (x = d2.symm) :=
    ⟨fun h => by subst h; rw [SimpleGraph.Dart.symm_symm], fun h => by subst h; rw [SimpleGraph.Dart.symm_symm]⟩
  simp_rw [h_eq, sum_ite_eq_mul_ite_eq d1.symm d2.symm]
  rcases eq_or_ne d1 d2 with rfl | h
  · simp
  · have : d1.symm ≠ d2.symm := fun h' => h (by have := congrArg SimpleGraph.Dart.symm h'; simpa using this)
    simp [h, this]

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

end IharaZeta
