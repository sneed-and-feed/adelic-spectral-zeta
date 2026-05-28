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

noncomputable def Z : FermionState I := fun _ => 0
lemma Z_valid : ValidFermionState (Z : FermionState I) := by intro i; left; rfl

noncomputable def Z_state : QuantumState I :=
  fun n => if n = ⟨Z, Z_valid⟩ then (1 : ℂ) else (0 : ℂ)

lemma join_Z_eq (nA : BasisState bp.A) (nB : BasisState bp.B) :
    joinBasisState nA nB = ⟨Z, Z_valid⟩ ↔ nA.val = (fun _ => 0) ∧ nB.val = (fun _ => 0) := by
  constructor
  · intro h
    have h_val := congr_arg Subtype.val h
    constructor
    · funext a
      have h_a := congr_fun h_val (bp.equiv.symm (Sum.inl a))
      unfold joinState Z at h_a
      rw [Equiv.apply_symm_apply] at h_a
      exact h_a
    · funext b
      have h_b := congr_fun h_val (bp.equiv.symm (Sum.inr b))
      unfold joinState Z at h_b
      rw [Equiv.apply_symm_apply] at h_b
      exact h_b
  · intro h
    rcases h with ⟨hA, hB⟩
    apply Subtype.ext
    funext i
    unfold joinBasisState joinState Z
    cases h_eq : bp.equiv i
    · rw [hA]; rfl
    · rw [hB]; rfl

lemma Z_state_eval (nA : BasisState bp.A) (nB : BasisState bp.B) :
    Z_state (joinBasisState nA nB) = if nA.val = (fun _ => 0) ∧ nB.val = (fun _ => 0) then (1 : ℂ) else (0 : ℂ) := by
  unfold Z_state
  split_ifs with h1 h2
  · rfl
  · rw [join_Z_eq] at h1
    contradiction
  · rw [join_Z_eq] at h2
    contradiction
  · rfl

lemma Z_reduced (nA1 nA2 : BasisState bp.A) :
    ReducedDensityMatrix bp Z_state nA1 nA2 = if nA1.val = (fun _ => 0) ∧ nA2.val = (fun _ => 0) then (1 : ℂ) else (0 : ℂ) := by
  unfold ReducedDensityMatrix
  simp only [Z_state_eval]
  have h0 : BasisState bp.B := ⟨fun _ => 0, fun _ => Or.inl rfl⟩
  rw [Finset.sum_eq_single h0]
  · split_ifs with h1 h2 h3
    · rw [starRingEnd_apply, star_one, mul_one]
    · rcases h1 with ⟨h1A, h1B⟩
      rcases h2 with ⟨h2A, h2B⟩
      rfl
    · rcases h1 with ⟨h1A, h1B⟩
      exact False.elim (h2 ⟨h1A, rfl⟩)
    · rfl
  · intro b _ hb
    have h_neq : ¬(b.val = fun _ => 0) := by
      intro h
      apply hb
      apply Subtype.ext
      exact h
    have hf : ¬(nA1.val = (fun _ => 0) ∧ b.val = (fun _ => 0)) := fun h => h_neq h.2
    rw [if_neg hf, zero_mul]
  · intro hb
    exfalso
    exact hb (Finset.mem_univ _)

lemma Z_purity : Purity bp Z_state = 1 := by
  unfold Purity Matrix.trace Matrix.diag
  simp only [Z_reduced]
  have h0 : BasisState bp.A := ⟨fun _ => 0, fun _ => Or.inl rfl⟩
  rw [Finset.sum_eq_single h0]
  · change ∑ a2 : BasisState bp.A, (if h0.val = (fun _ => 0) ∧ a2.val = (fun _ => 0) then (1 : ℂ) else (0 : ℂ)) * (if a2.val = (fun _ => 0) ∧ h0.val = (fun _ => 0) then (1 : ℂ) else (0 : ℂ)) = 1
    rw [Finset.sum_eq_single h0]
    · split_ifs
      · exact mul_one 1
      · rfl
    · intro a2 _ ha2
      have h_neq : ¬(a2.val = fun _ => 0) := by
        intro h
        apply ha2
        apply Subtype.ext
        exact h
      have hf : ¬(h0.val = (fun _ => 0) ∧ a2.val = (fun _ => 0)) := fun h => h_neq h.2
      rw [if_neg hf, mul_zero]
    · intro ha
      exfalso
      exact ha (Finset.mem_univ _)
  · intro a _ ha
    change ∑ a2 : BasisState bp.A, (if a.val = (fun _ => 0) ∧ a2.val = (fun _ => 0) then (1 : ℂ) else (0 : ℂ)) * (if a2.val = (fun _ => 0) ∧ a.val = (fun _ => 0) then (1 : ℂ) else (0 : ℂ)) = 0
    have h_neq : ¬(a.val = fun _ => 0) := by
      intro h
      apply ha
      apply Subtype.ext
      exact h
    have : ∀ k : BasisState bp.A, (if a.val = (fun _ => 0) ∧ k.val = (fun _ => 0) then (1 : ℂ) else (0 : ℂ)) * 
               (if k.val = (fun _ => 0) ∧ a.val = (fun _ => 0) then (1 : ℂ) else (0 : ℂ)) = 0 := by
      intro k
      have hf : ¬(a.val = (fun _ => 0) ∧ k.val = (fun _ => 0)) := fun h => h_neq h.1
      rw [if_neg hf, zero_mul]
    rw [Finset.sum_congr rfl (fun k _ => this k)]
    exact Finset.sum_const_zero
  · intro ha
    exfalso
    exact ha (Finset.mem_univ _)

end ManyBodyPhaseTransition
