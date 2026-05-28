import Mathlib
import Formalization.CyclotomicProduct

open Matrix Finset Complex

lemma star_W1 {n : ℕ} (C : Finset (ZMod (2^n)))
  (χ : AddChar (ZMod (2^n)) ℂ)
  (hχ : IsPrimitiveRoot (χ 1) (⟨2^n, by positivity⟩ : ℕ+)) :
  star (W_1 (χ 1) C) = W_2 (χ 1) (C.image (-·)) := by
  let ζ := χ 1
  dsimp [W_1, W_2]
  rw [map_prod]
  sorry
