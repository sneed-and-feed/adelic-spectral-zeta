import Mathlib.Data.Matrix.Basic
import Mathlib.Algebra.Module.Submodule.Basic

open Matrix

lemma reindex_mul_lemma {l m n l' m' n' : Type*} [Fintype m] [Fintype m'] [DecidableEq m] [DecidableEq m'] {α : Type*} [AddCommMonoid α] [Mul α]
  (A : Matrix l m α) (B : Matrix m n α) (f : l ≃ l') (g : m ≃ m') (h : n ≃ n') :
  Matrix.reindex f.symm g.symm A * Matrix.reindex g.symm h.symm B = Matrix.reindex f.symm h.symm (A * B) := by
  ext i j
  simp only [Matrix.reindex_apply, Matrix.mul_apply]
  exact Equiv.sum_comp g.symm (fun x => A (f.symm i) x * B x (h.symm j)) |>.symm

lemma reindex_one_lemma {m m' : Type*} [DecidableEq m] [DecidableEq m'] {α : Type*} [DecidableEq α] [Zero α] [One α] (f : m ≃ m') :
  Matrix.reindex f.symm f.symm (1 : Matrix m m α) = 1 := by
  ext i j
  simp only [Matrix.reindex_apply, Matrix.one_apply]
  split_ifs with h1 h2 h2
  · rfl
  · exact False.elim (h2 (f.symm.injective h1))
  · exact False.elim (h1 (congr_arg f.symm h2))
  · rfl
