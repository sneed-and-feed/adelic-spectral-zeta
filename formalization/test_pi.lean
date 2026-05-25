import Mathlib

lemma pi_natCast {d : ℕ} (n : ℕ) : (ZMod.castHom (show 2^(d-2) ∣ 2^(d-1) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) (n : ZMod (2^(d-1)))) = (n : ZMod (2^(d-2))) := by
  simp

lemma pi_eq_zero_iff {d : ℕ} (hd : d ≥ 3) (z : ZMod (2^(d-1))) :
    (ZMod.castHom (show 2^(d-2) ∣ 2^(d-1) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) z) = 0 ↔ z = 0 ∨ z = (2^(d-2) : ZMod (2^(d-1))) := by
  constructor
  · -- Forward:
    intro hz
    have h_cast : ((z.val : ℕ) : ZMod (2^(d-2))) = 0 := by
      have hz2 : (ZMod.castHom (show 2^(d-2) ∣ 2^(d-1) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) z) = 0 := hz
      have h_z : z = (z.val : ZMod (2^(d-1))) := (ZMod.natCast_zmod_val z).symm
      rw [h_z] at hz2
      rw [pi_natCast] at hz2
      exact hz2
    have h_div : 2^(d-2) ∣ z.val := by
      exact (CharP.cast_eq_zero_iff (ZMod (2^(d-2))) (2^(d-2)) z.val).mp h_cast
    have h_bound : z.val < 2^(d-1) := ZMod.val_lt z
    have h_cases : z.val = 0 ∨ z.val = 2^(d-2) := by
      obtain ⟨k, hk⟩ := h_div
      have h_pos : 0 < 2^(d-2) := by positivity
      have h_exp : 2^(d-1) = 2 * 2^(d-2) := by
        have h_sub : d - 1 = (d - 2) + 1 := by omega
        rw [h_sub, pow_add, pow_one, mul_comm]
      have h_k : k < 2 := by
        have hk' : k * 2^(d-2) = z.val := by rw [mul_comm]; exact hk.symm
        nlinarith [h_bound, hk', h_pos, h_exp]
      have h_k_eq : k = 0 ∨ k = 1 := by omega
      rcases h_k_eq with h_k_eq | h_k_eq
      · left; rw [hk, h_k_eq]; ring
      · right; rw [hk, h_k_eq]; ring
    rcases h_cases with h_cases | h_cases
    · left
      have h_zero_val : (0 : ZMod (2^(d-1))).val = 0 := ZMod.val_zero
      have h2 : z.val = (0 : ZMod (2^(d-1))).val := by rw [h_cases, h_zero_val]
      exact ZMod.val_injective (2^(d-1)) h2
    · right
      have h_cast2 : (2^(d-2) : ZMod (2^(d-1))) = ((2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; rfl
      have h_target : ((2^(d-2) : ℕ) : ZMod (2^(d-1))).val = 2^(d-2) := by
        have h_bound2 : 2^(d-2) < 2^(d-1) := by
          have h_sub : d - 2 < d - 1 := by omega
          exact Nat.pow_lt_pow_right (by decide) h_sub
        exact ZMod.val_natCast_of_lt h_bound2
      have h2 : z.val = (2^(d-2) : ZMod (2^(d-1))).val := by 
        rw [h_cast2]
        rw [h_target]
        exact h_cases
      exact ZMod.val_injective (2^(d-1)) h2
  · -- Backward: trivial
    rintro (rfl | rfl)
    · simp
    · have h_cast2 : (2^(d-2) : ZMod (2^(d-1))) = ((2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; rfl
      rw [h_cast2]
      rw [pi_natCast]
      have h_div : 2^(d-2) ∣ 2^(d-2) := dvd_refl _
      exact (CharP.cast_eq_zero_iff (ZMod (2^(d-2))) (2^(d-2)) (2^(d-2))).mpr h_div
