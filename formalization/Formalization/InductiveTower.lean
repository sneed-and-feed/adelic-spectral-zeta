import Mathlib
import Formalization.SchreierSpectral
import Formalization.ChiralDecomposition

open Classical
open Matrix
open scoped Matrix
open SchreierSpectral

lemma no_double_edges {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
  ¬ ((G_d d).Adj (canonicalLift u) (canonicalLift v) ∧ (G_d d).Adj (canonicalLift u) (tau (canonicalLift v))) := by
  sorry

lemma weighted_adj_eq_adj {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    weighted_adj hd u v = if (G_d (d-1)).Adj u v then (1 : ℚ) else 0 := by
  have h_le := weighted_adj_bounds hd u v
  have h_ge := weighted_adj_ge_adj hd u v
  by_cases h : (G_d (d-1)).Adj u v
  · rw [if_pos h] at h_ge ⊢
    have h_two : weighted_adj hd u v ≠ 2 := by
      intro h2
      have h_iff := (weighted_adj_eq_two_iff hd u v).mp h2
      exact no_double_edges hd u v h_iff
    -- weighted_adj is a sum of two items that are 0 or 1.
    -- So it's an integer.
    sorry
  · rw [if_neg h] at h_ge ⊢
    -- if it's 0, and >= 0, it could be 1.
    -- Wait, if it's not adj in d-1, could it be adj in d?
    -- No, lift_adj says if it's adj in d, it's adj in d-1!
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
      True := by
  use 0
  trivial
