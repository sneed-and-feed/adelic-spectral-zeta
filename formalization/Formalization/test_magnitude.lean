
import Mathlib
import Mathlib.LinearAlgebra.Eigenspace.Basic
import Formalization.CollatzRelMatrix
import Formalization.CyclotomicProduct

open Matrix
open Complex
open CollatzDirMatrix

axiom twisted_block_eigenvalues (n : ℕ) (hn : 3 ≤ n) (lambda : ℂ) : 
    Module.End.HasEigenvalue (Matrix.toLin' (Matrix.map (twistedDirMatrix (n := n) (by omega)) (algebraMap ℚ ℂ))) lambda → 
    ∃ (W : ℂ) (C_1 C_2 : Finset (ZMod (2^n))), 
      lambda^(2^(n-2)) = W ∧ 
      W * star W = 2 ∧
      Disjoint C_1 C_2 ∧
      C_1 ∪ C_2 = {x : ZMod (2^n) | Odd x.val}.toFinset ∧
      C_2 = C_1.image (fun x ↦ -x)

lemma twisted_eigenvalue_magnitude (n : ℕ) (hn : 3 ≤ n) (lambda : ℂ) :
    Module.End.HasEigenvalue (Matrix.toLin' (Matrix.map (twistedDirMatrix (n := n) (by omega)) (algebraMap ℚ ℂ))) lambda → 
    Complex.abs lambda = (2 : ℝ) ^ ((1 : ℝ) / (2^(n-1) : ℝ)) := by
  intro h_eig
  obtain ⟨W, C_1, C_2, h_lam, h_W_star, h_disj, h_union, h_neg⟩ := twisted_block_eigenvalues n hn lambda h_eig
  -- We have lambda ^ (2^(n-2)) = W
  -- So (lambda * star lambda) ^ (2^(n-2)) = W * star W = 2
  have h1 : (lambda * star lambda) ^ (2^(n-2)) = 2 := by
    calc
      (lambda * star lambda) ^ (2^(n-2)) = lambda ^ (2^(n-2)) * (star lambda) ^ (2^(n-2)) := by rw [mul_pow]
      _ = lambda ^ (2^(n-2)) * star (lambda ^ (2^(n-2))) := by rw [star_pow]
      _ = W * star W := by rw [h_lam]
      _ = 2 := h_W_star
  
  -- lambda * star lambda = (Complex.abs lambda)^2
  have h2 : lambda * star lambda = (Complex.abs lambda ^ 2 : ℝ) := by
    sorry
  sorry
