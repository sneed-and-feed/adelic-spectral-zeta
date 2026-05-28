import Mathlib
import Mathlib.RingTheory.RootsOfUnity.Basic
import Mathlib.RingTheory.Polynomial.Cyclotomic.Eval

open Polynomial
open Finset

variable {F : Type _} [Field F] {n : ℕ} (zeta : F) (hzeta : IsPrimitiveRoot zeta (2^n))

lemma neg_mem_primitiveRoots (μ : F) (hn : 2 ≤ n) (hμ : μ ∈ primitiveRoots (2^n) F) :
  -μ ∈ primitiveRoots (2^n) F := by
  have hnpos : 0 < 2^n := by positivity
  have h_prim : IsPrimitiveRoot μ (2^n) := (mem_primitiveRoots hnpos).mp hμ
  apply (mem_primitiveRoots hnpos).mpr
  have heven : Even (2^n) := by
    obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le hn
    use 2 * 2^m
    ring
  constructor
  · rw [neg_pow, heven.neg_one_pow, one_mul, h_prim.pow_eq_one]
  · intro l hl
    have heven_l : Even l := by
      have hl2 : (-μ)^(2*l) = 1 := by rw [mul_comm, pow_mul, hl, one_pow]
      have hl2_pos : (-μ)^(2*l) = μ^(2*l) := by
        rw [pow_mul, neg_sq, ←pow_mul]
      rw [hl2_pos] at hl2
      have hdvd := h_prim.dvd_of_pow_eq_one _ hl2
      obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le hn
      have h1 : 2^(2+m) = 2 * 2^(1+m) := by
        rw [show 2+m = 1+(1+m) by omega, pow_add, pow_one]
      rw [h1] at hdvd
      have h2 : 2^(1+m) ∣ l := Nat.dvd_of_mul_dvd_mul_left zero_lt_two hdvd
      rcases h2 with ⟨k, rfl⟩
      use 2^m * k
      rw [show 1+m = m+1 by omega, pow_add, pow_one]
      ring
    have hl_pos : (-μ)^l = μ^l := by
      rw [neg_pow, heven_l.neg_one_pow, one_mul]
    rw [hl_pos] at hl
    exact h_prim.dvd_of_pow_eq_one _ hl
