import Mathlib

lemma two_torsion {d : ℕ} (hd : d ≥ 3) (x : ZMod (2^(d-1))) (h : 2 * x = 0) :
    x = 0 ∨ x = 2^(d-2) := by
  have h2 : x + x = 0 := by
    calc x + x = 2 * x := by ring
         _ = 0 := h
  have h_val : (x + x).val = 0 := by rw [h2, ZMod.val_zero]
  have h_add : (x + x).val = (x.val + x.val) % (2^(d-1)) := ZMod.val_add x x
  rw [h_add] at h_val
  have h_dvd : 2^(d-1) ∣ (x.val + x.val) := Nat.dvd_of_mod_eq_zero h_val
  obtain ⟨k, hk⟩ := h_dvd
  have hx_lt : x.val < 2^(d-1) := ZMod.val_lt x
  have h_pow_pos : 2^(d-1) > 0 := Nat.pos_pow_of_pos _ (by decide)
  have h_k : k = 0 ∨ k = 1 := by
    cases k with
    | zero => left; rfl
    | succ k' =>
      cases k' with
      | zero => right; rfl
      | succ k'' =>
        exfalso
        have h1 : x.val + x.val < 2^(d-1) + 2^(d-1) := by omega
        have h2 : 2^(d-1) + 2^(d-1) = 2^(d-1) * 2 := by ring
        rw [h2] at h1
        have h3 : (k'' + 2) * 2^(d-1) = k'' * 2^(d-1) + 2 * 2^(d-1) := by ring
        have h4 : 2 * 2^(d-1) = 2^(d-1) * 2 := by ring
        rw [h4] at h3
        nlinarith
  rcases h_k with rfl | rfl
  · left
    have : x.val = 0 := by omega
    exact ZMod.val_injective (2^(d-1)) this
  · right
    have h_pow : 2^(d-1) = 2 * 2^(d-2) := by
      have : d - 1 = d - 2 + 1 := by omega
      rw [this, pow_add, pow_one]
    have : x.val = 2^(d-2) := by
      have h1 : x.val + x.val = 2^(d-1) := by omega
      have h2 : x.val + x.val = 2 * x.val := by ring
      rw [h2, h_pow] at h1
      omega
    have h_val2 : (2^(d-2) : ZMod (2^(d-1))).val = 2^(d-2) := by
      apply ZMod.val_natCast_of_lt
      have : d - 1 = d - 2 + 1 := by omega
      rw [this, pow_add, pow_one]
      omega
    have : x.val = (2^(d-2) : ZMod (2^(d-1))).val := by omega
    exact ZMod.val_injective (2^(d-1)) this
