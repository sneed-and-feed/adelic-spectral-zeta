import Mathlib.Data.ZMod.Basic
import Mathlib.Combinatorics.SimpleGraph.Basic
import Mathlib.Tactic

open Classical

lemma three_coprime_pow_two (d : ℕ) : Nat.Coprime 3 (2^(d-1)) := by
  have h1 : Nat.Coprime 3 2 := by decide
  exact Nat.Coprime.pow_right (d-1) h1

noncomputable def inv3_unit {d : ℕ} : (ZMod (2^(d-1)))ˣ :=
  (ZMod.unitOfCoprime 3 (three_coprime_pow_two d))⁻¹

noncomputable def inv3 {d : ℕ} : ZMod (2^(d-1)) :=
  (inv3_unit : (ZMod (2^(d-1)))ˣ)

lemma inv3_mul_three {d : ℕ} : inv3 * (3 : ZMod (2^(d-1))) = 1 := by
  unfold inv3 inv3_unit
  have h_val : (3 : ZMod (2^(d-1))) = (ZMod.unitOfCoprime 3 (three_coprime_pow_two d) : ZMod (2^(d-1))) := by
    exact (ZMod.coe_unitOfCoprime 3 (three_coprime_pow_two d)).symm
  rw [h_val, ←Units.val_mul, mul_left_inv, Units.val_one]

lemma three_mul_inv3 {d : ℕ} : (3 : ZMod (2^(d-1))) * inv3 = 1 := by
  rw [mul_comm]
  exact inv3_mul_three

lemma mul_inv3 {d : ℕ} (x : ZMod (2^(d-1))) : 3 * (inv3 * x) = x := by
  rw [← mul_assoc, three_mul_inv3, one_mul]

lemma inv3_mul {d : ℕ} (x y : ZMod (2^(d-1))) (h : x = 3 * y) : y = inv3 * x := by
  rw [h, ← mul_assoc, inv3_mul_three, one_mul]

lemma inv3_mul_add {d : ℕ} (x y : ZMod (2^(d-1))) (h : x = 3 * y - 1) : y = inv3 * (x + 1) := by
  have h1 : x + 1 = 3 * y := by
    calc x + 1 = 3 * y - 1 + 1 := by rw [h]
         _ = 3 * y := by ring
  exact inv3_mul (x + 1) y h1
