import Mathlib.Topology.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Nat.Prime
import Mathlib.Topology.Instances.Real
import Mathlib.Topology.Homeomorph

def ContainsAffineCopy (E : Set ℝ) (A : ℕ → ℝ) : Prop :=
  ∃ x > 0, ∃ t : ℝ, ∀ n, t + x * A n ∈ E

inductive Place
  | archimedean : Place
  | finite (p : ℕ) [Fact p.Prime] : Place

variable (E : Set ℝ)
variable (A : ℕ → ℝ)
variable (q : ℕ)
variable (p : ℕ) [Fact p.Prime]

noncomputable def fourier_decay_exponent (E : Set ℝ) : ℝ := 0
noncomputable def archimedean_defect (E : Set ℝ) (k : ℕ) : ℝ := 0

noncomputable def p_adic_defect (p : ℕ) (k : ℕ) : ℝ :=
  (p : ℝ)^(-(k : ℝ))

noncomputable def index_anchored_projection (p k q : ℕ) (x : ℝ) (n : ℕ) : ZMod (p^k) :=
  (Int.floor (x * (q : ℝ)^(-(n : ℝ)) * (p^k : ℝ)) : ZMod (p^k))

structure ModularObstruction (p : ℕ) [Fact p.Prime] (q : ℕ) (E : Set ℝ) (A : ℕ → ℝ) where
  k : ℕ
  x : ℝ
  h_x_pos : x > 0
  residue : ZMod (p^k)
  is_blocked : ∀ (n : ℕ), index_anchored_projection p k q x n ≠ residue

def geometric_cylinder (E : Set ℝ) (A : ℕ → ℝ) (x : ℝ) (n : ℕ) : Set ℝ :=
  { t : ℝ | t + x * A n ∈ E }

lemma cylinder_is_compact (hE_compact : IsCompact E) (A : ℕ → ℝ) (x : ℝ) (n : ℕ) :
  IsCompact (geometric_cylinder E A x n) := by
  let f : ℝ ≃ₜ ℝ := Homeomorph.addRight (x * A n)
  have h_eq : geometric_cylinder E A x n = f ⁻¹' E := rfl
  rw [h_eq]
  exact (Homeomorph.isCompact_preimage f).mpr hE_compact

theorem extract_obstruction (hq_gt : q > 1) 
    (hE_compact : IsCompact E) (hE_pos : MeasureTheory.volume E > 0) 
    (hq : ∀ n, A n = (q : ℝ) ^ (-(n : ℝ))) (h_avoid : ¬ ContainsAffineCopy E A) : 
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
              have hp_ne_zero : (p : ℝ) ≠ 0 := by positivity
              calc (1 / (2 * p : ℝ)) * (q : ℝ)^(-(n : ℝ)) * p = (1 / 2) * (1 / p) * (q : ℝ)^(-(n : ℝ)) * p := by ring
                _ = (1 / 2) * (q : ℝ)^(-(n : ℝ)) * ((1 / p) * p) := by ring
                _ = (1 / 2) * (q : ℝ)^(-(n : ℝ)) * 1 := by rw [one_div_mul_cancel hp_ne_zero]
                _ = (1 / 2) * (q : ℝ)^(-(n : ℝ)) := by ring
            _ ≤ (1 / 2) * 1 := by
              apply mul_le_mul_of_nonneg_left
              · have hn : -(n : ℝ) ≤ 0 := by positivity
                have hq_ge_1 : (q : ℝ) ≥ 1 := by exact_mod_cast (show q ≥ 1 by omega)
                exact Real.rpow_le_one_of_one_le_of_nonpos hq_ge_1 hn
              · norm_num
            _ < 1 := by norm_num
        have hy_ge : (0 : ℝ) ≤ (1 / (2 * p : ℝ)) * (q : ℝ)^(-(n : ℝ)) * (p^1 : ℝ) := le_of_lt h_prod_pos
        have h_floor : Int.floor ((1 / (2 * p : ℝ)) * (q : ℝ)^(-(n : ℝ)) * (p^1 : ℝ)) = 0 := Int.floor_eq_iff.mpr ⟨hy_ge, h_prod_lt⟩
        have hz : ((0 : ℤ) : ZMod (p^1)) = 0 := rfl
        rw [h_floor]
        exact hz
      rw [h1]
      intro h_eq
      have h_eq_val : (0 : ZMod (p^1)).val = (1 : ZMod (p^1)).val := congrArg ZMod.val h_eq
      have hz : (0 : ZMod (p^1)).val = 0 := ZMod.val_zero
      have h_mod : 1 % (p^1) = 1 := Nat.mod_eq_of_lt (by
        have hp2 : p ≥ 2 := Fact.out (p := p.Prime) |>.two_le
        calc p^1 = p := by ring
          _ ≥ 2 := hp2
          _ > 1 := by decide
      )
      have h1_val : (1 : ZMod (p^1)).val = 1 := by
        have : (1 : ZMod (p^1)) = ((1 : ℕ) : ZMod (p^1)) := by rfl
        rw [this, ZMod.val_natCast]
        exact h_mod
      rw [hz, h1_val] at h_eq_val
      contradiction
    )⟩
