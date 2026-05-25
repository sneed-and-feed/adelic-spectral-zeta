import Mathlib

def pi {d : ℕ} (x : ZMod (2^(d-1))) : ZMod (2^(d-2)) :=
  ZMod.castHom (show 2^(d-2) ∣ 2^(d-1) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) x

lemma pi_add {d : ℕ} (x y : ZMod (2^(d-1))) : pi (x + y) = pi x + pi y :=
  map_add _ _ _

lemma pi_natCast {d : ℕ} (n : ℕ) : pi (n : ZMod (2^(d-1))) = (n : ZMod (2^(d-2))) :=
  map_natCast _ _

def tau {d : ℕ} (x : ZMod (2^(d-1))) : ZMod (2^(d-1)) :=
  x + (2^(d-2) : ℕ)

lemma tau_pi {d : ℕ} (hd : d ≥ 3) (x : ZMod (2^(d-1))) : pi (tau x) = pi x := by
  change pi (x + ((2^(d-2) : ℕ) : ZMod (2^(d-1)))) = pi x
  rw [pi_add, pi_natCast]
  have h_zero : ((2^(d-2) : ℕ) : ZMod (2^(d-2))) = 0 := ZMod.natCast_self _
  rw [h_zero, add_zero]
