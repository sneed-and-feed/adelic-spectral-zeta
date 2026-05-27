import Mathlib.Analysis.Asymptotics.Asymptotics
import Formalization.FourierIsomorphism

open Real
open Asymptotics
open Filter
open Matrix

namespace SchreierSpectral

theorem chain_rayleigh_upper_bound_test (d : ℕ) (hd : d ≥ 4) :
    chain_rayleigh_quotient d < 4 := by
  unfold chain_rayleigh_quotient
  have h_num := chain_rayleigh_numerator_bound d
  have h_denom := test_vector_norm d
  have h_denom_pos : 0 < Matrix.dotProduct (test_vector d) (test_vector d) := by
    rw [h_denom]
    have hd_pos : (L_supp d : ℝ) ≥ 0 := Nat.cast_nonneg (L_supp d)
    linarith
  have h_div : Matrix.dotProduct (test_vector d) (T_chain d *ᵥ test_vector d) / Matrix.dotProduct (test_vector d) (test_vector d) ≤ 2 * Real.cos (Real.pi / (L_supp d + 1)) := by
    rw [div_le_iff₀ h_denom_pos]
    exact h_num
  have h_cos : Real.cos (Real.pi / (L_supp d + 1)) ≤ 1 := Real.cos_le_one _
  linarith

end SchreierSpectral

