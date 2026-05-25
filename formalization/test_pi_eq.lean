import Mathlib

lemma pi_eq_zero_iff {d : ℕ} (hd : d ≥ 3) (z : ZMod (2^(d-1))) :
    (ZMod.castHom (show 2^(d-2) ∣ 2^(d-1) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) z) = 0 ↔ 
    z = 0 ∨ z = (2^(d-2) : ZMod (2^(d-1))) := by
  constructor
  · intro hz
    have hz2 : (z.val : ZMod (2^(d-2))) = 0 := by
      calc (z.val : ZMod (2^(d-2))) = ZMod.castHom (show 2^(d-2) ∣ 2^(d-1) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) z := by
            -- ZMod.castHom of z is basically ZMod.cast z.val
            sorry
           _ = 0 := hz
    sorry
  · sorry
