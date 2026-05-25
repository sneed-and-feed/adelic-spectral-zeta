import Mathlib

def pi {d : ℕ} (x : ZMod (2^(d-1))) : ZMod (2^(d-2)) :=
  ZMod.castHom (show 2^(d-2) ∣ 2^(d-1) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) x

lemma pi_natCast {d : ℕ} (n : ℕ) : pi (n : ZMod (2^(d-1))) = (n : ZMod (2^(d-2))) := by
  exact ZMod.castHom_natCast _ _ _

lemma pi_add {d : ℕ} (x y : ZMod (2^(d-1))) : pi (x + y) = pi x + pi y :=
  map_add _ _ _

lemma nontrivial_loop_lift_part {d : ℕ} (hd : d ≥ 3) :
    let y := (2^(d-3) : ZMod (2^(d-2)))
    let x₂ := (2^(d-3) + 2^(d-2) : ZMod (2^(d-1)))
    pi x₂ = y := by
  intro y x₂
  simp [x₂, y]
  rw [pi_add]
  have h_pi_1 : pi (2^(d-3) : ZMod (2^(d-1))) = (2^(d-3) : ZMod (2^(d-2))) := by
    have h_cast : (2^(d-3) : ZMod (2^(d-1))) = ((2^(d-3) : ℕ) : ZMod (2^(d-1))) := by push_cast; rfl
    rw [h_cast, pi_natCast]
    push_cast; rfl
  have h_pi_2 : pi (2^(d-2) : ZMod (2^(d-1))) = 0 := by
    have h_cast : (2^(d-2) : ZMod (2^(d-1))) = ((2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; rfl
    rw [h_cast, pi_natCast]
    have : ((2^(d-2) : ℕ) : ZMod (2^(d-2))) = 0 := ZMod.natCast_self _
    exact this
  rw [h_pi_1, h_pi_2, add_zero]
