import Formalization.CollatzSpectral

open Matrix
open CollatzSpectral

lemma test_hadamardInv_left_inv {d : ℕ} (hd : d ≥ 3) :
    hadamardInv * hadamardBlock = 1 := by
  rw [hadamardInv]
  rw [Matrix.smul_mul]
  rw [hadamard_sq hd]
  simp
