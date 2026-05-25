import Mathlib.Data.Matrix.Basic
import Formalization.CollatzConnectivity

open Matrix

variable {d : ℕ}

noncomputable def conjBlockInv (hd : d ≥ 3) : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2)) × ZMod 2) ℚ := sorry
noncomputable def conjBlock (hd : d ≥ 3) : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2)) × ZMod 2) ℚ := sorry
def sheetSplit (hd : d ≥ 3) : ZMod (2^(d-1)) ≃ (ZMod (2^(d-2)) × ZMod 2) := sorry

lemma submatrix_one_eq_one {n m : Type*} [DecidableEq n] [DecidableEq m] {α : Type*} [DecidableEq α] [Zero α] [One α] (e : n ≃ m) :
  (1 : Matrix m m α).submatrix e e = 1 := by
  ext i j
  simp only [Matrix.submatrix_apply, Matrix.one_apply]
  split_ifs with h1 h2 h2
  · rfl
  · exact False.elim (h2 (e.injective h1))
  · exact False.elim (h1 (congr_arg e h2))
  · rfl

lemma test_proof (hd : d ≥ 3) :
  (conjBlockInv hd).submatrix (sheetSplit hd).symm (sheetSplit hd).symm * 
  (conjBlock hd).submatrix (sheetSplit hd).symm (sheetSplit hd).symm = 1 := by
  let e := sheetSplit hd
  have h : conjBlockInv hd * conjBlock hd = 1 := sorry
  rw [Matrix.submatrix_mul_equiv]
  rw [h]
  exact submatrix_one_eq_one e.symm
