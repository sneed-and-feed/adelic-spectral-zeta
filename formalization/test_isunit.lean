import Mathlib

lemma test_2v {d : ℕ} (v : ZMod (2^(d-2))) (h_6v : 6 * v = 0) : 2 * v = 0 := by
  have h_unit : IsUnit (3 : ZMod (2^(d-2))) := by
    have h_cast : (3 : ZMod (2^(d-2))) = ((3 : ℕ) : ZMod (2^(d-2))) := by rfl
    rw [h_cast, ZMod.isUnit_iff_coprime]
    have h1 : Nat.Coprime 3 2 := by decide
    exact Nat.Coprime.pow_right (d-2) h1
  have h_6 : (3 : ZMod (2^(d-2))) * (2 * v) = 0 := by
    calc 3 * (2 * v) = 6 * v := by ring
         _ = 0 := h_6v
  -- what is the name of the lemma?
  exact (IsUnit.mul_right_eq_zero h_unit).mp h_6
