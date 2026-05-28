import Formalization.ManyBodyEntanglement
open Classical
open scoped BigOperators
open Matrix

namespace ManyBodyPhaseTransition
variable {I : Type} [Fintype I] [DecidableEq I]
variable (bp : Bipartition I)

noncomputable def stateA (state : FermionState I) (h : ValidFermionState state) : BasisState bp.A :=
  ⟨fun a => state (bp.equiv.symm (Sum.inl a)), fun _ => h _⟩

noncomputable def stateB (state : FermionState I) (h : ValidFermionState state) : BasisState bp.B :=
  ⟨fun b => state (bp.equiv.symm (Sum.inr b)), fun _ => h _⟩

lemma join_state_eq (state : FermionState I) (h : ValidFermionState state) :
    joinBasisState (stateA bp state h) (stateB bp state h) = ⟨state, h⟩ := by
  apply Subtype.ext
  funext i
  unfold joinBasisState joinState stateA stateB
  dsimp
  cases h_equiv : bp.equiv i with
  | inl val =>
    have : i = bp.equiv.symm (Sum.inl val) := by
      apply Equiv.injective bp.equiv
      rw [Equiv.apply_symm_apply]
      exact h_equiv
    rw [this]
  | inr val =>
    have : i = bp.equiv.symm (Sum.inr val) := by
      apply Equiv.injective bp.equiv
      rw [Equiv.apply_symm_apply]
      exact h_equiv
    rw [this]

lemma purity_basis_state (state : FermionState I) (h : ValidFermionState state) :
    Purity bp (fun n => if n = ⟨state, h⟩ then (1 : ℂ) else (0 : ℂ)) = 1 := by
  sorry

end ManyBodyPhaseTransition
