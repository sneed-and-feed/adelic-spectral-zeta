import Mathlib.Analysis.Asymptotics.Asymptotics
import Formalization.FourierIsomorphism

open Real
open Asymptotics
open Filter

namespace SchreierSpectral

lemma chain_rayleigh_quotient_le (d : ℕ) :
    chain_rayleigh_quotient d ≤ 2 * Real.cos (Real.pi / (L_supp d + 1)) := by
  unfold chain_rayleigh_quotient
  have h_num := chain_rayleigh_numerator_bound d
  have h_denom := test_vector_norm d
  have h_denom_pos : Matrix.dotProduct (test_vector d) (test_vector d) > 0 := by
    rw [h_denom]
    have h1 : (L_supp d : ℝ) ≥ 0 := Nat.cast_nonneg (L_supp d)
    linarith
  exact (div_le_iff₀ h_denom_pos).mpr h_num

end SchreierSpectral
