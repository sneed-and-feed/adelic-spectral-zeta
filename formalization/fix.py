with open('Formalization/CyclicWeightCharpoly.lean', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace block 1
code = code.replace('''      have h2 : (0 : ZMod 1) = (0 : ZMod 1) + 1 := Subsingleton.elim _ _
      rw [if_pos h2]
      simp [pow_one]
      congr 1
      exact congrArg W (Subsingleton.elim _ _)''', '''      have h2 : (0 : ZMod 1) = (0 : ZMod 1) + 1 := Subsingleton.elim _ _
      rw [if_pos h2]
      simp [pow_one]''')

# Replace block 2
old2 = '''        rw [charmatrix_cyclic_submatrix_0n, det_upperBidiagonal]
        have h_pow : (-1 : Polynomial R) ^ ((Fin.last (n + 1) : ℕ) + 0) = (-1) ^ (n + 1) := by congr 1; omega
        rw [h_pow]
        dsimp [cyclicWeightMatrix, Matrix.of_apply, charmatrix, Matrix.diagonal_apply]
        have c0 : ((0 : Fin (n + 2)) : ZMod (n + 2)) = 0 := rfl
        have c_last : ((Fin.last (n + 1)) : ZMod (n + 2)) = n + 1 := rfl
        rw [c0, c_last]
        have c1 : (0 : ZMod (n + 2)) = 0 + 1 ↔ False := by
          apply iff_false_intro; intro h
          have h' := congrArg ZMod.val h
          change 0 = 1 % (n + 2) at h'
          have h_lt : 1 < n + 2 := by omega
          rw [Nat.mod_eq_of_lt h_lt] at h'
          omega
        have c2 : (0 : ZMod (n + 2)) = (n + 1 : ZMod (n + 2)) ↔ False := by
          apply iff_false_intro; intro h
          have h' := congrArg ZMod.val h
          change 0 = (n + 1) % (n + 2) at h'
          have h_lt : n + 1 < n + 2 := by omega
          rw [Nat.mod_eq_of_lt h_lt] at h'
          omega
        have c3 : (0 : ZMod (n + 2)) = (n + 1 : ZMod (n + 2)) + 1 ↔ True := by
          apply iff_true_intro
          have h_eq : n + 1 + 1 = n + 2 := by omega
          have h_val : ((n + 1 : ZMod (n + 2)) + 1).val = (n + 1 + 1) % (n + 2) := rfl
          apply ZMod.val_injective
          rw [h_val, h_eq, Nat.mod_self]
          rfl
        simp only [c1, c2, c3, if_false, if_true, sub_zero, zero_sub, Fin.prod_univ_succ, zero_add, mul_neg, mul_zero]
        rw [prod_ZMod]
        ring_nf
        have h_prod_neg : (∏ i : Fin n, -C (W (Fin.castSucc (Fin.succ i)))) = (-1 : Polynomial R) ^ n * ∏ i : Fin n, C (W (Fin.castSucc (Fin.succ i))) := by
          have : ∀ i, -C (W (Fin.castSucc (Fin.succ i))) = (-1 : Polynomial R) * C (W (Fin.castSucc (Fin.succ i))) := fun i => by ring
          simp_rw [this]
          rw [Finset.prod_mul_distrib, Finset.prod_const]
          have hc : Finset.card (Finset.univ : Finset (Fin n)) = n := Finset.card_univ
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
        ring'''

new2 = '''        rw [charmatrix_cyclic_submatrix_0n, det_upperBidiagonal]
        have h_pow : (-1 : Polynomial R) ^ ((Fin.last (n + 1) : ℕ) + 0) = (-1) ^ (n + 1) := by simp
        rw [h_pow]
        dsimp [cyclicWeightMatrix, Matrix.of_apply, charmatrix, Matrix.diagonal_apply]
        have c0 : ((0 : Fin (n + 2)) : ZMod (n + 2)) = (0 : ZMod (n + 2)) := rfl
        have c_last : ((Fin.last (n + 1)) : ZMod (n + 2)) = (n + 1 : ZMod (n + 2)) := rfl
        rw [c0, c_last]
        have c1 : (0 : ZMod (n + 2)) = 0 + 1 ↔ False := by
          apply iff_false_intro; intro h
          have h' := congrArg ZMod.val h
          change 0 = 1 % (n + 2) at h'
          have h_lt : 1 < n + 2 := by omega
          rw [Nat.mod_eq_of_lt h_lt] at h'
          omega
        have c2 : (0 : ZMod (n + 2)) = (n + 1 : ZMod (n + 2)) ↔ False := by
          apply iff_false_intro; intro h
          have h' := congrArg ZMod.val h
          change 0 = (n + 1) % (n + 2) at h'
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
        simp only [c1, c2, c3, if_false, if_true, sub_zero, zero_sub, Fin.prod_univ_succ, zero_add, mul_neg, mul_zero]
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
        ring'''

code = code.replace(old2, new2)

old3 = '''      · intro b _ hb_ne
        have hb0 : b ≠ 0 := hb_ne.1
        have hbn : b ≠ Fin.last (n + 1) := hb_ne.2
        dsimp [charmatrix, Matrix.diagonal_apply, cyclicWeightMatrix, Matrix.of_apply]
        have c1 : ((0 : Fin (n+2)) : ZMod (n+2)) = (b : ZMod (n+2)) ↔ False := by apply iff_false_intro; intro h; exact hb0 h.symm
        have c2 : ((0 : Fin (n + 2)) : ZMod (n+2)) = (b : ZMod (n+2)) + 1 ↔ False := by
          apply iff_false_intro
          intro h
          have h1 : (b : ℕ) + 1 < n + 2 := by
            have h_lt : (b : ℕ) < n + 2 := b.is_lt
            have h_neq : (b : ℕ) ≠ n + 1 := fun eq => hbn (Fin.ext eq)
            omega
          have h2 := congrArg ZMod.val h
          change 0 = ((b : ℕ) + 1) % (n + 2) at h2
          rw [Nat.mod_eq_of_lt h1] at h2
          have : (b : ℕ) = 0 := by omega
          apply hb0
          exact Fin.ext this
        simp [c1, c2]'''

new3 = '''      · intro b _ hb_ne
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
          change 0 = (b : ℕ) % (n + 2) at h'
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
          have h2 := congrArg ZMod.val h
          change 0 = ((b : ℕ) + 1) % (n + 2) at h2
          rw [Nat.mod_eq_of_lt h1] at h2
          have : (b : ℕ) = 0 := by omega
          apply hb0
          exact Fin.ext this
        simp [c1, c2]'''

code = code.replace(old3, new3)

with open('Formalization/CyclicWeightCharpoly.lean', 'w', encoding='utf-8') as f:
    f.write(code)
print("done")
