import Mathlib

lemma test_cast (d : ℕ) (h : ((2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0) : 2^(d-1) ∣ 2^(d-2) := by
  exact (CharP.cast_eq_zero_iff (ZMod (2^(d-1))) (2^(d-1)) (2^(d-2))).mp h
