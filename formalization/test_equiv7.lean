import Mathlib
import Mathlib.Data.ZMod.Basic

variable {n : ℕ} (hn : n ≥ 3)

lemma mod_pow_add_div_mul (x : ℕ) (n : ℕ) (hn : n ≥ 3) :
  x % 2^(n-2) + (x / 2^(n-2) % 2) * 2^(n-2) = x % 2^(n-1) := by
  have h_pow : 2^(n-1) = 2^(n-2) * 2 := by
    rw [← pow_succ]
    congr 1
    omega
  rw [h_pow]
  rw [Nat.add_comm]
  have h_eq : (x / 2^(n-2) % 2) * 2^(n-2) + x % 2^(n-2) = x % (2^(n-2) * 2) := by
    exact (Nat.mod_add_div' (x % (2^(n-2) * 2)) (2^(n-2))).symm -- Actually Nat.mod_mul_mod wasn't quite right
    -- let's use omega since we only deal with Nat
  -- wait, omega can't do non-linear. Let's just use `Nat.mod_add_div`
  sorry

noncomputable def index_equiv : ZMod (2^(n-1)) ≃ (ZMod (2^(n-2)) × ZMod 2) where
  toFun x := (x.val, x.val / 2^(n-2))
  invFun p := p.1.val + p.2.val * 2^(n-2)
  left_inv x := by
    apply ZMod.val_injective
    dsimp
    have h1 : (x.val : ZMod (2^(n-2))).val = x.val % 2^(n-2) := ZMod.val_natCast _
    have h2 : (x.val / 2^(n-2) : ZMod 2).val = (x.val / 2^(n-2)) % 2 := ZMod.val_natCast _
    have h3 : ((x.val : ZMod (2^(n-2))).val + (x.val / 2^(n-2) : ZMod 2).val * 2^(n-2) : ZMod (2^(n-1))).val =
      ((x.val : ZMod (2^(n-2))).val + (x.val / 2^(n-2) : ZMod 2).val * 2^(n-2)) % 2^(n-1) := ZMod.val_natCast _
    rw [h3, h1, h2]
    -- sorry for now
    sorry
  right_inv p := by
    ext
    · apply ZMod.val_injective
      dsimp
      have h1 : (p.1.val + p.2.val * 2^(n-2) : ZMod (2^(n-1))).val = (p.1.val + p.2.val * 2^(n-2)) % 2^(n-1) := ZMod.val_natCast _
      rw [h1]
      -- sorry for now
      sorry
    · apply ZMod.val_injective
      dsimp
      have h1 : (p.1.val + p.2.val * 2^(n-2) : ZMod (2^(n-1))).val = (p.1.val + p.2.val * 2^(n-2)) % 2^(n-1) := ZMod.val_natCast _
      rw [h1]
      -- sorry for now
      sorry
