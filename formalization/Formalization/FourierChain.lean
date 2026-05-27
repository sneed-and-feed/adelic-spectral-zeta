import Mathlib.Data.Real.Basic
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Complex.Exponential
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Formalization.SchreierSpectral

open Real

namespace SchreierSpectral

variable {d : ℕ} (hd : d ≥ 3)

def N (d : ℕ) : ℕ := 2^(d-1)

/-- The discrete Fourier modes using real sine and cosine -/
def fourier_cos (k : ℕ) (x : ZMod (2^(d-1))) : ℝ :=
  Real.cos (2 * Real.pi * k * x.val / (2^(d-1)))

def fourier_sin (k : ℕ) (x : ZMod (2^(d-1))) : ℝ :=
  Real.sin (2 * Real.pi * k * x.val / (2^(d-1)))

end SchreierSpectral
