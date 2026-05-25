import Formalization.CollatzSpectral

open Matrix CollatzSpectral

open Classical in
lemma test_weighted_adj_ge_adj {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    weighted_adj hd u v ≥ if (G_d (d-1)).Adj u v then 1 else 0 := by
  rw [weighted_adj_eq_sum hd]
  dsimp [weightedMatrix, A'_matrix, adjacencyMatrix, Matrix.reindex, Equiv.refl]
  rw [sheetSplitInv_zero hd u, sheetSplitInv_zero hd v, sheetSplitInv_one hd v]
  split_ifs with h
  · -- we have (G_d (d-1)).Adj u v. we need to show at least one is 1.
    -- meaning either (canonicalLift u) ~ (canonicalLift v) or (canonicalLift u) ~ tau (canonicalLift v)
    sorry
  · -- it's 0, so it's trivial
    norm_num
