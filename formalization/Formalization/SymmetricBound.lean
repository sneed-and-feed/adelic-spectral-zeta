import Mathlib.Data.Matrix.Basic
import Mathlib.LinearAlgebra.Matrix.Spectrum
import Formalization.SchreierSpectral

open Matrix
open Classical

namespace SchreierSpectral

variable {d : ℕ} (hd : d ≥ 4)

-- We will define the symmetric lift and prove it maps to the previous depth
-- and preserves eigenvalues!

def sym_lift (w : ZMod (2^(d-2)) → ℝ) : ZMod (2^(d-1)) → ℝ :=
  fun x => w (pi x)

open Classical in
/-- The symmetric block of G_d is EXACTLY the adjacency matrix of G_{d-1}. -/
theorem symmetric_block_eq_prev_adj (u v : ZMod (2^(d-2))) :
    weightedMatrix hd u v = @adjacencyMatrix (d-1) u v := by
  sorry


end SchreierSpectral
