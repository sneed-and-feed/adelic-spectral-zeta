import Mathlib.Data.ZMod.Basic

lemma diff_not_zero {d : ℕ} (hd : d ≥ 3) :
    ((2^(d-2) : ℕ) : ZMod (2^(d-1))) ≠ 0 := by
  intro h
  have h3 : 2^(d-1) ∣ 2^(d-2) := by
    exact (CharP.cast_eq_zero_iff (ZMod (2^(d-1))) (2^(d-1)) (2^(d-2))).mp h
  have h4 : 2^(d-1) ≤ 2^(d-2) := Nat.le_of_dvd (by positivity) h3
  have h5 : d - 2 < d - 1 := by omega
  have h6 : 2^(d-2) < 2^(d-1) := Nat.pow_lt_pow_right (by decide) h5
  linarith

lemma eq_three {d : ℕ} (hd : d ≥ 3) :
    (3 : ZMod (2^(d-1))) * (2^(d-3) : ℕ) = (2^(d-3) : ℕ) + (2^(d-2) : ℕ) := by
  have h_pow : 2 * 2^(d-3) = 2^(d-2) := by
    have hd_sub : d - 2 = d - 3 + 1 := by omega
    rw [hd_sub, pow_add, pow_one, mul_comm]
  have h3 : (3 : ZMod (2^(d-1))) = 2 + 1 := by norm_num
  calc (3 : ZMod (2^(d-1))) * (2^(d-3) : ℕ)
    _ = (2 + 1) * (2^(d-3) : ℕ) := by rw [h3]
    _ = 2 * (2^(d-3) : ℕ) + 1 * (2^(d-3) : ℕ) := add_mul 2 1 _
    _ = 2 * (2^(d-3) : ℕ) + (2^(d-3) : ℕ) := by rw [one_mul]
    _ = (2 * 2^(d-3) : ℕ) + (2^(d-3) : ℕ) := by
      have : 2 * ((2^(d-3) : ℕ) : ZMod (2^(d-1))) = ((2 * 2^(d-3) : ℕ) : ZMod (2^(d-1))) := by
        push_cast
        rfl
      rw [this]
    _ = (2^(d-2) : ℕ) + (2^(d-3) : ℕ) := by rw [h_pow]
    _ = (2^(d-3) : ℕ) + (2^(d-2) : ℕ) := add_comm _ _
