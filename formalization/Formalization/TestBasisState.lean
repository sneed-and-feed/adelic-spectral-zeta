import Formalization.ManyBodyPhaseTransition
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Matrix.Basic

namespace ManyBodyPhaseTransition

variable {I : Type} [Fintype I] [DecidableEq I]

def BasisState (I : Type) := { n : FermionState I // ValidFermionState n }

def basisEquivFin2 (I : Type) : BasisState I ≃ (I → Fin 2) where
  toFun n i := ⟨n.val i, by
    rcases n.property i with h | h
    · rw [h]; decide
    · rw [h]; decide⟩
  invFun f := ⟨fun i => (f i).val, fun i => by
    have h1 : (f i).val < 2 := (f i).isLt
    have h2 : (f i).val = 0 ∨ (f i).val = 1 := by omega
    exact h2⟩
  left_inv n := Subtype.ext (funext (fun i => rfl))
  right_inv f := funext (fun i => Fin.ext rfl)

instance : Fintype (BasisState I) :=
  Fintype.ofEquiv (I → Fin 2) (basisEquivFin2 I).symm

end ManyBodyPhaseTransition
