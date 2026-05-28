import Mathlib
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Matrix.Kronecker
import Mathlib.NumberTheory.LegendreSymbol.AddCharacter
import Formalization.CollatzRelMatrix

open Matrix Finset Complex CollatzDirMatrix

variable {N : ℕ+} (zeta : ℂ) (hzeta : IsPrimitiveRoot zeta N)
noncomputable def zmodChar_C : AddChar (ZMod N) ℂ := AddChar.zmodChar N hzeta.pow_eq_one
noncomputable def dftMatrix : Matrix (ZMod N) (ZMod N) ℂ := fun i j ↦ (1 / Real.sqrt N) * zmodChar_C zeta hzeta (i * j)
noncomputable def dftMatrix_star : Matrix (ZMod N) (ZMod N) ℂ := fun i j ↦ star (dftMatrix zeta hzeta j i)

lemma char_neg (x : ZMod N) : (zmodChar_C zeta hzeta) (-x) = ((zmodChar_C zeta hzeta) x)⁻¹ := by
  apply eq_inv_of_mul_eq_one_left; rw [← AddChar.map_add_mul, add_left_neg, AddChar.map_zero_one]

lemma char_star (x : ZMod N) : star (zmodChar_C zeta hzeta x) = zmodChar_C zeta hzeta (-x) := by
  rw [char_neg]
  have h_norm : ‖zmodChar_C zeta hzeta x‖ = 1 := by rw [AddChar.zmodChar_apply, norm_pow, Complex.norm_eq_one_of_pow_eq_one hzeta.pow_eq_one N.ne_zero, one_pow]
  apply eq_inv_of_mul_eq_one_left
  rw [RCLike.star_def, RCLike.conj_mul, show (‖zmodChar_C zeta hzeta x‖ : ℂ)^2 = 1 by simp [h_norm]]

lemma dft_mul_star : dftMatrix zeta hzeta * dftMatrix_star zeta hzeta = 1 := by
  ext i j
  simp only [mul_apply, one_apply, dftMatrix, dftMatrix_star]
  have hs : star (1 / (Real.sqrt N : ℂ)) = 1 / (Real.sqrt N : ℂ) := by simp [star_div']
  have hs2 : (1 / (Real.sqrt N : ℂ)) * (1 / (Real.sqrt N : ℂ)) = 1 / (N : ℂ) := by
    calc _ = 1 / (Real.sqrt N : ℂ)^2 := by ring _ = 1 / N := by congr 1; norm_cast; exact Real.sq_sqrt (by positivity)
  have h_sum : (∑ k : ZMod N, (1 / (Real.sqrt N : ℂ) * zmodChar_C zeta hzeta (i * k)) * star (1 / (Real.sqrt N : ℂ) * zmodChar_C zeta hzeta (j * k))) = ∑ k : ZMod N, (1 / (N : ℂ)) * zmodChar_C zeta hzeta (k * (i - j)) := by
    apply sum_congr rfl; intro k _
    rw [star_mul', char_star, hs]
    calc _ = ((1 / (Real.sqrt N : ℂ)) * (1 / (Real.sqrt N : ℂ))) * (zmodChar_C zeta hzeta (i * k) * zmodChar_C zeta hzeta (-(j * k))) := by ring
      _ = (1 / (N : ℂ)) * zmodChar_C zeta hzeta (k * (i - j)) := by rw [hs2, ← AddChar.map_add_mul]; congr 2; ring
  rw [h_sum, ← Finset.mul_sum, AddChar.sum_mulShift (i - j) (AddChar.zmodChar_primitive_of_primitive_root N hzeta)]
  have h_iff : i - j = 0 ↔ i = j := sub_eq_zero
  simp_rw [h_iff]; split_ifs
  · rw [ZMod.card, one_div, inv_mul_cancel (by exact_mod_cast N.ne_zero)]
  · simp

lemma dft_star_mul : dftMatrix_star zeta hzeta * dftMatrix zeta hzeta = 1 := by
  ext i j
  simp only [mul_apply, one_apply, dftMatrix, dftMatrix_star]
  have hs : star (1 / (Real.sqrt N : ℂ)) = 1 / (Real.sqrt N : ℂ) := by simp [star_div']
  have hs2 : (1 / (Real.sqrt N : ℂ)) * (1 / (Real.sqrt N : ℂ)) = 1 / (N : ℂ) := by
    calc _ = 1 / (Real.sqrt N : ℂ)^2 := by ring _ = 1 / N := by congr 1; norm_cast; exact Real.sq_sqrt (by positivity)
  have h_sum : (∑ k : ZMod N, star (1 / (Real.sqrt N : ℂ) * zmodChar_C zeta hzeta (k * i)) * (1 / (Real.sqrt N : ℂ) * zmodChar_C zeta hzeta (k * j))) = ∑ k : ZMod N, (1 / (N : ℂ)) * zmodChar_C zeta hzeta (k * (j - i)) := by
    apply sum_congr rfl; intro k _
    rw [star_mul', char_star, hs]
    calc _ = ((1 / (Real.sqrt N : ℂ)) * (1 / (Real.sqrt N : ℂ))) * (zmodChar_C zeta hzeta (-(k * i)) * zmodChar_C zeta hzeta (k * j)) := by ring
      _ = (1 / (N : ℂ)) * zmodChar_C zeta hzeta (k * (j - i)) := by rw [hs2, ← AddChar.map_add_mul]; congr 2; ring
  rw [h_sum, ← Finset.mul_sum, AddChar.sum_mulShift (j - i) (AddChar.zmodChar_primitive_of_primitive_root N hzeta)]
  have h_iff : j - i = 0 ↔ i = j := by constructor <;> intro h <;> [exact sub_eq_zero.mp h |>.symm; rw [h, sub_self]]
  simp_rw [h_iff]; split_ifs
  · rw [ZMod.card, one_div, inv_mul_cancel (by exact_mod_cast N.ne_zero)]
  · simp
