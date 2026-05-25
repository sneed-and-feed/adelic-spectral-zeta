import Mathlib

lemma test (a b x_loop other_x : ℕ) (h_ne : a ≠ b) (h_x_loop : x_loop = a ∨ x_loop = b)
  (h_other : other_x = if x_loop = a then b else a) : other_x ≠ x_loop := by
  rw [h_other]
  split_ifs with h_eq
  · rw [h_eq]
    exact h_ne.symm
  · have h_loop_b : x_loop = b := by
      rcases h_x_loop with h_a | h_b
      · contradiction
      · exact h_b
    rw [h_loop_b]
    exact h_ne
