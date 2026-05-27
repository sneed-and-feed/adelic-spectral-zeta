import Mathlib.Data.Matrix.Basic
import Mathlib.LinearAlgebra.Matrix.Spectrum
import Formalization.SchreierSpectral
import Formalization.SchreierAntisymBound

open Matrix
open Classical

namespace SchreierSpectral

variable {d : ℕ} (hd : d ≥ 4)

def sym_lift (w : ZMod (2^(d-2)) → ℝ) : ZMod (2^(d-1)) → ℝ :=
  fun x => w (pi x)

noncomputable def const_vec (d : ℕ) : ZMod (2^(d-2)) → ℝ :=
  fun _ => 1

/-- Define the second eigenvalue of the symmetric block using the Min-Max theorem,
    as the maximum Rayleigh quotient over all vectors orthogonal to the constant vector. -/
noncomputable def sym_second_eigenvalue {d : ℕ} (hd : d ≥ 4) : ℝ :=
  sSup { (dotProduct (mulVec (realWeightedMatrix (by omega : d ≥ 3)) v) v) / (dotProduct v v) |
         (v : ZMod (2^(d-2)) → ℝ) (hv_ortho : dotProduct v (const_vec d) = 0) (hv_nz : v ≠ 0) }

/-- The second eigenvalue of the symmetric block is strictly dominated by the 
    energy of the Fourier test vector on the antisymmetric block. -/
def symmetric_gap_dominated_by_antisym_hypothesis (d : ℕ) (hd : d ≥ 7) : Prop :=
    sym_second_eigenvalue hd < chain_rayleigh_quotient d

/-- The final relative spectral gap unifying the bounds: 
    λ_{sym, 2} < λ_{anti, 1}. -/
theorem global_relative_gap (d : ℕ) (hd : d ≥ 7) 
    (h_dom : symmetric_gap_dominated_by_antisym_hypothesis d hd)
    (h_lower : max_antisym_eig_lower_bound_hypothesis d hd) :
    sym_second_eigenvalue hd < @max_antisym_eig d (by omega) := by
  calc sym_second_eigenvalue hd
    _ < chain_rayleigh_quotient d := h_dom
    _ ≤ @max_antisym_eig d (by omega) := h_lower

end SchreierSpectral
