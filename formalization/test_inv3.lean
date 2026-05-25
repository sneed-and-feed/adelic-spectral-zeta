import Mathlib

lemma coprime_3_2_pow {d : ℕ} : Nat.Coprime 3 (2^(d-1)) := by
  have h1 : Nat.Coprime 3 2 := by decide
  exact Nat.Coprime.pow_right (d-1) h1

def inv3 {d : ℕ} (hd : d ≥ 3) : ZMod (2^(d-1)) :=
  (ZMod.unitOfCoprime 3 (coprime_3_2_pow (d:=d))).inv

lemma three_mul_inv3 {d : ℕ} (hd : d ≥ 3) : (3 : ZMod (2^(d-1))) * inv3 hd = 1 := by
  have h := (ZMod.unitOfCoprime 3 (coprime_3_2_pow (d:=d))).mul_inv
  exact h

lemma inv3_mul_three {d : ℕ} (hd : d ≥ 3) : inv3 hd * (3 : ZMod (2^(d-1))) = 1 := by
  rw [mul_comm]
  exact three_mul_inv3 hd

def pi {d : ℕ} (x : ZMod (2^(d-1))) : ZMod (2^(d-2)) :=
  ZMod.castHom (show 2^(d-2) ∣ 2^(d-1) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) x

lemma pi_natCast {d : ℕ} (n : ℕ) : pi (n : ZMod (2^(d-1))) = (n : ZMod (2^(d-2))) := by
  exact ZMod.castHom_natCast _ _ _

lemma pi_mul {d : ℕ} (x y : ZMod (2^(d-1))) : pi (x * y) = pi x * pi y :=
  map_mul _ _ _

lemma pi_inv3 {d : ℕ} (hd : d ≥ 3) : pi (inv3 hd) = inv3 (by omega) := by
  have hd_minus : d - 1 ≥ 3 := by omega
  have h1 : (3 : ZMod (2^(d-1))) * inv3 hd = 1 := three_mul_inv3 hd
  have h2 : pi ((3 : ZMod (2^(d-1))) * inv3 hd) = pi 1 := by rw [h1]
  rw [pi_mul] at h2
  have h3 : pi (3 : ZMod (2^(d-1))) = (3 : ZMod (2^(d-2))) := by
    have : (3 : ZMod (2^(d-1))) = ((3 : ℕ) : ZMod (2^(d-1))) := by rfl
    rw [this, pi_natCast]
    rfl
  rw [h3] at h2
  have h4 : pi 1 = 1 := map_one _
  rw [h4] at h2
  -- now 3 * pi (inv3 hd) = 1
  -- multiply both sides by inv3 hd_minus
  have h5 : inv3 hd_minus * (3 * pi (inv3 hd)) = inv3 hd_minus * 1 := congrArg (fun x => inv3 hd_minus * x) h2
  rw [←mul_assoc, inv3_mul_three hd_minus, one_mul, mul_one] at h5
  exact h5.symm
