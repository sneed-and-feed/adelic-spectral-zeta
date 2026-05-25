import Mathlib

lemma not_loop_implies_not_fixed {d : ℕ} (hd : d ≥ 3) (x : ZMod (2^(d-1))) :
    (ZMod.castHom (show 2^(d-2) ∣ 2^(d-1) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) x) ≠ (2^(d-3) : ZMod (2^(d-2))) → x ≠ 3 * x := by
  contrapose!
  intro hx
  have h2x : 2 * x = 0 := by
    calc 2 * x = 3 * x - x := by ring
         _ = x - x := by rw [←hx]
         _ = 0 := by ring
  -- 2x = 0 implies x = 0 or x = 2^(d-2)
  have hx_cases : x = 0 ∨ x = (2^(d-2) : ZMod (2^(d-1))) := by
    have h_mod : x.val * 2 % 2^(d-1) = 0 := by
      have hz : (2 * x).val = 0 := by rw [h2x, ZMod.val_zero]
      have hm : (2 * x).val = x.val * 2 % 2^(d-1) := by
        rw [mul_comm]
        exact ZMod.val_mul x 2
      rwa [hm] at hz
    have h_dvd : 2^(d-1) ∣ x.val * 2 := Nat.dvd_of_mod_eq_zero h_mod
    have hk : ∃ k, x.val * 2 = k * 2^(d-1) := h_dvd
    obtain ⟨k, hk⟩ := hk
    have h_bound : x.val < 2^(d-1) := ZMod.val_lt x
    have h_k : k = 0 ∨ k = 1 := by
      have h_pow_pos : 2^(d-1) > 0 := Nat.pos_pow_of_pos _ (by decide)
      nlinarith
    rcases h_k with rfl | rfl
    · left
      have : x.val = 0 := by nlinarith
      exact Fin.ext this
    · right
      have h_sub : d - 1 = d - 2 + 1 := by omega
      have h_pow : 2^(d-1) = 2^(d-2) * 2 := by rw [h_sub, pow_add, pow_one]
      have : x.val = 2^(d-2) := by nlinarith
      exact Fin.ext this
  rcases hx_cases with rfl | rfl
  · have h_zero : (ZMod.castHom (pow_dvd_pow 2 (by omega)) (ZMod (2^(d-2))) 0) = 0 := map_zero _
    rw [h_zero]
    intro heq
    have h_val : (0 : ZMod (2^(d-2))).val = (2^(d-3) : ZMod (2^(d-2))).val := by rw [heq]
    have hv0 : (0 : ZMod (2^(d-2))).val = 0 := ZMod.val_zero
    have hv2 : (2^(d-3) : ZMod (2^(d-2))).val = 2^(d-3) := by
      exact ZMod.val_natCast_of_lt (Nat.pow_lt_pow_right (by decide) (by omega))
    rw [hv0, hv2] at h_val
    have h_pos : 2^(d-3) > 0 := Nat.pos_pow_of_pos _ (by decide)
    omega
  · have h_cast : (ZMod.castHom (pow_dvd_pow 2 (by omega)) (ZMod (2^(d-2))) (2^(d-2) : ZMod (2^(d-1)))) = 0 := by
      rw [map_natCast]
      exact ZMod.natCast_self _
    rw [h_cast]
    intro heq
    have h_val : (0 : ZMod (2^(d-2))).val = (2^(d-3) : ZMod (2^(d-2))).val := by rw [heq]
    have hv0 : (0 : ZMod (2^(d-2))).val = 0 := ZMod.val_zero
    have hv2 : (2^(d-3) : ZMod (2^(d-2))).val = 2^(d-3) := by
      exact ZMod.val_natCast_of_lt (Nat.pow_lt_pow_right (by decide) (by omega))
    rw [hv0, hv2] at h_val
    have h_pos : 2^(d-3) > 0 := Nat.pos_pow_of_pos _ (by decide)
    omega
