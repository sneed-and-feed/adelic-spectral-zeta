import Mathlib.Analysis.Asymptotics.Asymptotics
import Formalization.FourierIsomorphism

open Real
open Asymptotics
open Filter

namespace SchreierSpectral

lemma chain_rayleigh_quotient_le (d : ℕ) :
    chain_rayleigh_quotient d ≤ 4 * Real.cos (Real.pi / (L_supp d + 1)) := by
  sorry

theorem chain_rayleigh_upper_bound_test (d : ℕ) (hd : d ≥ 4) :
    chain_rayleigh_quotient d < 4 := by
  have h1 := chain_rayleigh_quotient_le d
  have h2 : Real.cos (Real.pi / (L_supp d + 1)) < 1 := by sorry
  linarith

end SchreierSpectral
