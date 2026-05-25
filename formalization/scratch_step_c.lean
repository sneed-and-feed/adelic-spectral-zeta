import Mathlib.Data.Matrix.Basic
import Formalization.CollatzConnectivity
import Formalization.CollatzSpectral

open Matrix
open CollatzSpectral

lemma adj_tau_iff {d : ℕ} (hd : d ≥ 3) (x y : ZMod (2^(d-1))) :
    (G_d d).Adj (tau x) y ↔ (G_d d).Adj x (tau y) := by
  constructor
  · intro h
    have h1 := tau_is_hom hd h
    rw [tau_tau hd x] at h1
    exact h1
  · intro h
    have h1 := tau_is_hom hd h
    rw [tau_tau hd y] at h1
    exact h1

open Classical in
lemma tau_adjacency_commute {d : ℕ} (hd : d ≥ 3) :
    (@tauMatrix d : Matrix (ZMod (2^(d-1))) (ZMod (2^(d-1))) ℚ) * (@adjacencyMatrix d) = (@adjacencyMatrix d) * (@tauMatrix d) := by
  sorry
