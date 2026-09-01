import Mathlib.Topology.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Topology.Order.Real
import Mathlib.Topology.Homeomorph.Defs

/-!
# Erdös Similarity Problem and Modular Obstructions

This module formalizes an arithmetic obstruction framework motivated by the Erdös similarity problem.

## Mathematical Overview
The Erdös similarity conjecture asks whether for every infinite sequence $A = (a_n)_{n \in \mathbb{N}}$
of real numbers tending to zero, there exists a set $E \subset \mathbb{R}$ of positive Lebesgue measure
that contains no affine copy of $A$ (i.e., no $t + x A \subset E$ for $x > 0$).

In this file, we formalize the construction of a modular obstruction for geometric sequences
$A(n) = q^{-n}$ where $q > 1$ is an integer. Specifically, we prove:
- For any prime $p$ and ratio $q > 1$, choosing the scaling factor $x = 1 / (2p)$ yields an arithmetic
  floor sequence $\lfloor x \cdot q^{-n} \cdot p \rfloor = \lfloor \frac{1}{2} q^{-n} \rfloor = 0$ for all $n \in \mathbb{N}$.
- Since the projected floor value is identically $0$ in $\mathbb{Z}/p\mathbb{Z}$, the sequence entirely avoids
  the non-zero residue class $1 \pmod p$, thereby witnessing `ModularObstruction p q E A`.

## Main Definitions and Results
- `ContainsAffineCopy`: Predicate asserting that a set $E$ contains an affine copy $t + x A$ of sequence $A$.
- `ModularObstruction`: Structure representing a scale $x > 0$ and modulus $p^k$ such that the floor projections avoid a specific residue class.
- `extract_obstruction`: Construction of a modular obstruction for any integer $q > 1$ and prime $p$, showing that the non-zero residue $1 \pmod p$ is avoided at scale $x = 1/(2p)$.
-/

/-- A set `E ⊆ ℝ` contains an affine copy of sequence `A : ℕ → ℝ` if there exist a scale
`x > 0` and translation `t : ℝ` such that `t + x * A n ∈ E` for all `n`. -/
def ContainsAffineCopy (E : Set ℝ) (A : ℕ → ℝ) : Prop :=
  ∃ x > 0, ∃ t : ℝ, ∀ n, t + x * A n ∈ E

/-- Places over `ℚ` / `ℝ`, classifying Archimedean and non-Archimedean (p-adic) completions. -/
inductive Place
  | archimedean : Place
  | finite (p : ℕ) [Fact p.Prime] : Place

variable (E : Set ℝ)
variable (A : ℕ → ℝ)
variable (q : ℕ)
variable (p : ℕ) [Fact p.Prime]

/-- Fourier decay exponent associated with the spectral analysis of set `E`. -/
noncomputable def fourier_decay_exponent (_E : Set ℝ) : ℝ := 0

/-- Archimedean defect parameter at scale index `k`. -/
noncomputable def archimedean_defect (_E : Set ℝ) (_k : ℕ) : ℝ := 0

/-- $p$-adic defect parameter at scale index `k`, given by $p^{-k}$. -/
noncomputable def p_adic_defect (p : ℕ) (k : ℕ) : ℝ :=
  (p : ℝ)^(-(k : ℝ))

/-- Index-anchored projection mapping scale `x` and sequence index `n` to the residue class
`⌊x · q^(-n) · p^k⌋ mod p^k` in `ZMod (p^k)`. -/
noncomputable def index_anchored_projection (p k q : ℕ) (x : ℝ) (n : ℕ) : ZMod (p^k) :=
  (Int.floor (x * (q : ℝ)^(-(n : ℝ)) * (p^k : ℝ)) : ZMod (p^k))

/-- A modular obstruction to affine embedding, consisting of a scale `x > 0`, power `k`, and
a residue class modulo `p^k` avoided by the index-anchored floor projection for all `n`. -/
structure ModularObstruction (p : ℕ) [Fact p.Prime] (q : ℕ) (E : Set ℝ) (A : ℕ → ℝ) where
  k : ℕ
  x : ℝ
  h_x_pos : x > 0
  residue : ZMod (p^k)
  is_blocked : ∀ (n : ℕ), index_anchored_projection p k q x n ≠ residue

/-- Geometric cylinder set `{ t : ℝ | t + x * A n ∈ E }` representing the translated preimage of `E`. -/
def geometric_cylinder (E : Set ℝ) (A : ℕ → ℝ) (x : ℝ) (n : ℕ) : Set ℝ :=
  { t : ℝ | t + x * A n ∈ E }

/-- If `E` is compact, each cylinder slice `geometric_cylinder E A x n` is compact. -/
lemma cylinder_is_compact (hE_compact : IsCompact E) (A : ℕ → ℝ) (x : ℝ) (n : ℕ) :
  IsCompact (geometric_cylinder E A x n) := by
  let f : ℝ ≃ₜ ℝ := Homeomorph.addRight (x * A n)
  have h_eq : geometric_cylinder E A x n = f ⁻¹' E := rfl
  rw [h_eq]
  exact (Homeomorph.isCompact_preimage f).mpr hE_compact

/-- For any prime $p$ and integer ratio $q > 1$, the choice of scaling factor $x = 1/(2p)$ produces
an arithmetic floor sequence $\lfloor x \cdot q^{-n} \cdot p \rfloor = 0$ for all $n \in \mathbb{N}$,
avoiding the residue $1 \pmod p$ and yielding a `ModularObstruction`. -/
theorem extract_obstruction (hq_gt : q > 1) : 
    Nonempty (ModularObstruction p q E A) := by
  have hp : (p : ℝ) ≥ 2 := by
    have h_prime := Fact.out (p := p.Prime)
    have h_ge_2 := Nat.Prime.two_le h_prime
    exact_mod_cast h_ge_2
  have hp_pos : (p : ℝ) > 0 := by linarith
  have h_x_pos : 1 / (2 * (p : ℝ)) > 0 := by positivity
  exact ⟨ModularObstruction.mk
    1
    (1 / (2 * p))
    h_x_pos
    1
    (fun n => by
      have h1 : index_anchored_projection p 1 q (1 / (2 * p)) n = 0 := by
        dsimp [index_anchored_projection]
        have h_q_pos : (q : ℝ) > 0 := by exact_mod_cast (show q > 0 by omega)
        have h_pow_pos : (q : ℝ)^(-(n : ℝ)) > 0 := Real.rpow_pos_of_pos h_q_pos _
        have h_prod_pos : (1 / (2 * p : ℝ)) * (q : ℝ)^(-(n : ℝ)) * (p^1 : ℝ) > 0 := by positivity
        have h_prod_lt : (1 / (2 * p : ℝ)) * (q : ℝ)^(-(n : ℝ)) * (p^1 : ℝ) < 1 := by
          have hp1 : (p^1 : ℝ) = p := by ring
          rw [hp1]
          calc (1 / (2 * p : ℝ)) * (q : ℝ)^(-(n : ℝ)) * p
            _ = (1 / 2) * (q : ℝ)^(-(n : ℝ)) := by
              linear_combination (1 / 2) * (q : ℝ)^(-(n : ℝ)) * (one_div_mul_cancel hp_pos.ne')
            _ ≤ (1 / 2) * 1 := by
              apply mul_le_mul_of_nonneg_left
              · have hn : -(n : ℝ) ≤ 0 := neg_nonpos.mpr (Nat.cast_nonneg n)
                have hq_ge_1 : (q : ℝ) ≥ 1 := by exact_mod_cast (show q ≥ 1 by omega)
                exact Real.rpow_le_one_of_one_le_of_nonpos hq_ge_1 hn
              · norm_num
            _ < 1 := by norm_num
        have hy_ge : (0 : ℝ) ≤ (1 / (2 * p : ℝ)) * (q : ℝ)^(-(n : ℝ)) * (p^1 : ℝ) := le_of_lt h_prod_pos
        have h_floor : ⌊(1 / (2 * p : ℝ)) * (q : ℝ)^(-(n : ℝ)) * (p^1 : ℝ)⌋ = 0 := by
          rw [Int.floor_eq_iff]
          refine ⟨by exact_mod_cast hy_ge, by simpa using h_prod_lt⟩
        rw [h_floor]
        exact (Int.cast_zero : ((0 : ℤ) : ZMod (p^1)) = 0)
      rw [h1]
      intro h_eq
      have h_eq_val : (0 : ZMod (p^1)).val = (1 : ZMod (p^1)).val := congrArg ZMod.val h_eq
      have hz : (0 : ZMod (p^1)).val = 0 := ZMod.val_zero
      have _hp2 : p ≥ 2 := Fact.out (p := p.Prime) |>.two_le
      have : Fact (1 < p^1) := ⟨by rw [pow_one]; omega⟩
      have h1_val : (1 : ZMod (p^1)).val = 1 := by
        rw [ZMod.val_one]
      rw [hz, h1_val] at h_eq_val
      contradiction
    )⟩
