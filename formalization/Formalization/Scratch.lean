import Mathlib
import Mathlib.LinearAlgebra.Eigenspace.Basic
import Formalization.CollatzRelMatrix
import Formalization.CyclotomicProduct
import Formalization.TwistedBlockPow

open Matrix
open Complex
open CollatzDirMatrix

theorem twisted_eigenvalue_magnitude (n : ℕ) (hn : 3 ≤ n) (lambda : ℂ) :
    Module.End.HasEigenvalue (Matrix.toLin' (Matrix.map (twistedDirMatrix (n := n) (by omega)) (algebraMap ℚ ℂ))) lambda → 
    Complex.abs lambda = (2 : ℝ) ^ ((1 : ℝ) / (2^(n-1) : ℝ)) := by
  intro h_eig
  have hn2 : 2 ≤ n := by omega
  set S := twistedDirMatrix hn2
  have h_id := twistedPow_eq_neg_two hn2
  have h_map : (RingHom.mapMatrix (algebraMap ℚ ℂ)) (S ^ (2^(n-1))) = (RingHom.mapMatrix (algebraMap ℚ ℂ)) (-2 * 1) := by
    rw [h_id]
  rw [map_pow] at h_map
  have h_rhs : (RingHom.mapMatrix (algebraMap ℚ ℂ)) (-2 * 1) = -2 * 1 := by
    simp
  sorry
