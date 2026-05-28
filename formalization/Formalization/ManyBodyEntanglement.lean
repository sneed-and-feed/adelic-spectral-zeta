import Formalization.ManyBodyPhaseTransition
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Fintype.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic

namespace ManyBodyPhaseTransition

variable {I : Type} [Fintype I] [DecidableEq I]

/-- Step 2.1: Spatial Bipartition -/
structure Bipartition (I : Type) where
  A : Type
  B : Type
  equiv : I ≃ A ⊕ B
  fintypeA : Fintype A
  fintypeB : Fintype B
  decEqA : DecidableEq A
  decEqB : DecidableEq B

attribute [instance] Bipartition.fintypeA Bipartition.fintypeB
attribute [instance] Bipartition.decEqA Bipartition.decEqB

/-- The subset of valid fermion states where occupation is 0 or 1. -/
def BasisState (I : Type) := { n : FermionState I // ValidFermionState n }

/-- Equivalence to finite target type to construct Fintype -/
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

instance basisStateFintype [Fintype I] [DecidableEq I] : Fintype (BasisState I) :=
  Fintype.ofEquiv (I → Fin 2) (basisEquivFin2 I).symm

/-- A quantum state in the Hilbert space is a linear combination of basis states. -/
def QuantumState (I : Type) := BasisState I → ℂ

/-- Join a fermion state across the bipartition. -/
def joinState {bp : Bipartition I} (nA : FermionState bp.A) (nB : FermionState bp.B) : FermionState I :=
  fun i => match bp.equiv i with
    | Sum.inl a => nA a
    | Sum.inr b => nB b

theorem valid_join {bp : Bipartition I} (nA : BasisState bp.A) (nB : BasisState bp.B) :
    ValidFermionState (joinState nA.val nB.val) := by
  intro i
  unfold joinState
  cases bp.equiv i
  · exact nA.property _
  · exact nB.property _

def joinBasisState {bp : Bipartition I} (nA : BasisState bp.A) (nB : BasisState bp.B) : BasisState I :=
  ⟨joinState nA.val nB.val, valid_join nA nB⟩

open scoped BigOperators

/-- The reduced density matrix ρ_A = Tr_B(|ψ⟩⟨ψ|) -/
noncomputable def ReducedDensityMatrix (bp : Bipartition I) (ψ : QuantumState I) :
    Matrix (BasisState bp.A) (BasisState bp.A) ℂ :=
  fun nA1 nA2 =>
    ∑ nB : BasisState bp.B, ψ (joinBasisState nA1 nB) * starRingEnd ℂ (ψ (joinBasisState nA2 nB))

/-- Purity γ = Tr(ρ_A^2) -/
noncomputable def Purity (bp : Bipartition I) (ψ : QuantumState I) : ℂ :=
  let ρA := ReducedDensityMatrix bp ψ
  Matrix.trace (ρA * ρA)

/-- Rényi-2 entropy S^{(2)}_A = -log(γ) -/
noncomputable def Renyi2Entropy (bp : Bipartition I) (ψ : QuantumState I) : ℝ :=
  - Real.log (Complex.re (Purity bp ψ))

end ManyBodyPhaseTransition
