import Mathlib
import Formalization.SchreierSpectral

open Classical
open Matrix
open SchreierSpectral

lemma double_edges_exist :
  ∃ (d : ℕ) (hd : d ≥ 3) (u v : ZMod (2^(d-2))),
    ((G_d d).Adj (canonicalLift u) (canonicalLift v) ∧ (G_d d).Adj (canonicalLift u) (tau (canonicalLift v))) := by
  use 4, (by decide), 0, 3
  constructor
  · refine ⟨by decide, Or.inr (Or.inr (Or.inr ?_))⟩
    rfl
  · refine ⟨by decide, Or.inr (Or.inl ?_)⟩
    rfl
