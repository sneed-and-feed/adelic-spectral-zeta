import Mathlib
import Mathlib.Data.Matrix.Basic
import Mathlib.NumberTheory.LegendreSymbol.AddCharacter
import Mathlib.RingTheory.RootsOfUnity.Complex

variable {N : ℕ+} (zeta : ℂ) (hzeta : IsPrimitiveRoot zeta ↑N) (i j : ZMod N)

lemma test : 1 / (N : ℂ) * ↑(if i = j then Fintype.card (ZMod N) else 0) = Matrix.one_apply i j := by
  split_ifs with h_eq
  · have h_card : (Fintype.card (ZMod N) : ℂ) = N := by
      rw [ZMod.card]
      norm_cast
    have hN : (N : ℂ) ≠ 0 := by exact_mod_cast N.ne_zero
    rw [h_card, one_div, inv_mul_cancel hN]
  · simp [mul_zero]
