import Formalization.CollatzSpectral

open Matrix
open CollatzSpectral

lemma collatz_spectral_decomposition {d : ℕ} (hd : d ≥ 3) :
    ∃ (S : Matrix (ZMod (2^(d-1))) (ZMod (2^(d-1))) ℚ) (S_inv : Matrix (ZMod (2^(d-1))) (ZMod (2^(d-1))) ℚ),
      S_inv * S = 1 ∧ S * S_inv = 1 ∧
      S_inv * (@adjacencyMatrix d) * S = 
        Matrix.reindex (sheetSplit hd).symm (sheetSplit hd).symm (A'_block_diag_target hd) := by
  let e := sheetSplit hd
  use Matrix.reindex e.symm e.symm conjBlock
  use Matrix.reindex e.symm e.symm conjBlockInv
  constructor
  · -- S_inv * S = 1
    sorry
  · constructor
    · -- S * S_inv = 1
      sorry
    · -- S_inv * A * S = block diag
      sorry
