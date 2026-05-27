import Mathlib
import Formalization.CollatzRelMatrix

open CollatzDirMatrix
open Classical

lemma projDir_eq_iff (n : ℕ) (hn : n ≥ 2) (x y : ZMod (2^n)) :
  projDir n (by omega) x = projDir n (by omega) y ↔ x = y ∨ x = y + ((2^(n-1) : ℕ) : ZMod (2^n)) := by
  constructor
  · intro h
    have h_sub : projDir n (by omega) (x - y) = 0 := by
      rw [map_sub, h, sub_self]
    have h_cast : ((x - y).val : ZMod (2^(n-1))) = 0 := by
      have h_z : (x - y) = ((x - y).val : ZMod (2^n)) := (ZMod.natCast_zmod_val (x - y)).symm
      rw [h_z] at h_sub
      simp only [projDir, ZMod.castHom_apply] at h_sub
      exact h_sub
    have h_div : 2^(n-1) ∣ (x - y).val := by
      rw [ZMod.natCast_zmod_eq_zero_iff_dvd] at h_cast
      exact h_cast
    have h_bound : (x - y).val < 2^n := ZMod.val_lt (x - y)
    obtain ⟨k, hk⟩ := h_div
    have h_k : k < 2 := by
      have h_exp : 2^n = 2 * 2^(n-1) := by
        calc 2^n = 2^(1 + (n - 1)) := by rw [show 1 + (n - 1) = n from by omega]
             _ = 2^1 * 2^(n-1) := pow_add 2 1 (n-1)
             _ = 2 * 2^(n-1) := by ring
      nlinarith
    have h_k_eq : k = 0 ∨ k = 1 := by omega
    rcases h_k_eq with rfl | rfl
    · left
      have : (x - y).val = 0 := by rw [hk, Nat.zero_mul]
      have h_xy : x - y = 0 := (ZMod.val_eq_zero (x - y)).mp this
      exact sub_eq_zero.mp h_xy
    · right
      have : (x - y).val = 2^(n-1) := by rw [hk, Nat.one_mul]
      have h_xy : x - y = ((2^(n-1) : ℕ) : ZMod (2^n)) := by
        have h_z : x - y = ((x - y).val : ZMod (2^n)) := (ZMod.natCast_zmod_val (x - y)).symm
        rw [h_z, this]
      exact eq_add_of_sub_eq h_xy
  · rintro (rfl | rfl)
    · rfl
    · rw [map_add]
      have : projDir n (by omega) ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
        simp only [projDir, ZMod.castHom_apply, ZMod.natCast_zmod_eq_zero_iff_dvd]
      rw [this, add_zero]

lemma projDir_three_mul (n : ℕ) (hn : n ≥ 1) (x : ZMod (2^n)) :
    projDir n hn (3 * x) = 3 * projDir n hn x := by
  rw [map_mul, map_natCast]

lemma projDir_three_mul_sub_one (n : ℕ) (hn : n ≥ 1) (x : ZMod (2^n)) :
    projDir n hn (3 * x - 1) = 3 * projDir n hn x - 1 := by
  rw [map_sub, map_mul, map_natCast, map_one]

-- Now fiber_sum_identity
theorem fiber_sum_identity_proof (n : ℕ) (hn : n ≥ 2) (v u : ZMod (2^(n-1))) :
    collatzDirMatrix n (liftDir v) (liftDir u) +
    collatzDirMatrix n (liftDir v) (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) =
    collatzDirMatrix (n-1) v u := by
  simp only [collatzDirMatrix]
  have h_proj_u : projDir n (by omega) (liftDir u) = u := projDir_liftDir (by omega) u
  have h_proj_v : projDir n (by omega) (liftDir v) = v := projDir_liftDir (by omega) v
  have h_proj_u_shift : projDir n (by omega) (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) = u := by
    rw [map_add, h_proj_u]
    have : projDir n (by omega) ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
      simp only [projDir, ZMod.castHom_apply, ZMod.natCast_zmod_eq_zero_iff_dvd]
    rw [this, add_zero]
  
  -- Use projDir_eq_iff to convert lifts to relations at scale n-1
  have h1 : liftDir u = 3 * liftDir v ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v ↔ u = 3 * v := by
    rw [← projDir_eq_iff n hn (3 * liftDir v) (liftDir u)]
    rw [projDir_three_mul n (by omega) (liftDir v)]
    rw [h_proj_u, h_proj_v]
    tauto
  
  have h2 : liftDir u = 3 * liftDir v - 1 ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v - 1 ↔ u = 3 * v - 1 := by
    rw [← projDir_eq_iff n hn (3 * liftDir v - 1) (liftDir u)]
    rw [projDir_three_mul_sub_one n (by omega) (liftDir v)]
    rw [h_proj_u, h_proj_v]
    tauto
  
  -- The generators 3v and 3v-1 are distinct mod 2^n
  have h_diff : 3 * liftDir v ≠ 3 * liftDir v - 1 := by
    intro h
    have : (0 : ZMod (2^n)) = -1 := by calc
      (0 : ZMod (2^n)) = 3 * liftDir v - 3 * liftDir v := by ring
      _ = (3 * liftDir v - 1) - 3 * liftDir v := by rw [← h]
      _ = -1 := by ring
    have h_one : (1 : ZMod (2^n)) = 0 := by
      calc (1 : ZMod (2^n)) = -(-1) := by ring
        _ = -0 := by rw [← this]
        _ = 0 := by ring
    have h_n : 2^n > 1 := by
      calc 2^n ≥ 2^2 := Nat.pow_le_pow_right (by omega) hn
        _ = 4 := by norm_num
        _ > 1 := by omega
    exact absurd h_one (ZMod.one_ne_zero (by omega))
  
  sorry
