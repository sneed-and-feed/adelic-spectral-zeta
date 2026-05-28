import Mathlib

lemma char_val {n : ℕ} {k : ZMod (2^n)} {χ : AddChar (ZMod (2^n)) ℂ} :
  χ k = χ 1 ^ k.val := by
  have hk : k = k.val • 1 := by
    rw [nsmul_one]
    exact (ZMod.natCast_zmod_val k).symm
  rw [hk]
  have h2 : (k.val • (1 : ZMod (2^n))).val = k.val := by
    rw [nsmul_one]
    exact ZMod.val_natCast_of_lt (ZMod.val_lt k)
  rw [h2]
  exact AddChar.map_nsmul_pow χ k.val 1
