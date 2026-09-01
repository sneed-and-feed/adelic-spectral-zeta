import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Matrix.Block
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Tactic
import Formalization.Util.ZMod2

/-!
# Hadamard Transformation Utilities

Shared definitions and algebraic properties of the 2x2 Hadamard matrix
and tensor product conjugation block matrices.
-/

open Matrix
open scoped Matrix BigOperators

/-- The standard 2x2 Hadamard matrix over ℚ. -/
def hadamardBlock : Matrix (ZMod 2) (ZMod 2) ℚ
  | 0, 0 => 1
  | 0, 1 => 1
  | 1, 0 => 1
  | 1, 1 => -1

lemma hadamardBlock_00 : hadamardBlock (0 : ZMod 2) (0 : ZMod 2) = 1 := rfl
lemma hadamardBlock_01 : hadamardBlock (0 : ZMod 2) (1 : ZMod 2) = 1 := rfl
lemma hadamardBlock_10 : hadamardBlock (1 : ZMod 2) (0 : ZMod 2) = 1 := rfl
lemma hadamardBlock_11 : hadamardBlock (1 : ZMod 2) (1 : ZMod 2) = -1 := rfl

lemma hadamard_mul_self : hadamardBlock * hadamardBlock = (2 : ℚ) • (1 : Matrix (ZMod 2) (ZMod 2) ℚ) := by
  ext i j
  simp only [Matrix.mul_apply, sum_zmod_two, Matrix.smul_apply, Matrix.one_apply]
  have hi : i = 0 ∨ i = 1 := by fin_cases i <;> tauto
  have hj : j = 0 ∨ j = 1 := by fin_cases j <;> tauto
  rcases hi with rfl | rfl <;> rcases hj with rfl | rfl <;> (dsimp [hadamardBlock]; ring)

/-- The inverse of the 2x2 Hadamard matrix over ℚ. -/
def hadamardInv : Matrix (ZMod 2) (ZMod 2) ℚ := (2 : ℚ)⁻¹ • hadamardBlock

lemma hadamardInv_00 : hadamardInv (0 : ZMod 2) (0 : ZMod 2) = (2:ℚ)⁻¹ := by
  dsimp [hadamardInv, hadamardBlock, Matrix.smul_apply]; ring
lemma hadamardInv_01 : hadamardInv (0 : ZMod 2) (1 : ZMod 2) = (2:ℚ)⁻¹ := by
  dsimp [hadamardInv, hadamardBlock, Matrix.smul_apply]; ring
lemma hadamardInv_10 : hadamardInv (1 : ZMod 2) (0 : ZMod 2) = (2:ℚ)⁻¹ := by
  dsimp [hadamardInv, hadamardBlock, Matrix.smul_apply]; ring
lemma hadamardInv_11 : hadamardInv (1 : ZMod 2) (1 : ZMod 2) = -(2:ℚ)⁻¹ := by
  dsimp [hadamardInv, hadamardBlock, Matrix.smul_apply]; ring

lemma hadamard_inv_mul : hadamardInv * hadamardBlock = 1 := by
  unfold hadamardInv
  rw [Matrix.smul_mul, hadamard_mul_self]
  ext i j
  simp only [Matrix.smul_apply, Matrix.one_apply, smul_eq_mul]
  split_ifs <;> norm_num

lemma hadamard_mul_inv : hadamardBlock * hadamardInv = 1 := by
  unfold hadamardInv
  rw [Matrix.mul_smul, hadamard_mul_self]
  ext i j
  simp only [Matrix.smul_apply, Matrix.one_apply, smul_eq_mul]
  split_ifs <;> norm_num

/-- The tensor product of identity on `m` and Hadamard matrix. -/
def conjBlock (m : Type*) [DecidableEq m] : Matrix (m × ZMod 2) (m × ZMod 2) ℚ :=
  fun ⟨i1, j1⟩ ⟨i2, j2⟩ => if i1 = i2 then hadamardBlock j1 j2 else 0

/-- The tensor product of identity on `m` and Hadamard inverse. -/
def conjBlockInv (m : Type*) [DecidableEq m] : Matrix (m × ZMod 2) (m × ZMod 2) ℚ :=
  fun ⟨i1, j1⟩ ⟨i2, j2⟩ => if i1 = i2 then hadamardInv j1 j2 else 0

lemma conjBlockInv_mul_conjBlock (m : Type*) [Fintype m] [DecidableEq m] :
    conjBlockInv m * conjBlock m = (1 : Matrix (m × ZMod 2) (m × ZMod 2) ℚ) := by
  ext ⟨i1, j1⟩ ⟨i2, j2⟩
  simp only [conjBlockInv, conjBlock, Matrix.mul_apply, Matrix.one_apply, Fintype.sum_prod_type]
  by_cases h : i1 = i2
  · subst h
    have : ∀ k1, (∑ k2, (if i1 = k1 then hadamardInv j1 k2 else 0) * (if k1 = i1 then hadamardBlock k2 j2 else 0))
        = if i1 = k1 then ∑ k2, hadamardInv j1 k2 * hadamardBlock k2 j2 else 0 := by
      intro k1
      by_cases hk : i1 = k1 <;> simp [hk]
    simp_rw [this]
    have h_inv : (∑ k2 : ZMod 2, hadamardInv j1 k2 * hadamardBlock k2 j2) = if j1 = j2 then (1 : ℚ) else 0 := by
      calc (∑ k2 : ZMod 2, hadamardInv j1 k2 * hadamardBlock k2 j2)
        _ = (hadamardInv * hadamardBlock) j1 j2 := rfl
        _ = (1 : Matrix (ZMod 2) (ZMod 2) ℚ) j1 j2 := by rw [hadamard_inv_mul]
        _ = if j1 = j2 then (1 : ℚ) else 0 := by rw [Matrix.one_apply]
    simp_rw [h_inv]
    simp
  · have : ∀ k1 k2, (if i1 = k1 then hadamardInv j1 k2 else 0) * (if k1 = i2 then hadamardBlock k2 j2 else 0) = (0 : ℚ) := by
      intro k1 k2
      by_cases hk1 : i1 = k1
      · subst hk1; simp [h]
      · simp [hk1]
    simp_rw [this]
    simp [h]

lemma conjBlock_mul_conjBlockInv (m : Type*) [Fintype m] [DecidableEq m] :
    conjBlock m * conjBlockInv m = (1 : Matrix (m × ZMod 2) (m × ZMod 2) ℚ) := by
  exact (Matrix.mul_eq_one_comm_of_equiv (Equiv.refl _)).mp (conjBlockInv_mul_conjBlock m)
