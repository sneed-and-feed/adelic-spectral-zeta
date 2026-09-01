import Mathlib.Data.Matrix.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.SchurComplement
import Mathlib.Tactic
import Formalization.Dynamics.CollatzRelMatrix
import Formalization.Spectral.SchreierSpectral
import Formalization.Util.ZMod2
import Formalization.Util.Hadamard

open Matrix
open scoped Matrix
open CollatzDirMatrix

namespace CollatzDirMatrix

noncomputable def sheetSplitDirEquiv {n : ℕ} (hn : n ≥ 2) : ZMod (2^n) ≃ (ZMod (2^(n-1)) × ZMod 2) where
  toFun x := (projDir n (by omega) x, if x.val < 2^(n-1) then 0 else 1)
  invFun p := if p.2 = 0 then liftDir p.1 else liftDir p.1 + ((2^(n-1) : ℕ) : ZMod (2^n))
  left_inv := by
    intro x
    have hn1 : n ≥ 1 := by omega
    have h_x_cast : x = (x.val : ZMod (2^n)) := (ZMod.natCast_zmod_val x).symm
    have h_proj : projDir n hn1 x = (x.val : ZMod (2^(n-1))) := by
      nth_rw 1 [h_x_cast]
      exact map_natCast (projDir n hn1) x.val

    have h_pos : 0 < 2^(n-1) := Nat.two_pow_pos (n-1)
    have h_pow : 2^n = 2^(n-1) * 2 := by
      calc 2^n = 2^(n-1+1) := by congr 1; omega
        _ = 2^(n-1) * 2^1 := pow_add 2 (n-1) 1
        _ = 2^(n-1) * 2 := by rw [pow_one]

    by_cases h : x.val < 2^(n-1)
    · have h1 : (projDir n hn1 x).val = x.val % 2^(n-1) := by rw [h_proj]; exact ZMod.val_natCast (2^(n-1)) x.val
      have h_if : (if x.val < 2^(n-1) then (0:ZMod 2) else 1) = 0 := by simp [h]
      change (if (if x.val < 2^(n-1) then (0:ZMod 2) else 1) = 0 then liftDir (projDir n hn1 x) else liftDir (projDir n hn1 x) + ((2^(n-1) : ℕ) : ZMod (2^n))) = x
      rw [h_if]
      apply ZMod.val_injective
      have h2 : x.val % 2^(n-1) = x.val := Nat.mod_eq_of_lt h
      have h_proj_val : (projDir n hn1 x).val = x.val := by rw [h1, h2]
      change (liftDir (projDir n hn1 x)).val = x.val
      have h_lift : (liftDir (projDir n hn1 x)).val = (projDir n hn1 x).val := by
        change ((projDir n hn1 x).val : ZMod (2^n)).val = _
        apply ZMod.val_natCast_of_lt
        rw [h_proj_val]
        exact ZMod.val_lt x
      rw [h_lift, h_proj_val]
    · have h_if : (if x.val < 2^(n-1) then (0:ZMod 2) else 1) = 1 := by simp [h]
      change (if (if x.val < 2^(n-1) then (0:ZMod 2) else 1) = 0 then liftDir (projDir n hn1 x) else liftDir (projDir n hn1 x) + ((2^(n-1) : ℕ) : ZMod (2^n))) = x
      rw [h_if]
      have h_one_ne_zero : ¬((1:ZMod 2) = 0) := by decide
      simp only [h_one_ne_zero, ↓reduceIte]
      apply ZMod.val_injective
      have h1 : (projDir n hn1 x).val = x.val - 2^(n-1) := by
        rw [h_proj, ZMod.val_natCast (2^(n-1))]
        have h_eq : x.val = (x.val - 2^(n-1)) + 2^(n-1) := by omega
        nth_rw 1 [h_eq]
        rw [Nat.add_mod_right]
        apply Nat.mod_eq_of_lt
        have h_x_lt : x.val < 2^n := ZMod.val_lt x
        omega
      have h_lift : (liftDir (projDir n hn1 x)).val = (projDir n hn1 x).val := by
        change ((projDir n hn1 x).val : ZMod (2^n)).val = _
        apply ZMod.val_natCast_of_lt
        rw [h1]
        have h_x_lt : x.val < 2^n := ZMod.val_lt x
        omega
      have h3 : ((2^(n-1) : ℕ) : ZMod (2^n)).val = 2^(n-1) := by
        apply ZMod.val_natCast_of_lt
        omega
      rw [ZMod.val_add]
      rw [h_lift, h1, h3]
      have h_bound : x.val - 2^(n-1) + 2^(n-1) = x.val := by omega
      rw [h_bound]
      exact Nat.mod_eq_of_lt (ZMod.val_lt x)
  right_inv := by
    rintro ⟨v, b⟩
    have hn1 : n ≥ 1 := by omega
    have h_pos : 0 < 2^(n-1) := Nat.two_pow_pos (n-1)
    have h_pow : 2^n = 2^(n-1) * 2 := by
      calc 2^n = 2^(n-1+1) := by congr 1; omega
        _ = 2^(n-1) * 2^1 := pow_add 2 (n-1) 1
        _ = 2^(n-1) * 2 := by rw [pow_one]
    have h_v_lt : v.val < 2^(n-1) := ZMod.val_lt v

    fin_cases b
    · change (projDir n hn1 (liftDir v), if (liftDir v).val < 2^(n-1) then 0 else 1) = (v, 0)
      have h1 : (liftDir v).val = v.val := by
        change (v.val : ZMod (2^n)).val = v.val
        apply ZMod.val_natCast_of_lt
        omega
      have h2 : (liftDir v).val < 2^(n-1) := by
        rw [h1]
        exact ZMod.val_lt v
      rw [projDir_liftDir hn1]
      simp [h2]
    · change (projDir n hn1 (liftDir v + ((2^(n-1) : ℕ) : ZMod (2^n))), if (liftDir v + ((2^(n-1) : ℕ) : ZMod (2^n))).val < 2^(n-1) then 0 else 1) = (v, 1)
      have h1 : (liftDir v).val = v.val := by
        change (v.val : ZMod (2^n)).val = v.val
        apply ZMod.val_natCast_of_lt
        omega
      have h3 : ((2^(n-1) : ℕ) : ZMod (2^n)).val = 2^(n-1) := by
        apply ZMod.val_natCast_of_lt
        omega
      have h2 : (liftDir v + ((2^(n-1) : ℕ) : ZMod (2^n))).val = v.val + 2^(n-1) := by
        rw [ZMod.val_add]
        rw [h1, h3]
        apply Nat.mod_eq_of_lt
        omega
      have h4 : ¬((liftDir v + ((2^(n-1) : ℕ) : ZMod (2^n))).val < 2^(n-1)) := by
        rw [h2]
        have : v.val ≥ 0 := by exact Nat.zero_le v.val
        omega
      have h_proj : projDir n hn1 (liftDir v + ((2^(n-1) : ℕ) : ZMod (2^n))) = v := by
        rw [RingHom.map_add, projDir_liftDir hn1]
        have h_cast : projDir n hn1 ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
          have : projDir n hn1 ((2^(n-1) : ℕ) : ZMod (2^n)) = ((2^(n-1) : ℕ) : ZMod (2^(n-1))) := by exact map_natCast (projDir n hn1) _
          rw [this]; exact ZMod.natCast_self _
        rw [h_cast, add_zero]
      rw [h_proj]
      simp only [h4, ↓reduceIte]

lemma D'_matrix_eq_reindex {n : ℕ} (hn : n ≥ 2) :
  D'_matrix hn = Matrix.reindex (sheetSplitDirEquiv hn) (sheetSplitDirEquiv hn) (collatzDirMatrix n) := by
  ext ⟨v, s⟩ ⟨u, t⟩
  dsimp [D'_matrix, sheetSplitDirEquiv, Matrix.reindex_apply, Matrix.submatrix_apply]

/-- Internal equivalence between sum type and product type. -/
def sumProdEquivDir {n : ℕ} : (ZMod (2^(n-1))) ⊕ (ZMod (2^(n-1))) ≃ ZMod (2^(n-1)) × ZMod 2 :=
  sumProdEquiv (ZMod (2^(n-1)))

noncomputable def blockDiagDirMatrix {n : ℕ} (hn : n ≥ 2) : 
  Matrix ((ZMod (2^(n-1))) ⊕ (ZMod (2^(n-1)))) ((ZMod (2^(n-1))) ⊕ (ZMod (2^(n-1)))) ℚ :=
  Matrix.fromBlocks (weightedDirMatrix hn) 0 0 (twistedDirMatrix hn)

lemma D'_block_diag_target_eq_blockDiagDirMatrix {n : ℕ} (hn : n ≥ 2) :
  D'_block_diag_target hn = Matrix.reindex sumProdEquivDir sumProdEquivDir (blockDiagDirMatrix hn) := by
  ext ⟨v1, b1⟩ ⟨v2, b2⟩
  fin_cases b1 <;> fin_cases b2 <;> rfl

@[nolint unusedArguments]
lemma conjBlockInv_mul_conjBlock_dir {n : ℕ} (_hn : n ≥ 2) :
  conjBlockInv_dir * conjBlock_dir = (1 : Matrix (ZMod (2^(n-1)) × ZMod 2) (ZMod (2^(n-1)) × ZMod 2) ℚ) :=
  conjBlockInv_mul_conjBlock (ZMod (2^(n-1)))

@[nolint unusedArguments]
lemma conjBlock_mul_conjBlockInv_dir {n : ℕ} (_hn : n ≥ 2) :
  conjBlock_dir (n := n) * conjBlockInv_dir (n := n) = (1 : Matrix (ZMod (2^(n-1)) × ZMod 2) (ZMod (2^(n-1)) × ZMod 2) ℚ) :=
  conjBlock_mul_conjBlockInv (ZMod (2^(n-1)))

/-- The main determinant factorization for the Collatz 2-cover -/
theorem det_collatzDirMatrix_factorization (n : ℕ) (hn : n ≥ 2) (u : ℚ) :
    det (1 - u • collatzDirMatrix n) = 
    det (1 - u • collatzDirMatrix (n - 1)) * det (1 - u • twistedDirMatrix hn) := by
  -- 1. Apply D'_matrix reindexing
  have h1 : det (1 - u • D'_matrix hn) = det (1 - u • collatzDirMatrix n) := by
    rw [D'_matrix_eq_reindex hn]
    have h_eq : 1 - u • Matrix.reindex (sheetSplitDirEquiv hn) (sheetSplitDirEquiv hn) (collatzDirMatrix n) = Matrix.reindex (sheetSplitDirEquiv hn) (sheetSplitDirEquiv hn) (1 - u • collatzDirMatrix n) := by
      ext i j
      simp [Matrix.reindex_apply, Matrix.submatrix_apply, Matrix.sub_apply, Matrix.smul_apply, Matrix.one_apply]
    rw [h_eq]
    exact Matrix.det_reindex_self (sheetSplitDirEquiv hn) (1 - u • collatzDirMatrix n)

  -- 2. D'_matrix is similar to blockDiagTarget
  have h2 : det (1 - u • D'_matrix hn) = det (1 - u • D'_block_diag_target hn) := by
    have h_conj : conjBlockInv_dir * (1 - u • D'_matrix hn) * conjBlock_dir = 1 - u • D'_block_diag_target hn := by
      calc conjBlockInv_dir * (1 - u • D'_matrix hn) * conjBlock_dir
        _ = conjBlockInv_dir * 1 * conjBlock_dir - conjBlockInv_dir * (u • D'_matrix hn) * conjBlock_dir := by
          rw [Matrix.mul_sub, Matrix.sub_mul]
        _ = conjBlockInv_dir * conjBlock_dir - u • (conjBlockInv_dir * D'_matrix hn * conjBlock_dir) := by
          rw [Matrix.mul_one, Matrix.mul_smul, Matrix.smul_mul]
        _ = 1 - u • D'_block_diag_target hn := by
          rw [conjBlockInv_mul_conjBlock_dir hn, D'_block_diag hn]
    have h_det : det (conjBlockInv_dir (n := n) * (1 - u • D'_matrix hn) * conjBlock_dir (n := n)) = det (1 - u • D'_matrix hn) := by
      simp only [det_mul]
      have h_inv : det (conjBlockInv_dir (n := n)) * det (conjBlock_dir (n := n)) = 1 := by
        have : det (conjBlockInv_dir (n := n) * conjBlock_dir (n := n)) = det (1 : Matrix (ZMod (2^(n-1)) × ZMod 2) (ZMod (2^(n-1)) × ZMod 2) ℚ) := by rw [conjBlockInv_mul_conjBlock_dir hn]
        rw [det_mul, det_one] at this
        exact this
      calc det (conjBlockInv_dir (n := n)) * det (1 - u • D'_matrix hn) * det (conjBlock_dir (n := n))
        _ = det (1 - u • D'_matrix hn) * (det (conjBlockInv_dir (n := n)) * det (conjBlock_dir (n := n))) := by ring
        _ = det (1 - u • D'_matrix hn) * 1 := by rw [h_inv]
        _ = det (1 - u • D'_matrix hn) := by ring
    rw [← h_conj, h_det]

  -- 3. blockDiagTarget reindexes to blockDiagMatrix
  have h3 : det (1 - u • D'_block_diag_target hn) = det (1 - u • blockDiagDirMatrix hn) := by
    rw [D'_block_diag_target_eq_blockDiagDirMatrix hn]
    have h_eq : 1 - u • Matrix.reindex sumProdEquivDir sumProdEquivDir (blockDiagDirMatrix hn) = Matrix.reindex sumProdEquivDir sumProdEquivDir (1 - u • blockDiagDirMatrix hn) := by
      ext i j
      simp [Matrix.reindex_apply, Matrix.submatrix_apply, Matrix.sub_apply, Matrix.smul_apply, Matrix.one_apply]
    rw [h_eq]
    exact Matrix.det_reindex_self sumProdEquivDir (1 - u • blockDiagDirMatrix hn)

  -- 4. Det of blockDiagMatrix splits
  have h4 : det (1 - u • blockDiagDirMatrix hn) = det (1 - u • weightedDirMatrix hn) * det (1 - u • twistedDirMatrix hn) := by
    have h_eq : 1 - u • blockDiagDirMatrix hn = Matrix.fromBlocks (1 - u • weightedDirMatrix hn) 0 0 (1 - u • twistedDirMatrix hn) := by
      ext i j
      cases i <;> cases j <;> simp [blockDiagDirMatrix, Matrix.fromBlocks, Matrix.one_apply, Matrix.sub_apply, Matrix.smul_apply]
    rw [h_eq]
    exact det_fromBlocks_zero₂₁ _ _ _

  -- 5. Substitute weighted = D_{n-1}
  have h5 : weightedDirMatrix hn = collatzDirMatrix (n-1) := weightedDirMatrix_eq n hn

  rw [← h1, h2, h3, h4, h5]

end CollatzDirMatrix
