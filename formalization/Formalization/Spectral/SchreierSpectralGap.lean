import Mathlib.Data.Complex.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.LinearAlgebra.Eigenspace.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic
import Formalization.Dynamics.CollatzRelMatrix

open Matrix
open Complex
open CollatzDirMatrix

/--
Hypothesis stating that any eigenvalue of the twisted block has magnitude exactly 2^(1/2^{n-1}).
This uses the monomial character action and the cyclotomic product identity.
-/
structure TwistedBlockHypothesis (n : ℕ) : Prop where
  twisted_eigenvalue_magnitude : ∀ (hn : 3 ≤ n) (lambda : ℂ),
    Module.End.HasEigenvalue (Matrix.toLin' (Matrix.map (twistedDirMatrix (n := n) (by omega)) (algebraMap ℚ ℂ))) lambda →
    ‖lambda‖ = (2 : ℝ) ^ ((1 : ℝ) / (2^(n-1) : ℝ))

/--
Theorem: Any eigenvalue of the twisted block has magnitude exactly 2^(1/2^{n-1}),
conditional on the TwistedBlockHypothesis for level n.
-/
theorem twisted_eigenvalue_magnitude (n : ℕ) (h : TwistedBlockHypothesis n) (hn : 3 ≤ n) (lambda : ℂ) :
    Module.End.HasEigenvalue (Matrix.toLin' (Matrix.map (twistedDirMatrix (n := n) (by omega)) (algebraMap ℚ ℂ))) lambda →
    ‖lambda‖ = (2 : ℝ) ^ ((1 : ℝ) / (2^(n-1) : ℝ)) :=
  h.twisted_eigenvalue_magnitude hn lambda

/--
The Absolute Spectral Gap Conjecture:
For every n ≥ 3, any eigenvalue λ of the twisted directed Collatz block satisfies
‖λ‖ ≤ 2^(1/4) = ∜2 < 2, guaranteeing a strictly positive spectral gap.
-/
def AbsoluteSpectralGapConjecture : Prop :=
  ∀ (n : ℕ) (hn : 3 ≤ n) (lambda : ℂ),
    Module.End.HasEigenvalue (Matrix.toLin' (Matrix.map (twistedDirMatrix (n := n) (by omega)) (algebraMap ℚ ℂ))) lambda →
    ‖lambda‖ ≤ (2 : ℝ) ^ ((1 : ℝ) / 4)

/--
Conditional proof of the Absolute Spectral Gap bound:
Under TwistedBlockHypothesis n for n ≥ 3, every eigenvalue λ of the twisted block satisfies
‖λ‖ = 2^(1/2^{n-1}) ≤ 2^(1/4).
-/
theorem absolute_spectral_gap (n : ℕ) (h : TwistedBlockHypothesis n) (hn : 3 ≤ n) (lambda : ℂ)
    (heig : Module.End.HasEigenvalue (Matrix.toLin' (Matrix.map (twistedDirMatrix (n := n) (by omega)) (algebraMap ℚ ℂ))) lambda) :
    ‖lambda‖ ≤ (2 : ℝ) ^ ((1 : ℝ) / 4) := by
  have h_mag := h.twisted_eigenvalue_magnitude hn lambda heig
  rw [h_mag]
  apply Real.rpow_le_rpow_of_exponent_le (by norm_num)
  have hn_sub : (2 : ℝ) ≤ ((n - 1 : ℕ) : ℝ) := by
    have : 2 ≤ n - 1 := by omega
    exact Nat.cast_le.mpr this
  have h_pow_le : (4 : ℝ) ≤ (2^(n-1) : ℝ) := by
    have : (4 : ℕ) ≤ 2^(n - 1) := by
      calc (4 : ℕ) = 2^2 := by norm_num
      _ ≤ 2^(n - 1) := Nat.pow_le_pow_right (by decide) (by omega)
    exact_mod_cast this
  exact one_div_le_one_div_of_le (by positivity) h_pow_le

