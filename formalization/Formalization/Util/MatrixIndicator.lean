import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Finset.Basic
import Mathlib.Algebra.BigOperators.Ring.Finset

/-!
# Matrix Indicator Sum Lemmas

Utility lemmas for simplifying indicator sums arising in matrix multiplication.
-/

variable {α : Type*} [Fintype α] [DecidableEq α] {R : Type*} [Semiring R]

@[simp]
lemma sum_ite_eq (u : α) : ∑ x : α, (if x = u then (1 : R) else 0) = 1 := by
  simp

@[simp]
lemma sum_ite_eq' (u : α) : ∑ x : α, (if u = x then (1 : R) else 0) = 1 := by
  simp

lemma sum_ite_eq_mul_ite_eq (u v : α) :
    ∑ x : α, (if x = u then (1 : R) else 0) * (if x = v then (1 : R) else 0) = if u = v then 1 else 0 := by
  rcases eq_or_ne u v with rfl | hne
  · simp
  · rw [ite_eq_right hne]
    exact Finset.sum_eq_zero fun x _ => by split_ifs <;> simp_all

lemma sum_ite_eq_mul_ite_eq' (u v : α) :
    ∑ x : α, (if u = x then (1 : R) else 0) * (if v = x then (1 : R) else 0) = if u = v then 1 else 0 := by
  rcases eq_or_ne u v with rfl | hne
  · simp
  · rw [ite_eq_right hne]
    exact Finset.sum_eq_zero fun x _ => by split_ifs <;> simp_all

lemma sum_ite_eq_mul_ite_eq_right (u v : α) :
    ∑ x : α, (if u = x then (1 : R) else 0) * (if x = v then (1 : R) else 0) = if u = v then 1 else 0 := by
  rcases eq_or_ne u v with rfl | hne
  · simp
  · rw [ite_eq_right hne]
    exact Finset.sum_eq_zero fun x _ => by split_ifs <;> simp_all

lemma sum_ite_eq_mul_ite_eq_left (u v : α) :
    ∑ x : α, (if x = u then (1 : R) else 0) * (if v = x then (1 : R) else 0) = if u = v then 1 else 0 := by
  rcases eq_or_ne u v with rfl | hne
  · simp
  · rw [ite_eq_right hne]
    exact Finset.sum_eq_zero fun x _ => by split_ifs <;> simp_all
