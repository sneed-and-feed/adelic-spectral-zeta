import Mathlib
import Formalization.SchreierSpectral
open Matrix SchreierSpectral

lemma weightedMatrix_eq_adjacencyMatrix {d : ℕ} (hd : d ≥ 3) (hd_sub : d - 1 ≥ 2) : weightedMatrix hd = @adjacencyMatrix (d-1) := by
  ext u v
  sorry

