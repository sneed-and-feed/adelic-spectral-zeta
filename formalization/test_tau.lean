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

def tau {d : ℕ} (x : ZMod (2^(d-1))) : ZMod (2^(d-1)) :=
  x + (2^(d-2) : ℕ)

lemma tau_tau {d : ℕ} (hd : d ≥ 3) (x : ZMod (2^(d-1))) : tau (tau x) = x := by
  simp [tau]
  have h : (2^(d-2) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) = 0 := by
    have h_pow : 2^(d-2) + 2^(d-2) = 2^(d-1) := by
      have hd_sub : d - 1 = d - 2 + 1 := by omega
      rw [hd_sub, pow_add, pow_one]
      ring
    have h_cast : (2^(d-2) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) = ((2^(d-2) + 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; rfl
    rw [h_cast, h_pow]
    exact ZMod.natCast_self _
  rw [add_assoc, h, add_zero]

lemma tau_is_hom {d : ℕ} (hd : d ≥ 3) {x y : ZMod (2^(d-1))} :
    (G_d d).Adj x y → (G_d d).Adj (tau x) (tau y) := by
  intro hxy
  rcases hxy with ⟨hne, h | h | h | h⟩
  · refine ⟨?_, Or.inl ?_⟩
    · intro h_eq
      apply hne
      calc x = tau (tau x) := (tau_tau hd x).symm
           _ = tau (tau y) := by rw [h_eq]
           _ = y := tau_tau hd y
    · simp [tau]
      have h_zero : ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
        have h_pow : 2 * 2^(d-2) = 2^(d-1) := by
          have hd_sub : d - 1 = d - 2 + 1 := by omega
          rw [hd_sub, pow_add, pow_one, mul_comm]
        rw [h_pow]
        exact ZMod.natCast_self _
      calc y + ↑(2 ^ (d - 2)) = 3 * x + ↑(2 ^ (d - 2)) := by rw [h]
           _ = 3 * (x + ↑(2 ^ (d - 2))) - ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; ring
           _ = 3 * (x + ↑(2 ^ (d - 2))) - 0 := by rw [h_zero]
           _ = 3 * (x + ↑(2 ^ (d - 2))) := by ring
  · refine ⟨?_, Or.inr (Or.inl ?_)⟩
    · intro h_eq
      apply hne
      calc x = tau (tau x) := (tau_tau hd x).symm
           _ = tau (tau y) := by rw [h_eq]
           _ = y := tau_tau hd y
    · simp [tau]
      have h_zero : ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
        have h_pow : 2 * 2^(d-2) = 2^(d-1) := by
          have hd_sub : d - 1 = d - 2 + 1 := by omega
          rw [hd_sub, pow_add, pow_one, mul_comm]
        rw [h_pow]
        exact ZMod.natCast_self _
      calc y + ↑(2 ^ (d - 2)) = 3 * x - 1 + ↑(2 ^ (d - 2)) := by rw [h]
           _ = 3 * (x + ↑(2 ^ (d - 2))) - 1 - ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; ring
           _ = 3 * (x + ↑(2 ^ (d - 2))) - 1 - 0 := by rw [h_zero]
           _ = 3 * (x + ↑(2 ^ (d - 2))) - 1 := by ring
  · refine ⟨?_, Or.inr (Or.inr (Or.inl ?_))⟩
    · intro h_eq
      apply hne
      calc x = tau (tau x) := (tau_tau hd x).symm
           _ = tau (tau y) := by rw [h_eq]
           _ = y := tau_tau hd y
    · simp [tau]
      have h_zero : ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
        have h_pow : 2 * 2^(d-2) = 2^(d-1) := by
          have hd_sub : d - 1 = d - 2 + 1 := by omega
          rw [hd_sub, pow_add, pow_one, mul_comm]
        rw [h_pow]
        exact ZMod.natCast_self _
      calc x + ↑(2 ^ (d - 2)) = 3 * y + ↑(2 ^ (d - 2)) := by rw [h]
           _ = 3 * (y + ↑(2 ^ (d - 2))) - ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; ring
           _ = 3 * (y + ↑(2 ^ (d - 2))) - 0 := by rw [h_zero]
           _ = 3 * (y + ↑(2 ^ (d - 2))) := by ring
  · refine ⟨?_, Or.inr (Or.inr (Or.inr ?_))⟩
    · intro h_eq
      apply hne
      calc x = tau (tau x) := (tau_tau hd x).symm
           _ = tau (tau y) := by rw [h_eq]
           _ = y := tau_tau hd y
    · simp [tau]
      have h_zero : ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
        have h_pow : 2 * 2^(d-2) = 2^(d-1) := by
          have hd_sub : d - 1 = d - 2 + 1 := by omega
          rw [hd_sub, pow_add, pow_one, mul_comm]
        rw [h_pow]
        exact ZMod.natCast_self _
      calc x + ↑(2 ^ (d - 2)) = 3 * y - 1 + ↑(2 ^ (d - 2)) := by rw [h]
           _ = 3 * (y + ↑(2 ^ (d - 2))) - 1 - ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; ring
           _ = 3 * (y + ↑(2 ^ (d - 2))) - 1 - 0 := by rw [h_zero]
           _ = 3 * (y + ↑(2 ^ (d - 2))) - 1 := by ring

def tau_hom {d : ℕ} (hd : d ≥ 3) : (G_d d) →g (G_d d) where
  toFun := tau
  map_rel' := @tau_is_hom d hd
