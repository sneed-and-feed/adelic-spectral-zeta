import Mathlib
import Formalization.SchreierSpectral
import Formalization.ChiralDecomposition

open Classical
open Matrix
open scoped Matrix
open SchreierSpectral

/-- The original strategy assumed no double edges between lifted sheets.
    This disproof shows that double edges DO exist in the Schreier graphs,
    which prevents the continuous transfer operator from block diagonalizing cleanly. -/
lemma double_edges_exist :
  ∃ (d : ℕ) (hd : d ≥ 3) (u v : ZMod (2^(d-2))),
    ((G_d d).Adj (canonicalLift u) (canonicalLift v) ∧ (G_d d).Adj (canonicalLift u) (tau (canonicalLift v))) := by
  use 4, (by decide), 0, 3
  constructor
  · refine ⟨by decide, Or.inr (Or.inr (Or.inr ?_))⟩
    rfl
  · refine ⟨by decide, Or.inr (Or.inl ?_)⟩
    rfl

/-- Consequently, the weighted adjacency matrix at depth `d` does NOT equal the 
    adjacency matrix at depth `d-1`. -/
lemma weighted_adj_neq_adj :
  ¬ (∀ {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))),
    weighted_adj hd u v = if (G_d (d-1)).Adj u v then (1 : ℚ) else 0) := by
  intro h
  have h_eval := h (by decide : 4 ≥ 3) 0 3
  have h_adj : (G_d 3).Adj 0 3 := by
    refine ⟨by decide, Or.inr (Or.inr (Or.inr ?_))⟩
    rfl
  rw [if_pos h_adj] at h_eval
  have h_w : weighted_adj (by decide : 4 ≥ 3) 0 3 = 2 := by
    rw [weighted_adj_eq_two_iff]
    constructor
    · refine ⟨by decide, Or.inr (Or.inr (Or.inr ?_))⟩
      rfl
    · refine ⟨by decide, Or.inr (Or.inl ?_)⟩
      rfl
  rw [h_w] at h_eval
  norm_num at h_eval

/-- The symmetric block `weightedMatrix` at depth `d` is NOT exactly the adjacency matrix at depth `d-1`. -/
lemma weightedMatrix_neq_adjacencyMatrix :
  ¬ (∀ {d : ℕ} (hd : d ≥ 3) (_hd_sub : d - 1 ≥ 2),
    weightedMatrix hd = @adjacencyMatrix (d-1)) := by
  intro h
  have h_eval := h (by decide : 4 ≥ 3) (by decide)
  have h_eval_03 := congrFun (congrFun h_eval 0) 3
  dsimp [adjacencyMatrix] at h_eval_03
  have h_adj : (G_d 3).Adj 0 3 := by
    refine ⟨by decide, Or.inr (Or.inr (Or.inr ?_))⟩
    rfl
  rw [if_pos h_adj] at h_eval_03
  have h_w : weightedMatrix (by decide : 4 ≥ 3) 0 3 = 2 := by
    have h_w_adj : weighted_adj (by decide : 4 ≥ 3) 0 3 = 2 := by
      rw [weighted_adj_eq_two_iff]
      constructor
      · refine ⟨by decide, Or.inr (Or.inr (Or.inr ?_))⟩
        rfl
      · refine ⟨by decide, Or.inr (Or.inl ?_)⟩
        rfl
    exact h_w_adj
  rw [h_w] at h_eval_03
  norm_num at h_eval_03

/-- The two-step spectral tower decomposition fails because of these topological discontinuities. -/
lemma spectral_tower_two_step_fails :
  ¬ (∀ {d : ℕ} (hd : d ≥ 4),
    weightedMatrix (by omega : d ≥ 3) = @adjacencyMatrix (d-1)) := by
  intro h
  have h_eval := h (by decide : 4 ≥ 4)
  have h_eval_03 := congrFun (congrFun h_eval 0) 3
  dsimp [adjacencyMatrix] at h_eval_03
  have h_adj : (G_d 3).Adj 0 3 := by
    refine ⟨by decide, Or.inr (Or.inr (Or.inr ?_))⟩
    rfl
  rw [if_pos h_adj] at h_eval_03
  have h_w : weightedMatrix (by decide : 4 ≥ 3) 0 3 = 2 := by
    have h_w_adj : weighted_adj (by decide : 4 ≥ 3) 0 3 = 2 := by
      rw [weighted_adj_eq_two_iff]
      constructor
      · refine ⟨by decide, Or.inr (Or.inr (Or.inr ?_))⟩
        rfl
      · refine ⟨by decide, Or.inr (Or.inl ?_)⟩
        rfl
    exact h_w_adj
  rw [h_w] at h_eval_03
  norm_num at h_eval_03
