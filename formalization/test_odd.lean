import Mathlib

lemma odd_iff_coprime (n : ℕ) (hn : 2 ≤ n) (x : ℕ) : Odd x ↔ x.Coprime (2^n) := by
  have hnpos : 0 < n := by omega
  rw [Nat.coprime_pow_right_iff hnpos, Nat.coprime_two_right]
  exact Iff.rfl

lemma odd_iff_isUnit (n : ℕ) (hn : 2 ≤ n) (x : ZMod (2^n)) : Odd x.val ↔ IsUnit x := by
  have hnpos : 0 < 2^n := by positivity
  rw [odd_iff_coprime n hn, ZMod.isUnit_iff_coprime x hnpos]
  
lemma odd_neg (n : ℕ) (hn : 2 ≤ n) (x : ZMod (2^n)) : Odd x.val ↔ Odd (-x).val := by
  rw [odd_iff_isUnit n hn, odd_iff_isUnit n hn]
  exact isUnit_neg_iff
