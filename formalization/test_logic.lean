import Formalization.CollatzSpectral

open Matrix CollatzSpectral

open Classical in
lemma two_add_eq_two_iff (A B : Prop) [Decidable A] [Decidable B] :
  ((if A then (1 : ℚ) else 0) + (if B then 1 else 0) = 2) ↔ A ∧ B := by
  split_ifs <;> simp [*] <;> norm_num
