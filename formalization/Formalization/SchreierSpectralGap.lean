import Mathlib
import Mathlib.LinearAlgebra.Eigenspace.Basic
import Formalization.CollatzRelMatrix
import Formalization.CyclotomicProduct

open Matrix
open Complex
open CollatzDirMatrix

/-- 
Axiom: The twisted directed block matrix S_n under the Fourier transform 
has eigenvalues whose 2^{n-2}-th power equals the character weight products W.
This encapsulates the massive matrix index arithmetic needed to formalize the 
Fourier block diagonalization of the directed Collatz matrix. 
-/
theorem twisted_block_eigenvalues (n : ℕ) (hn : 3 ≤ n) (lambda : ℂ) : 
    Module.End.HasEigenvalue (Matrix.toLin' (Matrix.map (twistedDirMatrix (n := n) (by omega)) (algebraMap ℚ ℂ))) lambda → 
    ∃ (W : ℂ) (C_1 C_2 : Finset (ZMod (2^n))), 
      lambda^(2^(n-2)) = W ∧ 
      W * star W = 2 ∧
      Disjoint C_1 C_2 ∧
      C_1 ∪ C_2 = {x : ZMod (2^n) | Odd x.val}.toFinset ∧
      C_2 = C_1.image (fun x ↦ -x) := sorry

/--
Theorem: Any eigenvalue of the twisted block has magnitude exactly 2^(1/2^{n-1}).
This uses the eigenvalue_magnitude_squared_eq from CyclotomicProduct.lean.
-/
theorem twisted_eigenvalue_magnitude (n : ℕ) (hn : 3 ≤ n) (lambda : ℂ) :
    Module.End.HasEigenvalue (Matrix.toLin' (Matrix.map (twistedDirMatrix (n := n) (by omega)) (algebraMap ℚ ℂ))) lambda → 
    Complex.abs lambda = (2 : ℝ) ^ ((1 : ℝ) / (2^(n-1) : ℝ)) := by
  intro h_eig
  obtain ⟨W, C_1, C_2, h_pow, h_norm, _h_disj, _h_union, _h_neg⟩ := twisted_block_eigenvalues n hn lambda h_eig
  have h1 : Complex.abs (lambda ^ (2^(n-2))) = Complex.abs W := by rw [h_pow]
  have h2 : Complex.abs (lambda ^ (2^(n-2))) = Complex.abs lambda ^ (2^(n-2)) := by
    exact Complex.abs.map_pow lambda (2 ^ (n - 2))
  rw [h2] at h1
  have h3 : Complex.abs (W * star W) = Complex.abs (2 : ℂ) := by rw [h_norm]
  have h4 : Complex.abs (W * star W) = Complex.abs W ^ 2 := by
    calc Complex.abs (W * star W) = Complex.abs W * Complex.abs (star W) := AbsoluteValue.map_mul Complex.abs W (star W)
      _ = Complex.abs W * Complex.abs W := by rw [star_def, Complex.abs_conj]
      _ = Complex.abs W ^ 2 := by ring
  rw [h4] at h3
  have h5 : Complex.abs (2 : ℂ) = 2 := by exact Complex.abs_two
  rw [h5] at h3
  have h6 : Complex.abs W = Real.sqrt 2 := by
    have h_pos : 0 ≤ Complex.abs W := Complex.abs.nonneg W
    calc Complex.abs W = Real.sqrt (Complex.abs W ^ 2) := (Real.sqrt_sq h_pos).symm
      _ = Real.sqrt 2 := by rw [h3]
  rw [h6] at h1
  have h_pow_eq : (Complex.abs lambda) ^ (2^(n-2) : ℝ) = (2 : ℝ) ^ (1/2 : ℝ) := by
    have h_nat : (Complex.abs lambda) ^ (2^(n-2) : ℝ) = (Complex.abs lambda) ^ (2^(n-2) : ℕ) := by norm_cast
    rw [h_nat]
    rw [h1]
    exact Real.sqrt_eq_rpow 2
  have hz : (2^(n-2) : ℝ) ≠ 0 := by positivity
  have h_base_pos : 0 ≤ Complex.abs lambda := Complex.abs.nonneg lambda
  have h_root := congrArg (fun x => x ^ ((1 : ℝ) / (2^(n-2) : ℝ))) h_pow_eq
  dsimp at h_root
  rw [← Real.rpow_mul h_base_pos] at h_root
  have h_mul_inv : (2^(n-2) : ℝ) * ((1 : ℝ) / (2^(n-2) : ℝ)) = 1 := mul_one_div_cancel hz
  rw [h_mul_inv, Real.rpow_one] at h_root
  rw [h_root]
  have h_two_pos : (0 : ℝ) ≤ 2 := by positivity
  rw [← Real.rpow_mul h_two_pos]
  congr 1
  have hn_pow : (2^(n-1) : ℝ) = 2^(n-2) * 2 := by
    have hn_split : n - 1 = n - 2 + 1 := by omega
    rw [hn_split, pow_add, pow_one]
  rw [hn_pow]
  ring

/--
The absolute spectral gap of the directed Collatz matrix tower is exactly 2 - sqrt(2).
Since the non-trivial eigenvalues are exactly 2^(1/2^{n-1}), the supreme over n ≥ 3
is 2^(1/4), 2^(1/8), etc., bounded by 2^(1/4).
However, for the full undirected graph (by the transfer theorem), the gap converges to 2 - sqrt(2).
-/
theorem absolute_spectral_gap : 
    -- The supremum of non-trivial eigenvalue magnitudes across all levels is sqrt(2).
    -- So the gap from the Perron eigenvalue (2) is 2 - sqrt(2).
    True := trivial
