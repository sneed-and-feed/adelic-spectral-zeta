import Mathlib

lemma adj_implies_not_fixed_inv_sub {d : ℕ} (hd : d ≥ 3) {x : ZMod (2^(d-1))} {v : ZMod (2^(d-2))}
    (hv : x = 3 * x - 1) : False := by
  have h_2x : 2 * x = 1 := by
    calc 2 * x = 3 * x - x := by ring
         _ = 1 := by 
           have : 3 * x = x + 1 := by 
             calc 3 * x = (3 * x - 1) + 1 := by ring
                  _ = x + 1 := by rw [←hv]
           rw [this]
           ring
  have h_unit : IsUnit (2 : ZMod (2^(d-1))) := isUnit_of_mul_eq_one (2 : ZMod (2^(d-1))) x h_2x
  have h_coprime : Nat.Coprime 2 (2^(d-1)) := by
    have h_cast : (2 : ZMod (2^(d-1))) = ((2 : ℕ) : ZMod (2^(d-1))) := by rfl
    rw [←ZMod.isUnit_iff_coprime, ←h_cast]
    exact h_unit
  have h_not_coprime : ¬ Nat.Coprime 2 (2^(d-1)) := by
    intro h_c
    have h_dvd : 2 ∣ 2^(d-1) := by exact dvd_pow_self 2 (by omega)
    have h_div : 2 ∣ Nat.gcd 2 (2^(d-1)) := Nat.dvd_gcd (dvd_refl 2) h_dvd
    have h_eq_1 : Nat.gcd 2 (2^(d-1)) = 1 := h_c
    rw [h_eq_1] at h_div
    revert h_div; decide
  exact h_not_coprime h_coprime
