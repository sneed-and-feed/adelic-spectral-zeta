import Mathlib
import Formalization.CollatzRelMatrix

open Classical
open Matrix
open scoped Matrix
open CollatzDirMatrix

lemma projDir_eq_iff {n : ℕ} (hn : n ≥ 2) (x y : ZMod (2^n)) :
    projDir n (by omega) x = projDir n (by omega) y ↔
    x = y ∨ x = y + ((2^(n-1) : ℕ) : ZMod (2^n)) := by
  constructor
  · intro h
    have h1 : projDir n (by omega) (x - y) = 0 := by rw [RingHom.map_sub, h, sub_self]
    have h_cast : projDir n (by omega) (x - y) = ZMod.cast (x - y) := rfl
    rw [h_cast] at h1
    have h2 : ((x - y).val : ZMod (2^(n-1))) = 0 := by
      calc ((x - y).val : ZMod (2^(n-1))) = ZMod.cast (x - y) := (ZMod.cast_eq_val (x - y)).symm
        _ = 0 := h1
    have h3 : 2^(n-1) ∣ (x - y).val := by
      exact ZMod.natCast_zmod_eq_zero_iff_dvd _ _ |>.mp h2
    have h4 : (x - y).val < 2^n := ZMod.val_lt (x - y)
    rcases h3 with ⟨k, hk⟩
    have h_exp : 2^n = 2^(n-1) * 2 := by
      have h1 : n = n - 1 + 1 := by omega
      nth_rw 1 [h1]
      rw [pow_add, pow_one]
    have h4' : (x - y).val < 2^(n-1) * 2 := by
      calc (x - y).val < 2^n := h4
        _ = 2^(n-1) * 2 := h_exp
    have hk2 : 2^(n-1) * k < 2^(n-1) * 2 := by rw [← hk] ; exact h4'
    have h_k_lt : k < 2 := Nat.lt_of_mul_lt_mul_left hk2
    have h_k_cases : k = 0 ∨ k = 1 := by omega
    rcases h_k_cases with rfl | rfl
    · left
      have h5 : (x - y).val = 0 := by omega
      have h6 : x - y = 0 := by
        calc x - y = ((x - y).val : ZMod (2^n)) := (ZMod.natCast_zmod_val (x - y)).symm
          _ = (0 : ZMod (2^n)) := by rw [h5, Nat.cast_zero]
      exact sub_eq_zero.mp h6
    · right
      have h5 : (x - y).val = 2^(n-1) := by omega
      have h6 : x - y = ((2^(n-1) : ℕ) : ZMod (2^n)) := by
        calc x - y = ((x - y).val : ZMod (2^n)) := (ZMod.natCast_zmod_val (x - y)).symm
          _ = ((2^(n-1) : ℕ) : ZMod (2^n)) := by rw [h5]
      calc x = x - y + y := by ring
        _ = ((2^(n-1) : ℕ) : ZMod (2^n)) + y := by rw [h6]
        _ = y + ((2^(n-1) : ℕ) : ZMod (2^n)) := by ring
  · intro h
    rcases h with rfl | rfl
    · rfl
    · rw [RingHom.map_add]
      have h_cast : projDir n (by omega) ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
        calc projDir n (by omega) ((2^(n-1) : ℕ) : ZMod (2^n)) = ((2^(n-1) : ℕ) : ZMod (2^(n-1))) := by exact map_natCast (projDir n (by omega)) _
          _ = 0 := ZMod.natCast_self _
      rw [h_cast, add_zero]

theorem fiber_sum_identity_test (n : ℕ) (hn : n ≥ 2) (v u : ZMod (2^(n-1))) :
    collatzDirMatrix n (liftDir v) (liftDir u) +
    collatzDirMatrix n (liftDir v) (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) =
    collatzDirMatrix (n-1) v u := by
  simp only [collatzDirMatrix]
  have hn1 : n ≥ 1 := by omega
  have h_proj_u : projDir n hn1 (liftDir u) = u := projDir_liftDir hn1 u
  have h_proj_u2 : projDir n hn1 (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) = u := by
    rw [RingHom.map_add, h_proj_u]
    have h_cast : projDir n hn1 ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
      calc projDir n hn1 ((2^(n-1) : ℕ) : ZMod (2^n)) = ((2^(n-1) : ℕ) : ZMod (2^(n-1))) := by exact map_natCast (projDir n hn1) _
        _ = 0 := ZMod.natCast_self _
    rw [h_cast, add_zero]
  have h_proj_3v : projDir n hn1 (3 * liftDir v) = 3 * v := by
    calc projDir n hn1 (3 * liftDir v) = projDir n hn1 3 * projDir n hn1 (liftDir v) := by rw [RingHom.map_mul]
      _ = 3 * projDir n hn1 (liftDir v) := by
        have : projDir n hn1 3 = 3 := by exact map_natCast (projDir n hn1) 3
        rw [this]
      _ = 3 * v := by rw [projDir_liftDir hn1 v]
  have h_proj_3v_sub : projDir n hn1 (3 * liftDir v - 1) = 3 * v - 1 := by
    calc projDir n hn1 (3 * liftDir v - 1) = projDir n hn1 (3 * liftDir v) - projDir n hn1 1 := by rw [RingHom.map_sub]
      _ = (3 * v) - 1 := by
        have : projDir n hn1 1 = 1 := by exact RingHom.map_one _
        rw [h_proj_3v, this]
  have h_0_ne_m1 : (0 : ZMod (2^(n-1))) ≠ -1 := by
    intro contra
    have h_one : (1 : ZMod (2^(n-1))) = 0 := by
      calc (1 : ZMod (2^(n-1))) = 0 + 1 := by ring
        _ = -1 + 1 := by rw [← contra]
        _ = 0 := by ring
    have h_one_cast : ((1 : ℕ) : ZMod (2^(n-1))) = 0 := by
      calc ((1 : ℕ) : ZMod (2^(n-1))) = (1 : ZMod (2^(n-1))) := by exact Nat.cast_one
        _ = 0 := h_one
    have hdvd : 2^(n-1) ∣ 1 := (ZMod.natCast_zmod_eq_zero_iff_dvd 1 (2^(n-1))).mp h_one_cast
    have hle : 2^(n-1) ≤ 1 := Nat.le_of_dvd (by decide) hdvd
    have hgt : 2^(n-1) > 1 := by
      have h_pow : n - 1 ≥ 1 := by omega
      calc 2^(n-1) ≥ 2^1 := Nat.pow_le_pow_right (by omega) h_pow
        _ > 1 := by omega
    omega
  by_cases h : u = 3 * v ∨ u = 3 * v - 1
  · rw [if_pos h]
    rcases h with h_eq1 | h_eq2
    · have c2 : liftDir u ≠ 3 * liftDir v - 1 := by
        intro contra
        have := congr_arg (projDir n hn1) contra
        rw [h_proj_u, h_proj_3v_sub, h_eq1] at this
        have : (0 : ZMod (2^(n-1))) = -1 := by
          calc (0 : ZMod (2^(n-1))) = 3*v - 3*v := by ring
            _ = 3*v - 1 - 3*v := by rw [← this]
            _ = -1 := by ring
        exact h_0_ne_m1 this
      have c4 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 3 * liftDir v - 1 := by
        intro contra
        have := congr_arg (projDir n hn1) contra
        rw [h_proj_u2, h_proj_3v_sub, h_eq1] at this
        have : (0 : ZMod (2^(n-1))) = -1 := by
          calc (0 : ZMod (2^(n-1))) = 3*v - 3*v := by ring
            _ = 3*v - 1 - 3*v := by rw [← this]
            _ = -1 := by ring
        exact h_0_ne_m1 this
      have h_proj_eq : projDir n hn1 (3 * liftDir v) = projDir n hn1 (liftDir u) := by
        rw [h_proj_3v, h_proj_u, h_eq1]
      have h_cases := (projDir_eq_iff hn (3 * liftDir v) (liftDir u)).mp h_proj_eq
      rcases h_cases with h_cases1 | h_cases2
      · have h_true1 : liftDir u = 3 * liftDir v ∨ liftDir u = 3 * liftDir v - 1 := Or.inl h_cases1.symm
        rw [if_pos h_true1]
        have c3 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 3 * liftDir v := by
          intro contra
          have : ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
            calc ((2^(n-1) : ℕ) : ZMod (2^n)) = (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) - liftDir u := by ring
              _ = 3 * liftDir v - 3 * liftDir v := by rw [contra, ← h_cases1.symm]
              _ = 0 := by ring
          have hdvd : 2^n ∣ 2^(n-1) := (ZMod.natCast_zmod_eq_zero_iff_dvd _ _).mp this
          have hle : 2^n ≤ 2^(n-1) := Nat.le_of_dvd (by positivity) hdvd
          have hgt : 2^n > 2^(n-1) := by
            have : n = n - 1 + 1 := by omega
            nth_rw 1 [this]
            rw [pow_add, pow_one]
            omega
          omega
        have h_false2 : ¬(liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v - 1) := not_or.mpr ⟨c3, c4⟩
        rw [if_neg h_false2]
        exact add_zero 1
      · have c1 : liftDir u ≠ 3 * liftDir v := by
          intro contra
          have : ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
            calc ((2^(n-1) : ℕ) : ZMod (2^n)) = (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) - liftDir u := by ring
              _ = 3 * liftDir v - 3 * liftDir v := by rw [← h_cases2, contra]
              _ = 0 := by ring
          have hdvd : 2^n ∣ 2^(n-1) := (ZMod.natCast_zmod_eq_zero_iff_dvd _ _).mp this
          have hle : 2^n ≤ 2^(n-1) := Nat.le_of_dvd (by positivity) hdvd
          have hgt : 2^n > 2^(n-1) := by
            have : n = n - 1 + 1 := by omega
            nth_rw 1 [this]
            rw [pow_add, pow_one]
            omega
          omega
        have h_false1 : ¬(liftDir u = 3 * liftDir v ∨ liftDir u = 3 * liftDir v - 1) := not_or.mpr ⟨c1, c2⟩
        rw [if_neg h_false1]
        have h_true2 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v - 1 := Or.inl h_cases2.symm
        rw [if_pos h_true2]
        exact zero_add 1
    · have c1 : liftDir u ≠ 3 * liftDir v := by
        intro contra
        have := congr_arg (projDir n hn1) contra
        rw [h_proj_u, h_proj_3v, h_eq2] at this
        have : (0 : ZMod (2^(n-1))) = -1 := by
          calc (0 : ZMod (2^(n-1))) = 3*v - 3*v := by ring
            _ = 3*v - 1 - 3*v := by rw [this]
            _ = -1 := by ring
        exact h_0_ne_m1 this
      have c3 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 3 * liftDir v := by
        intro contra
        have := congr_arg (projDir n hn1) contra
        rw [h_proj_u2, h_proj_3v, h_eq2] at this
        have : (0 : ZMod (2^(n-1))) = -1 := by
          calc (0 : ZMod (2^(n-1))) = 3*v - 3*v := by ring
            _ = 3*v - 1 - 3*v := by rw [this]
            _ = -1 := by ring
        exact h_0_ne_m1 this
      have h_proj_eq : projDir n hn1 (3 * liftDir v - 1) = projDir n hn1 (liftDir u) := by
        rw [h_proj_3v_sub, h_proj_u, h_eq2]
      have h_cases := (projDir_eq_iff hn (3 * liftDir v - 1) (liftDir u)).mp h_proj_eq
      rcases h_cases with h_cases1 | h_cases2
      · have h_true1 : liftDir u = 3 * liftDir v ∨ liftDir u = 3 * liftDir v - 1 := Or.inr h_cases1.symm
        rw [if_pos h_true1]
        have c4 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 3 * liftDir v - 1 := by
          intro contra
          have : ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
            calc ((2^(n-1) : ℕ) : ZMod (2^n)) = (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) - liftDir u := by ring
              _ = (3 * liftDir v - 1) - (3 * liftDir v - 1) := by rw [contra, ← h_cases1.symm]
              _ = 0 := by ring
          have hdvd : 2^n ∣ 2^(n-1) := (ZMod.natCast_zmod_eq_zero_iff_dvd _ _).mp this
          have hle : 2^n ≤ 2^(n-1) := Nat.le_of_dvd (by positivity) hdvd
          have hgt : 2^n > 2^(n-1) := by
            have : n = n - 1 + 1 := by omega
            nth_rw 1 [this]
            rw [pow_add, pow_one]
            omega
          omega
        have h_false2 : ¬(liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v - 1) := not_or.mpr ⟨c3, c4⟩
        rw [if_neg h_false2]
        exact add_zero 1
      · have c2 : liftDir u ≠ 3 * liftDir v - 1 := by
          intro contra
          have : ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
            calc ((2^(n-1) : ℕ) : ZMod (2^n)) = (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) - liftDir u := by ring
              _ = (3 * liftDir v - 1) - (3 * liftDir v - 1) := by rw [← h_cases2, contra]
              _ = 0 := by ring
          have hdvd : 2^n ∣ 2^(n-1) := (ZMod.natCast_zmod_eq_zero_iff_dvd _ _).mp this
          have hle : 2^n ≤ 2^(n-1) := Nat.le_of_dvd (by positivity) hdvd
          have hgt : 2^n > 2^(n-1) := by
            have : n = n - 1 + 1 := by omega
            nth_rw 1 [this]
            rw [pow_add, pow_one]
            omega
          omega
        have h_false1 : ¬(liftDir u = 3 * liftDir v ∨ liftDir u = 3 * liftDir v - 1) := not_or.mpr ⟨c1, c2⟩
        rw [if_neg h_false1]
        have h_true2 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v - 1 := Or.inr h_cases2.symm
        rw [if_pos h_true2]
        exact zero_add 1
  · rw [if_neg h]
    push_neg at h
    have c1 : liftDir u ≠ 3 * liftDir v := by
      intro contra
      have := congr_arg (projDir n hn1) contra
      rw [h_proj_u, h_proj_3v] at this
      exact h.1 this
    have c2 : liftDir u ≠ 3 * liftDir v - 1 := by
      intro contra
      have := congr_arg (projDir n hn1) contra
      rw [h_proj_u, h_proj_3v_sub] at this
      exact h.2 this
    have c3 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 3 * liftDir v := by
      intro contra
      have := congr_arg (projDir n hn1) contra
      rw [h_proj_u2, h_proj_3v] at this
      exact h.1 this
    have c4 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 3 * liftDir v - 1 := by
      intro contra
      have := congr_arg (projDir n hn1) contra
      rw [h_proj_u2, h_proj_3v_sub] at this
      exact h.2 this
    have d1 : ¬(liftDir u = 3 * liftDir v ∨ liftDir u = 3 * liftDir v - 1) := not_or.mpr ⟨c1, c2⟩
    have d2 : ¬(liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v - 1) := not_or.mpr ⟨c3, c4⟩
    rw [if_neg d1, if_neg d2]
    exact add_zero 0
