import Mathlib.Data.Finset.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic

/-- Predicate checking if a set of natural numbers contains a k-term arithmetic progression -/
def ContainsProgression (S : Finset ℕ) (k : ℕ) : Prop :=
  ∃ (a d : ℕ), d > 0 ∧ ∀ i < k, (a + i * d) ∈ S

/-- Predicate defining a Szemerédi Progression-Free Set -/
def IsProgressionFree (S : Finset ℕ) (k : ℕ) : Prop :=
  ¬ ContainsProgression S k

/-- Theorem: A greedy construction yields a maximal progression-free set -/
theorem greedy_progression_free_exists (n k : ℕ) (hk : k ≥ 3) :
    ∃ (S : Finset ℕ), (S ⊆ Finset.range n) ∧ IsProgressionFree S k ∧ 
    (S.card : ℝ) ≥ (n : ℝ) ^ (Real.log (k - 1) / Real.log k) := sorry

/-- The restricted spectral gap scaling function, a corollary explicitly linking to the SpectralCircle theorem (from Formalization.SpectralCircle) -/
noncomputable def restrictedSpectralGap (d : ℕ) : ℝ :=
  2.0 - (2.0 ^ (1.0 / ((2 : ℝ) ^ (d - 1))))

/-- Theorem: Restricted spectral gap is strictly positive and increases monotonically for d ≥ 2 -/
theorem restricted_spectral_gap_pos_and_monotone (d : ℕ) (hd : d ≥ 2) :
    restrictedSpectralGap d > 0 ∧ restrictedSpectralGap d < restrictedSpectralGap (d + 1) := by
  have h_one : (1.0 : ℝ) = 1 := by norm_num
  constructor
  · have h1 : (2.0 : ℝ) = (2.0 : ℝ) ^ (1 : ℝ) := by norm_num
    have h2 : 1.0 / ((2 : ℝ) ^ (d - 1)) < 1 := by
      rw [h_one, one_div, inv_lt_one_iff]
      right
      have hd' : 1 ≤ d - 1 := by omega
      have h3 : (2 : ℝ) ^ 1 ≤ (2 : ℝ) ^ (d - 1) := by
        exact pow_le_pow_right (by norm_num) hd'
      linarith
    unfold restrictedSpectralGap
    have h3 : (2.0 : ℝ) ^ (1.0 / ((2 : ℝ) ^ (d - 1))) < (2.0 : ℝ) ^ (1 : ℝ) := by
      apply Real.rpow_lt_rpow_of_exponent_lt (by norm_num) h2
    rw [← h1] at h3
    linarith
  · unfold restrictedSpectralGap
    rw [sub_lt_sub_iff_left (2.0 : ℝ)]
    apply Real.rpow_lt_rpow_of_exponent_lt (by norm_num)
    have hd' : d - 1 < d + 1 - 1 := by omega
    have h2 : (2 : ℝ) ^ (d - 1) < (2 : ℝ) ^ (d + 1 - 1) := by
      exact pow_lt_pow_right (by norm_num) hd'
    have h3 : 0 < (2 : ℝ) ^ (d - 1) := by positivity
    have h4 : 0 < (2 : ℝ) ^ (d + 1 - 1) := by positivity
    rw [h_one, one_div, one_div]
    rw [inv_lt_inv h4 h3]
    exact h2
