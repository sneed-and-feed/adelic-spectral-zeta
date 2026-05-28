import Mathlib
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Matrix.Kronecker
import Mathlib.NumberTheory.LegendreSymbol.AddCharacter
import Formalization.CollatzRelMatrix

open Matrix Finset Complex CollatzDirMatrix

variable {N : ℕ+} (zeta : ℂ) (hzeta : IsPrimitiveRoot zeta N)

noncomputable def zmodChar_C : AddChar (ZMod N) ℂ := 
  AddChar.zmodChar N hzeta.pow_eq_one

lemma char_neg (x : ZMod N) : (zmodChar_C zeta hzeta) (-x) = ((zmodChar_C zeta hzeta) x)⁻¹ := 
  eq_inv_of_mul_eq_one_left <| by rw [← AddChar.map_add_mul, add_left_neg, AddChar.map_zero_one]

lemma char_star (x : ZMod N) : star (zmodChar_C zeta hzeta x) = zmodChar_C zeta hzeta (-x) := by
  have := Complex.norm_eq_one_of_pow_eq_one hzeta.pow_eq_one N.ne_zero
  have h2 : ‖AddChar.zmodChar N hzeta.pow_eq_one x‖ = 1 := by 
    rw [AddChar.zmodChar_apply, norm_pow, this, one_pow]
  rw [char_neg]
  apply eq_inv_of_mul_eq_one_left
  have hz2 := RCLike.conj_mul (zmodChar_C zeta hzeta x)
  rwa [← RCLike.star_def, h2, Complex.ofReal_one, one_pow] at hz2

