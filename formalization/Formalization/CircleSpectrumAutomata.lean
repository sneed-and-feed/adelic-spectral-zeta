import Mathlib
import Formalization.DFT
import Formalization.CyclotomicProduct

open Matrix Finset Complex

/-- An affine automaton on ZMod N is defined by a multiplier `a` and a set of shifts `B`. -/
structure AffineAutomaton (N : ℕ+) where
  a : ZMod N
  B : Finset (ZMod N)

namespace AffineAutomaton

variable {N : ℕ+} (A : AffineAutomaton N)

/-- The transition matrix of the affine automaton. 
    Entry (x, y) is the number of transitions from x to y. -/
noncomputable def transitionMatrix : Matrix (ZMod N) (ZMod N) ℂ :=
  fun x y ↦ ∑ b ∈ A.B, if y = A.a * x + b then 1 else 0

/-- The weight of a state k in the character basis -/
noncomputable def weight (χ : AddChar (ZMod N) ℂ) (k : ZMod N) : ℂ :=
  ∑ b ∈ A.B, χ (k * b)

/-- The orbit weight product over a cycle C -/
noncomputable def orbitWeightProduct (χ : AddChar (ZMod N) ℂ) (C : Finset (ZMod N)) : ℂ :=
  ∏ k ∈ C, weight A χ k

/-- Action on the additive character basis: 
    The transition matrix maps each character to a weighted character with multiplier a.
    This establishes the matrix acts as a generalized permutation (monomial) matrix. -/
lemma char_action (χ : AddChar (ZMod N) ℂ) (k x : ZMod N) :
    ∑ y : ZMod N, A.transitionMatrix x y * χ (k * y) =
    A.weight χ k * χ (A.a * k * x) := sorry

/-- The Fourier conjugated block -/
noncomputable def fourierMatrix (zeta : ℂ) (hzeta : IsPrimitiveRoot zeta N) :
    Matrix (ZMod N) (ZMod N) ℂ :=
  dftMatrix zeta hzeta * A.transitionMatrix * dftMatrix_star zeta hzeta

end AffineAutomaton
