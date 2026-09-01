import Mathlib.Algebra.Polynomial.Basic
import Mathlib.GroupTheory.PGroup
import Mathlib.FieldTheory.PolynomialGaloisGroup
import Mathlib.FieldTheory.SplittingField.Construction
import Mathlib.GroupTheory.GroupAction.Basic

open Polynomial

noncomputable section

def f_map : ℚ[X] := 8 * X - X^2

def P_d : ℕ → ℚ[X]
| 0 => X - 4
| (n + 1) => (P_d n).comp f_map

def P_9 : ℚ[X] := P_d 5

/-- Hypothesis structure capturing the Galois-theoretic assumptions on the iterate polynomial P_9. -/
structure CollatzGaloisAssumptions : Prop where
  P9_irreducible : Irreducible P_9
  P9_galois_is_2_group : IsPGroup 2 (P_9.Gal)
  P9_galois_transitive : MulAction.IsPretransitive (P_9.Gal) (P_9.rootSet P_9.SplittingField)

