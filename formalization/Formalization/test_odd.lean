import Mathlib

lemma odd_neg_zmod (n : ℕ) (hn : 2 ≤ n) (x : ZMod (2^n)) : Odd x.val ↔ Odd (-x).val := by
  have hnpos : 0 < 2^n := by positivity
  have h_val_neg : (-x).val = (2^n - x.val) % 2^n := ZMod.val_neg x
  have heven : Even (2^n) := by
    obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le hn
    use 2 * 2^m
    ring
  rcases eq_or_ne x.val 0 with h0 | h0
  · -- x.val = 0
    simp [h0]
  · -- x.val != 0
    have hlt : x.val < 2^n := ZMod.val_lt x
    rw [Nat.mod_eq_of_lt] at h_val_neg
    · constructor
      · intro h_odd
        -- Even (2^n) - Odd (x.val) is Odd
        rw [Nat.odd_sub hlt.le]
        simp [heven, h_odd]
      · intro h_odd
        rw [Nat.odd_sub hlt.le] at h_odd
        simp [heven] at h_odd
        exact h_odd
    · exact Nat.sub_lt hnpos h0
