import Mathlib
import Formalization.RamanujanTau

-- We can write tau 2 computationally
-- tau n is coefficient of X^n in X * prod_{k=1}^n (1 - X^k)^24
-- For n=2, X * (1 - X)^24 * (1 - X^2)^24
-- So coeff of X^2 is the coeff of X^1 in (1 - X)^24 * (1 - X^2)^24
-- Coeff of X^1 in (1 - X)^24 is -24.

-- We can just prove it for n=2.

lemma tau_two : tau 2 = -24 := by
  sorry
