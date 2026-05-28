import re

with open("formalization/Formalization/CollatzRelMatrix.lean", "r") as f:
    text = f.read()

# We want to replace the `projDir_eq_iff` block.
proj_start = text.find("lemma projDir_eq_iff")
proj_end = text.find("-- ============================================================================\n-- 4. FIBER-SUM IDENTITY: W_D = D_{n-1}")

new_proj = """lemma half_ne_zero {n : ℕ} (hn : n ≥ 2) : ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 0 := by
  intro contra
  have hdvd : 2^n ∣ 2^(n-1) := (ZMod.natCast_zmod_eq_zero_iff_dvd _ _).mp contra
  have hle : 2^n ≤ 2^(n-1) := Nat.le_of_dvd (by positivity) hdvd
  have : 2^(n-1) * 2 = 2^n := by
    have : n - 1 + 1 = n := by omega
    nth_rw 2 [← this]; rw [pow_add, pow_one]
  omega

lemma zero_ne_neg_one {n : ℕ} (hn : n ≥ 2) : (0 : ZMod (2^(n-1))) ≠ -1 := by
  intro contra
  have : (1 : ZMod (2^(n-1))) = 0 := by
    calc 1 = 1 + 0 := by ring
      _ = 1 + -1 := by rw [← contra]
      _ = 0 := by ring
  have h_one_cast : ((1 : ℕ) : ZMod (2^(n-1))) = 0 := by exact_mod_cast this
  have hdvd : 2^(n-1) ∣ 1 := (ZMod.natCast_zmod_eq_zero_iff_dvd 1 _).mp h_one_cast
  have hle : 2^(n-1) ≤ 1 := Nat.le_of_dvd (by decide) hdvd
  have : 2^1 ≤ 2^(n-1) := Nat.pow_le_pow_right (by omega) (by omega)
  omega

lemma projDir_eq_iff {n : ℕ} (hn : n ≥ 2) (x y : ZMod (2^n)) :
    projDir n (by omega) x = projDir n (by omega) y ↔
    x = y ∨ x = y + ((2^(n-1) : ℕ) : ZMod (2^n)) := by
  constructor
  · intro h
    have h1 : projDir n (by omega) (x - y) = 0 := by rw [RingHom.map_sub, h, sub_self]
    have h3 : 2^(n-1) ∣ (x - y).val := by
      have : ((x - y).val : ZMod (2^(n-1))) = 0 := by
        rw [← ZMod.cast_eq_val]
        exact h1
      exact (ZMod.natCast_zmod_eq_zero_iff_dvd _ _).mp this
    have h4 : (x - y).val < 2^n := ZMod.val_lt (x - y)
    have h_exp : 2^n = 2^(n-1) * 2 := by
      have : n - 1 + 1 = n := by omega
      nth_rw 1 [← this]; rw [pow_add, pow_one]
    rcases h3 with ⟨k, hk⟩
    have h_k_lt : k < 2 := by
      have h4' : 2^(n-1) * k < 2^(n-1) * 2 := by linarith
      exact Nat.lt_of_mul_lt_mul_left h4'
    have h_k_cases : k = 0 ∨ k = 1 := by omega
    rcases h_k_cases with rfl | rfl
    · left
      have : (x - y).val = 0 := by omega
      have h6 : x - y = 0 := by
        rw [← ZMod.natCast_zmod_val (x - y), this, Nat.cast_zero]
      exact sub_eq_zero.mp h6
    · right
      have : (x - y).val = 2^(n-1) := by omega
      have h6 : x - y = ((2^(n-1) : ℕ) : ZMod (2^n)) := by
        rw [← ZMod.natCast_zmod_val (x - y), this]
      linear_combination h6
  · intro h
    rcases h with rfl | rfl
    · rfl
    · rw [RingHom.map_add]
      have h_cast : projDir n (by omega) ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
        have : projDir n (by omega) ((2^(n-1) : ℕ) : ZMod (2^n)) = ((2^(n-1) : ℕ) : ZMod (2^(n-1))) := by exact map_natCast (projDir n (by omega)) _
        rw [this]
        exact ZMod.natCast_self _
      rw [h_cast, add_zero]

"""

text = text[:proj_start] + new_proj + text[proj_end:]

fiber_start = text.find("theorem fiber_sum_identity")
fiber_end = text.find("-- ============================================================================\n-- 5. REINDEXED DIRECTED MATRIX")

new_fiber = """theorem fiber_sum_identity (n : ℕ) (hn : n ≥ 2) (v u : ZMod (2^(n-1))) :
    collatzDirMatrix n (liftDir v) (liftDir u) +
    collatzDirMatrix n (liftDir v) (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) =
    collatzDirMatrix (n-1) v u := by
  simp only [collatzDirMatrix]
  have hn1 : n ≥ 1 := by omega
  have h_proj_u : projDir n hn1 (liftDir u) = u := projDir_liftDir hn1 u
  have h_proj_u2 : projDir n hn1 (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) = u := by
    rw [RingHom.map_add, h_proj_u]
    have h_cast : projDir n hn1 ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
      have : projDir n hn1 ((2^(n-1) : ℕ) : ZMod (2^n)) = ((2^(n-1) : ℕ) : ZMod (2^(n-1))) := by exact map_natCast (projDir n hn1) _
      rw [this]; exact ZMod.natCast_self _
    rw [h_cast, add_zero]
  have h_proj_3v : projDir n hn1 (3 * liftDir v) = 3 * v := by
    rw [RingHom.map_mul, show projDir n hn1 3 = 3 by exact map_natCast (projDir n hn1) 3, projDir_liftDir hn1 v]
  have h_proj_3v_sub : projDir n hn1 (3 * liftDir v - 1) = 3 * v - 1 := by
    rw [RingHom.map_sub, h_proj_3v, show projDir n hn1 1 = 1 by exact RingHom.map_one _]
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
        exact zero_ne_neg_one hn this
      have c4 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 3 * liftDir v - 1 := by
        intro contra
        have := congr_arg (projDir n hn1) contra
        rw [h_proj_u2, h_proj_3v_sub, h_eq1] at this
        have : (0 : ZMod (2^(n-1))) = -1 := by
          calc (0 : ZMod (2^(n-1))) = 3*v - 3*v := by ring
            _ = 3*v - 1 - 3*v := by rw [← this]
            _ = -1 := by ring
        exact zero_ne_neg_one hn this
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
          exact half_ne_zero hn this
        have h_false2 : ¬(liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v - 1) := not_or.mpr ⟨c3, c4⟩
        rw [if_neg h_false2]; exact add_zero 1
      · have c1 : liftDir u ≠ 3 * liftDir v := by
          intro contra
          have : ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
            calc ((2^(n-1) : ℕ) : ZMod (2^n)) = (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) - liftDir u := by ring
              _ = 3 * liftDir v - 3 * liftDir v := by rw [← h_cases2, contra]
              _ = 0 := by ring
          exact half_ne_zero hn this
        have h_false1 : ¬(liftDir u = 3 * liftDir v ∨ liftDir u = 3 * liftDir v - 1) := not_or.mpr ⟨c1, c2⟩
        rw [if_neg h_false1]
        have h_true2 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v - 1 := Or.inl h_cases2.symm
        rw [if_pos h_true2]; exact zero_add 1
    · have c1 : liftDir u ≠ 3 * liftDir v := by
        intro contra
        have := congr_arg (projDir n hn1) contra
        rw [h_proj_u, h_proj_3v, h_eq2] at this
        have : (0 : ZMod (2^(n-1))) = -1 := by
          calc (0 : ZMod (2^(n-1))) = 3*v - 3*v := by ring
            _ = 3*v - 1 - 3*v := by rw [this]
            _ = -1 := by ring
        exact zero_ne_neg_one hn this
      have c3 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 3 * liftDir v := by
        intro contra
        have := congr_arg (projDir n hn1) contra
        rw [h_proj_u2, h_proj_3v, h_eq2] at this
        have : (0 : ZMod (2^(n-1))) = -1 := by
          calc (0 : ZMod (2^(n-1))) = 3*v - 3*v := by ring
            _ = 3*v - 1 - 3*v := by rw [this]
            _ = -1 := by ring
        exact zero_ne_neg_one hn this
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
          exact half_ne_zero hn this
        have h_false2 : ¬(liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v - 1) := not_or.mpr ⟨c3, c4⟩
        rw [if_neg h_false2]; exact add_zero 1
      · have c2 : liftDir u ≠ 3 * liftDir v - 1 := by
          intro contra
          have : ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
            calc ((2^(n-1) : ℕ) : ZMod (2^n)) = (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) - liftDir u := by ring
              _ = (3 * liftDir v - 1) - (3 * liftDir v - 1) := by rw [← h_cases2, contra]
              _ = 0 := by ring
          exact half_ne_zero hn this
        have h_false1 : ¬(liftDir u = 3 * liftDir v ∨ liftDir u = 3 * liftDir v - 1) := not_or.mpr ⟨c1, c2⟩
        rw [if_neg h_false1]
        have h_true2 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v - 1 := Or.inr h_cases2.symm
        rw [if_pos h_true2]; exact zero_add 1
  · rw [if_neg h]; push_neg at h
    have c1 : liftDir u ≠ 3 * liftDir v := by
      intro contra; have := congr_arg (projDir n hn1) contra; rw [h_proj_u, h_proj_3v] at this; exact h.1 this
    have c2 : liftDir u ≠ 3 * liftDir v - 1 := by
      intro contra; have := congr_arg (projDir n hn1) contra; rw [h_proj_u, h_proj_3v_sub] at this; exact h.2 this
    have c3 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 3 * liftDir v := by
      intro contra; have := congr_arg (projDir n hn1) contra; rw [h_proj_u2, h_proj_3v] at this; exact h.1 this
    have c4 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 3 * liftDir v - 1 := by
      intro contra; have := congr_arg (projDir n hn1) contra; rw [h_proj_u2, h_proj_3v_sub] at this; exact h.2 this
    have d1 : ¬(liftDir u = 3 * liftDir v ∨ liftDir u = 3 * liftDir v - 1) := not_or.mpr ⟨c1, c2⟩
    have d2 : ¬(liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v - 1) := not_or.mpr ⟨c3, c4⟩
    rw [if_neg d1, if_neg d2]; exact add_zero 0

"""

text = text[:fiber_start] + new_fiber + text[fiber_end:]

with open("formalization/Formalization/CollatzRelMatrix.lean", "w") as f:
    f.write(text)

