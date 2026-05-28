import Mathlib

open Polynomial
open Finset

variable {F : Type _} [Field F] {n : ℕ} (zeta : F) (hzeta : IsPrimitiveRoot zeta (2^n))

lemma eval_neg_one_cyclotomic_two_pow (hn : 2 ≤ n) : 
  eval (-1) (cyclotomic (2^n) F) = 2 := by
  sorry
