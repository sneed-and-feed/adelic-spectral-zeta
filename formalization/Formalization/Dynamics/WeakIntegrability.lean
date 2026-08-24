import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Finset.Basic

open Classical

/-- Spin-1/2 state representation on a 1D lattice -/
def SpinState (I : Type) [DecidableEq I] := I → ℝ

/-- The Parity String Operator product for a subsystem J ⊆ I -/
noncomputable def ParityString {I : Type} [DecidableEq I] (J : Finset I) (s : SpinState I) : ℝ :=
  J.prod (fun j => s j)

/-- Definition of Algebraic Decay (Integrable behavior) -/
def IsAlgebraicDecay (f : ℝ → ℝ) : Prop :=
  ∃ (C α : ℝ), α > 0 ∧ ∀ t ≥ 1, |f t| ≤ C * t^(-α)

/-- Definition of Exponential Decay (Integrability broken behavior) -/
def IsExponentialDecay (f : ℝ → ℝ) : Prop :=
  ∃ (C γ : ℝ), γ > 0 ∧ ∀ t ≥ 1, |f t| ≤ C * Real.exp (-γ * t)

/-- Core Theorem Statement: Integrability breaking shifts string correlation from algebraic to exponential decay -/
theorem integrability_breaking_decay_shift {I : Type} [DecidableEq I] (J : Finset I) 
    (f_int f_broken : ℝ → ℝ) (h_int : IsAlgebraicDecay f_int) (γ : ℝ) (hγ : γ > 0)
    (hJ : J.card > 0)
    (h_link : ∀ t ≥ 1, f_broken t = f_int t * Real.exp (-γ * J.card * t)) :
    IsExponentialDecay f_broken := by
  rcases h_int with ⟨C, α, hα, h_bound⟩
  use C, γ * J.card
  refine ⟨?_, ?_⟩
  · apply mul_pos hγ
    exact Nat.cast_pos.mpr hJ
  · intro t ht
    rw [h_link t ht]
    have h1 : |f_int t * Real.exp (-γ * ↑J.card * t)| = |f_int t| * |Real.exp (-γ * ↑J.card * t)| := abs_mul _ _
    rw [h1]
    have h2 : |Real.exp (-γ * ↑J.card * t)| = Real.exp (-γ * ↑J.card * t) := abs_of_pos (Real.exp_pos _)
    rw [h2]
    have h3 : |f_int t| ≤ C * t^(-α) := h_bound t ht
    have h4 : |f_int t| * Real.exp (-γ * ↑J.card * t) ≤ C * t^(-α) * Real.exp (-γ * ↑J.card * t) := mul_le_mul_of_nonneg_right h3 (le_of_lt (Real.exp_pos _))
    apply le_trans h4
    have hC_nonneg : 0 ≤ C := by
      have ht1 : (1:ℝ) ≥ 1 := le_refl 1
      have h_b1 := h_bound 1 ht1
      have h_pow1 : (1:ℝ)^(-α) = 1 := Real.one_rpow _
      rw [h_pow1] at h_b1
      have h_abs1 : 0 ≤ |f_int 1| := abs_nonneg _
      linarith
    have ht_pow : t^(-α) ≤ 1 := by
      apply Real.rpow_le_one_of_one_le_of_nonpos
      · exact ht
      · linarith
    have h_mul : C * t^(-α) ≤ C * 1 := mul_le_mul_of_nonneg_left ht_pow hC_nonneg
    rw [mul_one] at h_mul
    have h_final : C * t^(-α) * Real.exp (-γ * ↑J.card * t) ≤ C * Real.exp (-γ * ↑J.card * t) := mul_le_mul_of_nonneg_right h_mul (le_of_lt (Real.exp_pos _))
    have h_eq : -(γ * ↑J.card) * t = -γ * ↑J.card * t := by ring
    rw [h_eq]
    exact h_final
