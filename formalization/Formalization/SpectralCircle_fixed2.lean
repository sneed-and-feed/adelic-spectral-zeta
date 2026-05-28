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
import Formalization.CyclotomicProduct
import Formalization.CyclotomicProduct


open Matrix Finset Complex
open CollatzDirMatrix

-- ============================================================================
-- 1. DISTINCTNESS OF COLLATZ TARGETS
-- ============================================================================

/-- The two targets 3x and 3x-1 are always distinct in ZMod(2^n) for n ≥ 1.
    Proof: if 3x = 3x - 1, then 1 = 0 in ZMod(2^n), but 2^n ≥ 2 so this is false. -/
lemma collatzDir_targets_distinct (n : ℕ) (hn : n ≥ 1) (x : ZMod (2^n)) :
    (3 : ZMod (2^n)) * x ≠ 3 * x - 1 := by
  haveI : Fact (1 < 2^n) := ⟨Nat.one_lt_two_pow (by omega)⟩
  exact sub_ne_zero.mp <| fun h => one_ne_zero <| by
    calc (1 : ZMod (2^n)) = 3*x - (3*x - 1) := by ring
      _ = 0 := h

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
  have : ∀ y, algebraMap ℚ ℂ (collatzDirMatrix n x y) * χ (k * y) = if y = 3 * x ∨ y = 3 * x - 1 then χ (k * y) else 0 := by
    intro y; simp only [collatzDirMatrix]; split_ifs <;> simp
  simp_rw [this, ← Finset.sum_filter]
  have : Finset.univ.filter (fun y => y = 3 * x ∨ y = 3 * x - 1) = {3 * x, 3 * x - 1} := by ext y; simp
  rw [this, Finset.sum_pair (collatzDir_targets_distinct n hn x)]
  have hk1 : k * (3 * x) = 3 * k * x := by ring
  have hk2 : k * (3 * x - 1) = 3 * k * x + (-k) := by ring
  rw [hk1, hk2, AddChar.map_add_mul]
  ring

-- ============================================================================
-- 3. ORBIT STRUCTURE (×3 on odd residues)
-- ============================================================================

lemma three_pow_two_pow (k : ℕ) (hk : k ≥ 1) :
    ∃ (a : ℤ), Odd a ∧ (3 : ℤ)^(2^k) = 1 + a * 2^(k+2) := by
  induction' k, hk using Nat.le_induction with k _ ih
  · use 1
    constructor
    · exact odd_one
    · norm_num
  · rcases ih with ⟨a, ha, h_eq⟩
    use a + a^2 * 2^(k+1)
    constructor
    · obtain ⟨c, hc⟩ := ha
      rw [hc]
      use c + (2 * c + 1)^2 * 2^k
      have h2 : (2 : ℤ) ^ (k + 1) = 2 * (2 : ℤ)^k := by
        rw [pow_add, pow_one, mul_comm]
      rw [h2]
      ring
    · have h1 : (3 : ℤ)^(2^(k+1)) = ((3 : ℤ)^(2^k))^2 := by
        rw [pow_add, pow_one, pow_mul]
      rw [h1, h_eq]
      ring

lemma three_pow_two_pow_mod_pow_two (n : ℕ) (hn : n ≥ 3) :
    (3 : ZMod (2^n))^(2^(n-2)) = 1 := by
  obtain ⟨a, _, h_eq⟩ := three_pow_two_pow (n - 2) (by omega)
  have h_pow : ((3 : ℤ) : ZMod (2^n))^(2^(n-2)) = (((3 : ℤ)^(2^(n-2)) : ℤ) : ZMod (2^n)) := by
    simp only [Int.cast_pow]
  have h3 : ((3 : ℤ) : ZMod (2^n)) = 3 := by norm_cast
  rw [h3] at h_pow
  rw [h_pow]
  have h_k : n - 2 + 2 = n := by omega
  have h_eq2 : (3 : ℤ)^(2^(n-2)) = 1 + a * 2^n := by
    have h_eq' := h_eq
    rw [h_k] at h_eq'
    exact h_eq'
  rw [h_eq2]
  push_cast
  have h_zero2 : (2 : ZMod (2^n))^n = 0 := by
    have h : (2 : ZMod (2^n))^n = ((2^n : ℕ) : ZMod (2^n)) := by norm_cast
    rw [h]
    exact (ZMod.natCast_zmod_eq_zero_iff_dvd (2 ^ n) (2 ^ n)).mpr (dvd_refl (2 ^ n))
  rw [h_zero2]
  ring

lemma three_pow_two_pow_mod_pow_two_ne_one (n : ℕ) (hn : n ≥ 3) :
    (3 : ZMod (2^n))^(2^(n-3)) ≠ 1 := by
  by_cases hn3 : n = 3
  · subst hn3
    decide
  · have hn4 : n ≥ 4 := by omega
    obtain ⟨a, ha, h_eq⟩ := three_pow_two_pow (n - 3) (by omega)
    intro h_one
    have h_pow : ((3 : ℤ) : ZMod (2^n))^(2^(n-3)) = (((3 : ℤ)^(2^(n-3)) : ℤ) : ZMod (2^n)) := by
      simp only [Int.cast_pow]
    have h3 : ((3 : ℤ) : ZMod (2^n)) = 3 := by norm_cast
    rw [h3] at h_pow
    rw [h_pow] at h_one
    have h_k : n - 3 + 2 = n - 1 := by omega
    have h_eq2 : (3 : ℤ)^(2^(n-3)) = 1 + a * 2^(n-1) := by
      have h_eq' := h_eq
      rw [h_k] at h_eq'
      exact h_eq'
    rw [h_eq2] at h_one
    push_cast at h_one
    have h_cancel : (1 : ZMod (2^n)) + ↑a * (2 : ZMod (2^n)) ^ (n - 1) = 1 → ↑a * (2 : ZMod (2^n)) ^ (n - 1) = 0 := by
      intro h
      calc ↑a * (2 : ZMod (2^n)) ^ (n - 1) = (1 : ZMod (2^n)) + ↑a * (2 : ZMod (2^n)) ^ (n - 1) - 1 := by ring
        _ = 1 - 1 := by rw [h]
        _ = 0 := by ring
    have h_zero := h_cancel h_one
    have h_zero_int : ((a * 2^(n-1) : ℤ) : ZMod (2^n)) = 0 := by
      calc ((a * 2^(n-1) : ℤ) : ZMod (2^n)) = ↑a * (2 : ZMod (2^n)) ^ (n - 1) := by push_cast; rfl
        _ = 0 := h_zero
    have h_dvd : ((2^n : ℕ) : ℤ) ∣ a * 2^(n-1) := by
      exact (ZMod.intCast_zmod_eq_zero_iff_dvd (a * 2 ^ (n - 1)) (2 ^ n)).mp h_zero_int
    have h_dvd2 : (2 : ℤ) ∣ a := by
      have h_pow_split : ((2^n : ℕ) : ℤ) = 2 * 2^(n-1) := by
        have hn_split : 2^n = 2^(1 + (n - 1)) := by congr 1; omega
        calc ((2^n : ℕ) : ℤ) = ((2^(1 + (n - 1)) : ℕ) : ℤ) := by rw [hn_split]
          _ = ((2^1 * 2^(n-1) : ℕ) : ℤ) := by rw [pow_add]
          _ = 2 * 2^(n-1) := by push_cast; ring
      rw [h_pow_split] at h_dvd
      have h_pos : (2^(n-1) : ℤ) ≠ 0 := by positivity
      exact mul_dvd_mul_iff_right h_pos |>.mp h_dvd
    have h_even : Even a := even_iff_two_dvd.mpr h_dvd2
    have h_odd : Odd a := ha
    exact Int.even_iff_not_odd.mp h_even h_odd

/-- The order of 3 in (ZMod (2^n))ˣ is 2^{n-2} for n ≥ 3.
    Classical result: 3^{2^{n-3}} ≡ 1 + 2^{n-1} (mod 2^n), so
    3^{2^{n-2}} ≡ 1 but 3^{2^{n-3}} ≢ 1. -/
lemma order_three_mod_pow_two (n : ℕ) (hn : n ≥ 3) :
    orderOf (ZMod.unitOfCoprime 3 (Nat.Coprime.pow_right n (by decide)) : (ZMod (2^n))ˣ) = 2^(n-2) := by
  have h_not : ¬ (ZMod.unitOfCoprime 3 (Nat.Coprime.pow_right n (by decide)) : (ZMod (2^n))ˣ) ^ 2 ^ (n - 3) = 1 := by
    intro h
    have h_eq_val : (((ZMod.unitOfCoprime 3 (Nat.Coprime.pow_right n (by decide)) : (ZMod (2^n))ˣ) ^ (2 ^ (n - 3)) : (ZMod (2^n))ˣ) : ZMod (2^n)) = (1 : ZMod (2^n)) := by
      rw [h]
      rfl
    push_cast at h_eq_val
    have h_ne := three_pow_two_pow_mod_pow_two_ne_one n hn
    exact h_ne h_eq_val
  have h_fin : (ZMod.unitOfCoprime 3 (Nat.Coprime.pow_right n (by decide)) : (ZMod (2^n))ˣ) ^ 2 ^ (n - 2) = 1 := by
    ext
    push_cast
    exact three_pow_two_pow_mod_pow_two n hn
  have h_pow_eq : 2 ^ (n - 2) = 2 ^ (n - 3 + 1) := by
    congr 1
    omega
  rw [h_pow_eq]
  rw [h_pow_eq] at h_fin
  exact orderOf_eq_prime_pow h_not h_fin

-- ============================================================================
-- 4. ORBIT WEIGHT MAGNITUDE
-- ============================================================================



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
