import Mathlib
open PowerSeries

noncomputable def E_12 : PowerSeries ℚ := 0

theorem test_coeff (a b : ℚ) (f g : PowerSeries ℚ) (n : ℕ) :
  coeff ℚ n (a • f + b • g) = a * coeff ℚ n f + b * coeff ℚ n g := by
  simp [map_add, map_smul]
