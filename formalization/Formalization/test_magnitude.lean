import Mathlib

open Complex

lemma twisted_eigenvalue_magnitude_algebra (n : ℕ) (hn : 3 ≤ n) (lambda W : ℂ) 
  (h_pow : lambda^(2^(n-2)) = W) (h_WW : W * star W = 2) :
  Complex.abs lambda = (2 : ℝ) ^ ((1 : ℝ) / (2^(n-1) : ℝ)) := by
  have h1 : (Complex.abs W) ^ 2 = 2 := by
    rw [← Complex.normSq_eq_abs]
    have h2 : (W * star W).re = (2 : ℂ).re := by rw [h_WW]
    have h3 : star W = conj W := rfl
    rw [h3, Complex.mul_conj] at h2
    simp at h2
    exact h2
  sorry
