import Mathlib
import Mathlib.Data.ZMod.Basic

variable {n : ℕ} (hn : n ≥ 3)

lemma mod_pow_add_div_mul (x : ℕ) (n : ℕ) (hn : n ≥ 3) :
  (x % 2^(n-2) + (x / 2^(n-2) % 2) * 2^(n-2)) % 2^(n-1) = x % 2^(n-1) := by
  have h_pow : 2^(n-1) = 2^(n-2) * 2 := by
    rw [← pow_succ]
    congr 1
    omega
  rw [h_pow]
  rw [Nat.add_comm]
  have h_eq : (x / 2^(n-2) % 2) * 2^(n-2) + x % 2^(n-2) = x % (2^(n-2) * 2) := by
    exact (Nat.mod_mul_mod x (2^(n-2)) 2).symm
  exact h_eq

noncomputable def index_equiv : ZMod (2^(n-1)) ≃ (ZMod (2^(n-2)) × ZMod 2) where
  toFun x := (x.val, x.val / 2^(n-2))
  invFun p := p.1.val + p.2.val * 2^(n-2)
  left_inv x := by
    apply ZMod.val_injective
    dsimp
    have h1 : ((x.val : ZMod (2^(n-2))) : ℕ) = x.val % 2^(n-2) := ZMod.val_natCast _
    have h2 : ((x.val / 2^(n-2) : ZMod 2) : ℕ) = (x.val / 2^(n-2)) % 2 := ZMod.val_natCast _
    have h3 : (((x.val : ZMod (2^(n-2))) : ℕ) + ((x.val / 2^(n-2) : ZMod 2) : ℕ) * 2^(n-2) : ZMod (2^(n-1))).val =
      (((x.val : ZMod (2^(n-2))) : ℕ) + ((x.val / 2^(n-2) : ZMod 2) : ℕ) * 2^(n-2)) % 2^(n-1) := ZMod.val_natCast _
    rw [h3, h1, h2]
    have hz := mod_pow_add_div_mul x.val n hn
    rw [hz]
    exact ZMod.val_lt _ |> Nat.mod_eq_of_lt
  right_inv p := by
    ext
    · apply ZMod.val_injective
      dsimp
      have h1 : ((p.1.val + p.2.val * 2^(n-2) : ZMod (2^(n-1))) : ℕ) = (p.1.val + p.2.val * 2^(n-2)) % 2^(n-1) := ZMod.val_natCast _
      rw [h1]
      have h_pow : 2^(n-1) = 2^(n-2) * 2 := by
        rw [← pow_succ]
        congr 1
        omega
      rw [h_pow]
      have h_mod : (p.1.val + p.2.val * 2^(n-2)) % (2^(n-2) * 2) % 2^(n-2) = p.1.val := by
        rw [Nat.mod_mod_of_dvd _ (by use 2)]
        rw [Nat.add_mul_mod_self_left]
        exact ZMod.val_lt _ |> Nat.mod_eq_of_lt
      have h_zmod : (((p.1.val + p.2.val * 2^(n-2)) % (2^(n-2) * 2) : ℕ) : ZMod (2^(n-2))).val = (p.1.val + p.2.val * 2^(n-2)) % (2^(n-2) * 2) % 2^(n-2) := ZMod.val_natCast _
      rw [h_zmod, h_mod]
    · apply ZMod.val_injective
      dsimp
      have h1 : ((p.1.val + p.2.val * 2^(n-2) : ZMod (2^(n-1))) : ℕ) = (p.1.val + p.2.val * 2^(n-2)) % 2^(n-1) := ZMod.val_natCast _
      rw [h1]
      have h_pow : 2^(n-1) = 2^(n-2) * 2 := by
        rw [← pow_succ]
        congr 1
        omega
      rw [h_pow]
      have h_div : (p.1.val + p.2.val * 2^(n-2)) % (2^(n-2) * 2) / 2^(n-2) = p.2.val := by
        have h_lt : p.1.val + p.2.val * 2^(n-2) < 2^(n-2) * 2 := by
          have hp1 := ZMod.val_lt p.1
          have hp2 := ZMod.val_lt p.2
          nlinarith
        rw [Nat.mod_eq_of_lt h_lt]
        rw [Nat.add_comm, Nat.add_mul_div_left _ _ (by positivity)]
        have hp1 := ZMod.val_lt p.1
        rw [Nat.div_eq_of_lt hp1, add_zero]
      have h_zmod : (((p.1.val + p.2.val * 2^(n-2)) % (2^(n-2) * 2) / 2^(n-2) : ℕ) : ZMod 2).val = (p.1.val + p.2.val * 2^(n-2)) % (2^(n-2) * 2) / 2^(n-2) % 2 := ZMod.val_natCast _
      rw [h_zmod, h_div]
      exact ZMod.val_lt _ |> Nat.mod_eq_of_lt
