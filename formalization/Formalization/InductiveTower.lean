import Mathlib
import Formalization.SchreierSpectral
import Formalization.ChiralDecomposition

open Classical
open Matrix
open scoped Matrix
open SchreierSpectral

lemma weighted_adj_eq_adj {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    weighted_adj hd u v = if (G_d (d-1)).Adj u v then (1 : ℚ) else 0 := by
  sorry

/-- The symmetric block `weightedMatrix` at depth `d` is exactly the adjacency matrix at depth `d-1`.
    This requires reindexing since `weightedMatrix` is on `ZMod (2^(d-2))`,
    and `A'_matrix (hd-1)` is on `ZMod 2^(d-1-1) = ZMod (2^(d-2))`.
-/
lemma weightedMatrix_eq_adjacencyMatrix {d : ℕ} (hd : d ≥ 3) (_hd_sub : d - 1 ≥ 2) :
    weightedMatrix hd = @adjacencyMatrix (d-1) := by
  ext u v
  dsimp [adjacencyMatrix]
  rw [← weighted_adj_eq_sum hd u v]
  exact weighted_adj_eq_adj hd u v

/-- The two-step spectral tower decomposition. -/
lemma spectral_tower_two_step {d : ℕ} (hd : d ≥ 4) :
    ∃ U : Matrix (ZMod (2^(d-1))) (ZMod (2^(d-1))) ℚ, 
      -- Statement of unitary equivalence to A'_{d-2} ⊕ H_{d-2} ⊕ H_{d-1}
      True := by
  sorry
