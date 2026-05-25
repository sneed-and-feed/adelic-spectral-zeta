import Mathlib

def pi {d : ℕ} (x : ZMod (2^(d-1))) : ZMod (2^(d-2)) :=
  ZMod.castHom (show 2^(d-2) ∣ 2^(d-1) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) x

lemma pi_mul {d : ℕ} (x y : ZMod (2^(d-1))) : pi (x * y) = pi x * pi y :=
  map_mul _ _ _

lemma pi_natCast {d : ℕ} (n : ℕ) : pi (n : ZMod (2^(d-1))) = (n : ZMod (2^(d-2))) :=
  map_natCast _ _

def inv3 {d : ℕ} (hd : d ≥ 3) : ZMod (2^(d-1)) :=
  (3 : ZMod (2^(d-1)))⁻¹

lemma inv3_mul_three {d : ℕ} (hd : d ≥ 3) : (inv3 hd) * (3 : ZMod (2^(d-1))) = 1 := by
  sorry

lemma pi_inv3 {d : ℕ} (hd : d ≥ 3) : pi (inv3 hd) * (3 : ZMod (2^(d-2))) = 1 := by
  have h1 : (inv3 hd) * (3 : ZMod (2^(d-1))) = 1 := inv3_mul_three hd
  have h2 := congrArg pi h1
  rw [pi_mul] at h2
  have h3 : pi (3 : ZMod (2^(d-1))) = (3 : ZMod (2^(d-2))) := by
    have h_cast1 : (3 : ZMod (2^(d-1))) = ((3 : ℕ) : ZMod (2^(d-1))) := by exact Eq.symm Nat.cast_ofNat
    have h_cast2 : (3 : ZMod (2^(d-2))) = ((3 : ℕ) : ZMod (2^(d-2))) := by exact Eq.symm Nat.cast_ofNat
    rw [h_cast1, h_cast2, pi_natCast]
  rw [h3] at h2
  have h4 : pi (1 : ZMod (2^(d-1))) = (1 : ZMod (2^(d-2))) := by
    have h_cast1 : (1 : ZMod (2^(d-1))) = ((1 : ℕ) : ZMod (2^(d-1))) := by exact Eq.symm Nat.cast_one
    have h_cast2 : (1 : ZMod (2^(d-2))) = ((1 : ℕ) : ZMod (2^(d-2))) := by exact Eq.symm Nat.cast_one
    rw [h_cast1, h_cast2, pi_natCast]
  rw [h4] at h2
  exact h2
