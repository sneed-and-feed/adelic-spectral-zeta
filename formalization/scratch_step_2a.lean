import Mathlib.Data.Matrix.Basic
import Formalization.CollatzConnectivity
import Formalization.CollatzSpectral

open Matrix
open CollatzSpectral
open Classical

lemma hadamardInv_left_inv_user {d : ℕ} (hd : d ≥ 3) :
    hadamardInv * hadamardBlock = 1 := by
  change ((1/2 : ℚ) • hadamardBlock) * hadamardBlock = 1
  rw [Matrix.smul_mul, hadamard_sq hd]
  ext i j
  fin_cases i <;> fin_cases j <;> simp [Matrix.one_apply] <;> norm_num
