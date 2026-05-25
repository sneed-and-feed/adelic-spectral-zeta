import Mathlib

def G_d (d : ℕ) : SimpleGraph (ZMod (2^(d-1))) where
  Adj x y := 
    x ≠ y ∧ (y = 3 * x ∨ y = 3 * x - 1 ∨ x = 3 * y ∨ x = 3 * y - 1)
  symm := by
    intro x y hxy
    rcases hxy with ⟨hne, h | h | h | h⟩
    · exact ⟨hne.symm, Or.inr (Or.inr (Or.inl h))⟩
    · exact ⟨hne.symm, Or.inr (Or.inr (Or.inr h))⟩
    · exact ⟨hne.symm, Or.inl h⟩
    · exact ⟨hne.symm, Or.inr (Or.inl h)⟩
  loopless := by
    intro x hx
    exact hx.1 rfl

def pi {d : ℕ} (x : ZMod (2^(d-1))) : ZMod (2^(d-2)) :=
  ZMod.castHom (show 2^(d-2) ∣ 2^(d-1) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) x

lemma pi_add {d : ℕ} (x y : ZMod (2^(d-1))) : pi (x + y) = pi x + pi y :=
  map_add _ _ _

lemma pi_natCast {d : ℕ} (n : ℕ) : pi (n : ZMod (2^(d-1))) = (n : ZMod (2^(d-2))) :=
  map_natCast _ _

def tau {d : ℕ} (x : ZMod (2^(d-1))) : ZMod (2^(d-1)) :=
  x + (2^(d-2) : ℕ)

lemma tau_neq {d : ℕ} (hd : d ≥ 3) (x : ZMod (2^(d-1))) : tau x ≠ x := by
  intro h
  have h_zero : ((2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
    calc ((2^(d-2) : ℕ) : ZMod (2^(d-1))) = tau x - x := by
           simp [tau]
           ring
         _ = x - x := by rw [h]
         _ = 0 := sub_self x
  have h_dvd : 2^(d-1) ∣ 2^(d-2) := by
    exact (CharP.cast_eq_zero_iff (ZMod (2^(d-1))) (2^(d-1)) (2^(d-2))).mp h_zero
  have h_pos : 0 < 2^(d-2) := by positivity
  have h_le : 2^(d-1) ≤ 2^(d-2) := Nat.le_of_dvd h_pos h_dvd
  have h_lt : 2^(d-2) < 2^(d-1) := by
    have h_sub : d - 1 = d - 2 + 1 := by omega
    rw [h_sub, pow_add, pow_one]
    omega
  omega

lemma tau_pi {d : ℕ} (hd : d ≥ 3) (x : ZMod (2^(d-1))) : pi (tau x) = pi x := by
  simp [tau, pi_add]
  have h : pi ((2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
    rw [pi_natCast]
    exact ZMod.natCast_self _
  rw [h, add_zero]
