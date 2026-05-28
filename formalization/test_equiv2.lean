import Mathlib
import Mathlib.Data.ZMod.Basic

variable {n : ℕ} (hn : n ≥ 3)

noncomputable def index_equiv : ZMod (2^(n-1)) ≃ (ZMod (2^(n-2)) × ZMod 2) where
  toFun x := (x.val, x.val / 2^(n-2))
  invFun p := p.1.val + p.2.val * 2^(n-2)
  left_inv x := by
    dsimp
    have h1 : (x.val : ZMod (2^(n-2))).val = x.val % 2^(n-2) := by
      rw [ZMod.val_natCast]
    have h2 : ((x.val / 2^(n-2) : ℕ) : ZMod 2).val = x.val / 2^(n-2) := by
      rw [ZMod.val_natCast]
      apply Nat.mod_eq_of_lt
      have h_lt : x.val < 2^(n-1) := ZMod.val_lt x
      have h_pow : 2^(n-1) = 2^(n-2) * 2 := by
        rw [← pow_succ]
        congr 1
        omega
      rw [h_pow] at h_lt
      exact Nat.div_lt_of_lt_mul h_lt
    rw [h1, h2]
    have h_div_mod : x.val % 2^(n-2) + x.val / 2^(n-2) * 2^(n-2) = x.val := by
      exact Nat.mod_add_div _ _
    rw [h_div_mod]
    exact ZMod.natCast_val x
  right_inv p := by
    ext
    · dsimp
      have h_val : (p.1.val + p.2.val * 2^(n-2) : ZMod (2^(n-1))).val = p.1.val + p.2.val * 2^(n-2) := by
        rw [ZMod.val_natCast, Nat.mod_eq_of_lt]
        have h1 : p.1.val < 2^(n-2) := ZMod.val_lt p.1
        have h2 : p.2.val < 2 := ZMod.val_lt p.2
        have h_pow : 2^(n-1) = 2^(n-2) * 2 := by
          rw [← pow_succ]
          congr 1
          omega
        rw [h_pow]
        nlinarith
      rw [h_val]
      simp only [Nat.cast_add, Nat.cast_mul, ZMod.natCast_val]
      have hz : (2^(n-2) : ZMod (2^(n-2))) = 0 := by
        exact ZMod.natCast_self _
      rw [hz, mul_zero, add_zero]
    · dsimp
      have h_val : (p.1.val + p.2.val * 2^(n-2) : ZMod (2^(n-1))).val = p.1.val + p.2.val * 2^(n-2) := by
        rw [ZMod.val_natCast, Nat.mod_eq_of_lt]
        have h1 : p.1.val < 2^(n-2) := ZMod.val_lt p.1
        have h2 : p.2.val < 2 := ZMod.val_lt p.2
        have h_pow : 2^(n-1) = 2^(n-2) * 2 := by
          rw [← pow_succ]
          congr 1
          omega
        rw [h_pow]
        nlinarith
      rw [h_val]
      have h_div : (p.1.val + p.2.val * 2^(n-2)) / 2^(n-2) = p.2.val := by
        rw [add_comm, Nat.add_mul_div_left _ _ (by positivity)]
        have h1 : p.1.val < 2^(n-2) := ZMod.val_lt p.1
        rw [Nat.div_eq_of_lt h1, add_zero]
      rw [h_div, ZMod.natCast_val]
