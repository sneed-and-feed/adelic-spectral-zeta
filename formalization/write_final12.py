import os

content = """import Mathlib
import Mathlib.LinearAlgebra.Matrix.Charpoly.Basic

open Matrix Polynomial Finset
open scoped Polynomial

variable {R : Type*} [CommRing R] {L : ℕ} [NeZero L] (W : ZMod L → R)

def shiftMatrix (n : ℕ) (W : Fin n → R) : Matrix (Fin n) (Fin n) R :=
  fun i j => if (i : ℕ) = (j : ℕ) + 1 then W j else 0

lemma charmatrix_shiftMatrix_submatrix (n : ℕ) (W : Fin (n + 1) → R) :
    (charmatrix (shiftMatrix (n + 1) W)).submatrix Fin.succ Fin.succ =
      charmatrix (shiftMatrix n (fun x => W (Fin.succ x))) := by
  ext i j
  dsimp [charmatrix, Matrix.submatrix_apply, Matrix.sub_apply, Matrix.diagonal, shiftMatrix]
  by_cases h_eq : i = j
  · have h_eq_nat : (i : ℕ) = (j : ℕ) := congrArg Fin.val h_eq
    have c1 : Fin.succ i = Fin.succ j := congrArg Fin.succ h_eq
    have c2 : (Fin.succ i : ℕ) ≠ (Fin.succ j : ℕ) + 1 := by simp only [Fin.val_succ]; omega
    have c3 : (i : ℕ) ≠ (j : ℕ) + 1 := by omega
    simp [h_eq, h_eq_nat, c1, c2, c3]
  · have h_eq_nat : (i : ℕ) ≠ (j : ℕ) := fun h => h_eq (Fin.ext h)
    have c1 : Fin.succ i ≠ Fin.succ j := fun h => h_eq (Fin.succ_injective _ h)
    by_cases h_succ : (i : ℕ) = (j : ℕ) + 1
    · have c2 : (Fin.succ i : ℕ) = (Fin.succ j : ℕ) + 1 := by simp only [Fin.val_succ]; omega
      simp [h_eq, h_eq_nat, h_succ, c1, c2]
    · have c2 : (Fin.succ i : ℕ) ≠ (Fin.succ j : ℕ) + 1 := by simp only [Fin.val_succ]; omega
      simp [h_eq, h_eq_nat, h_succ, c1, c2]

lemma charpoly_shiftMatrix (n : ℕ) (W : Fin n → R) :
    (shiftMatrix n W).charpoly = X ^ n := by
  induction n with
  | zero => rw [Matrix.charpoly, Matrix.det_fin_zero, pow_zero]
  | succ n ih =>
    rw [Matrix.charpoly, Matrix.det_succ_row_zero, Finset.sum_eq_single 0]
    · change (-1) ^ (0 : ℕ) * _ * ((charmatrix (shiftMatrix (n + 1) W)).submatrix Fin.succ Fin.succ).det = _
      rw [charmatrix_shiftMatrix_submatrix]
      rw [← Matrix.charpoly, ih]
      dsimp [charmatrix, shiftMatrix, Matrix.diagonal]
      simp
      ring
    · intro b _ hb
      have h1 : (b : ℕ) ≠ 0 := Fin.val_ne_of_ne hb
      have h2 : (0 : ℕ) ≠ (b : ℕ) + 1 := by omega
      have h3 : (0 : Fin (n + 1)) ≠ b := hb.symm
      dsimp [charmatrix, shiftMatrix, Matrix.diagonal]
      simp [h1, h2, h3]
    · simp

noncomputable def upperBidiagonal (n : ℕ) (W : Fin n → R) : Matrix (Fin n) (Fin n) (Polynomial R) :=
  fun i j => if (i : ℕ) = (j : ℕ) then - C (W j) else if (i : ℕ) + 1 = (j : ℕ) then X else 0

lemma upperBidiagonal_submatrix (n : ℕ) (W : Fin (n + 1) → R) :
    ((upperBidiagonal (n + 1) W).submatrix Fin.succ Fin.succ) =
      upperBidiagonal n (fun x => W (Fin.succ x)) := by
  ext i j
  dsimp [upperBidiagonal, Matrix.submatrix_apply]
  by_cases h_eq : (i : ℕ) = (j : ℕ)
  · have c1 : (Fin.succ i : ℕ) = (Fin.succ j : ℕ) := by simp only [Fin.val_succ]; omega
    have c2 : (Fin.succ i : ℕ) + 1 ≠ (Fin.succ j : ℕ) := by simp only [Fin.val_succ]; omega
    have c3 : (i : ℕ) + 1 ≠ (j : ℕ) := by omega
    simp [h_eq, c1, c2, c3]
  · have c1 : (Fin.succ i : ℕ) ≠ (Fin.succ j : ℕ) := by simp only [Fin.val_succ]; omega
    by_cases h_succ : (i : ℕ) + 1 = (j : ℕ)
    · have c2 : (Fin.succ i : ℕ) + 1 = (Fin.succ j : ℕ) := by simp only [Fin.val_succ]; omega
      simp [h_eq, h_succ, c1, c2]
    · have c2 : (Fin.succ i : ℕ) + 1 ≠ (Fin.succ j : ℕ) := by simp only [Fin.val_succ]; omega
      simp [h_eq, h_succ, c1, c2]

lemma det_upperBidiagonal (n : ℕ) (W : Fin n → R) :
    (upperBidiagonal n W).det = ∏ i : Fin n, - C (W i) := by
  induction n with
  | zero => exact Matrix.det_fin_zero
  | succ n ih =>
    rw [Matrix.det_succ_column_zero, Finset.sum_eq_single 0]
    · change (-1) ^ (0 : ℕ) * _ * ((upperBidiagonal (n + 1) W).submatrix Fin.succ Fin.succ).det = _
      rw [upperBidiagonal_submatrix, ih, Fin.prod_univ_succ]
      dsimp [upperBidiagonal]
      simp
    · intro b _ hb
      have h1 : (b : ℕ) ≠ 0 := Fin.val_ne_of_ne hb
      have h2 : (b : ℕ) + 1 ≠ 0 := Nat.succ_ne_zero _
      have h3 : (0 : Fin (n + 1)) ≠ b := hb.symm
      dsimp [upperBidiagonal]
      simp [h1, h2, h3]
    · simp

def cyclicWeightMatrix : Matrix (ZMod L) (ZMod L) R :=
  fun i j => if i = j + 1 then W j else 0

lemma charmatrix_cyclic_submatrix_00 (n : ℕ) (W : ZMod (n + 2) → R) :
    (charmatrix (Matrix.of fun i j : Fin (n+2) => cyclicWeightMatrix W i j)).submatrix Fin.succ Fin.succ =
      charmatrix (shiftMatrix (n + 1) (fun x => W (Fin.succ x))) := by
  ext i j n_coeff
  dsimp [charmatrix, Matrix.submatrix_apply, Matrix.sub_apply, Matrix.diagonal_apply, shiftMatrix, cyclicWeightMatrix, Matrix.of_apply]
  have eq1 : (Fin.succ i : Fin (n + 2)) = (Fin.succ j : Fin (n + 2)) ↔ i = j :=
    ⟨fun h => Fin.succ_injective _ h, fun h => h ▸ rfl⟩
  have eq2 : (Fin.succ i : Fin (n + 2)) = (Fin.succ j : Fin (n + 2)) + 1 ↔ (i : ℕ) = (j : ℕ) + 1 := by
    constructor
    · intro h
      have h_val := congrArg Fin.val h
      change (i : ℕ) + 1 = ((j : ℕ) + 1 + 1) % (n + 2) at h_val
      have h_lt : (j : ℕ) + 1 + 1 < n + 2 ∨ (j : ℕ) + 1 + 1 = n + 2 := by
        have : (j : ℕ) < n + 1 := j.is_lt
        omega
      rcases h_lt with h_lt1 | h_eq1
      · rw [Nat.mod_eq_of_lt h_lt1] at h_val
        omega
      · rw [h_eq1, Nat.mod_self] at h_val
        omega
    · intro h
      ext
      change (i : ℕ) + 1 = ((j : ℕ) + 1 + 1) % (n + 2)
      have h_lt : (j : ℕ) + 1 + 1 < n + 2 := by
        have : (i : ℕ) < n + 1 := i.is_lt
        omega
      rw [Nat.mod_eq_of_lt h_lt]
      omega
  simp only [eq1, eq2]

lemma charmatrix_cyclic_submatrix_0n (n : ℕ) (W : ZMod (n + 2) → R) :
    (charmatrix (Matrix.of fun i j : Fin (n+2) => cyclicWeightMatrix W i j)).submatrix Fin.succ (Fin.last (n + 1)).succAbove =
      upperBidiagonal (n + 1) (fun x => W (Fin.castSucc x)) := by
  ext i j n_coeff
  dsimp [charmatrix, Matrix.submatrix_apply, Matrix.sub_apply, Matrix.diagonal_apply, cyclicWeightMatrix, upperBidiagonal, Matrix.of_apply]
  rw [Fin.succAbove_last]
  change ((if Fin.succ i = Fin.castSucc j then X else 0) - C (if Fin.succ i = Fin.castSucc j + 1 then W (Fin.castSucc j) else 0)).coeff n_coeff =
    (if (i : ℕ) = (j : ℕ) then -C (W (Fin.castSucc j)) else if (i : ℕ) + 1 = (j : ℕ) then X else 0).coeff n_coeff
  have eq1 : (Fin.succ i : Fin (n + 2)) = j.castSucc ↔ (i : ℕ) + 1 = (j : ℕ) := by
    constructor
    · intro h
      have h_val := congrArg Fin.val h
      change (i : ℕ) + 1 = (j : ℕ) at h_val
      omega
    · intro h
      ext
      change (i : ℕ) + 1 = (j : ℕ)
      omega
  have eq2 : (Fin.succ i : Fin (n + 2)) = j.castSucc + 1 ↔ (i : ℕ) = (j : ℕ) := by
    constructor
    · intro h
      have h_val := congrArg Fin.val h
      change (i : ℕ) + 1 = ((j : ℕ) + 1) % (n + 2) at h_val
      have h_lt : (j : ℕ) + 1 < n + 2 := by
        have : (j : ℕ) < n + 1 := j.is_lt
        omega
      rw [Nat.mod_eq_of_lt h_lt] at h_val
      omega
    · intro h
      ext
      change (i : ℕ) + 1 = ((j : ℕ) + 1) % (n + 2)
      have h_lt : (j : ℕ) + 1 < n + 2 := by
        have : (j : ℕ) < n + 1 := j.is_lt
        omega
      rw [Nat.mod_eq_of_lt h_lt]
      omega
  simp only [eq1, eq2]
  by_cases h1 : (i : ℕ) = (j : ℕ)
  · have h2 : (i : ℕ) + 1 ≠ (j : ℕ) := by omega
    simp [h1, h2]
  · by_cases h2 : (i : ℕ) + 1 = (j : ℕ)
    · simp [h1, h2]
    · simp [h1, h2]

lemma prod_ZMod (n : ℕ) (W : ZMod (n + 2) → R) :
    (∏ k : ZMod (n + 2), W k) = W 0 * W (Fin.last (n + 1)) * ∏ i : Fin n, W (Fin.castSucc (Fin.succ i)) := by
  have h_equiv : (∏ k : ZMod (n + 2), W k) = ∏ k : Fin (n + 2), W k := rfl
  rw [h_equiv]
  rw [Fin.prod_univ_castSucc, Fin.prod_univ_succ]
  have h0 : W (Fin.castSucc 0) = W 0 := rfl
  rw [h0]
  ring

theorem charpoly_cyclicWeightMatrix :
    (cyclicWeightMatrix W).charpoly = X ^ L - C (∏ k : ZMod L, W k) := by
  cases L with
  | zero => exact (NeZero.ne 0 rfl).elim
  | succ m =>
    cases m with
    | zero =>
      have h_charpoly : (cyclicWeightMatrix W).charpoly = (Matrix.of fun (i j : Fin 1) => cyclicWeightMatrix W i j).charpoly := rfl
      rw [h_charpoly]
      rw [Matrix.charpoly, Matrix.det_fin_one]
      change X - C (if ((0 : Fin 1) : ZMod 1) = ((0 : Fin 1) : ZMod 1) + 1 then W ((0 : Fin 1) : ZMod 1) else 0) = X ^ 1 - C (∏ k : ZMod 1, W k)
      have h2 : ((0 : Fin 1) : ZMod 1) = ((0 : Fin 1) : ZMod 1) + 1 := Subsingleton.elim _ _
      rw [if_pos h2]
      simp [pow_one]
      congr 1
      exact congrArg W (Subsingleton.elim _ _)
    | succ n =>
      have h_charpoly : (cyclicWeightMatrix W).charpoly = (Matrix.of fun (i j : Fin (n + 2)) => cyclicWeightMatrix W i j).charpoly := rfl
      rw [h_charpoly]
      rw [Matrix.charpoly, Matrix.det_succ_row_zero, Finset.sum_eq_add_of_mem 0 (Fin.last (n + 1))]
      · change (-1) ^ (0 : ℕ) * _ * ((charmatrix (Matrix.of fun (i j : Fin (n + 2)) => cyclicWeightMatrix W i j)).submatrix Fin.succ Fin.succ).det + _ = _
        rw [charmatrix_cyclic_submatrix_00]
        have h_shift := charpoly_shiftMatrix (n + 1) (fun x => W (Fin.succ x))
        rw [Matrix.charpoly] at h_shift
        rw [h_shift]
        change _ + (-1) ^ ((Fin.last (n + 1) : ℕ) + 0) * _ * ((charmatrix (Matrix.of fun (i j : Fin (n + 2)) => cyclicWeightMatrix W i j)).submatrix Fin.succ (Fin.last (n + 1)).succAbove).det = _
        rw [charmatrix_cyclic_submatrix_0n, det_upperBidiagonal]
        have h_pow : (-1 : Polynomial R) ^ ((Fin.last (n + 1) : ℕ) + 0) = (-1) ^ (n + 1) := by congr 1; omega
        rw [h_pow]
        dsimp [cyclicWeightMatrix, Matrix.of_apply, charmatrix, Matrix.diagonal_apply]
        have c0 : (0 : ZMod (n + 2)) = 0 ↔ True := by simp
        have c1 : (0 : ZMod (n + 2)) = 1 ↔ False := by
          apply iff_false_intro; intro h
          have h' : (0 : Fin (n + 2)) = (1 : Fin (n + 2)) := h
          have h'' := congrArg Fin.val h'
          change 0 = 1 at h''
          omega
        have c2 : (0 : ZMod (n + 2)) = Fin.last (n + 1) ↔ False := by
          apply iff_false_intro; intro h
          have h' : (0 : Fin (n + 2)) = (Fin.last (n + 1) : Fin (n + 2)) := h
          have h'' := congrArg Fin.val h'
          change 0 = n + 1 at h''
          omega
        have c3 : (0 : ZMod (n + 2)) = (Fin.last (n + 1) : ZMod (n + 2)) + 1 ↔ True := by
          apply iff_true_intro
          have h' : (0 : Fin (n + 2)).val = ((Fin.last (n + 1) : Fin (n + 2)) + 1).val := by
            change 0 = (n + 1 + 1) % (n + 2)
            have h_eq : n + 1 + 1 = n + 2 := by omega
            rw [h_eq, Nat.mod_self]
          exact Fin.ext h'
        simp only [c0, c1, c2, c3, if_false, if_true, sub_zero, zero_sub, Fin.prod_univ_succ, zero_add, mul_neg, mul_zero]
        rw [prod_ZMod]
        ring_nf
        have h_prod_neg : (∏ i : Fin n, -C (W (Fin.castSucc (Fin.succ i)))) = (-1 : Polynomial R) ^ n * ∏ i : Fin n, C (W (Fin.castSucc (Fin.succ i))) := by
          have : ∀ i, -C (W (Fin.castSucc (Fin.succ i))) = (-1 : Polynomial R) * C (W (Fin.castSucc (Fin.succ i))) := fun i => by ring
          simp_rw [this]
          rw [Finset.prod_mul_distrib]
          congr 1
          exact Finset.prod_const _
        rw [h_prod_neg]
        ring_nf
        have h_pow_even : (-1 : Polynomial R) ^ (n * 2) = 1 := by
          rw [pow_mul]
          have : (-1 : Polynomial R) ^ 2 = 1 := by ring
          rw [this, one_pow]
        have h_pow_simp : (-1 : Polynomial R) ^ n * (-1) ^ n = 1 := by
          have : (-1 : Polynomial R) ^ n * (-1) ^ n = (-1 : Polynomial R) ^ (n * 2) := by ring_nf
          rw [this, h_pow_even]
        rw [mul_assoc]
        have h_simplify : (-1 : Polynomial R) ^ n * ((-1) ^ n * C (W (Fin.last (n + 1))) * C (W 0) * ∏ i : Fin n, C (W (Fin.castSucc (Fin.succ i)))) =
          ((-1 : Polynomial R) ^ n * (-1) ^ n) * C (W (Fin.last (n + 1))) * C (W 0) * ∏ i : Fin n, C (W (Fin.castSucc (Fin.succ i))) := by ring
        rw [h_simplify, h_pow_simp, one_mul]
        ring
      · exact mem_univ 0
      · exact mem_univ (Fin.last (n + 1))
      · intro h
        have : (0 : ℕ) = n + 1 := congrArg Fin.val h
        omega
      · intro b _ hb_ne
        have hb0 : b ≠ 0 := hb_ne.1
        have hbn : b ≠ Fin.last (n + 1) := hb_ne.2
        dsimp [charmatrix, Matrix.diagonal_apply, cyclicWeightMatrix, Matrix.of_apply]
        have c1 : (0 : ZMod (n+2)) = b ↔ False := by
          apply iff_false_intro; intro h
          have h' : (0 : Fin (n+2)) = b := h
          exact hb0 h'.symm
        have c2 : (0 : ZMod (n+2)) = (b + 1 : Fin (n+2)) ↔ False := by
          apply iff_false_intro
          intro h
          have h1 : (b : ℕ) + 1 < n + 2 := by
            have h_lt : (b : ℕ) < n + 2 := b.is_lt
            have h_neq : (b : ℕ) ≠ n + 1 := fun eq => hbn (Fin.ext eq)
            omega
          have h2 : (0 : Fin (n+2)) = b + 1 := h
          have h3 := congrArg Fin.val h2
          change 0 = ((b : ℕ) + 1) % (n + 2) at h3
          rw [Nat.mod_eq_of_lt h1] at h3
          have : (b : ℕ) = 0 := by omega
          apply hb0
          exact Fin.ext this
        simp [c1, c2]
"""
with open("Formalization/CyclicWeightCharpoly.lean", "w", encoding="utf-8") as f:
    f.write(content)
