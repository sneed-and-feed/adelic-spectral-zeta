import Mathlib
lemma test (n : ℕ) : (⟨2^(n-2), Nat.two_pow_pos _⟩ : ℕ+) = ⟨2^(n-2), by positivity⟩ := by rfl