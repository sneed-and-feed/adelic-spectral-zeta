/-
  SpectralCircle.lean
  
  Core lemma: D_n acts as a monomial matrix in the character basis.
  The additive character χ satisfies:
    ∑_y D(x,y) · χ(k·y) = (1 + χ(-k)) · χ(3k·x)
  
  This is the algebraic foundation of the Spectral Circle Theorem:
  all eigenvalues of S_n lie on a circle of radius 2^{1/2^{n-1}}.
-/

import Mathlib
import Formalization.CollatzRelMatrix
import Formalization.DFT

open Matrix Finset Complex
open CollatzDirMatrix

-- ============================================================================
-- 1. DISTINCTNESS OF COLLATZ TARGETS
-- ============================================================================

/-- The two targets 3x and 3x-1 are always distinct in ZMod(2^n) for n ≥ 1.
    Proof: if 3x = 3x - 1, then 1 = 0 in ZMod(2^n), but 2^n ≥ 2 so this is false. -/
lemma collatzDir_targets_distinct (n : ℕ) (hn : n ≥ 1) (x : ZMod (2^n)) :
    (3 : ZMod (2^n)) * x ≠ 3 * x - 1 := by
  intro h
  -- From 3x = 3x - 1 we get 1 = 0
  have h1 : (1 : ZMod (2^n)) = 0 := by
    have : 3 * x - (3 * x - 1) = 1 := by ring
    rw [← this]
    rw [sub_eq_zero.mpr h]
  -- But 2^n ≥ 2, so ZMod(2^n) is nontrivial and 1 ≠ 0
  have h2 : 1 < 2^n := by
    calc 1 < 2 := by omega
      _ = 2^1 := by ring
      _ ≤ 2^n := Nat.pow_le_pow_right (by omega) hn
  haveI : Fact (1 < 2^n) := ⟨h2⟩
  exact absurd h1 (by exact one_ne_zero)

-- ============================================================================
-- 2. CHARACTER ACTION LEMMA (the monomial structure)
-- ============================================================================

/-- The core monomial action: D_n maps χ_k to (1 + χ(-k)) · χ_{3k}.

    For an additive character χ:
    ∑_y D(x,y) · χ(ky) = χ(k·3x) + χ(k·(3x-1))
                        = χ(3kx) + χ(3kx + (-k))
                        = χ(3kx) + χ(3kx)·χ(-k)
                        = (1 + χ(-k)) · χ(3kx)
-/
lemma collatzDirMatrix_char_action (n : ℕ) (hn : n ≥ 1)
    (χ : AddChar (ZMod (2^n)) ℂ)
    (k x : ZMod (2^n)) :
    ∑ y : ZMod (2^n), (algebraMap ℚ ℂ (collatzDirMatrix n x y)) * χ (k * y) =
    (1 + χ (-k)) * χ (3 * k * x) := by
  -- Step 1: Rewrite each summand. collatzDirMatrix n x y is an ite.
  have h_simp : ∀ y : ZMod (2^n),
      algebraMap ℚ ℂ (collatzDirMatrix n x y) * χ (k * y) =
      if (y = 3 * x ∨ y = 3 * x - 1) then χ (k * y) else 0 := by
    intro y
    simp only [collatzDirMatrix]
    split_ifs with h
    · simp [_root_.map_one]
    · simp [_root_.map_zero]
  simp_rw [h_simp]
  -- Step 2: The sum is over exactly two elements
  rw [← Finset.sum_filter]
  have h_filter : Finset.univ.filter (fun y => y = 3 * x ∨ y = 3 * x - 1) =
      {3 * x, 3 * x - 1} := by
    ext y; simp [Finset.mem_filter, Finset.mem_insert, Finset.mem_singleton]
  rw [h_filter]
  rw [Finset.sum_pair (collatzDir_targets_distinct n hn x)]
  -- Step 3: Simplify k*(3x) and k*(3x-1) using ring and character additivity
  have hk1 : k * (3 * x) = 3 * k * x := by ring
  have hk2 : k * (3 * x - 1) = 3 * k * x + (-k) := by ring
  rw [hk1, hk2]
  rw [AddChar.map_add_mul]
  ring

-- ============================================================================
-- 3. ORBIT STRUCTURE (×3 on odd residues)
-- ============================================================================

/-- The order of 3 in (ZMod (2^n))ˣ is 2^{n-2} for n ≥ 3.
    Classical result: 3^{2^{n-3}} ≡ 1 + 2^{n-1} (mod 2^n), so
    3^{2^{n-2}} ≡ 1 but 3^{2^{n-3}} ≢ 1. -/
lemma order_three_mod_pow_two (n : ℕ) (hn : n ≥ 3) :
    orderOf (ZMod.unitOfCoprime 3 (Nat.Coprime.pow_right n (by decide)) : (ZMod (2^n))ˣ) = 2^(n-2) := by
  sorry

-- ============================================================================
-- 4. ORBIT WEIGHT MAGNITUDE
-- ============================================================================

/-- Each orbit of ×3 on odd residues has weight product with magnitude √2.
    This follows from the cyclotomic product identity (proven in CyclotomicProduct.lean)
    combined with the symmetry C₂ = -C₁. -/
lemma orbit_weight_magnitude_sq (n : ℕ) (hn : n ≥ 3)
    (χ : AddChar (ZMod (2^n)) ℂ)
    (hχ : IsPrimitiveRoot (χ 1) (⟨2^n, by positivity⟩ : ℕ+))
    (C : Finset (ZMod (2^n)))
    (hC_orbit : ∀ k ∈ C, (3 : ZMod (2^n)) * k ∈ C)
    (hC_size : C.card = 2^(n-2))
    (hC_odd : ∀ k ∈ C, (k.val % 2 = 1)) :
    Complex.normSq (∏ k ∈ C, (1 + χ (-k))) = 2 := by
  sorry

-- ============================================================================
-- 5. SPECTRAL CIRCLE THEOREM (combining all ingredients)
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
