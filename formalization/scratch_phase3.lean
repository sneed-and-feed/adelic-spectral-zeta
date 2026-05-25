import Formalization.CollatzSpectral

open Matrix
open CollatzSpectral
open Finset

lemma weighted_adj_bounds {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    weighted_adj hd u v ≤ 2 := by
  rw [weighted_adj_eq_sum hd u v]
  dsimp [weightedMatrix, A'_matrix, adjacencyMatrix]
  -- A'_matrix is Matrix.reindex
  sorry
