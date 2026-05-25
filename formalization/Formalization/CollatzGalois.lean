import Mathlib

open Polynomial

noncomputable section

def f_map : ℚ[X] := 8 * X - X^2

def P_d : ℕ → ℚ[X]
| 0 => X - 4
| (n + 1) => (P_d n).comp f_map

def P_9 : ℚ[X] := P_d 5

axiom P9_irreducible : Irreducible P_9

axiom P9_galois_is_2_group : IsPGroup 2 (P_9.Gal)

axiom P9_galois_transitive : MulAction.IsPretransitive (P_9.Gal) (P_9.rootSet P_9.SplittingField)
