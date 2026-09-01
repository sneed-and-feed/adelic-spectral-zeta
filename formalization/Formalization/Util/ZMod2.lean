import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Fin.Basic
import Mathlib.Tactic

/-!
# ZMod 2 Utilities

Utility lemmas and equivalences for `ZMod 2`.
-/

/-- Equivalence between the direct sum `α ⊕ α` and the product `α × ZMod 2`. -/
def sumProdEquiv (α : Type*) : α ⊕ α ≃ α × ZMod 2 where
  toFun := fun x => match x with
    | Sum.inl a => (a, 0)
    | Sum.inr a => (a, 1)
  invFun := fun p => match p.2 with
    | 0 => Sum.inl p.1
    | 1 => Sum.inr p.1
  left_inv := by intro x; cases x <;> rfl
  right_inv := by rintro ⟨v, b⟩; fin_cases b <;> rfl

/-- Equivalence between `ZMod 2` and `Fin 2`. -/
def zmodTwoEquivFinTwo : ZMod 2 ≃ Fin 2 where
  toFun := fun x => match x with
    | 0 => 0
    | 1 => 1
  invFun := fun x => match x with
    | 0 => 0
    | 1 => 1
  left_inv := by intro x; fin_cases x <;> rfl
  right_inv := by intro x; fin_cases x <;> rfl

/-- Evaluation of a sum over `ZMod 2` as `f 0 + f 1`. -/
lemma sum_zmod_two {β : Type*} [AddCommMonoid β] (f : ZMod 2 → β) :
    ∑ i : ZMod 2, f i = f 0 + f 1 := by
  have : (Finset.univ : Finset (ZMod 2)) = {0, 1} := rfl
  rw [this]
  simp
