import Mathlib

lemma h_pi_u_fix {d : ℕ} (u : ZMod (2^(d+1))) : 
  (ZMod.castHom (show 2^(d+1) ∣ 2^(d+2) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d+1))) (u.val : ZMod (2^(d+2)))) = u := by
  have h_val_eq : ZMod.castHom (pow_dvd_pow _ (by omega)) (ZMod (2^(d+1))) (u.val : ZMod (2^(d+2))) = (u.val : ZMod (2^(d+1))) := by
    exact ZMod.castHom_natCast _ _ _
  rw [h_val_eq, ZMod.natCast_zmod_val]

lemma pi_eq_zero_iff {d : ℕ} (hd : d ≥ 3) (z : ZMod (2^(d-1))) :
    (ZMod.castHom (show 2^(d-2) ∣ 2^(d-1) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) z) = 0 ↔ 
    z = 0 ∨ z = (2^(d-2) : ZMod (2^(d-1))) := by
  constructor
  · intro hz
    have hz2 : (z.val : ZMod (2^(d-2))) = 0 := by
      calc (z.val : ZMod (2^(d-2))) = ZMod.castHom (pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) z := by
            -- castHom is just casting the value
            have h_cast : ZMod.castHom (pow_dvd_pow 2 (by omega)) (ZMod (2^(d-2))) z = (z.val : ZMod (2^(d-2))) := by
              have h_eq_cast := ZMod.castHom_apply _ z
              sorry
            sorry
           _ = 0 := hz
    have h_dvd : 2^(d-2) ∣ z.val := by
      exact (CharP.cast_eq_zero_iff (ZMod (2^(d-2))) (2^(d-2)) z.val).mp hz2
    have h_lt : z.val < 2^(d-1) := ZMod.val_lt z
    have h_cases : z.val = 0 ∨ z.val = 2^(d-2) := by
      obtain ⟨k, hk⟩ := h_dvd
      have h_pow : 2^(d-1) = 2 * 2^(d-2) := by
        have h_sub : d - 1 = d - 2 + 1 := by omega
        rw [h_sub, pow_add, pow_one]
      rw [h_pow] at h_lt
      have h_k : k < 2 := by
        nlinarith [h_lt, hk, show 2^(d-2) > 0 by exact Nat.pos_pow_of_pos _ (by decide)]
      have hk_cases : k = 0 ∨ k = 1 := by omega
      rcases hk_cases with rfl | rfl
      · left; omega
      · right; omega
    rcases h_cases with h_cases | h_cases
    · left; exact Fin.ext h_cases
    · right; exact Fin.ext h_cases
  · intro hz
    rcases hz with rfl | rfl
    · exact map_zero _
    · rw [map_natCast]
      exact ZMod.natCast_self _
