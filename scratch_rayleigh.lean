import Mathlib.Data.Matrix.Basic
import Mathlib.LinearAlgebra.Matrix.Spectrum
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Data.Real.Basic

open Matrix
open Classical

lemma rayleigh_quotient_le_max_eigenvalue {n : Type*} [Fintype n] [DecidableEq n]
    (A : Matrix n n ℝ) (hA : A.IsHermitian) (v : n → ℝ) :
    dotProduct v (A *ᵥ v) ≤ (Finset.max' (Finset.image hA.eigenvalues Finset.univ) ⟨hA.eigenvalues (Classical.arbitrary n), Finset.mem_image_of_mem _ (Finset.mem_univ _)⟩) * dotProduct v v := by
  sorry
