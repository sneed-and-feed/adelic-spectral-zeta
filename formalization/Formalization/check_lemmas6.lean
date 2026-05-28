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
  
  have h_rpow_inv : ((Complex.abs lambda : ℝ) ^ ((2^(n-2) : ℕ) : ℝ)) ^ (1 / ((2^(n-2) : ℕ) : ℝ)) = ((2 : ℝ) ^ (1/2 : ℝ)) ^ (1 / ((2^(n-2) : ℕ) : ℝ)) := by
    rw [h_abs_lambda_rpow]

  have h_rpow_mul : ((Complex.abs lambda : ℝ) ^ ((2^(n-2) : ℕ) : ℝ)) ^ (1 / ((2^(n-2) : ℕ) : ℝ)) = (Complex.abs lambda : ℝ) ^ (((2^(n-2) : ℕ) : ℝ) * (1 / ((2^(n-2) : ℕ) : ℝ))) := by
    exact ← Real.rpow_mul (Complex.abs.nonneg lambda) ((2 ^ (n - 2) : ℝ)) (1 / (2 ^ (n - 2) : ℝ))

  rw [h_rpow_mul] at h_rpow_inv
  
  have h_cancel : ((2^(n-2) : ℕ) : ℝ) * (1 / ((2^(n-2) : ℕ) : ℝ)) = 1 := by
    apply mul_one_div_cancel
    have h_pos : (0 : ℝ) < ((2^(n-2) : ℕ) : ℝ) := by
      apply Nat.cast_pos.mpr
      apply pow_pos
      exact zero_lt_two
    exact ne_of_gt h_pos

  rw [h_cancel] at h_rpow_inv
  
  have h_pow_one : (Complex.abs lambda : ℝ) ^ (1 : ℝ) = Complex.abs lambda := by
    exact Real.rpow_one (Complex.abs lambda)

  rw [h_pow_one] at h_rpow_inv
  
  -- now h_rpow_inv is: Complex.abs lambda = (2 ^ (1/2)) ^ (1 / 2^(n-2))
  rw [h_rpow_inv]
  
  have h_2_rpow_mul : ((2 : ℝ) ^ (1/2 : ℝ)) ^ (1 / ((2^(n-2) : ℕ) : ℝ)) = (2 : ℝ) ^ ((1/2 : ℝ) * (1 / ((2^(n-2) : ℕ) : ℝ))) := by
    exact ← Real.rpow_mul (by positivity) (1 / 2) (1 / (2 ^ (n - 2) : ℝ))
  
  rw [h_2_rpow_mul]
  
  have h_mul_div : (1/2 : ℝ) * (1 / ((2^(n-2) : ℕ) : ℝ)) = 1 / ((2^(n-1) : ℕ) : ℝ) := by
    -- 1/2 * 1 / 2^(n-2) = 1 / (2 * 2^(n-2)) = 1 / 2^(n-1)
    rw [one_div_mul_one_div]
    congr 1
    have h_2_cast : (2 : ℝ) = ((2 : ℕ) : ℝ) := by exact rfl
    rw [h_2_cast]
    rw [← Nat.cast_mul]
    congr 1
    have h_pow_add : 2 * 2 ^ (n - 2) = 2 ^ (n - 1) := by
      have hn2 : 1 ≤ n - 1 := by omega
      have hn3 : n - 2 + 1 = n - 1 := by omega
      have eq : 2 * 2 ^ (n - 2) = 2 ^ (n - 2 + 1) := by
        exact (pow_succ' 2 (n - 2)).symm
      rw [eq, hn3]
    exact h_pow_add
    
  rw [h_mul_div]
