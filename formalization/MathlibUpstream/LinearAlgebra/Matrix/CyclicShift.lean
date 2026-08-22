import Mathlib.Data.Matrix.Basic
import Mathlib.LinearAlgebra.Matrix.Charpoly.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.RingTheory.Polynomial.Basic

/-!
# Characteristic Polynomial of Cyclic Shift and Weighted Cyclic Matrices

This file proves the characteristic polynomial of a general weighted cyclic shift matrix
over an arbitrary commutative ring `R`.

## Main Definitions
- `shiftMatrix n W`: The `n × n` subdiagonal shift matrix with weights `W : Fin n → R`.
- `upperBidiagonal n W`: An auxiliary upper-bidiagonal polynomial matrix whose determinant
  computes the off-diagonal minor in the cofactor expansion.
- `cyclicWeightMatrix W`: The `L × L` cyclic matrix indexed by `ZMod L` where entry `(i, j)`
  is `W j` if `i = j + 1` and `0` otherwise.

## Main Results
- `charpoly_shiftMatrix`: The characteristic polynomial of `shiftMatrix n W` is `X ^ n`.
- `det_upperBidiagonal`: The determinant of `upperBidiagonal n W` is `∏ i, - C (W i)`.
- `charpoly_cyclicWeightMatrix`: For any `L : ℕ` with `[NeZero L]` and any `W : ZMod L → R`,
  the characteristic polynomial of `cyclicWeightMatrix W` is `X ^ L - C (∏ k, W k)`.

## Tags
matrix, charpoly, cyclic shift, determinant, characteristic polynomial
-/

open Matrix Polynomial Finset
open scoped Polynomial

variable {R : Type*} [CommRing R]

/-- The `n × n` subdiagonal shift matrix with weights `W`. -/
def shiftMatrix (n : ℕ) (W : Fin n → R) : Matrix (Fin n) (Fin n) R :=
  fun i j => if (i : ℕ) = (j : ℕ) + 1 then W j else 0

lemma charmatrix_shiftMatrix_submatrix (n : ℕ) (W : Fin (n + 1) → R) :
    (charmatrix (shiftMatrix (n + 1) W)).submatrix Fin.succ Fin.succ =
      charmatrix (shiftMatrix n (fun x => W (Fin.succ x))) := by
  apply Matrix.ext; intro i j
  dsimp [charmatrix, Matrix.submatrix_apply, Matrix.sub_apply, Matrix.diagonal_apply]
  have h_succ_eq : (Fin.succ i = Fin.succ j) ↔ (i = j) := Fin.succ_inj
  have h_succ_add : (Fin.succ i : ℕ) = (Fin.succ j : ℕ) + 1 ↔ (i : ℕ) = (j : ℕ) + 1 := by
    have _hi : (Fin.succ i : ℕ) = (i : ℕ) + 1 := Fin.val_succ i
    have _hj : (Fin.succ j : ℕ) = (j : ℕ) + 1 := Fin.val_succ j
    omega
  simp only [h_succ_eq, h_succ_add, RingHom.mapMatrix_apply, Matrix.map_apply, shiftMatrix]

@[simp]
lemma shiftMatrix_apply_zero (n : ℕ) (W : Fin (n + 1) → R) (b : Fin (n + 1)) :
    shiftMatrix (n + 1) W 0 b = 0 := by
  dsimp [shiftMatrix]

/-- The characteristic polynomial of a nilpotent shift matrix is `X ^ n`. -/
lemma charpoly_shiftMatrix (n : ℕ) (W : Fin n → R) :
    (shiftMatrix n W).charpoly = X ^ n := by
  induction n with
  | zero => rw [Matrix.charpoly, Matrix.det_fin_zero, pow_zero]
  | succ n ih =>
    rw [Matrix.charpoly, Matrix.det_succ_row_zero, Finset.sum_eq_single 0]
    · have h_succ : (Fin.succAbove (0 : Fin (n + 1)) : Fin n → Fin (n + 1)) = Fin.succ := rfl
      rw [h_succ, charmatrix_shiftMatrix_submatrix, ← Matrix.charpoly, ih]
      dsimp [charmatrix, Matrix.sub_apply, Matrix.diagonal_apply, Matrix.map_apply, shiftMatrix_apply_zero]
      simp [pow_succ]
      ring
    · intro b _ hb
      dsimp [charmatrix, Matrix.sub_apply, Matrix.diagonal_apply, Matrix.map_apply, shiftMatrix_apply_zero]
      have hb0 : (0 : Fin (n + 1)) ≠ b := hb.symm
      simp [hb0]
    · simp

/-- Upper-bidiagonal auxiliary matrix for cofactor expansion of cyclic matrices. -/
noncomputable def upperBidiagonal (n : ℕ) (W : Fin n → R) : Matrix (Fin n) (Fin n) (Polynomial R) :=
  fun i j => if (i : ℕ) = (j : ℕ) then - C (W j) else if (i : ℕ) + 1 = (j : ℕ) then X else 0

lemma upperBidiagonal_submatrix (n : ℕ) (W : Fin (n + 1) → R) :
    ((upperBidiagonal (n + 1) W).submatrix Fin.succ Fin.succ) =
      upperBidiagonal n (fun x => W (Fin.succ x)) := by
  apply Matrix.ext; intro i j
  dsimp [upperBidiagonal, Matrix.submatrix_apply]
  have c1 : (i : ℕ) + 1 = (j : ℕ) + 1 ↔ (i : ℕ) = (j : ℕ) := by omega
  have c2 : (i : ℕ) + 1 + 1 = (j : ℕ) + 1 ↔ (i : ℕ) + 1 = (j : ℕ) := by omega
  simp only [c1, c2]

lemma det_upperBidiagonal (n : ℕ) (W : Fin n → R) :
    (upperBidiagonal n W).det = ∏ i : Fin n, - C (W i) := by
  induction n with
  | zero => rw [Matrix.det_fin_zero, Fin.prod_univ_zero]
  | succ n ih =>
    rw [Matrix.det_succ_column_zero, Finset.sum_eq_single 0]
    · change (-1) ^ (0 : ℕ) * _ * ((upperBidiagonal (n + 1) W).submatrix Fin.succ Fin.succ).det = _
      rw [upperBidiagonal_submatrix, ih, Fin.prod_univ_succ]
      dsimp [upperBidiagonal]
      simp
    · intro b _ hb
      have h1 : (b : ℕ) ≠ 0 := Fin.val_ne_of_ne hb
      dsimp [upperBidiagonal]
      simp [h1]
    · simp

variable {L : ℕ} [NeZero L] (W : ZMod L → R)

/-- The cyclic matrix with edge weights `W` along the cyclic shift `j ↦ j + 1`. -/
def cyclicWeightMatrix : Matrix (ZMod L) (ZMod L) R :=
  fun i j => if i = j + 1 then W j else 0

lemma charmatrix_cyclic_submatrix_00 (n : ℕ) (W : ZMod (n + 1 + 1) → R) :
    (charmatrix (Matrix.of fun i j : Fin (n + 1 + 1) => cyclicWeightMatrix W i j)).submatrix Fin.succ Fin.succ =
      charmatrix (shiftMatrix (n + 1) (fun x => W (Fin.succ x))) := by
  apply Matrix.ext; intro i j
  dsimp [charmatrix, Matrix.submatrix_apply, Matrix.sub_apply, Matrix.diagonal_apply]
  simp only [RingHom.mapMatrix_apply, Matrix.map_apply, Matrix.of_apply,
    shiftMatrix, cyclicWeightMatrix, Fin.succ_inj]
  congr 2
  split_ifs with h1 h2 h2
  · rfl
  · exfalso
    have hi : (i : ℕ) < n + 1 := i.is_lt
    have hj : (j : ℕ) < n + 1 := j.is_lt
    have hval := congrArg Fin.val h1
    change (i : ℕ) + 1 = ((j : ℕ) + 1 + 1) % (n + 1 + 1) at hval
    rcases lt_or_eq_of_le (Nat.succ_le_of_lt hj) with hlt | heq
    · rw [Nat.mod_eq_of_lt (by omega)] at hval
      omega
    · have h_mod : ((j : ℕ) + 1 + 1) % (n + 1 + 1) = 0 := by
        have : (j : ℕ) + 1 + 1 = n + 1 + 1 := by omega
        rw [this, Nat.mod_self]
      rw [h_mod] at hval
      omega
  · exfalso
    have hi : (i : ℕ) < n + 1 := i.is_lt
    have hj : (j : ℕ) < n + 1 := j.is_lt
    apply h1
    apply Fin.ext
    change (i : ℕ) + 1 = ((j : ℕ) + 1 + 1) % (n + 1 + 1)
    rw [Nat.mod_eq_of_lt (by omega)]
    omega
  · rfl

lemma charmatrix_cyclic_submatrix_0n (n : ℕ) (W : ZMod (n + 1 + 1) → R) :
    (charmatrix (Matrix.of fun i j : Fin (n + 1 + 1) => cyclicWeightMatrix W i j)).submatrix Fin.succ (Fin.last (n + 1)).succAbove =
      upperBidiagonal (n + 1) (fun x => W (Fin.castSucc x)) := by
  apply Matrix.ext; intro i j
  dsimp [charmatrix, Matrix.submatrix_apply, Matrix.sub_apply, Matrix.diagonal_apply, upperBidiagonal]
  rw [Fin.succAbove_last]
  simp only [RingHom.mapMatrix_apply, Matrix.map_apply, Matrix.of_apply, cyclicWeightMatrix]
  have hi : (i : ℕ) < n + 1 := i.is_lt
  have hj : (j : ℕ) < n + 1 := j.is_lt
  split_ifs with h1 h2 h3 h4 h5 h6 h7 h8 <;> try { simp [map_zero] } <;> try {
    exfalso
    first
    | have hval := congrArg Fin.val h1; dsimp at hval; omega
    | have hval1 := congrArg Fin.val h1; have hval2 := congrArg Fin.val h2; dsimp at hval1; change (i : ℕ) + 1 = ((j : ℕ) + 1) % (n + 1 + 1) at hval2; rw [Nat.mod_eq_of_lt (by omega)] at hval2; omega
    | have hval := congrArg Fin.val h7; change (i : ℕ) + 1 = ((j : ℕ) + 1) % (n + 1 + 1) at hval; rw [Nat.mod_eq_of_lt (by omega)] at hval; omega
    | apply h1; apply Fin.ext; dsimp; omega
    | apply h7; apply Fin.ext; change (i : ℕ) + 1 = ((j : ℕ) + 1) % (n + 1 + 1); rw [Nat.mod_eq_of_lt (by omega)]; omega
  }

lemma prod_ZMod (n : ℕ) (W : ZMod (n + 1 + 1) → R) :
    (∏ k : ZMod (n + 1 + 1), W k) = (∏ i : Fin n, W (Fin.castSucc i).succ) * W (Fin.last (n + 1) : ZMod (n + 1 + 1)) * W 0 := by
  have h1 : (∏ k : ZMod (n + 1 + 1), W k) = (∏ k : Fin (n + 1 + 1), (W k : R)) := rfl
  rw [h1, Fin.prod_univ_castSucc (fun k : Fin (n + 1 + 1) => W k), Fin.prod_univ_succ (fun k : Fin (n + 1) => W (Fin.castSucc k))]
  have h_eq : (∏ i : Fin n, W (Fin.castSucc (Fin.succ i) : ZMod (n + 1 + 1))) = ∏ i : Fin n, W ((Fin.castSucc i).succ : ZMod (n + 1 + 1)) := rfl
  rw [h_eq]
  have h0 : (Fin.castSucc (0 : Fin (n + 1)) : ZMod (n + 1 + 1)) = (0 : ZMod (n + 1 + 1)) := rfl
  rw [h0]
  ring

/-- The characteristic polynomial of an `L × L` cyclic weight matrix is `X ^ L - ∏ W`. -/
theorem charpoly_cyclicWeightMatrix :
    (cyclicWeightMatrix W).charpoly = X ^ L - C (∏ k : ZMod L, W k) := by
  cases L with
  | zero => exact (NeZero.ne 0 rfl).elim
  | succ m =>
    cases m with
    | zero =>
      have h_charpoly : (cyclicWeightMatrix W).charpoly = (Matrix.of fun (i j : Fin 1) => cyclicWeightMatrix W i j).charpoly := rfl
      rw [h_charpoly, Matrix.charpoly, Matrix.det_fin_one]
      change X - C (if ((0 : Fin 1) : ZMod 1) = ((0 : Fin 1) : ZMod 1) + 1 then W ((0 : Fin 1) : ZMod 1) else 0) = X ^ 1 - C (∏ k : ZMod 1, W k)
      have h2 : ((0 : Fin 1) : ZMod 1) = ((0 : Fin 1) : ZMod 1) + 1 := Subsingleton.elim _ _
      have h_prod : (∏ k : ZMod 1, W k) = W (0 : ZMod 1) := by
        have h_equiv : (∏ k : ZMod 1, W k) = ∏ k : Fin 1, (W k : R) := rfl
        rw [h_equiv]
        exact Fin.prod_univ_one (fun k : Fin 1 => W k)
      rw [if_pos h2, pow_one, h_prod]
      rfl
    | succ n =>
      have h_charpoly : (cyclicWeightMatrix W).charpoly = (Matrix.of fun (i j : Fin (n + 1 + 1)) => cyclicWeightMatrix W i j).charpoly := rfl
      rw [h_charpoly]
      rw [Matrix.charpoly, Matrix.det_succ_row_zero, Finset.sum_eq_add_of_mem 0 (Fin.last (n + 1))]
      · have h_succ : (Fin.succAbove (0 : Fin (n + 1 + 1)) : Fin (n + 1) → Fin (n + 1 + 1)) = Fin.succ := rfl
        rw [h_succ]
        rw [charmatrix_cyclic_submatrix_00]
        have h_shift := charpoly_shiftMatrix (n + 1) (fun x => W (Fin.succ x))
        rw [Matrix.charpoly] at h_shift
        rw [h_shift]
        rw [charmatrix_cyclic_submatrix_0n, det_upperBidiagonal]
        have h_pow : (-1 : Polynomial R) ^ (Fin.last (n + 1) : ℕ) = (-1) ^ (n + 1) := rfl
        rw [h_pow]
        rw [prod_ZMod]
        rw [Fin.prod_univ_succ (fun i : Fin (n + 1) => -C (W (Fin.castSucc i)))]
        rw [Matrix.charmatrix_apply, Matrix.diagonal_apply, Matrix.charmatrix_apply, Matrix.diagonal_apply]
        dsimp [cyclicWeightMatrix, Matrix.of_apply]
        have h_prod_neg : (∏ i : Fin n, -C (W (Fin.castSucc i).succ)) = (-1 : Polynomial R) ^ n * ∏ i : Fin n, C (W (Fin.castSucc i).succ) := by
          have : ∀ i, -C (W (Fin.castSucc i).succ) = (-1 : Polynomial R) * C (W (Fin.castSucc i).succ) := fun i => by ring
          simp_rw [this]
          rw [Finset.prod_mul_distrib]
          have h_const : (∏ i : Fin n, (-1 : Polynomial R)) = (-1 : Polynomial R) ^ n := by
            have hc : (Finset.univ : Finset (Fin n)).card = n := Fintype.card_fin n
            have : (∏ i : Fin n, (-1 : Polynomial R)) = (-1 : Polynomial R) ^ (Finset.univ : Finset (Fin n)).card := Finset.prod_const (-1 : Polynomial R)
            rw [this, hc]
          rw [h_const]
        rw [h_prod_neg]
        split_ifs with h1 h2 h3
        · exfalso
          have hval := congrArg Fin.val h1
          change 0 = (0 + 1) % (n + 1 + 1) at hval
          rw [Nat.mod_eq_of_lt (by omega)] at hval
          omega
        · exfalso
          have hval := congrArg Fin.val h1
          change 0 = (0 + 1) % (n + 1 + 1) at hval
          rw [Nat.mod_eq_of_lt (by omega)] at hval
          omega
        · simp only [pow_zero, map_zero, sub_zero, one_mul, zero_sub]
          have h_term1 : (X : Polynomial R) * X ^ (n + 1) = X ^ (n + 1 + 1) := by
            have : (X : Polynomial R) = X ^ 1 := (pow_one X).symm
            nth_rw 1 [this]
            rw [← pow_add]
            congr 1
            omega
          rw [h_term1]
          have h_pow_even : (-1 : Polynomial R) ^ (n * 2) = 1 := by
            have h1 : (-1 : Polynomial R) ^ (n * 2) = ((-1 : Polynomial R) ^ 2) ^ n := by
              have : n * 2 = 2 * n := mul_comm n 2
              rw [this, pow_mul]
            rw [h1]
            have h2 : (-1 : Polynomial R) ^ 2 = 1 := by ring
            rw [h2, one_pow]
          have h_pow_simp : (-1 : Polynomial R) ^ n * (-1 : Polynomial R) ^ n = 1 := by
            have h3 : (-1 : Polynomial R) ^ n * (-1 : Polynomial R) ^ n = (-1 : Polynomial R) ^ (n * 2) := by
              rw [← pow_add]
              have : n + n = n * 2 := by omega
              rw [this]
            rw [h3, h_pow_even]
          have h_pow_succ : (-1 : Polynomial R) ^ (n + 1) = (-1 : Polynomial R) ^ n * -1 := by ring
          have h_C_all : C (W (Fin.last (n + 1))) * C (W 0) * ∏ i : Fin n, C (W (Fin.castSucc i).succ) = C ((∏ i : Fin n, W (Fin.castSucc i).succ) * W (Fin.last (n + 1)) * W 0) := by
            have h_prod_C : (∏ i : Fin n, C (W (Fin.castSucc i).succ)) = C (∏ i : Fin n, W (Fin.castSucc i).succ) := (map_prod C _ _).symm
            rw [h_prod_C, ← _root_.map_mul, ← _root_.map_mul]
            congr 1
            ring
          rw [sub_eq_add_neg, h_pow_succ]
          congr 1
          rw [← h_C_all]
          calc
            (-1 : Polynomial R) ^ n * -1 * -C (W (Fin.last (n + 1))) * (-C (W 0) * ((-1 : Polynomial R) ^ n * ∏ i : Fin n, C (W (Fin.castSucc i).succ))) =
              - (((-1 : Polynomial R) ^ n * (-1 : Polynomial R) ^ n) * (C (W (Fin.last (n + 1))) * C (W 0) * ∏ i : Fin n, C (W (Fin.castSucc i).succ))) := by ring
            _ = - (1 * (C (W (Fin.last (n + 1))) * C (W 0) * ∏ i : Fin n, C (W (Fin.castSucc i).succ))) := by rw [h_pow_simp]
            _ = - (C (W (Fin.last (n + 1))) * C (W 0) * ∏ i : Fin n, C (W (Fin.castSucc i).succ)) := by ring
        · exfalso
          apply h3
          apply Fin.ext
          change 0 = (n + 1 + 1) % (n + 1 + 1)
          rw [Nat.mod_self]
      · exact mem_univ 0
      · exact mem_univ (Fin.last (n + 1))
      · intro h
        have : (0 : ℕ) = n + 1 := congrArg Fin.val h
        omega
      · intro b _ hb_ne
        have hb0 : b ≠ 0 := hb_ne.1
        have hbn : b ≠ Fin.last (n + 1) := hb_ne.2
        rw [Matrix.charmatrix_apply, Matrix.diagonal_apply]
        dsimp [cyclicWeightMatrix, Matrix.of_apply]
        split_ifs with h1 h2 h3
        · exfalso; exact hb0 h1.symm
        · exfalso; exact hb0 h1.symm
        · exfalso
          have hlt : (b : ℕ) + 1 < n + 1 + 1 := by
            have h_lt : (b : ℕ) < n + 1 + 1 := b.is_lt
            have h_neq : (b : ℕ) ≠ n + 1 := fun eq => hbn (Fin.ext eq)
            omega
          have hval := congrArg Fin.val h3
          change 0 = ((b : ℕ) + 1) % (n + 1 + 1) at hval
          rw [Nat.mod_eq_of_lt hlt] at hval
          omega
        · simp
