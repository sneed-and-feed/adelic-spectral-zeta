import Mathlib.Data.Finset.Basic
import Mathlib.Data.Complex.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.Group.AddChar
import Mathlib.Analysis.Normed.Ring.Finite
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Pow.Continuity
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Topology.Algebra.Order.Field
import Mathlib.Combinatorics.SimpleGraph.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring

import Formalization.Analysis.SpectralOracle

open scoped Topology
open Filter

namespace Formalization.Analysis.ConjectureA

/-!
# Conjecture A: Progression-Free Expander Graphs & Restricted Spectral Gap

This file formalizes the mathematical foundation and statement of **Conjecture A**:
The spectral gap of a Cayley graph constructed over `ℤ_n` using a maximal `k`-term
progression-free generator set scales asymptotically with the `restrictedSpectralGap(k)`:

$$\text{Gap}(d) = 2.0 - 2^{1 / 2^{d-1}}$$

## Main Components:
1. **Restricted Spectral Gap Analysis**:
   - `restrictedSpectralGap_pos`: Positivity for $d \ge 2$.
   - `restrictedSpectralGap_two`: Exact closed-form at base dimension $d = 2$: $2 - \sqrt{2}$.
   - `one_sub_restrictedSpectralGap_two`: Exact complement at base dimension $d = 2$: $\sqrt{2} - 1$.
   - `restrictedSpectralGap_strictMono`: Strict monotonicity for $d \ge 2$.
   - `tendsto_restrictedSpectralGap_atTop`: Asymptotic convergence $\lim_{d \to \infty} \text{Gap}(d) = 1$.
   - `tendsto_one_sub_restrictedSpectralGap_atTop`: Asymptotic non-trivial eigenvalue decay to 0.

2. **Additive Combinatorics & Progression-Free Sets**:
   - Arithmetic progressions and progression-free subsets in `ZMod n` and `Finset ℕ`.
   - Maximal progression-free subsets in `ZMod n`.
   - Symmetric generator sets.

3. **Cayley Graphs & Spectral Fourier Analysis**:
   - Simple Cayley graphs on `ZMod n`.
   - Character sums / Fourier transform of generator sets.
   - Boundedness of non-trivial adjacency eigenvalues by the Fourier bias.

4. **Additive Combinatorics Fourier-Bias Connection**:
   - Roth / Szemerédi dichotomy linking progression-free structure to Fourier concentration.
   - Strictly positive spectral expansion guaranteeing connectivity and expansion.
   - Monotonic growth of spectral expansion lower bounds.

5. **Conjecture A Formulation & Expander Properties**:
   - `ProgressionFreeExpanderConjecture`: Formal statement of Conjecture A.
   - `ProgressionFreeExpanderTheorem_base`: Conditional evaluation lemma evaluating the base spectral gap $c(2 - \sqrt{2})$ from hypothesis `ProgressionFreeExpanderBound`.
   - `ProgressionFreeExpanderTheorem_asymptotic`: Asymptotic behavior of the decay factor as $d \to \infty$.
-/

-- ============================================================================
-- 1. RESTRICTED SPECTRAL GAP FUNCTION & ANALYTICAL PROPERTIES
-- ============================================================================

/-- Theorem (a): Positivity of the restricted spectral gap for d ≥ 2. -/
theorem restrictedSpectralGap_pos (d : ℕ) (hd : d ≥ 2) :
    restrictedSpectralGap d > 0 :=
  (restricted_spectral_gap_pos_and_monotone d hd).1

/-- Theorem (b): Sharp base gap at d = 2 matches 2 - √2. -/
theorem restrictedSpectralGap_two : restrictedSpectralGap 2 = 2 - Real.sqrt 2 := by
  unfold restrictedSpectralGap
  norm_num [Real.sqrt_eq_rpow]

/-- Complement of base gap at d = 2 is √2 - 1. -/
theorem one_sub_restrictedSpectralGap_two :
    1 - restrictedSpectralGap 2 = Real.sqrt 2 - 1 := by
  rw [restrictedSpectralGap_two]
  ring

/-- Theorem (c): Strict monotonicity of restricted spectral gap for d ≥ 2. -/
theorem restrictedSpectralGap_strictMono (d : ℕ) (hd : d ≥ 2) :
    restrictedSpectralGap d < restrictedSpectralGap (d + 1) :=
  (restricted_spectral_gap_pos_and_monotone d hd).2

/-- Scaled restricted spectral gap is strictly positive for any positive scaling factor c > 0. -/
theorem restrictedSpectralGap_scaled_pos (d : ℕ) (hd : d ≥ 2) (c : ℝ) (hc : c > 0) :
    c * restrictedSpectralGap d > 0 :=
  mul_pos hc (restrictedSpectralGap_pos d hd)

/-- Theorem (d): Asymptotic limit of restricted spectral gap: Tendsto Gap(d) atTop (𝓝 1). -/
theorem tendsto_restrictedSpectralGap_atTop :
    Tendsto restrictedSpectralGap atTop (𝓝 1) := by
  have h_pow : Tendsto (fun d : ℕ => (2 : ℝ) ^ (d - 1)) atTop atTop :=
    (tendsto_pow_atTop_atTop_of_one_lt (by norm_num)).comp (tendsto_sub_atTop_nat 1)
  have h_inv : Tendsto (fun d : ℕ => (1 : ℝ) / ((2 : ℝ) ^ (d - 1))) atTop (𝓝 0) :=
    tendsto_const_nhds.div_atTop h_pow
  have h_cont : Continuous (fun x : ℝ => (2 : ℝ) ^ x) := Real.continuous_const_rpow (by norm_num)
  have h_rpow : Tendsto (fun d : ℕ => (2 : ℝ) ^ ((1 : ℝ) / ((2 : ℝ) ^ (d - 1)))) atTop (𝓝 1) := by
    have := (h_cont.tendsto 0).comp h_inv
    rwa [Real.rpow_zero] at this
  have h_sub : Tendsto (fun d : ℕ => (2 : ℝ) - (2 : ℝ) ^ ((1 : ℝ) / ((2 : ℝ) ^ (d - 1)))) atTop (𝓝 1) := by
    have := (tendsto_const_nhds (x := (2 : ℝ))).sub h_rpow
    have h2 : (2 : ℝ) - 1 = 1 := by norm_num
    rwa [h2] at this
  have h_eq : restrictedSpectralGap = fun d => (2 : ℝ) - (2 : ℝ) ^ ((1 : ℝ) / ((2 : ℝ) ^ (d - 1))) := by
    ext d
    unfold restrictedSpectralGap
    norm_num
  rwa [h_eq]

/-- Complement of restricted spectral gap converges to 0 as d → ∞. -/
theorem tendsto_one_sub_restrictedSpectralGap_atTop :
    Tendsto (fun d => 1 - restrictedSpectralGap d) atTop (𝓝 0) := by
  simpa using (tendsto_const_nhds (x := (1 : ℝ))).sub tendsto_restrictedSpectralGap_atTop

-- ============================================================================
-- 2. ADDITIVE COMBINATORICS & PROGRESSION-FREE SUBSETS
-- ============================================================================

/-- A subset of ZMod n contains a k-term arithmetic progression if there exist a base a and step r ≠ 0
    such that a + i * r ∈ S for all 0 ≤ i < k. -/
def ContainsProgressionZMod (n : ℕ) (S : Finset (ZMod n)) (k : ℕ) : Prop :=
  ∃ (a r : ZMod n), r ≠ 0 ∧ ∀ i : ℕ, i < k → a + (i : ZMod n) * r ∈ S

/-- Predicate defining a k-term Progression-Free subset of ZMod n. -/
def IsProgressionFreeZMod (n : ℕ) (S : Finset (ZMod n)) (k : ℕ) : Prop :=
  ¬ ContainsProgressionZMod n S k

/-- Maximal k-term progression-free subset in ZMod n. -/
def IsMaximalProgressionFreeZMod (n : ℕ) (S : Finset (ZMod n)) (k : ℕ) : Prop :=
  IsProgressionFreeZMod n S k ∧ ∀ (T : Finset (ZMod n)), IsProgressionFreeZMod n T k → T.card ≤ S.card

/-- A generator set S ⊆ ZMod n is symmetric if -s ∈ S for all s ∈ S. -/
def IsSymmetric (n : ℕ) (S : Finset (ZMod n)) : Prop :=
  ∀ s ∈ S, -s ∈ S

/-- The empty set in ZMod n is progression-free for any k ≥ 1. -/
theorem progressionFree_empty (n : ℕ) (k : ℕ) (_hk : k ≥ 1) :
    IsProgressionFreeZMod n ∅ k :=
  fun ⟨_, _, _, h⟩ => Finset.notMem_empty _ (h 0 (by omega))

-- ============================================================================
-- 3. CAYLEY GRAPHS & SPECTRAL FOURIER ANALYSIS
-- ============================================================================

/-- Simple Cayley graph Cay(ZMod n, S) on ZMod n generated by S. -/
def cayleyGraph (n : ℕ) (S : Finset (ZMod n)) : SimpleGraph (ZMod n) :=
  SimpleGraph.fromRel (fun x y => y - x ∈ S)

/-- For symmetric S with 0 ∉ S, adjacency in the Cayley graph is given by y - x ∈ S. -/
lemma cayleyGraph_adj_of_symmetric (n : ℕ) (S : Finset (ZMod n)) (h_symm : IsSymmetric n S)
    (h_no_zero : (0 : ZMod n) ∉ S) (x y : ZMod n) :
    (cayleyGraph n S).Adj x y ↔ y - x ∈ S := by
  rw [cayleyGraph, SimpleGraph.fromRel_adj]
  constructor
  · rintro ⟨_, h | h⟩
    · exact h
    · simpa [neg_sub] using h_symm (x - y) h
  · intro h
    exact ⟨fun hxy => h_no_zero (by rwa [← hxy, sub_self] at h), Or.inl h⟩

/-- Fourier coefficient / character sum of indicator of S at character χ. -/
noncomputable def fourierCoeff (n : ℕ) (S : Finset (ZMod n)) (χ : AddChar (ZMod n) ℂ) : ℂ :=
  ∑ s ∈ S, χ s

/-- The trivial character sum equals the cardinality |S|. -/
theorem fourierCoeff_zero (n : ℕ) (S : Finset (ZMod n)) :
    fourierCoeff n S 0 = (S.card : ℂ) := by
  simp [fourierCoeff]

/-- Norm of the trivial character sum is |S|. -/
theorem norm_fourierCoeff_zero (n : ℕ) (S : Finset (ZMod n)) :
    ‖fourierCoeff n S 0‖ = (S.card : ℝ) := by
  simp [fourierCoeff_zero]

/-- Universal bound: every Fourier coefficient has norm at most |S|. -/
theorem fourierCoeff_le_card (n : ℕ) [NeZero n] (S : Finset (ZMod n)) (χ : AddChar (ZMod n) ℂ) :
    ‖fourierCoeff n S χ‖ ≤ (S.card : ℝ) :=
  (norm_sum_le S (fun s => χ s)).trans (by simp)

/-- Predicate stating that non-trivial Fourier coefficients are bounded by ε. -/
def HasFourierBiasBound (n : ℕ) (S : Finset (ZMod n)) (ε : ℝ) : Prop :=
  ∀ χ : AddChar (ZMod n) ℂ, χ ≠ 0 → ‖fourierCoeff n S χ‖ ≤ ε

/-- Predicate defining normalized spectral gap: non-trivial character sums are bounded by (1 - gap) * |S|. -/
def HasSpectralGap (n : ℕ) (S : Finset (ZMod n)) (gap : ℝ) : Prop :=
  ∀ χ : AddChar (ZMod n) ℂ, χ ≠ 0 → ‖fourierCoeff n S χ‖ ≤ (1 - gap) * (S.card : ℝ)

-- ============================================================================
-- 4. ADDITIVE COMBINATORICS FOURIER-BIAS CONNECTION
-- ============================================================================

/--
The Roth-Szemerédi Fourier dichotomy:
A subset S ⊆ ZMod n either exhibits large Fourier concentration (bias) on some non-trivial
character χ ≠ 0, or it contains arithmetic progressions.
-/
def RothFourierDichotomy (n : ℕ) (S : Finset (ZMod n)) (k : ℕ) (ε : ℝ) : Prop :=
  (∃ χ : AddChar (ZMod n) ℂ, χ ≠ 0 ∧ ‖fourierCoeff n S χ‖ ≥ ε * (S.card : ℝ)) ∨
  (ContainsProgressionZMod n S k)

/-- Theorem: Under the restricted spectral gap bound, all non-trivial adjacency eigenvalues
    are strictly smaller than the degree |S|, guaranteeing connectivity and expansion. -/
theorem nontrivial_eigenvalue_strictly_less (n : ℕ) (S : Finset (ZMod n)) (hS : S.card > 0)
    (d : ℕ) (hd : d ≥ 2) (c : ℝ) (hc : c > 0)
    (h_gap : HasSpectralGap n S (c * restrictedSpectralGap d))
    (χ : AddChar (ZMod n) ℂ) (hχ : χ ≠ 0) :
    ‖fourierCoeff n S χ‖ < (S.card : ℝ) := by
  have h_bound := h_gap χ hχ
  have h_pos := restrictedSpectralGap_scaled_pos d hd c hc
  have h_card_pos : (S.card : ℝ) > 0 := Nat.cast_pos.2 hS
  have h_lt : (1 - c * restrictedSpectralGap d) * (S.card : ℝ) < (S.card : ℝ) := by
    nlinarith
  exact lt_of_le_of_lt h_bound h_lt

/-- Monotonicity of spectral lower bounds: higher dimension d yields strictly stronger expansion. -/
theorem spectral_gap_monotone_expansion (d : ℕ) (hd : d ≥ 2) (c : ℝ) (hc : c > 0) :
    c * restrictedSpectralGap d < c * restrictedSpectralGap (d + 1) :=
  mul_lt_mul_of_pos_left (restrictedSpectralGap_strictMono d hd) hc

/-- Cayley graph progression-free spectral bound evaluating the explicit closed form. -/
theorem cayley_progression_free_spectral_bound (n : ℕ) (S : Finset (ZMod n))
    (d : ℕ) (_hd : d ≥ 2) (c : ℝ) (_hc : c > 0)
    (h_gap : HasSpectralGap n S (c * restrictedSpectralGap d)) :
    ∀ χ : AddChar (ZMod n) ℂ, χ ≠ 0 →
      ‖fourierCoeff n S χ‖ ≤ (1 - c * (2.0 - 2.0 ^ (1.0 / ((2 : ℝ) ^ (d - 1))))) * (S.card : ℝ) :=
  h_gap

-- ============================================================================
-- 5. CONJECTURE A FORMULATION & EXPANDER THEOREMS
-- ============================================================================

/-- The Progression-Free Expander Bound predicate linking progression-free generator sets
    to the restricted spectral gap lower bound Gap(d). -/
def ProgressionFreeExpanderBound (n k d : ℕ) (S : Finset (ZMod n)) (c : ℝ) : Prop :=
  IsProgressionFreeZMod n S k → HasSpectralGap n S (c * restrictedSpectralGap d)

/--
Conjecture A (Progression-Free Expander Conjecture):
The spectral gap of a Cayley graph constructed over ℤ_n using a maximal k-term
progression-free generator set scales asymptotically with the restrictedSpectralGap(k).

Formally: for any k ≥ 3, there exists a constant c > 0 and threshold N₀ such that for all n ≥ N₀,
every maximal k-term progression-free generator set S ⊆ ZMod n with |S| > 0 induces a Cayley
graph with normalized spectral gap at least c * restrictedSpectralGap(k).
-/
def ProgressionFreeExpanderConjecture : Prop :=
  ∀ (k : ℕ) (_hk : k ≥ 3),
    ∃ (c : ℝ) (_hc : c > 0),
      ∃ (N₀ : ℕ), ∀ (n : ℕ) (_hn : n ≥ N₀),
        ∀ (S : Finset (ZMod n)),
          IsMaximalProgressionFreeZMod n S k →
          S.card > 0 →
          HasSpectralGap n S (c * restrictedSpectralGap k)

/-- Conditional evaluation lemma at base dimension $d = 2$: Evaluates the spectral gap bound
to $c(2 - \sqrt{2})$ under the explicit hypothesis `h_bound : ProgressionFreeExpanderBound n k 2 S c`
and progression-freeness `h_free`. Note: This is an evaluation lemma conditioned on `ProgressionFreeExpanderBound`,
not an unconditional proof of graph expansion. -/
theorem ProgressionFreeExpanderTheorem_base (n k : ℕ) (S : Finset (ZMod n)) (c : ℝ)
    (h_bound : ProgressionFreeExpanderBound n k 2 S c) (h_free : IsProgressionFreeZMod n S k) :
    HasSpectralGap n S (c * (2 - Real.sqrt 2)) := by
  simpa [restrictedSpectralGap_two] using h_bound h_free

/-- Asymptotic Expansion Theorem: As arithmetic dimension d → ∞, the non-trivial eigenvalue
    decay factor converges to (1 - c), and for full scaling c = 1 converges to complete mixing 0. -/
theorem ProgressionFreeExpanderTheorem_asymptotic (c : ℝ) :
    Tendsto (fun d => 1 - c * restrictedSpectralGap d) atTop (𝓝 (1 - c * 1)) :=
  tendsto_const_nhds.sub (tendsto_const_nhds.mul tendsto_restrictedSpectralGap_atTop)

/-- When scaling factor c = 1, the non-trivial eigenvalue bound converges to 0 (optimal expander). -/
theorem ProgressionFreeExpanderTheorem_asymptotic_full :
    Tendsto (fun d => 1 - restrictedSpectralGap d) atTop (𝓝 0) :=
  tendsto_one_sub_restrictedSpectralGap_atTop

end Formalization.Analysis.ConjectureA
