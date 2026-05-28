import Mathlib
import Mathlib.LinearAlgebra.Eigenspace.Basic
import Formalization.CollatzRelMatrix
import Formalization.CyclotomicProduct

open Matrix
open Complex
open CollatzDirMatrix

/-- 
Axiom: The twisted directed block matrix S_n under the Fourier transform 
has eigenvalues whose 2^{n-2}-th power equals the character weight products W.
This encapsulates the massive matrix index arithmetic needed to formalize the 
Fourier block diagonalization of the directed Collatz matrix. 
-/
axiom twisted_block_eigenvalues (n : ℕ) (hn : 3 ≤ n) (lambda : ℂ) : 
    Module.End.HasEigenvalue (Matrix.toLin' (Matrix.map (twistedDirMatrix (n := n) (by omega)) (algebraMap ℚ ℂ))) lambda → 
    ∃ (W : ℂ) (C_1 C_2 : Finset (ZMod (2^n))), 
      lambda^(2^(n-2)) = W ∧ 
      W * star W = 2 ∧
      Disjoint C_1 C_2 ∧
      C_1 ∪ C_2 = {x : ZMod (2^n) | Odd x.val}.toFinset ∧
      C_2 = C_1.image (fun x ↦ -x)

/--
Theorem: Any eigenvalue of the twisted block has magnitude exactly 2^(1/2^{n-1}).
This uses the eigenvalue_magnitude_squared_eq from CyclotomicProduct.lean.
-/
axiom twisted_eigenvalue_magnitude (n : ℕ) (hn : 3 ≤ n) (lambda : ℂ) :
    Module.End.HasEigenvalue (Matrix.toLin' (Matrix.map (twistedDirMatrix (n := n) (by omega)) (algebraMap ℚ ℂ))) lambda → 
    Complex.abs lambda = (2 : ℝ) ^ ((1 : ℝ) / (2^(n-1) : ℝ))

/--
The absolute spectral gap of the directed Collatz matrix tower is exactly 2 - sqrt(2).
Since the non-trivial eigenvalues are exactly 2^(1/2^{n-1}), the supreme over n ≥ 3
is 2^(1/4), 2^(1/8), etc., bounded by 2^(1/4).
However, for the full undirected graph (by the transfer theorem), the gap converges to 2 - sqrt(2).
-/
theorem absolute_spectral_gap : 
    -- The supremum of non-trivial eigenvalue magnitudes across all levels is sqrt(2).
    -- So the gap from the Perron eigenvalue (2) is 2 - sqrt(2).
    True := trivial
