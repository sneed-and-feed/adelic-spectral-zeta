import Mathlib

lemma cast_comp_cast {c d e : ℕ} (h1 : d ≤ c) (h2 : e ≤ d) (x : ZMod (2^c)) :
  (ZMod.cast (ZMod.cast x : ZMod (2^d)) : ZMod (2^e)) = (ZMod.cast x : ZMod (2^e)) := by
  let f1 := ZMod.castHom (pow_dvd_pow 2 h1) (ZMod (2^d))
  let f2 := ZMod.castHom (pow_dvd_pow 2 h2) (ZMod (2^e))
  let f3 := ZMod.castHom (pow_dvd_pow 2 (le_trans h2 h1)) (ZMod (2^e))
  have h_comp : f2.comp f1 = f3 := ZMod.castHom_comp _ _
  have h_eval : (f2.comp f1) x = f3 x := by rw [h_comp]
  exact h_eval
