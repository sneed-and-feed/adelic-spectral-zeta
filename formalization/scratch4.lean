import Mathlib

open Polynomial

def ramanujan_trunc_poly (N : ℕ) : ℤ[X] :=
  (Finset.range N).prod (fun n => (1 - (X : ℤ[X]) ^ (n + 1)) ^ 24)

def tau_poly (n : ℕ) : ℤ :=
  coeff (X * ramanujan_trunc_poly n) n

def divisor_sum_11 (n : ℕ) : ℤ :=
  (Finset.filter (fun d => n % d = 0) (Finset.Icc 1 n)).sum (fun d => (d : ℤ) ^ 11)

def ramanujan_congruence_691_poly (n : ℕ) : Prop :=
  (tau_poly n - divisor_sum_11 n) % 691 = 0

theorem tau_poly_2 : ramanujan_congruence_691_poly 2 := by
  decide
