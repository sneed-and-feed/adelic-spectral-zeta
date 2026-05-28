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
    have h5 : Real.sqrt (Complex.abs W ^ 2) = Complex.abs W := Real.sqrt_sq (Complex.abs.nonneg W)
    rwa [h5] at h4

  have h_abs_lambda_pow : Complex.abs lambda ^ (2^(n-2)) = Real.sqrt 2 := by
    have h_abs_pow : Complex.abs (lambda ^ (2^(n-2))) = Complex.abs W := by rw [h_pow]
    rw [map_pow] at h_abs_pow
    rw [h_abs_pow]
    exact h_abs_W
    
  have h_abs_lambda_rpow : (Complex.abs lambda : ℝ) ^ ((2^(n-2) : ℕ) : ℝ) = Real.sqrt 2 := by
    have h_pow_eq_rpow : (Complex.abs lambda : ℝ) ^ (2^(n-2) : ℕ) = (Complex.abs lambda : ℝ) ^ ((2^(n-2) : ℕ) : ℝ) := by
      exact (Real.rpow_natCast (Complex.abs lambda) (2 ^ (n - 2))).symm
    rw [← h_pow_eq_rpow]
    exact h_abs_lambda_pow

  -- Real.sqrt 2 = 2 ^ (1/2)
  have h_sqrt2 : Real.sqrt 2 = (2 : ℝ) ^ (1/2 : ℝ) := by
    rw [Real.sqrt_eq_rpow]

  rw [h_sqrt2] at h_abs_lambda_rpow
  
  -- Now we have (abs lambda) ^ (2^(n-2)) = 2 ^ (1/2)
  -- Take (1 / 2^(n-2))-th power on both sides
  -- (abs lambda) = 2 ^ (1 / 2 / 2^(n-2)) = 2 ^ (1 / 2^(n-1))
  sorry
