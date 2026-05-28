import Mathlib

open Complex

lemma test_magnitude (n : ℕ) (hn : 3 ≤ n) (lambda W : ℂ) 
  (h_pow : lambda^(2^(n-2)) = W) (h_WW : W * star W = 2) :
  Complex.abs lambda = (2 : ℝ) ^ ((1 : ℝ) / (2^(n-1) : ℝ)) := by
  have h1 : W * star W = (normSq W : ℂ) := by
    rw [star_def]
    exact mul_conj W
  have h_normSq : normSq W = 2 := by 
    have h2 := h_WW
    rw [h1] at h2
    exact_mod_cast h2
  have h_abs_W_sq : Complex.abs W ^ 2 = 2 := by
    rw [← Complex.normSq_eq_abs, h_normSq]
  have h_abs_W : Complex.abs W = Real.sqrt 2 := by
    have h4 : Real.sqrt (Complex.abs W ^ 2) = Real.sqrt 2 := by rw [h_abs_W_sq]
    have h5 : Real.sqrt (Complex.abs W ^ 2) = Complex.abs W := Real.sqrt_sq (Complex.abs.nonneg lambda) -- wait
    sorry
