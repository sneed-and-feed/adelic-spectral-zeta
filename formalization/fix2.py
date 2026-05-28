with open('Formalization/CyclicWeightCharpoly.lean', 'r', encoding='utf-8') as f:
    code = f.read()

import re

start = code.find('theorem charpoly_cyclicWeightMatrix :')

new_theorem = '''theorem charpoly_cyclicWeightMatrix :
    (cyclicWeightMatrix W).charpoly = X ^ L - C (∏ k : ZMod L, W k) := by
  cases L with
  | zero => exact (NeZero.ne 0 rfl).elim
  | succ m =>
    cases m with
    | zero =>
      have h_charpoly : (cyclicWeightMatrix W).charpoly = (Matrix.of fun (i j : Fin 1) => cyclicWeightMatrix W i j).charpoly := rfl
      rw [h_charpoly]
      rw [Matrix.charpoly, Matrix.det_fin_one]
      change X - C (if (0 : ZMod 1) = (0 : ZMod 1) + 1 then W (0 : ZMod 1) else 0) = X ^ 1 - C (∏ k : ZMod 1, W k)
      have h2 : (0 : ZMod 1) = (0 : ZMod 1) + 1 := Subsingleton.elim _ _
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
        have h_pow : (-1 : Polynomial R) ^ ((Fin.last (n + 1) : ℕ) + 0) = (-1) ^ (n + 1) := by simp
        rw [h_pow]
        dsimp [cyclicWeightMatrix, Matrix.of_apply, charmatrix, Matrix.diagonal_apply]
        have c0 : ((0 : Fin (n + 2)) : ZMod (n + 2)) = (0 : ZMod (n + 2)) := rfl
        have c_last : ((Fin.last (n + 1)) : ZMod (n + 2)) = (n + 1 : ZMod (n + 2)) := by simp
        rw [c0, c_last]
        have c1 : (0 : ZMod (n + 2)) = 1 ↔ False := by
          apply iff_false_intro; intro h
          have h' := congrArg ZMod.val h
          simp only [ZMod.val_zero, ZMod.val_one] at h'
          have h_lt : 1 < n + 2 := by omega
          rw [Nat.mod_eq_of_lt h_lt] at h'
          omega
        have c1_alt : (0 : ZMod (n + 2)) = 0 + 1 ↔ False := by
          apply iff_false_intro; intro h
          have h' := congrArg ZMod.val h
          simp only [ZMod.val_zero, ZMod.val_add, ZMod.val_one] at h'
          have h_lt : 1 < n + 2 := by omega
          rw [Nat.mod_eq_of_lt h_lt] at h'
          omega
        have c2 : (0 : ZMod (n + 2)) = (n + 1 : ZMod (n + 2)) ↔ False := by
          apply iff_false_intro; intro h
          have h' := congrArg ZMod.val h
          simp only [ZMod.val_zero, ZMod.val_natCast] at h'
          have h_lt : n + 1 < n + 2 := by omega
          rw [Nat.mod_eq_of_lt h_lt] at h'
          omega
        have c3 : (0 : ZMod (n + 2)) = (n + 1 : ZMod (n + 2)) + 1 ↔ True := by
          apply iff_true_intro
          symm
          have h_eq : (n + 1 : ZMod (n + 2)) + 1 = (n + 1 + 1 : ℕ) := by push_cast; rfl
          rw [h_eq]
          have h_eq2 : n + 1 + 1 = n + 2 := by omega
          rw [h_eq2]
          exact ZMod.natCast_self (n + 2)
        simp only [c1, c1_alt, c2, c3, if_false, if_true, sub_zero, zero_sub, Fin.prod_univ_succ, zero_add, mul_neg, mul_zero]
        rw [prod_ZMod]
        ring_nf
        have h_prod_neg : (∏ i : Fin n, -C (W (Fin.castSucc (Fin.succ i)))) = (-1 : Polynomial R) ^ n * ∏ i : Fin n, C (W (Fin.castSucc (Fin.succ i))) := by
          have : ∀ i, -C (W (Fin.castSucc (Fin.succ i))) = (-1 : Polynomial R) * C (W (Fin.castSucc (Fin.succ i))) := fun i => by ring
          simp_rw [this]
          rw [Finset.prod_mul_distrib, Finset.prod_const]
          have hc : Finset.card (Finset.univ : Finset (Fin n)) = n := Fintype.card_fin n
          rw [hc]
        rw [h_prod_neg]
        ring_nf
        have h_pow_simp : (-1 : Polynomial R) ^ n * (-1) ^ n = 1 := by
          rw [← pow_add]
          have : n + n = 2 * n := by omega
          rw [this, pow_mul]
          have : (-1 : Polynomial R) ^ 2 = 1 := by ring
          rw [this, one_pow]
        rw [mul_assoc]
        have h_simplify : (-1 : Polynomial R) ^ n * ((-1) ^ n * C (W (n + 1)) * C (W 0) * ∏ i : Fin n, C (W (Fin.castSucc (Fin.succ i)))) =
          ((-1 : Polynomial R) ^ n * (-1) ^ n) * C (W (n + 1)) * C (W 0) * ∏ i : Fin n, C (W (Fin.castSucc (Fin.succ i))) := by ring
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
        have c0 : ((0 : Fin (n + 2)) : ZMod (n + 2)) = (0 : ZMod (n + 2)) := rfl
        rw [c0]
        have c1 : (0 : ZMod (n + 2)) = (b : ZMod (n + 2)) ↔ False := by
          apply iff_false_intro; intro h
          apply hb0
          apply Fin.ext
          have h' := congrArg ZMod.val h
          simp only [ZMod.val_zero, ZMod.val_natCast] at h'
          have hb_lt : (b : ℕ) < n + 2 := b.is_lt
          rw [Nat.mod_eq_of_lt hb_lt] at h'
          exact h'.symm
        have c2 : (0 : ZMod (n + 2)) = (b : ZMod (n + 2)) + 1 ↔ False := by
          apply iff_false_intro
          intro h
          have h1 : (b : ℕ) + 1 < n + 2 := by
            have h_lt : (b : ℕ) < n + 2 := b.is_lt
            have h_neq : (b : ℕ) ≠ n + 1 := fun eq => hbn (Fin.ext eq)
            omega
          have h_eq : ((b : ZMod (n + 2)) + 1 : ZMod (n + 2)) = ((b : ℕ) + 1 : ℕ) := by push_cast; rfl
          rw [h_eq] at h
          have h2 := congrArg ZMod.val h
          simp only [ZMod.val_zero, ZMod.val_natCast] at h2
          rw [Nat.mod_eq_of_lt h1] at h2
          have : (b : ℕ) = 0 := by omega
          apply hb0
          exact Fin.ext this
        simp [c1, c2]
'''

code = code[:start] + new_theorem

with open('Formalization/CyclicWeightCharpoly.lean', 'w', encoding='utf-8') as f:
    f.write(code)
print("done")
