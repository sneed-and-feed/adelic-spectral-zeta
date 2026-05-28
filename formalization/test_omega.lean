import Mathlib

example (n : ℕ) : ((Fin.last (n+1) : Fin (n+2)) : ZMod (n+2)) = ((n+1:ℕ) : ZMod (n+2)) := by
  apply Fin.ext
  change n+1 = (n+1) % (n+2)
  exact (Nat.mod_eq_of_lt (by omega)).symm
