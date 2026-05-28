import Mathlib.NumberTheory.Padics.PadicIntegers
import Mathlib.Topology.ContinuousFunction.Basic
import Mathlib.Analysis.Complex.Basic

open Topology

noncomputable section

instance : Fact (Nat.Prime 2) := ⟨Nat.prime_two⟩

namespace CollatzZ2

open Classical

-- 1. THE INVERSE BRANCHES

lemma three_norm : ‖(3 : ℤ_[2])‖ = 1 := by
  have h1 : ‖(3 : ℤ_[2])‖ ≤ 1 := PadicInt.norm_le_one 3
  have h2 : ¬(‖(3 : ℤ_[2])‖ < 1) := by
    have eq : (3 : ℤ_[2]) = ((3 : ℤ) : ℤ_[2]) := by norm_cast
    rw [eq, PadicInt.norm_int_lt_one_iff_dvd 3]
    intro h
    revert h
    decide
  exact le_antisymm h1 (not_lt.mp h2)

-- 3 is invertible in Z_2
lemma three_unit : IsUnit (3 : ℤ_[2]) := by
  rw [PadicInt.isUnit_iff]
  exact three_norm

def inv0 (x : ℤ_[2]) : ℤ_[2] := 2 * x

def inv1 (x : ℤ_[2]) : ℤ_[2] := (2 * x - 1) * PadicInt.inv 3

@[continuity]
lemma continuous_inv0 : Continuous inv0 := by
  change Continuous (fun x => 2 * x)
  continuity

@[continuity]
lemma continuous_inv1 : Continuous inv1 := by
  change Continuous (fun x => (2 * x - 1) * PadicInt.inv 3)
  continuity

-- 2. PROPERTIES

lemma inv0_is_even (x : ℤ_[2]) : 2 ∣ inv0 x := by
  use x
  rfl

lemma not_two_dvd_one : ¬ (2 : ℤ_[2]) ∣ 1 := by
  intro h
  have h1 : ‖(1 : ℤ_[2])‖ < 1 := (PadicInt.norm_lt_one_iff_dvd 1).mpr h
  have h2 : ‖(1 : ℤ_[2])‖ = 1 := norm_one
  rw [h2] at h1
  exact lt_irrefl 1 h1

lemma inv1_is_odd (x : ℤ_[2]) : ¬(2 ∣ inv1 x) := by
  intro h
  rcases h with ⟨y, hy⟩
  have h1 : inv1 x * 3 = 2 * y * 3 := by rw [hy]
  have h2 : inv1 x * 3 = 2 * x - 1 := by
    calc inv1 x * 3
      _ = (2 * x - 1) * PadicInt.inv 3 * 3 := rfl
      _ = (2 * x - 1) * (PadicInt.inv 3 * 3) := by rw [mul_assoc]
      _ = (2 * x - 1) * 1 := by rw [PadicInt.inv_mul three_norm]
      _ = 2 * x - 1 := by rw [mul_one]
  have h3 : 2 * x - 1 = 2 * y * 3 := by rw [← h2, h1]
  have h4 : 1 = 2 * (x - y * 3) := by
    calc 1
      _ = 2 * x - (2 * x - 1) := by ring
      _ = 2 * x - 2 * y * 3 := by rw [h3]
      _ = 2 * (x - y * 3) := by ring
  have h5 : (2 : ℤ_[2]) ∣ 1 := ⟨x - y * 3, h4⟩
  exact not_two_dvd_one h5

-- 4. THE TRANSFER OPERATOR

def collatzTransferOp (f : C(ℤ_[2], ℂ)) : C(ℤ_[2], ℂ) where
  toFun := fun x => (1 / 2 : ℂ) * f (inv0 x) + (1 / 2 : ℂ) * f (inv1 x)
  continuous_toFun := by continuity

end CollatzZ2
