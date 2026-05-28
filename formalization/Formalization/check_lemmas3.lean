import Mathlib

open Complex

lemma test_abs (W : ℂ) (h : W * star W = 2) : Complex.abs W = Real.sqrt 2 := by
  have h1 : W * star W = (normSq W : ℂ) := by
    rw [star_def]
    exact mul_conj W
  rw [h1] at h
  have h2 : normSq W = 2 := by exact_mod_cast h
  have h3 : Complex.abs W ^ 2 = 2 := by
    rw [← Complex.normSq_eq_abs, h2]
  have h4 : Real.sqrt (Complex.abs W ^ 2) = Real.sqrt 2 := by rw [h3]
  have h5 : Real.sqrt (Complex.abs W ^ 2) = Complex.abs W := Real.sqrt_sq (Complex.abs.nonneg W)
  rw [h5] at h4
  exact h4
