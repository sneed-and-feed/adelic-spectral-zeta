import Mathlib

open Complex

lemma test_normSq (W : ℂ) : W * star W = (normSq W : ℂ) := by
  rw [star_def]
  exact mul_conj W

lemma test_abs (W : ℂ) (h : W * star W = 2) : Complex.abs W = Real.sqrt 2 := by
  have h1 : W * star W = (normSq W : ℂ) := test_normSq W
  rw [h1] at h
  -- h : (normSq W : ℂ) = 2
  have h2 : normSq W = 2 := by exact_mod_cast h
  have h3 : Complex.abs W ^ 2 = 2 := by
    rw [← Complex.normSq_eq_abs, h2]
  exact (Real.sq_eq_sq_iff_eq_sqrt (AbsoluteValue.nonneg Complex.abs W) (by positivity)).mp h3
