import Formalization.CollatzSpectral

open Matrix
open CollatzSpectral
open Finset

lemma test_eq_sum {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    weighted_adj hd u v = weightedMatrix hd u v := by
  dsimp [weighted_adj, weightedMatrix, A'_matrix, adjacencyMatrix, Matrix.reindex]
  rw [sheetSplitInv_zero hd u, sheetSplitInv_zero hd v, sheetSplitInv_one hd v]
  sorry
