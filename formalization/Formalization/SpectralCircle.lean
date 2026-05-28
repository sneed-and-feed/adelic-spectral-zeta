/-
  SpectralCircle.lean
  
  Proof that D_n acts as a monomial matrix in the character basis:
    χ_k ↦ (1 + ω^{-k}) · χ_{3k}
  
  This is the core algebraic step toward the Spectral Circle Theorem:
  all eigenvalues of S_n lie on a circle of radius 2^{1/2^{n-1}}.
-/

import Mathlib
import Formalization.CollatzRelMatrix

open Matrix Finset Complex
open CollatzDirMatrix

-- ============================================================================
-- 1. CHARACTER ACTION LEMMA
-- ============================================================================

/-- The core computation: D_n maps χ_k to (1 + ω^{-k}) · χ_{3k}.
    That is, for every x:
      ∑_y D(x, y) · ω^{ky} = (1 + ω^{-k}) · ω^{3kx}
    
    This holds because only two y-values contribute: y = 3x and y = 3x - 1.
-/
lemma collatzDirMatrix_char_action (n : ℕ) (hn : n ≥ 1)
    (ω : ℂ) (hω : IsPrimitiveRoot ω (2^n))
    (k x : ZMod (2^n)) :
    ∑ y, (algebraMap ℚ ℂ (collatzDirMatrix n x y)) * ω ^ (k * y).val =
    (1 + ω ^ ((-(k : ZMod (2^n))).val)) * ω ^ ((3 * k * x).val) := by
  -- The sum has exactly two nonzero terms: y = 3x and y = 3x - 1
  -- For y = 3x: coefficient is 1, contribution is ω^{k·3x}
  -- For y = 3x-1: coefficient is 1, contribution is ω^{k·(3x-1)} = ω^{-k} · ω^{k·3x}
  sorry

-- ============================================================================
-- 2. ORBIT STRUCTURE (×3 on odd residues)
-- ============================================================================

/-- The order of 3 in (ZMod (2^n))ˣ is 2^{n-2} for n ≥ 3.
    Classical result: 3^{2^{n-3}} ≡ 1 + 2^{n-1} (mod 2^n), so
    3^{2^{n-2}} ≡ 1 but 3^{2^{n-3}} ≢ 1. -/
lemma order_three_mod_pow_two (n : ℕ) (hn : n ≥ 3) :
    orderOf (ZMod.unitOfCoprime 3 (Nat.Coprime.pow_right n (by decide)) : (ZMod (2^n))ˣ) = 2^(n-2) := by
  sorry

-- ============================================================================
-- 3. ORBIT WEIGHT MAGNITUDE
-- ============================================================================

/-- Each orbit of ×3 on odd residues has weight product with magnitude √2.
    This follows from the cyclotomic product identity (proven in CyclotomicProduct.lean)
    combined with the symmetry C₂ = -C₁. -/
lemma orbit_weight_magnitude_sq (n : ℕ) (hn : n ≥ 3)
    (ω : ℂ) (hω : IsPrimitiveRoot ω (2^n))
    (C : Finset (ZMod (2^n)))
    (hC_orbit : ∀ k ∈ C, (3 : ZMod (2^n)) * k ∈ C)
    (hC_size : C.card = 2^(n-2))
    (hC_odd : ∀ k ∈ C, (k.val % 2 = 1)) :
    Complex.normSq (∏ k ∈ C, (1 + ω ^ ((-(k : ZMod (2^n))).val))) = 2 := by
  sorry

-- ============================================================================
-- 4. SPECTRAL CIRCLE THEOREM (combining all ingredients)
-- ============================================================================

/-- All eigenvalues of the twisted block S_n have magnitude exactly 2^{1/2^{n-1}}.

    Proof sketch:
    1. S_n restricted to odd characters is monomial (collatzDirMatrix_char_action)
    2. The ×3 orbits form 2 cycles of length 2^{n-2} (order_three_mod_pow_two)
    3. Each orbit weight has |W| = √2 (orbit_weight_magnitude_sq)
    4. Cyclic monomial eigenvalues have magnitude |W|^{1/M} = (√2)^{1/2^{n-2}} = 2^{1/2^{n-1}}
-/
theorem spectral_circle (n : ℕ) (hn : n ≥ 3)
    (μ : ℂ) (hμ : μ ∈ spectrum ℂ (Matrix.map (twistedDirMatrix (show n ≥ 2 by omega)) (algebraMap ℚ ℂ))) :
    Complex.abs μ = (2 : ℝ) ^ ((1 : ℝ) / (2^(n-1) : ℝ)) := by
  sorry
