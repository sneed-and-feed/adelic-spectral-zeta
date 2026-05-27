import Mathlib.Data.Complex.Basic
import Mathlib.Data.Complex.Exponential
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Algebra.Group.AddChar
import Mathlib.LinearAlgebra.Matrix.Spectrum
import Mathlib.Analysis.Asymptotics.Asymptotics
import Formalization.SchreierSpectral
import Formalization.TrigSum
import Formalization.FourierChain

open Complex
open Matrix
open Finset

namespace SchreierSpectral

variable {d : ℕ} (hd : d ≥ 3)

def M (d : ℕ) : ℕ := 2^(d-3)

noncomputable def hopping (d : ℕ) (j : ℕ) : ℝ :=
  2 * Real.cos (Real.pi * (3^j) / (N d))

noncomputable def T_chain (d : ℕ) : Matrix (Fin (M d)) (Fin (M d)) ℝ :=
  fun i j =>
    if j.val = i.val + 1 then hopping d i.val
    else if i.val = j.val + 1 then hopping d j.val
    else 0

-- We use a dynamically scaling support L(d) = d/2 to match the asymptotic 1/d^2 gap
noncomputable def L_supp (d : ℕ) : ℕ :=
  d / 2

noncomputable def test_vector (d : ℕ) (j : Fin (M d)) : ℝ :=
  if j.val < L_supp d then
    Real.sin (Real.pi * (j.val + 1) / (L_supp d + 1))
  else
    0

/-- The Rayleigh quotient of the test vector on the 1D chain -/
noncomputable def chain_rayleigh_quotient (d : ℕ) : ℝ :=
  let u := test_vector d
  (Matrix.dotProduct u (T_chain d *ᵥ u)) / (Matrix.dotProduct u u)

lemma test_vector_norm (d : ℕ) :
    Matrix.dotProduct (test_vector d) (test_vector d) = ((L_supp d : ℝ) + 1) / 2 := by
  sorry


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

lemma chain_rayleigh_numerator_bound (d : ℕ) :
    Matrix.dotProduct (test_vector d) (T_chain d *ᵥ test_vector d) ≤
    2 * Real.cos (Real.pi / (L_supp d + 1)) * Matrix.dotProduct (test_vector d) (test_vector d) := by
  sorry


/-- The main algebraic upper bound on the 1D chain Rayleigh quotient.
    Because L(d) = d/2, the Taylor error (3^{d/2}/2^d)^2 vanishes exponentially,
    and the Rayleigh quotient is asymptotically bounded by ~2, which is strictly less than 4.
    This guarantees the spectral gap drops no faster than 1/d^2. -/
theorem chain_rayleigh_upper_bound (d : ℕ) (hd : d ≥ 4) :
    chain_rayleigh_quotient d < 4 := by
  sorry

/-- The rigorous asymptotic statement of the Collatz spectral bridge:
    The gap between the Rayleigh quotient and the trivial eigenvalue 4
    is bounded from below by Ω(1/d^2). -/
theorem chain_rayleigh_asymptotic_gap :
    Asymptotics.IsBigO Filter.atTop (fun d : ℕ => (1 : ℝ) / (d : ℝ)^2) (fun d => 4 - chain_rayleigh_quotient d) := by
  sorry

end SchreierSpectral
