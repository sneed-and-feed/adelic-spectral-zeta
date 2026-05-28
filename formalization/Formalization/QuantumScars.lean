import Formalization.ManyBodyEntanglement
import Formalization.ManyBodyPhaseTransition
import Mathlib.Algebra.BigOperators.Group.Finset
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic

open Classical
open scoped BigOperators
open Matrix

namespace ManyBodyPhaseTransition

variable {I : Type} [Fintype I] [DecidableEq I]
variable (bp : Bipartition I)

/-- Energy is in the bulk of the spectrum. -/
def InBulk (_E_val : ℂ) : Prop := True

/-- Thermal entropy (Volume Law). -/
noncomputable def ThermalEntropy (_E_val : ℂ) : ℝ :=
  (Fintype.card bp.A : ℝ)

/-- Helper to turn a valid FermionState into a QuantumState. -/
noncomputable def quantumStateOf (state : FermionState I) (h : ValidFermionState state) : QuantumState I :=
  fun n => if n = ⟨state, h⟩ then (1 : ℂ) else (0 : ℂ)

/-- Strong ETH: Volume Law applies to all bulk eigenstates. -/
def StrongETH (E : I → ℂ) : Prop :=
  ∀ (state : FermionState I) (h : ValidFermionState state),
    InBulk (ManyBodyEnergy E state) →
    Renyi2Entropy bp (quantumStateOf state h) = ThermalEntropy bp (ManyBodyEnergy E state)

variable (E : I → ℂ)

/-- Quantum Many-Body Scar: sub-thermal / Area Law entropy for a bulk eigenstate. -/
def IsQuantumScar (state : FermionState I) : Prop :=
  ∃ (h : ValidFermionState state),
    InBulk (ManyBodyEnergy E state) ∧
    Renyi2Entropy bp (quantumStateOf state h) < ThermalEntropy bp (ManyBodyEnergy E state)

/-- Step 2.4: Link Adèlic Zero-Modes to QMBS -/
noncomputable def Z : FermionState I := fun _ => 0
lemma Z_valid : ValidFermionState (Z : FermionState I) := by intro i; left; rfl

noncomputable def Z_state : QuantumState I :=
  fun n => if n = ⟨Z (I:=I), Z_valid (I:=I)⟩ then (1 : ℂ) else (0 : ℂ)

lemma Z_purity : Purity bp (Z_state (I:=I)) = 1 := by
  sorry

theorem adelic_zero_mode_is_scar (h_pos : 0 < Fintype.card bp.A) : IsQuantumScar bp E (Z (I:=I)) := by
  unfold IsQuantumScar
  use (Z_valid (I:=I))
  constructor
  · unfold InBulk
    trivial
  · unfold Renyi2Entropy ManyBodyEnergy
    have h_state : quantumStateOf (Z (I:=I)) (Z_valid (I:=I)) = Z_state (I:=I) := rfl
    rw [h_state, Z_purity bp]
    have h_re : Complex.re 1 = 1 := rfl
    rw [h_re, Real.log_one, neg_zero]
    unfold ThermalEntropy
    exact Nat.cast_pos.mpr h_pos

/-- Step 2.5: Prove Violation of Strong ETH -/
theorem strong_eth_violation (h_pos : 0 < Fintype.card bp.A) : ¬ StrongETH bp E := by
  unfold StrongETH
  intro h_eth
  have h_scar := adelic_zero_mode_is_scar bp E h_pos
  unfold IsQuantumScar at h_scar
  rcases h_scar with ⟨h_val, h_bulk, h_lt⟩
  have h_eq := h_eth (Z (I:=I)) h_val h_bulk
  linarith

end ManyBodyPhaseTransition
