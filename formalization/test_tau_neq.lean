import Mathlib

def tau {d : ℕ} (x : ZMod (2^(d-1))) : ZMod (2^(d-1)) :=
  x + (2^(d-2) : ℕ)

lemma tau_neq {d : ℕ} (hd : d ≥ 3) (x : ZMod (2^(d-1))) : tau x ≠ x := by
  intro h
  have h_zero : ((2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
    calc ((2^(d-2) : ℕ) : ZMod (2^(d-1))) = tau x - x := by
           dsimp [tau]
           ring
         _ = 0 := by
           rw [h]
           exact sub_self x
  sorry
