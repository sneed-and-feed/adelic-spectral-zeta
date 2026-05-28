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

lemma join_state_inj {nA nA' : BasisState bp.A} {nB : BasisState bp.B}
    (h_eq : joinBasisState nA nB = joinBasisState nA' nB) : nA = nA' := by
  apply Subtype.ext
  funext a
  have h_eq_fun := congr_arg Subtype.val h_eq
  have h_eq_eval := congr_fun h_eq_fun (bp.equiv.symm (Sum.inl a))
  unfold joinBasisState joinState at h_eq_eval
  dsimp at h_eq_eval
  rw [Equiv.apply_symm_apply] at h_eq_eval
  exact h_eq_eval

lemma join_state_inj_B {nA : BasisState bp.A} {nB nB' : BasisState bp.B}
    (h_eq : joinBasisState nA nB = joinBasisState nA nB') : nB = nB' := by
  apply Subtype.ext
  funext b
  have h_eq_fun := congr_arg Subtype.val h_eq
  have h_eq_eval := congr_fun h_eq_fun (bp.equiv.symm (Sum.inr b))
  unfold joinBasisState joinState at h_eq_eval
  dsimp at h_eq_eval
  rw [Equiv.apply_symm_apply] at h_eq_eval
  exact h_eq_eval

end ManyBodyPhaseTransition
