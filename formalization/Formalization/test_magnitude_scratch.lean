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
  have h2 : Complex.abs W = Real.sqrt 2 := by
    rw [← h1]
    exact Real.sqrt_sq (Complex.abs_nonneg W)
  have h3 : Complex.abs lambda ^ (2^(n-2)) = Real.sqrt 2 := by
    rw [← map_pow]
    rw [h_pow]
    exact h2
  have h4 : Real.sqrt 2 = (2 : ℝ) ^ ((1 : ℝ) / 2) := by
    rw [Real.sqrt_eq_rpow]
    ring_nf
  rw [h4] at h3
  sorry
