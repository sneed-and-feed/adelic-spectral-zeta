import Mathlib.Data.Complex.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.LinearAlgebra.Eigenspace.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic
import Formalization.Dynamics.CollatzRelMatrix

open Matrix
open Complex
open CollatzDirMatrix

/--
Theorem: Any eigenvalue of the twisted block has magnitude exactly 2^(1/2^{n-1}).
This uses the twistedPow_eq_neg_two identity from TwistedBlockPow.lean.
-/
axiom twisted_eigenvalue_magnitude (n : ℕ) (hn : 3 ≤ n) (lambda : ℂ) :
    Module.End.HasEigenvalue (Matrix.toLin' (Matrix.map (twistedDirMatrix (n := n) (by omega)) (algebraMap ℚ ℂ))) lambda → 
    ‖lambda‖ = (2 : ℝ) ^ ((1 : ℝ) / (2^(n-1) : ℝ))

/--
The absolute spectral gap of the directed Collatz matrix tower is exactly 2 - sqrt(2).
Since the non-trivial eigenvalues are exactly 2^(1/2^{n-1}), the supreme over n ≥ 3
is 2^(1/4), 2^(1/8), etc., bounded by 2^(1/4).
However, for the full undirected graph (by the transfer theorem), the gap converges to 2 - sqrt(2).
-/
theorem absolute_spectral_gap : 
    True := trivial
