import Formalization.Quantum.ManyBodyEntanglement
import Formalization.Quantum.ManyBodyPhaseTransition
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic

/-!
# Entanglement Entropy of Pure Product States and Toy Model of ETH

This module formalizes the entanglement properties of the pure product state
$Z = |0\dots 0\rangle$ across a spatial bipartition $I \simeq A \oplus B$.

## Mathematical Content
- **Pure Product State**: The all-zero occupation configuration $Z = \mathbf{0}$ represents
  the unentangled product state $|0\dots 0\rangle$.
- **Reduced Density Matrix & Purity**: The bipartite reduced density matrix
  $\rho_A = \mathrm{Tr}_B(|Z\rangle\langle Z|)$ is a rank-1 projection onto the local zero
  state $Z_A$, with purity $\gamma = \mathrm{Tr}(\rho_A^2) = 1$.
- **Rényi-2 Entanglement Entropy**: $S_A^{(2)}(Z) = -\ln(\mathrm{Tr}(\rho_A^2)) = -\ln 1 = 0$.
- **Toy Model of ETH & Sub-Thermal Entropy**: In a simplified finite-dimensional toy model
  where maximal thermal volume-law entropy is defined as $|A|$ and every energy level is
  treated as in the spectral bulk (`InBulk _ := True`), the zero-entropy state $Z$ satisfies
  $S_A^{(2)}(Z) = 0 < |A|$ whenever $|A| > 0$. This provides a concrete toy illustration
  of sub-thermal entanglement entropy (analogous to quantum many-body scars / failure of
  uniform volume-law ETH in such toy models).
-/

open Classical
open scoped BigOperators
open Matrix

namespace ManyBodyPhaseTransition

section QuantumScars

variable {I : Type} [Fintype I] [DecidableEq I]
variable (bp : Bipartition I)

/-- In this simplified toy model of eigenstate thermalization, all energy levels
are trivially considered to lie in the spectral bulk. -/
def InBulk (_ : ℂ) : Prop := True

/-- Maximal / thermal subsystem entropy in the toy model (volume-law scaling
proportional to subsystem size $|A|$). -/
noncomputable def ThermalEntropy (_ : ℂ) : ℝ :=
  (Fintype.card bp.A : ℝ)

/-- Helper to turn a valid `FermionState` into a single-basis-state `QuantumState`. -/
noncomputable def quantumStateOf (state : FermionState I) (h : ValidFermionState state) : QuantumState I :=
  fun n => if n = ⟨state, h⟩ then (1 : ℂ) else (0 : ℂ)

/-- Toy Model Strong ETH: all bulk eigenstates are required to exhibit maximal
thermal volume-law entanglement entropy $|A|$. -/
def StrongETH (E : I → ℂ) : Prop :=
  ∀ (state : FermionState I) (h : ValidFermionState state),
    InBulk (ManyBodyEnergy E state) →
    Renyi2Entropy bp (quantumStateOf state h) = ThermalEntropy bp (ManyBodyEnergy E state)

variable (E : I → ℂ)

/-- Sub-thermal / Area-Law entanglement entropy for an eigenstate in the toy model
(analogous to a quantum many-body scar state). -/
def IsQuantumScar (state : FermionState I) : Prop :=
  ∃ (h : ValidFermionState state),
    InBulk (ManyBodyEnergy E state) ∧
    Renyi2Entropy bp (quantumStateOf state h) < ThermalEntropy bp (ManyBodyEnergy E state)

/-- The unentangled all-zero product state $Z = |0\dots 0\rangle$. -/
noncomputable def Z : FermionState I := fun _ => 0

set_option linter.unusedSectionVars false in
/-- The all-zero state is a valid fermionic occupation state (all occupations are 0). -/
lemma Z_valid : ValidFermionState (Z : FermionState I) := by intro i; left; rfl

/-- The quantum state representation of the all-zero product state $|Z\rangle$. -/
noncomputable def Z_state : QuantumState I :=
  fun n => if n = ⟨Z (I:=I), Z_valid (I:=I)⟩ then (1 : ℂ) else (0 : ℂ)

/-- The restriction of the all-zero state to subsystem $A$. -/
noncomputable def Z_A : BasisState bp.A := ⟨fun _ => 0, fun _ => Or.inl rfl⟩

/-- The restriction of the all-zero state to subsystem $B$. -/
noncomputable def Z_B : BasisState bp.B := ⟨fun _ => 0, fun _ => Or.inl rfl⟩

/-- A joined basis state `nA ⊕ nB` equals the all-zero state $Z$ if and only if
both `nA` and `nB` are the local all-zero states $Z_A$ and $Z_B$. -/
lemma joinBasisState_eq_Z_iff (nA : BasisState bp.A) (nB : BasisState bp.B) :
    joinBasisState nA nB = ⟨Z (I:=I), Z_valid (I:=I)⟩ ↔ nA = Z_A bp ∧ nB = Z_B bp := by
  constructor
  · intro h
    constructor
    · apply Subtype.ext
      funext a
      have h_val : (joinBasisState nA nB).val = (⟨Z, Z_valid⟩ : BasisState I).val := congr_arg Subtype.val h
      change joinState nA.val nB.val = Z at h_val
      have h_i := congr_fun h_val (bp.equiv.symm (Sum.inl a))
      dsimp [joinState, Z] at h_i
      rw [Equiv.apply_symm_apply] at h_i
      exact h_i
    · apply Subtype.ext
      funext b
      have h_val : (joinBasisState nA nB).val = (⟨Z, Z_valid⟩ : BasisState I).val := congr_arg Subtype.val h
      change joinState nA.val nB.val = Z at h_val
      have h_i := congr_fun h_val (bp.equiv.symm (Sum.inr b))
      dsimp [joinState, Z] at h_i
      rw [Equiv.apply_symm_apply] at h_i
      exact h_i
  · rintro ⟨rfl, rfl⟩
    apply Subtype.ext
    funext i
    dsimp [joinBasisState, joinState, Z_A, Z_B, Z]
    cases bp.equiv i <;> rfl

/-- The reduced density matrix $\rho_A = \mathrm{Tr}_B(|Z\rangle\langle Z|)$ is the
rank-1 projection $|Z_A\rangle\langle Z_A|$. -/
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

/-- The purity $\gamma = \mathrm{Tr}(\rho_A^2)$ of the reduced density matrix of the
pure product state $|Z\rangle$ is identically 1. -/
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

/-- The pure product state $Z = |0\dots 0\rangle$ has Rényi-2 entanglement entropy
$-\ln 1 = 0$, which is strictly less than the maximal thermal entropy $|A|$ whenever
$|A| > 0$, thereby satisfying the toy sub-thermal / scar condition. -/
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

/-- In the toy ETH formulation, Strong ETH fails because the unentangled state $Z = |0\dots 0\rangle$
has zero entanglement entropy, contradicting the requirement that all bulk states have
maximal thermal entropy $|A| > 0$. -/
theorem strong_eth_violation (h_pos : 0 < Fintype.card bp.A) : ¬ StrongETH bp E := by
  unfold StrongETH
  intro h_eth
  have h_scar := adelic_zero_mode_is_scar bp E h_pos
  unfold IsQuantumScar at h_scar
  rcases h_scar with ⟨h_val, h_bulk, h_lt⟩
  have h_eq := h_eth (Z (I:=I)) h_val h_bulk
  linarith

end QuantumScars

end ManyBodyPhaseTransition
