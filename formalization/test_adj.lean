import Mathlib

lemma adj_implies_not_fixed_inv_sub {d : ℕ} (hd : d ≥ 3) {x : ZMod (2^(d-1))} {v : ZMod (2^(d-2))}
    (hne : pi x ≠ v) (hv : pi x = 3 * v - 1) : x ≠ 3 * x - 1 := by
  intro h
  have h_2x : 2 * x = 1 := by
    calc 2 * x = 3 * x - x := by ring
         _ = 1 := by 
           have : 3 * x = x + 1 := by 
             calc 3 * x = (3 * x - 1) + 1 := by ring
                  _ = x + 1 := by rw [←h]
           rw [this]
           ring
  have h_pow : (2^(d-2) : ZMod (2^(d-1))) * (2 * x) = (2^(d-2) : ZMod (2^(d-1))) * 1 := by
    rw [h_2x]
  have h_left : (2^(d-2) : ZMod (2^(d-1))) * (2 * x) = 0 := by
    calc (2^(d-2) : ZMod (2^(d-1))) * (2 * x) = (2^(d-2) * 2 : ZMod (2^(d-1))) * x := by ring
         _ = (2^(d-1) : ZMod (2^(d-1))) * x := by 
           have : 2^(d-2) * 2 = 2^(d-1) := by 
             have h_sub : d - 1 = d - 2 + 1 := by omega
             rw [h_sub, pow_add, pow_one]
           rw [this]
         _ = 0 * x := by 
           have : (2^(d-1) : ZMod (2^(d-1))) = 0 := ZMod.natCast_self _
           rw [this]
         _ = 0 := MulZeroClass.zero_mul _
  rw [h_left, mul_one] at h_pow
  -- so 2^(d-2) = 0 in ZMod (2^(d-1))
  -- this means 2^(d-1) ∣ 2^(d-2), so 2^(d-1) ≤ 2^(d-2) since 2^(d-2) > 0
  -- but d ≥ 3 so 2^(d-1) > 2^(d-2)
  have h_dvd : 2^(d-1) ∣ 2^(d-2) := by
    exact ZMod.natCast_eq_zero_iff_dvd.mp h_pow.symm
  have h_pos : 0 < 2^(d-2) := by positivity
  have h_le : 2^(d-1) ≤ 2^(d-2) := Nat.le_of_dvd h_pos h_dvd
  have h_lt : 2^(d-2) < 2^(d-1) := by
    have h_sub : d - 1 = d - 2 + 1 := by omega
    rw [h_sub, pow_add, pow_one]
    omega
  omega
