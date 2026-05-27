import Mathlib.Data.Complex.Basic
import Mathlib.Data.Complex.Exponential
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Algebra.Group.AddChar
import Mathlib.LinearAlgebra.Matrix.Spectrum
import Formalization.SchreierSpectral

open Complex
open Matrix

namespace SchreierSpectral

variable {d : ℕ} (hd : d ≥ 3)

def N (d : ℕ) : ℕ := 2^(d-1)

def M (d : ℕ) : ℕ := 2^(d-3)

noncomputable def hopping (d : ℕ) (j : ℕ) : ℝ :=
  2 * Real.cos (Real.pi * (3^j) / (N d))

noncomputable def T_chain (d : ℕ) : Matrix (Fin (M d)) (Fin (M d)) ℝ :=
  fun i j =>
    if j.val = i.val + 1 then hopping d i.val
    else if i.val = j.val + 1 then hopping d j.val
    else 0

-- We use a localized support L(d) <= M(d)
noncomputable def L_supp (d : ℕ) : ℕ :=
  if d < 7 then 0 else 5 -- Found via Python search

noncomputable def test_vector (d : ℕ) (j : Fin (M d)) : ℝ :=
  if j.val < L_supp d then
    Real.sin (Real.pi * (j.val + 1) / (L_supp d + 1))
  else
    0

/-- The Rayleigh quotient of the test vector on the 1D chain -/
noncomputable def chain_rayleigh_quotient (d : ℕ) : ℝ :=
  let u := test_vector d
  (Matrix.dotProduct u (T_chain d *ᵥ u)) / (Matrix.dotProduct u u)

/-- The Taylor bound for the hopping amplitudes: W_j >= 2 - (pi * 3^j / N)^2 -/
lemma hopping_taylor_bound (d : ℕ) (hd : d ≥ 3) (j : ℕ) :
    hopping d j ≥ 2 - (Real.pi * (3^j) / (N d))^2 := by
  unfold hopping
  have h_cos : 1 - (Real.pi * (3^j) / (N d))^2 / 2 ≤ Real.cos (Real.pi * (3^j) / (N d)) := 
    Real.one_sub_sq_div_two_le_cos
  linarith

/-- Product-to-sum simplification for the Rayleigh Quotient numerator -/
lemma sum_sin_mul_sin (L : ℕ) (j : ℕ) :
  2 * Real.sin (Real.pi * (j + 1) / (L + 1)) * Real.sin (Real.pi * (j + 2) / (L + 1)) =
  Real.cos (Real.pi / (L + 1)) - Real.cos (Real.pi * (2 * j + 3) / (L + 1)) := by
  have h := Real.cos_sub_cos (Real.pi / (L + 1)) (Real.pi * (2 * j + 3) / (L + 1))
  have h1 : (Real.pi / (L + 1) + Real.pi * (2 * j + 3) / (L + 1)) / 2 = Real.pi * (j + 2) / (L + 1) := by ring
  have h2 : (Real.pi / (L + 1) - Real.pi * (2 * j + 3) / (L + 1)) / 2 = -(Real.pi * (j + 1) / (L + 1)) := by ring
  rw [h1, h2] at h
  rw [Real.sin_neg] at h
  linarith

/-- The main algebraic lower bound on the 1D chain Rayleigh quotient.
    (This will be bounded below by the known algebraic expression for the previous depth's spectral gap) -/
theorem chain_rayleigh_lower_bound (d : ℕ) (hd : d ≥ 4) :
    chain_rayleigh_quotient d > 0 := by
  sorry

end SchreierSpectral
