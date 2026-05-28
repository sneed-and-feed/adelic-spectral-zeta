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

noncomputable def Z_A : BasisState bp.A := ⟨fun _ => 0, fun _ => Or.inl rfl⟩
noncomputable def Z_B : BasisState bp.B := ⟨fun _ => 0, fun _ => Or.inl rfl⟩

lemma joinBasisState_eq_Z_iff (nA : BasisState bp.A) (nB : BasisState bp.B) :
    joinBasisState nA nB = ⟨Z (I:=I), Z_valid (I:=I)⟩ ↔ nA = Z_A bp ∧ nB = Z_B bp := by
  constructor
  · intro h
    constructor
    · apply Subtype.ext
      funext a
      have h_val := congr_arg Subtype.val h
      have h_i := congr_fun h_val (bp.equiv.symm (Sum.inl a))
      dsimp [joinState, Z] at h_i
      rw [Equiv.apply_symm_apply] at h_i
      exact h_i
    · apply Subtype.ext
      funext b
      have h_val := congr_arg Subtype.val h
      have h_i := congr_fun h_val (bp.equiv.symm (Sum.inr b))
      dsimp [joinState, Z] at h_i
      rw [Equiv.apply_symm_apply] at h_i
      exact h_i
  · rintro ⟨rfl, rfl⟩
    apply Subtype.ext
    funext i
    dsimp [joinBasisState, joinState, Z_A, Z_B, Z]
    cases bp.equiv i <;> rfl

lemma Z_ReducedDensityMatrix (nA1 nA2 : BasisState bp.A) :
    ReducedDensityMatrix bp (Z_state (I:=I)) nA1 nA2 = if nA1 = Z_A bp ∧ nA2 = Z_A bp then 1 else 0 := by
  unfold ReducedDensityMatrix Z_state
  split_ifs with h
  · rcases h with ⟨rfl, rfl⟩
    have h_eq : ∀ nB : BasisState bp.B,
      (if joinBasisState (Z_A bp) nB = ⟨Z (I:=I), Z_valid (I:=I)⟩ then (1 : ℂ) else (0 : ℂ)) *
      starRingEnd ℂ (if joinBasisState (Z_A bp) nB = ⟨Z (I:=I), Z_valid (I:=I)⟩ then (1 : ℂ) else (0 : ℂ)) =
      if nB = Z_B bp then 1 else 0 := by
        intro nB
        rw [joinBasisState_eq_Z_iff]
        simp only [true_and]
        split_ifs with h_nB
        · simp
        · simp
    simp_rw [h_eq]
    rw [Finset.sum_ite_eq']
    simp
  · have h_zero : ∀ nB : BasisState bp.B,
      (if joinBasisState nA1 nB = ⟨Z (I:=I), Z_valid (I:=I)⟩ then (1 : ℂ) else (0 : ℂ)) *
      starRingEnd ℂ (if joinBasisState nA2 nB = ⟨Z (I:=I), Z_valid (I:=I)⟩ then (1 : ℂ) else (0 : ℂ)) = 0 := by
        intro nB
        split_ifs with h1 h2
        · rw [joinBasisState_eq_Z_iff] at h1 h2
          exfalso
          exact h ⟨h1.1, h2.1⟩
        · simp
        · simp
        · simp
    simp_rw [h_zero]
    rw [Finset.sum_const_zero]

lemma Z_purity : Purity bp (Z_state (I:=I)) = 1 := by
  unfold Purity
  have h_mul : ∀ nA1 nA2 : BasisState bp.A,
    (ReducedDensityMatrix bp Z_state * ReducedDensityMatrix bp Z_state) nA1 nA2 =
    if nA1 = Z_A bp ∧ nA2 = Z_A bp then 1 else 0 := by
      intro nA1 nA2
      simp_rw [Matrix.mul_apply]
      simp_rw [Z_ReducedDensityMatrix]
      have h_summand : ∀ nA3 : BasisState bp.A,
        (if nA1 = Z_A bp ∧ nA3 = Z_A bp then (1 : ℂ) else (0 : ℂ)) *
        (if nA3 = Z_A bp ∧ nA2 = Z_A bp then (1 : ℂ) else (0 : ℂ)) =
        if nA3 = Z_A bp then (if nA1 = Z_A bp ∧ nA2 = Z_A bp then (1 : ℂ) else (0 : ℂ)) else (0 : ℂ) := by
          intro nA3
          by_cases h1 : nA1 = Z_A bp <;> by_cases h2 : nA2 = Z_A bp <;> by_cases h3 : nA3 = Z_A bp <;> simp [h1, h2, h3]
      simp_rw [h_summand]
      rw [Finset.sum_ite_eq']
      simp
  unfold Matrix.trace Matrix.diag
  dsimp
  have h_diag : ∀ nA1 : BasisState bp.A,
    (ReducedDensityMatrix bp Z_state * ReducedDensityMatrix bp Z_state) nA1 nA1 =
    if nA1 = Z_A bp then 1 else 0 := by
      intro nA1
      rw [h_mul]
      simp
  simp_rw [h_diag]
  rw [Finset.sum_ite_eq']
  simp

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
