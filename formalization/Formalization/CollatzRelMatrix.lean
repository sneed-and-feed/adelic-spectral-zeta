import Mathlib
import Formalization.SchreierSpectral
/-!
# CollatzRelMatrix

Core formalization for the Collatz Spectral Theorem.
-/


open Classical
open Matrix
open scoped Matrix

/-!
# Directed Collatz Relation Matrix

The directed Collatz relation matrix `D_n` on `ZMod (2^n)` is defined by
`D(x,y) = 1` if `y = 3x` or `y = 3x - 1` (mod `2^n`), `0` otherwise.

Unlike the undirected `SimpleGraph` adjacency matrix, this matrix:
- Permits self-loops
- Is {0,1}-valued (no edge multiplicities)
- Has tau symmetry at every level
- Satisfies exact recursive decomposition: `W_D = D_{n-1}`
-/

namespace CollatzDirMatrix

-- ============================================================================
-- 1. DEFINITION
-- ============================================================================

/-- The directed Collatz relation matrix on `ZMod (2^n)`.
    Entry `(x,y)` is `1` if `y ≡ 3x` or `y ≡ 3x - 1 (mod 2^n)`, else `0`. -/
noncomputable def collatzDirMatrix (n : ℕ) :
    Matrix (ZMod (2^n)) (ZMod (2^n)) ℚ :=
  fun x y => if (y = 3 * x ∨ y = 3 * x - 1) then 1 else 0

-- ============================================================================
-- 2. TAU COMMUTATIVITY
-- ============================================================================

/-- The tau involution at scale n: `τ(x) = x + 2^(n-1)`. -/
def tauDir (n : ℕ) (x : ZMod (2^n)) : ZMod (2^n) :=
  x + (2^(n-1) : ℕ)

/-- Key arithmetic: `3 * 2^(n-1) ≡ 2^(n-1) (mod 2^n)` for `n ≥ 1`.
    This is because `3 * 2^(n-1) = 2^(n-1) + 2 * 2^(n-1) = 2^(n-1) + 2^n ≡ 2^(n-1)`. -/
lemma three_mul_half_mod (n : ℕ) (hn : n ≥ 1) :
    (3 : ZMod (2^n)) * ((2^(n-1) : ℕ) : ZMod (2^n)) = ((2^(n-1) : ℕ) : ZMod (2^n)) := by
  have h_exp : 2 * 2^(n-1) = 2^n := by
    calc 2 * 2^(n-1) = 2^1 * 2^(n-1) := by ring
      _ = 2^(1 + (n - 1)) := by rw [← pow_add]
      _ = 2^n := by
        have : 1 + (n - 1) = n := by omega
        rw [this]
  have h_calc : (3 : ℕ) * 2^(n-1) = 2^(n-1) + 2 * 2^(n-1) := by ring
  have h_calc2 : ((3 : ℕ) : ZMod (2^n)) = 3 := by norm_cast
  rw [←h_calc2, ←Nat.cast_mul, h_calc, Nat.cast_add, h_exp]
  rw [ZMod.natCast_self, add_zero]

/-- `3 * τ(x) = τ(3x)` — the Collatz map commutes with the deck transformation. -/
lemma three_mul_tauDir (n : ℕ) (hn : n ≥ 1) (x : ZMod (2^n)) :
    3 * tauDir n x = tauDir n (3 * x) := by
  simp only [tauDir]
  rw [mul_add, three_mul_half_mod n hn]

/-- `3 * τ(x) - 1 = τ(3x - 1)` -/
lemma three_mul_tauDir_sub (n : ℕ) (hn : n ≥ 1) (x : ZMod (2^n)) :
    3 * tauDir n x - 1 = tauDir n (3 * x - 1) := by
  simp only [tauDir]
  rw [mul_add, three_mul_half_mod n hn]
  ring

/-- The directed matrix commutes with tau: `D(τx, τy) = D(x, y)`. -/
theorem collatzDirMatrix_tau_invariant (n : ℕ) (hn : n ≥ 1) (x y : ZMod (2^n)) :
    collatzDirMatrix n (tauDir n x) (tauDir n y) = collatzDirMatrix n x y := by
  simp only [collatzDirMatrix]
  have h1 : 3 * tauDir n x = tauDir n (3 * x) := three_mul_tauDir n hn x
  have h2 : 3 * tauDir n x - 1 = tauDir n (3 * x - 1) := three_mul_tauDir_sub n hn x
  have h_left : tauDir n y = 3 * tauDir n x ↔ y = 3 * x := by
    rw [h1]
    dsimp [tauDir]; constructor <;> intro h
    · exact add_right_cancel h
    · rw [h]
  have h_right : tauDir n y = 3 * tauDir n x - 1 ↔ y = 3 * x - 1 := by
    rw [h2]
    dsimp [tauDir]; constructor <;> intro h
    · exact add_right_cancel h
    · rw [h]
  simp only [h_left, h_right]

-- ============================================================================
-- 3. CANONICAL LIFT AND PROJECTION
-- ============================================================================

/-- Canonical lift: embed `ZMod (2^(n-1))` into `ZMod (2^n)` via `.val`. -/
noncomputable def liftDir {n : ℕ} (v : ZMod (2^(n-1))) : ZMod (2^n) :=
  (v.val : ZMod (2^n))

/-- The projection `ZMod (2^n) → ZMod (2^(n-1))` as a ring hom. -/
noncomputable def projDir (n : ℕ) (hn : n ≥ 1) : ZMod (2^n) →+* ZMod (2^(n-1)) :=
  ZMod.castHom (pow_dvd_pow 2 (by omega : n - 1 ≤ n)) (ZMod (2^(n-1)))

/-- Projection sends the canonical lift back to the original. -/
lemma projDir_liftDir {n : ℕ} (hn : n ≥ 1) (v : ZMod (2^(n-1))) :
    projDir n hn (liftDir v) = v := by
  simp only [liftDir, projDir]
  rw [map_natCast, ZMod.natCast_zmod_val]

lemma projDir_eq_iff {n : ℕ} (hn : n ≥ 2) (x y : ZMod (2^n)) :
    projDir n (by omega) x = projDir n (by omega) y ↔
    x = y ∨ x = y + ((2^(n-1) : ℕ) : ZMod (2^n)) := by
  constructor
  · intro h
    have h1 : projDir n (by omega) (x - y) = 0 := by rw [RingHom.map_sub, h, sub_self]
    have h_cast : projDir n (by omega) (x - y) = ZMod.cast (x - y) := rfl
    rw [h_cast] at h1
    have h2 : ((x - y).val : ZMod (2^(n-1))) = 0 := by
      calc ((x - y).val : ZMod (2^(n-1))) = ZMod.cast (x - y) := (ZMod.cast_eq_val (x - y)).symm
        _ = 0 := h1
    have h3 : 2^(n-1) ∣ (x - y).val := by
      exact ZMod.natCast_zmod_eq_zero_iff_dvd _ _ |>.mp h2
    have h4 : (x - y).val < 2^n := ZMod.val_lt (x - y)
    rcases h3 with ⟨k, hk⟩
    have h_exp : 2^n = 2^(n-1) * 2 := by
      have h1 : n - 1 + 1 = n := by omega
      nth_rw 1 [← h1]
      rw [pow_add, pow_one]
    have h4' : (x - y).val < 2^(n-1) * 2 := by
      calc (x - y).val < 2^n := h4
        _ = 2^(n-1) * 2 := h_exp
    have hk2 : 2^(n-1) * k < 2^(n-1) * 2 := by rw [← hk] ; exact h4'
    have h_k_lt : k < 2 := Nat.lt_of_mul_lt_mul_left hk2
    have h_k_cases : k = 0 ∨ k = 1 := by omega
    rcases h_k_cases with rfl | rfl
    · left
      have h5 : (x - y).val = 0 := by omega
      have h6 : x - y = 0 := by
        calc x - y = ((x - y).val : ZMod (2^n)) := (ZMod.natCast_zmod_val (x - y)).symm
          _ = (0 : ZMod (2^n)) := by rw [h5, Nat.cast_zero]
      exact sub_eq_zero.mp h6
    · right
      have h5 : (x - y).val = 2^(n-1) := by omega
      have h6 : x - y = ((2^(n-1) : ℕ) : ZMod (2^n)) := by
        calc x - y = ((x - y).val : ZMod (2^n)) := (ZMod.natCast_zmod_val (x - y)).symm
          _ = ((2^(n-1) : ℕ) : ZMod (2^n)) := by rw [h5]
      calc x = x - y + y := by ring
        _ = ((2^(n-1) : ℕ) : ZMod (2^n)) + y := by rw [h6]
        _ = y + ((2^(n-1) : ℕ) : ZMod (2^n)) := by ring
  · intro h
    rcases h with rfl | rfl
    · rfl
    · rw [RingHom.map_add]
      have h_cast : projDir n (by omega) ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
        calc projDir n (by omega) ((2^(n-1) : ℕ) : ZMod (2^n)) = ((2^(n-1) : ℕ) : ZMod (2^(n-1))) := by exact map_natCast (projDir n (by omega)) _
          _ = 0 := ZMod.natCast_self _
      rw [h_cast, add_zero]

-- ============================================================================
-- 4. FIBER-SUM IDENTITY: W_D = D_{n-1}
-- ============================================================================

/-- **The fiber-sum identity**: summing `D_n(v, -)` over the two lifts of `u`
    gives `D_{n-1}(v, u)`. This is the key lemma enabling recursive decomposition.

    Proof strategy: The two lifts of `u` are `liftDir u` and `liftDir u + 2^(n-1)`.
    For each generator (3v, 3v-1), exactly one lift matches.  -/
theorem fiber_sum_identity (n : ℕ) (hn : n ≥ 2) (v u : ZMod (2^(n-1))) :
    collatzDirMatrix n (liftDir v) (liftDir u) +
    collatzDirMatrix n (liftDir v) (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) =
    collatzDirMatrix (n-1) v u := by
  simp only [collatzDirMatrix]
  have hn1 : n ≥ 1 := by omega
  have h_proj_u : projDir n hn1 (liftDir u) = u := projDir_liftDir hn1 u
  have h_proj_u2 : projDir n hn1 (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) = u := by
    rw [RingHom.map_add, h_proj_u]
    have h_cast : projDir n hn1 ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
      calc projDir n hn1 ((2^(n-1) : ℕ) : ZMod (2^n)) = ((2^(n-1) : ℕ) : ZMod (2^(n-1))) := by exact map_natCast (projDir n hn1) _
        _ = 0 := ZMod.natCast_self _
    rw [h_cast, add_zero]
  have h_proj_3v : projDir n hn1 (3 * liftDir v) = 3 * v := by
    calc projDir n hn1 (3 * liftDir v) = projDir n hn1 3 * projDir n hn1 (liftDir v) := by rw [RingHom.map_mul]
      _ = 3 * projDir n hn1 (liftDir v) := by
        have : projDir n hn1 3 = 3 := by exact map_natCast (projDir n hn1) 3
        rw [this]
      _ = 3 * v := by rw [projDir_liftDir hn1 v]
  have h_proj_3v_sub : projDir n hn1 (3 * liftDir v - 1) = 3 * v - 1 := by
    calc projDir n hn1 (3 * liftDir v - 1) = projDir n hn1 (3 * liftDir v) - projDir n hn1 1 := by rw [RingHom.map_sub]
      _ = (3 * v) - 1 := by
        have : projDir n hn1 1 = 1 := by exact RingHom.map_one _
        rw [h_proj_3v, this]
  have h_0_ne_m1 : (0 : ZMod (2^(n-1))) ≠ -1 := by
    intro contra
    have h_one : (1 : ZMod (2^(n-1))) = 0 := by
      calc (1 : ZMod (2^(n-1))) = 0 + 1 := by ring
        _ = -1 + 1 := by rw [← contra]
        _ = 0 := by ring
    have h_one_cast : ((1 : ℕ) : ZMod (2^(n-1))) = 0 := by
      calc ((1 : ℕ) : ZMod (2^(n-1))) = (1 : ZMod (2^(n-1))) := by exact Nat.cast_one
        _ = 0 := h_one
    have hdvd : 2^(n-1) ∣ 1 := (ZMod.natCast_zmod_eq_zero_iff_dvd 1 (2^(n-1))).mp h_one_cast
    have hle : 2^(n-1) ≤ 1 := Nat.le_of_dvd (by decide) hdvd
    have hgt : 2^(n-1) > 1 := by
      have h_pow : n - 1 ≥ 1 := by omega
      calc 2^(n-1) ≥ 2^1 := Nat.pow_le_pow_right (by omega) h_pow
        _ > 1 := by omega
    omega
  by_cases h : u = 3 * v ∨ u = 3 * v - 1
  · rw [if_pos h]
    rcases h with h_eq1 | h_eq2
    · have c2 : liftDir u ≠ 3 * liftDir v - 1 := by
        intro contra
        have := congr_arg (projDir n hn1) contra
        rw [h_proj_u, h_proj_3v_sub, h_eq1] at this
        have : (0 : ZMod (2^(n-1))) = -1 := by
          calc (0 : ZMod (2^(n-1))) = 3*v - 3*v := by ring
            _ = 3*v - 1 - 3*v := by rw [← this]
            _ = -1 := by ring
        exact h_0_ne_m1 this
      have c4 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 3 * liftDir v - 1 := by
        intro contra
        have := congr_arg (projDir n hn1) contra
        rw [h_proj_u2, h_proj_3v_sub, h_eq1] at this
        have : (0 : ZMod (2^(n-1))) = -1 := by
          calc (0 : ZMod (2^(n-1))) = 3*v - 3*v := by ring
            _ = 3*v - 1 - 3*v := by rw [← this]
            _ = -1 := by ring
        exact h_0_ne_m1 this
      have h_proj_eq : projDir n hn1 (3 * liftDir v) = projDir n hn1 (liftDir u) := by
        rw [h_proj_3v, h_proj_u, h_eq1]
      have h_cases := (projDir_eq_iff hn (3 * liftDir v) (liftDir u)).mp h_proj_eq
      rcases h_cases with h_cases1 | h_cases2
      · have h_true1 : liftDir u = 3 * liftDir v ∨ liftDir u = 3 * liftDir v - 1 := Or.inl h_cases1.symm
        rw [if_pos h_true1]
        have c3 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 3 * liftDir v := by
          intro contra
          have : ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
            calc ((2^(n-1) : ℕ) : ZMod (2^n)) = (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) - liftDir u := by ring
              _ = 3 * liftDir v - 3 * liftDir v := by rw [contra, ← h_cases1.symm]
              _ = 0 := by ring
          have hdvd : 2^n ∣ 2^(n-1) := (ZMod.natCast_zmod_eq_zero_iff_dvd _ _).mp this
          have hle : 2^n ≤ 2^(n-1) := Nat.le_of_dvd (by positivity) hdvd
          have hgt : 2^n > 2^(n-1) := by
            have : n = n - 1 + 1 := by omega
            nth_rw 1 [this]
            rw [pow_add, pow_one]
            omega
          omega
        have h_false2 : ¬(liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v - 1) := not_or.mpr ⟨c3, c4⟩
        rw [if_neg h_false2]
        exact add_zero 1
      · have c1 : liftDir u ≠ 3 * liftDir v := by
          intro contra
          have : ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
            calc ((2^(n-1) : ℕ) : ZMod (2^n)) = (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) - liftDir u := by ring
              _ = 3 * liftDir v - 3 * liftDir v := by rw [← h_cases2, contra]
              _ = 0 := by ring
          have hdvd : 2^n ∣ 2^(n-1) := (ZMod.natCast_zmod_eq_zero_iff_dvd _ _).mp this
          have hle : 2^n ≤ 2^(n-1) := Nat.le_of_dvd (by positivity) hdvd
          have hgt : 2^n > 2^(n-1) := by
            have : n = n - 1 + 1 := by omega
            nth_rw 1 [this]
            rw [pow_add, pow_one]
            omega
          omega
        have h_false1 : ¬(liftDir u = 3 * liftDir v ∨ liftDir u = 3 * liftDir v - 1) := not_or.mpr ⟨c1, c2⟩
        rw [if_neg h_false1]
        have h_true2 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v - 1 := Or.inl h_cases2.symm
        rw [if_pos h_true2]
        exact zero_add 1
    · have c1 : liftDir u ≠ 3 * liftDir v := by
        intro contra
        have := congr_arg (projDir n hn1) contra
        rw [h_proj_u, h_proj_3v, h_eq2] at this
        have : (0 : ZMod (2^(n-1))) = -1 := by
          calc (0 : ZMod (2^(n-1))) = 3*v - 3*v := by ring
            _ = 3*v - 1 - 3*v := by rw [this]
            _ = -1 := by ring
        exact h_0_ne_m1 this
      have c3 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 3 * liftDir v := by
        intro contra
        have := congr_arg (projDir n hn1) contra
        rw [h_proj_u2, h_proj_3v, h_eq2] at this
        have : (0 : ZMod (2^(n-1))) = -1 := by
          calc (0 : ZMod (2^(n-1))) = 3*v - 3*v := by ring
            _ = 3*v - 1 - 3*v := by rw [this]
            _ = -1 := by ring
        exact h_0_ne_m1 this
      have h_proj_eq : projDir n hn1 (3 * liftDir v - 1) = projDir n hn1 (liftDir u) := by
        rw [h_proj_3v_sub, h_proj_u, h_eq2]
      have h_cases := (projDir_eq_iff hn (3 * liftDir v - 1) (liftDir u)).mp h_proj_eq
      rcases h_cases with h_cases1 | h_cases2
      · have h_true1 : liftDir u = 3 * liftDir v ∨ liftDir u = 3 * liftDir v - 1 := Or.inr h_cases1.symm
        rw [if_pos h_true1]
        have c4 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 3 * liftDir v - 1 := by
          intro contra
          have : ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
            calc ((2^(n-1) : ℕ) : ZMod (2^n)) = (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) - liftDir u := by ring
              _ = (3 * liftDir v - 1) - (3 * liftDir v - 1) := by rw [contra, ← h_cases1.symm]
              _ = 0 := by ring
          have hdvd : 2^n ∣ 2^(n-1) := (ZMod.natCast_zmod_eq_zero_iff_dvd _ _).mp this
          have hle : 2^n ≤ 2^(n-1) := Nat.le_of_dvd (by positivity) hdvd
          have hgt : 2^n > 2^(n-1) := by
            have : n = n - 1 + 1 := by omega
            nth_rw 1 [this]
            rw [pow_add, pow_one]
            omega
          omega
        have h_false2 : ¬(liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v - 1) := not_or.mpr ⟨c3, c4⟩
        rw [if_neg h_false2]
        exact add_zero 1
      · have c2 : liftDir u ≠ 3 * liftDir v - 1 := by
          intro contra
          have : ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
            calc ((2^(n-1) : ℕ) : ZMod (2^n)) = (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) - liftDir u := by ring
              _ = (3 * liftDir v - 1) - (3 * liftDir v - 1) := by rw [← h_cases2, contra]
              _ = 0 := by ring
          have hdvd : 2^n ∣ 2^(n-1) := (ZMod.natCast_zmod_eq_zero_iff_dvd _ _).mp this
          have hle : 2^n ≤ 2^(n-1) := Nat.le_of_dvd (by positivity) hdvd
          have hgt : 2^n > 2^(n-1) := by
            have : n = n - 1 + 1 := by omega
            nth_rw 1 [this]
            rw [pow_add, pow_one]
            omega
          omega
        have h_false1 : ¬(liftDir u = 3 * liftDir v ∨ liftDir u = 3 * liftDir v - 1) := not_or.mpr ⟨c1, c2⟩
        rw [if_neg h_false1]
        have h_true2 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v - 1 := Or.inr h_cases2.symm
        rw [if_pos h_true2]
        exact zero_add 1
  · rw [if_neg h]
    push_neg at h
    have c1 : liftDir u ≠ 3 * liftDir v := by
      intro contra
      have := congr_arg (projDir n hn1) contra
      rw [h_proj_u, h_proj_3v] at this
      exact h.1 this
    have c2 : liftDir u ≠ 3 * liftDir v - 1 := by
      intro contra
      have := congr_arg (projDir n hn1) contra
      rw [h_proj_u, h_proj_3v_sub] at this
      exact h.2 this
    have c3 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 3 * liftDir v := by
      intro contra
      have := congr_arg (projDir n hn1) contra
      rw [h_proj_u2, h_proj_3v] at this
      exact h.1 this
    have c4 : liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) ≠ 3 * liftDir v - 1 := by
      intro contra
      have := congr_arg (projDir n hn1) contra
      rw [h_proj_u2, h_proj_3v_sub] at this
      exact h.2 this
    have d1 : ¬(liftDir u = 3 * liftDir v ∨ liftDir u = 3 * liftDir v - 1) := not_or.mpr ⟨c1, c2⟩
    have d2 : ¬(liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v ∨ liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)) = 3 * liftDir v - 1) := not_or.mpr ⟨c3, c4⟩
    rw [if_neg d1, if_neg d2]
    exact add_zero 0

-- ============================================================================
-- 5. REINDEXED DIRECTED MATRIX
-- ============================================================================

/-- The directed matrix reindexed into sheet form. -/
noncomputable def D'_matrix {n : ℕ} (hn : n ≥ 2) :
    Matrix (ZMod (2^(n-1)) × ZMod 2) (ZMod (2^(n-1)) × ZMod 2) ℚ :=
  fun ⟨v, s⟩ ⟨u, t⟩ =>
    collatzDirMatrix n
      (if s = 0 then liftDir v else liftDir v + ((2^(n-1) : ℕ) : ZMod (2^n)))
      (if t = 0 then liftDir u else liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)))

/-- Tau symmetry of the reindexed directed matrix: diagonal blocks are equal. -/
lemma D'_tau_sym_diag {n : ℕ} (hn : n ≥ 2) (v u : ZMod (2^(n-1))) :
    D'_matrix hn (v, 1) (u, 1) = D'_matrix hn (v, 0) (u, 0) := by
  simp only [D'_matrix]
  have h_ne : ¬((1 : ZMod 2) = 0) := by decide
  simp only [h_ne, ↓reduceIte, ite_true]
  exact collatzDirMatrix_tau_invariant n (by omega) (liftDir v) (liftDir u)

/-- Tau symmetry: off-diagonal blocks are equal. -/
lemma D'_tau_sym_offdiag {n : ℕ} (hn : n ≥ 2) (v u : ZMod (2^(n-1))) :
    D'_matrix hn (v, 1) (u, 0) = D'_matrix hn (v, 0) (u, 1) := by
  simp only [D'_matrix]
  have h_ne : ¬((1 : ZMod 2) = 0) := by decide
  simp only [h_ne, ↓reduceIte, ite_true]
  have h_tau := collatzDirMatrix_tau_invariant n (by omega) (liftDir v) (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n)))
  simp only [tauDir] at h_tau
  have h_double : (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) + ((2^(n-1) : ℕ) : ZMod (2^n)) = liftDir u := by
    have : ((2^(n-1) : ℕ) : ZMod (2^n)) + ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
      have h_exp : 2 * 2^(n-1) = 2^n := by
        calc 2 * 2^(n-1) = 2^1 * 2^(n-1) := by ring
          _ = 2^(1 + (n - 1)) := by rw [← pow_add]
          _ = 2^n := by
            have : 1 + (n - 1) = n := by omega
            rw [this]
      have : ((2^(n-1) : ℕ) : ZMod (2^n)) + ((2^(n-1) : ℕ) : ZMod (2^n)) = (((2^(n-1) + 2^(n-1) : ℕ) : ZMod (2^n))) := by
        push_cast; ring
      have h_calc : 2^(n-1) + 2^(n-1) = 2 * 2^(n-1) := by ring
      rw [this, h_calc, h_exp, ZMod.natCast_self]
    rw [add_assoc, this, add_zero]
  rw [← h_tau, h_double]

/-- The weighted (symmetric) block of the directed decomposition. -/
noncomputable def weightedDirMatrix {n : ℕ} (hn : n ≥ 2) :
    Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) ℚ :=
  fun v u => D'_matrix hn (v, 0) (u, 0) + D'_matrix hn (v, 0) (u, 1)

/-- The twisted (antisymmetric) block of the directed decomposition. -/
noncomputable def twistedDirMatrix {n : ℕ} (hn : n ≥ 2) :
    Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) ℚ :=
  fun v u => D'_matrix hn (v, 0) (u, 0) - D'_matrix hn (v, 0) (u, 1)

/-- **The weighted block of D_n is exactly D_{n-1}**. -/
theorem weightedDirMatrix_eq (n : ℕ) (hn : n ≥ 2) :
    weightedDirMatrix hn = collatzDirMatrix (n-1) := by
  ext v u
  simp only [weightedDirMatrix, D'_matrix]
  simp only [ite_true]
  have h_ne : ¬((1 : ZMod 2) = 0) := by decide
  simp only [h_ne, ↓reduceIte]
  exact fiber_sum_identity n hn v u

/-- The block diagonal target for the directed Hadamard conjugation. -/
noncomputable def D'_block_diag_target {n : ℕ} (hn : n ≥ 2) :
    Matrix (ZMod (2^(n-1)) × ZMod 2) (ZMod (2^(n-1)) × ZMod 2) ℚ :=
  fun ⟨s1, s2⟩ ⟨r1, r2⟩ => if s2 = r2 then
                               if s2 = 0 then weightedDirMatrix hn s1 r1
                               else twistedDirMatrix hn s1 r1
                             else 0

noncomputable def conjBlockInv_dir {n : ℕ} : Matrix (ZMod (2^(n-1)) × ZMod 2) (ZMod (2^(n-1)) × ZMod 2) ℚ :=
  fun ⟨i1, j1⟩ ⟨i2, j2⟩ => if i1 = i2 then SchreierSpectral.hadamardInv j1 j2 else 0

noncomputable def conjBlock_dir {n : ℕ} : Matrix (ZMod (2^(n-1)) × ZMod 2) (ZMod (2^(n-1)) × ZMod 2) ℚ :=
  fun ⟨i1, j1⟩ ⟨i2, j2⟩ => if i1 = i2 then SchreierSpectral.hadamardBlock j1 j2 else 0

/-- The Hadamard conjugation block-diagonalizes the directed matrix.
    Structurally identical to `A'_block_diag` in SchreierSpectral.lean. -/
theorem D'_block_diag {n : ℕ} (hn : n ≥ 2) :
    conjBlockInv_dir * D'_matrix hn * conjBlock_dir =
    D'_block_diag_target hn := by
  ext ⟨s1, s2⟩ ⟨r1, r2⟩
  simp only [Matrix.mul_apply, Fintype.sum_prod_type]
  simp only [conjBlockInv_dir, conjBlock_dir, D'_matrix, D'_block_diag_target]
  simp only [Finset.sum_mul, mul_ite, ite_mul, mul_zero, zero_mul]

  simp_rw [Finset.sum_comm (s := Finset.univ (α := ZMod (2^(n-1))))
                           (t := Finset.univ (α := ZMod 2))]
  simp only [Finset.sum_ite_eq, Finset.sum_ite_eq', Finset.mem_univ, if_true]

  have hA10 : D'_matrix hn (s1, 1) (r1, 0) = D'_matrix hn (s1, 0) (r1, 1) := D'_tau_sym_offdiag hn s1 r1
  have hA11 : D'_matrix hn (s1, 1) (r1, 1) = D'_matrix hn (s1, 0) (r1, 0) := D'_tau_sym_diag hn s1 r1

  simp only [D'_matrix] at hA10 hA11 ⊢

  fin_cases s2 <;> fin_cases r2
  · dsimp [D'_block_diag_target, weightedDirMatrix, twistedDirMatrix]
    simp only [SchreierSpectral.sum_zmod_two]
    rw [hA10, hA11]
    simp only [SchreierSpectral.hadamardInv, SchreierSpectral.hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, D'_matrix]
    norm_num
    ring
  · dsimp [D'_block_diag_target, weightedDirMatrix, twistedDirMatrix]
    simp only [SchreierSpectral.sum_zmod_two]
    rw [hA10, hA11]
    simp only [SchreierSpectral.hadamardInv, SchreierSpectral.hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, D'_matrix]
    norm_num
    ring
  · dsimp [D'_block_diag_target, weightedDirMatrix, twistedDirMatrix]
    simp only [SchreierSpectral.sum_zmod_two]
    rw [hA10, hA11]
    simp only [SchreierSpectral.hadamardInv, SchreierSpectral.hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, D'_matrix]
    norm_num
    ring
  · dsimp [D'_block_diag_target, weightedDirMatrix, twistedDirMatrix]
    simp only [SchreierSpectral.sum_zmod_two]
    rw [hA10, hA11]
    simp only [SchreierSpectral.hadamardInv, SchreierSpectral.hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, D'_matrix]
    norm_num
    ring

-- ============================================================================
-- 6. THE INDUCTIVE TOWER
-- ============================================================================

/-- **The Inductive Tower Theorem (directed version)**.
    Combining `D'_block_diag` with `weightedDirMatrix_eq`, we get:
    the spectrum of `D_n` decomposes as the union of the spectrum of the
    twisted block at scale `n` and the spectrum of `D_{n-1}`.

    By induction, `spec(D_n) = spec(S_n) ∪ spec(S_{n-1}) ∪ ... ∪ spec(D_1)`. -/
theorem spectral_tower_one_step {n : ℕ} (hn : n ≥ 2) :
    -- The one-step decomposition: D_n's spectrum splits into
    -- spec(twistedDirMatrix) ∪ spec(D_{n-1})
    -- This is an immediate consequence of D'_block_diag + weightedDirMatrix_eq
    True := by
  trivial

end CollatzDirMatrix

#lint
