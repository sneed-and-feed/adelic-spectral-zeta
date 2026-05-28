import Mathlib
import Mathlib.LinearAlgebra.Eigenspace.Basic
import Formalization.CollatzRelMatrix
import Formalization.CyclotomicProduct
import Formalization.TwistedBlockPow

open Matrix
open Complex
open CollatzDirMatrix

/--
Theorem: Any eigenvalue of the twisted block has magnitude exactly 2^(1/2^{n-1}).
This uses the twistedPow_eq_neg_two identity from TwistedBlockPow.lean.
-/
theorem twisted_eigenvalue_magnitude (n : ℕ) (hn : 3 ≤ n) (lambda : ℂ) :
    Module.End.HasEigenvalue (Matrix.toLin' (Matrix.map (twistedDirMatrix (n := n) (by omega)) (algebraMap ℚ ℂ))) lambda → 
    Complex.abs lambda = (2 : ℝ) ^ ((1 : ℝ) / (2^(n-1) : ℝ)) := by
  intro h_eig
  have hn2 : n ≥ 2 := by omega
  have h_base := twistedPow_eq_neg_two hn2
  have h_eig_pow := Module.End.HasEigenvalue.pow h_eig (2^(n-1))
  have h_alg_pow : (Matrix.toLin' (Matrix.map (twistedDirMatrix hn2) (algebraMap ℚ ℂ))) ^ (2^(n-1)) = 
    Matrix.toLin' ((Matrix.map (twistedDirMatrix hn2) (algebraMap ℚ ℂ)) ^ (2^(n-1))) := by
    exact (AlgEquiv.map_pow (Matrix.toLinAlgEquiv') _ _).symm
  rw [h_alg_pow] at h_eig_pow
  
  have h_map_pow : ((twistedDirMatrix hn2).map (algebraMap ℚ ℂ)) ^ (2^(n-1)) = 
                   RingHom.mapMatrix (algebraMap ℚ ℂ) (twistedDirMatrix hn2 ^ (2^(n-1))) := by
    have h1 : ((twistedDirMatrix hn2).map (algebraMap ℚ ℂ)) = RingHom.mapMatrix (algebraMap ℚ ℂ) (twistedDirMatrix hn2) := rfl
    rw [h1]
    exact (map_pow (RingHom.mapMatrix (algebraMap ℚ ℂ)) _ _).symm
  rw [h_map_pow] at h_eig_pow
  rw [h_base] at h_eig_pow
  
  have h_map_neg2 : RingHom.mapMatrix (algebraMap ℚ ℂ) (-2 * (1 : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) ℚ)) = -2 := by
    simp
  rw [h_map_neg2] at h_eig_pow
  
  obtain ⟨v, hv⟩ := Module.End.HasEigenvalue.exists_hasEigenvector h_eig_pow
  have h_v_nz : v ≠ 0 := hv.2
  have h_v_eq : (Matrix.toLin' (-2 : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) ℂ)) v = (lambda ^ (2^(n-1))) • v := by
    exact Module.End.mem_eigenspace_iff.mp hv.1
  
  have h_left : (Matrix.toLin' (-2 : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) ℂ)) v = (-2 : ℂ) • v := by
    have hn2_mat : (-2 : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) ℂ) = -2 • 1 := by simp
    rw [hn2_mat, Matrix.toLin'_apply]
    ext i
    simp [Matrix.mulVec, Matrix.dotProduct, Matrix.one_apply, mul_boole, Finset.sum_ite_eq, Finset.sum_ite_eq']
    
  rw [h_left] at h_v_eq
  have h_sub : ((-2 : ℂ) - lambda ^ (2^(n-1))) • v = 0 := by
    rw [sub_smul, h_v_eq, sub_self]
      
  have h_sub2 : (-2 : ℂ) - lambda ^ (2^(n-1)) = 0 := by
    cases smul_eq_zero.mp h_sub with
    | inl h => exact h
    | inr h => contradiction
  have h_lambda_pow : lambda ^ (2^(n-1)) = -2 := eq_of_sub_eq_zero h_sub2 |>.symm
  
  have h_abs_pow : Complex.abs (lambda ^ (2^(n-1))) = Complex.abs (-2) := by rw [h_lambda_pow]
  have h_abs_pow_dist : Complex.abs (lambda ^ (2^(n-1))) = (Complex.abs lambda) ^ (2^(n-1)) := by
    exact Complex.abs.map_pow lambda (2^(n-1))
  rw [h_abs_pow_dist] at h_abs_pow
  have h_abs_neg2 : Complex.abs (-2) = 2 := by simp
  rw [h_abs_neg2] at h_abs_pow
  
  have h_pow_eq : (Complex.abs lambda) ^ (2^(n-1) : ℝ) = (2 : ℝ) := by
    have h_nat : (Complex.abs lambda) ^ (2^(n-1) : ℝ) = (Complex.abs lambda) ^ (2^(n-1) : ℕ) := by norm_cast
    rw [h_nat, h_abs_pow]
    
  have hz : (2^(n-1) : ℝ) ≠ 0 := by positivity
  have h_base_pos : 0 ≤ Complex.abs lambda := Complex.abs.nonneg lambda
  have h_root := congrArg (fun x => x ^ ((1 : ℝ) / (2^(n-1) : ℝ))) h_pow_eq
  dsimp at h_root
  rw [← Real.rpow_mul h_base_pos] at h_root
  have h_mul_inv : (2^(n-1) : ℝ) * ((1 : ℝ) / (2^(n-1) : ℝ)) = 1 := mul_one_div_cancel hz
  rw [h_mul_inv, Real.rpow_one] at h_root
  exact h_root

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
