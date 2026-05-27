import Mathlib.Data.Matrix.Basic
import Formalization.SchreierSpectral

open Matrix
open Classical

namespace SchreierSpectral

lemma adj_4_0_3 : (G_d 4).Adj (0 : ZMod 8) (3 : ZMod 8) := by
  dsimp [G_d]
  refine ⟨by decide, Or.inr (Or.inr (Or.inr ?_))⟩
  -- 0 = 3*3 - 1
  decide

lemma adj_4_0_7 : (G_d 4).Adj (0 : ZMod 8) (7 : ZMod 8) := by
  dsimp [G_d]
  refine ⟨by decide, Or.inr (Or.inl ?_)⟩
  -- 7 = 3*0 - 1
  decide

lemma adj_3_0_3 : (G_d 3).Adj (0 : ZMod 4) (3 : ZMod 4) := by
  dsimp [G_d]
  refine ⟨by decide, Or.inr (Or.inl ?_)⟩
  -- 3 = 3*0 - 1
  decide

lemma counterexample_d4 :
    weightedMatrix (by decide : 4 ≥ 3) (0 : ZMod 4) (3 : ZMod 4) = 2 ∧
    @adjacencyMatrix 3 (0 : ZMod 4) (3 : ZMod 4) = 1 := by
  have hd_ge : 4 ≥ 3 := by decide
  constructor
  · -- Prove weightedMatrix = 2
    have h_w := weighted_adj_eq_two_iff hd_ge (0 : ZMod 4) (3 : ZMod 4)
    rw [weighted_adj_eq_sum] at h_w
    apply h_w.mpr
    constructor
    · have h_can_0 : @canonicalLift 4 (0 : ZMod 4) = (0 : ZMod 8) := rfl
      have h_can_3 : @canonicalLift 4 (3 : ZMod 4) = (3 : ZMod 8) := rfl
      rw [h_can_0, h_can_3]
      exact adj_4_0_3
    · have h_can_0 : @canonicalLift 4 (0 : ZMod 4) = (0 : ZMod 8) := rfl
      have h_can_3 : @canonicalLift 4 (3 : ZMod 4) = (3 : ZMod 8) := rfl
      rw [h_can_0, h_can_3]
      have h_tau : @tau 4 (3 : ZMod 8) = (7 : ZMod 8) := rfl
      rw [h_tau]
      exact adj_4_0_7
  · -- Prove adjacencyMatrix = 1
    dsimp [adjacencyMatrix]
    rw [if_pos adj_3_0_3]

end SchreierSpectral
