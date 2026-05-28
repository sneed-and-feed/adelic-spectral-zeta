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
    have h1 := Nat.mod_add_div (x % (2^(n-2) * 2)) (2^(n-2))
    have h2 : (x % (2^(n-2) * 2)) % 2^(n-2) = x % 2^(n-2) := by
      rw [Nat.mod_mod_of_dvd _ (by use 2)]
    have h3 : (x % (2^(n-2) * 2)) / 2^(n-2) = x / 2^(n-2) % 2 := by
      rw [Nat.mod_mul_div_eq] -- Wait, maybe `Nat.div_mod_eq_mod_mul_div`
      sorry
    -- sorry for now
    sorry
  exact h_eq

noncomputable def index_equiv : ZMod (2^(n-1)) ≃ (ZMod (2^(n-2)) × ZMod 2) where
  toFun x := ((x.val : ℕ), (x.val / 2^(n-2) : ℕ))
  invFun p := (p.1.val + p.2.val * 2^(n-2) : ℕ)
  left_inv x := by
    apply ZMod.val_injective
    dsimp
    have h1 : ((x.val : ZMod (2^(n-2))) : ℕ).val = x.val % 2^(n-2) := ZMod.val_natCast _
    have h2 : (((x.val / 2^(n-2) : ℕ) : ZMod 2) : ℕ).val = (x.val / 2^(n-2)) % 2 := ZMod.val_natCast _
    -- wait, ZMod.val_natCast works on `((a : ZMod N).val)`.
    sorry
  right_inv p := by
    sorry
