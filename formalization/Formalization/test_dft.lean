
import Mathlib
import Mathlib.Data.Matrix.Basic
import Mathlib.NumberTheory.LegendreSymbol.AddCharacter

open Matrix
open Finset
open Complex

variable {N : ℕ+} (zeta : ℂ) (hzeta : IsPrimitiveRoot zeta N)

-- Construct the zmodChar for ZMod N.
noncomputable def zmodChar_C : AddChar (ZMod N) ℂ := 
  AddChar.zmodChar N hzeta.pow_eq_one

-- Define the DFT Matrix
noncomputable def dftMatrix : Matrix (ZMod N) (ZMod N) ℂ :=
  fun i j ↦ (1 / Real.sqrt N) * zmodChar_C zeta hzeta (i * j)

-- Star (conjugate transpose) of the DFT Matrix
noncomputable def dftMatrix_star : Matrix (ZMod N) (ZMod N) ℂ :=
  fun i j ↦ star (dftMatrix zeta hzeta j i)

lemma dft_mul_star :
    dftMatrix zeta hzeta * dftMatrix_star zeta hzeta = 1 := by
  sorry
