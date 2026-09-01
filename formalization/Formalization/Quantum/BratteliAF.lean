import Mathlib.Algebra.Colimit.Module
import Mathlib.Algebra.Colimit.DirectLimit
import Mathlib.Data.Matrix.Basic
import Mathlib.Algebra.Ring.Subring.Basic
import Mathlib.Tactic

noncomputable section

structure BratteliDiagram where
  ranks : ℕ → ℕ
  incidence : (n : ℕ) → Matrix (Fin (ranks (n + 1))) (Fin (ranks n)) ℤ

namespace BratteliDiagram

/-- 1-step transition homomorphism via matrix-vector multiplication. -/
def stepHom (B : BratteliDiagram) (n : ℕ) : (Fin (B.ranks n) → ℤ) →+ (Fin (B.ranks (n + 1)) → ℤ) where
  toFun := (B.incidence n).mulVec
  map_zero' := Matrix.mulVec_zero _
  map_add' := Matrix.mulVec_add _

/-- k-step transition homomorphism from stage `i` to stage `i + k`. -/
def transIter (B : BratteliDiagram) (i : ℕ) : (k : ℕ) → ((Fin (B.ranks i) → ℤ) →+ (Fin (B.ranks (i + k)) → ℤ))
  | 0 => AddMonoidHom.id _
  | k + 1 => (B.stepHom (i + k)).comp (transIter B i k)

def castFinRanks (B : BratteliDiagram) {m n : ℕ} (h : m = n) : (Fin (B.ranks m) → ℤ) ≃+ (Fin (B.ranks n) → ℤ) :=
  match h with
  | rfl => AddEquiv.refl _

theorem castFinRanks_apply (B : BratteliDiagram) {m n : ℕ} (h : m = n)
    (w : Fin (B.ranks m) → ℤ) (idx : Fin (B.ranks n)) :
    ∃ (idx' : Fin (B.ranks m)), B.castFinRanks h w idx = w idx' := by
  cases h
  exact ⟨idx, rfl⟩

/-- Transition homomorphism between any two stages `i ≤ j`. -/
def transLe (B : BratteliDiagram) (i j : ℕ) (h : i ≤ j) : (Fin (B.ranks i) → ℤ) →+ (Fin (B.ranks j) → ℤ) :=
  (B.castFinRanks (Nat.add_sub_of_le h)).toAddMonoidHom.comp (B.transIter i (j - i))

/-- The dimension group of a Bratteli diagram defined as the direct limit of Fin (ranks n) → ℤ. -/
abbrev dimensionGroup (B : BratteliDiagram) : Type _ :=
  AddCommGroup.DirectLimit (fun n => Fin (B.ranks n) → ℤ) (fun i j h => B.transLe i j h)

/-- Canonical inclusion from stage `n` into the dimension group. -/
abbrev of (B : BratteliDiagram) (n : ℕ) : (Fin (B.ranks n) → ℤ) →+ dimensionGroup B :=
  AddCommGroup.DirectLimit.of (fun n => Fin (B.ranks n) → ℤ) (fun i j h => B.transLe i j h) n

/-- Positive cone in the dimension group. -/
def Nonneg (B : BratteliDiagram) (x : dimensionGroup B) : Prop :=
  ∃ (n : ℕ) (v : Fin (B.ranks n) → ℤ), (∀ i, 0 ≤ v i) ∧ of B n v = x

/-! ### UHF 2^∞ CAR Algebra -/

/-- Bratteli diagram for the UHF 2^∞ CAR algebra. -/
def uhf2_bratteli : BratteliDiagram where
  ranks := fun _ => 1
  incidence := fun _ _ _ => 2

def fin0 (n : ℕ) : Fin (uhf2_bratteli.ranks n) := ⟨0, Nat.zero_lt_one⟩

instance (n : ℕ) : Subsingleton (Fin (uhf2_bratteli.ranks n)) :=
  inferInstanceAs (Subsingleton (Fin 1))

theorem fin_eq_fin0 (n : ℕ) (i : Fin (uhf2_bratteli.ranks n)) : i = fin0 n :=
  Subsingleton.elim _ _

theorem uhf2_stepHom_apply (n : ℕ) (v : Fin (uhf2_bratteli.ranks n) → ℤ) (i : Fin (uhf2_bratteli.ranks (n + 1))) :
    uhf2_bratteli.stepHom n v i = 2 * v (fin0 n) := by
  change (Matrix.mulVec (fun _ _ => (2 : ℤ)) v) i = 2 * v (fin0 n)
  simp only [Matrix.mulVec, dotProduct]
  exact Fin.sum_univ_one (fun x => 2 * v x)

theorem uhf2_transIter_apply (i : ℕ) (k : ℕ) (v : Fin (uhf2_bratteli.ranks i) → ℤ)
    (idx : Fin (uhf2_bratteli.ranks (i + k))) :
    uhf2_bratteli.transIter i k v idx = (2 ^ k : ℤ) * v (fin0 i) := by
  induction k with
  | zero =>
    have : idx = fin0 i := Subsingleton.elim _ _
    subst this
    simp [transIter]
  | succ k ih =>
    simp only [transIter, AddMonoidHom.coe_comp, Function.comp_apply, uhf2_stepHom_apply, ih (fin0 (i + k)), pow_succ', mul_assoc]

theorem uhf2_transLe_apply (i j : ℕ) (h : i ≤ j) (v : Fin (uhf2_bratteli.ranks i) → ℤ)
    (idx : Fin (uhf2_bratteli.ranks j)) :
    uhf2_bratteli.transLe i j h v idx = (2 ^ (j - i) : ℤ) * v (fin0 i) := by
  dsimp [transLe]
  obtain ⟨idx', h_eq⟩ := uhf2_bratteli.castFinRanks_apply (Nat.add_sub_of_le h)
    (uhf2_bratteli.transIter i (j - i) v) idx
  rw [h_eq, uhf2_transIter_apply]

/-- Homomorphism from stage `n` to `ℚ` mapping `v` to `v(0) / 2^n`. -/
def toRatStage (n : ℕ) : (Fin (uhf2_bratteli.ranks n) → ℤ) →+ ℚ where
  toFun v := (v (fin0 n) : ℚ) / (2 : ℚ) ^ n
  map_zero' := by simp
  map_add' v w := by
    simp only [Pi.add_apply]
    push_cast
    exact add_div (v (fin0 n) : ℚ) (w (fin0 n) : ℚ) ((2 : ℚ) ^ n)

theorem toRatStage_comp (i j : ℕ) (hij : i ≤ j) (v : Fin (uhf2_bratteli.ranks i) → ℤ) :
    toRatStage j (uhf2_bratteli.transLe i j hij v) = toRatStage i v := by
  dsimp [toRatStage]
  rw [uhf2_transLe_apply]
  push_cast
  obtain ⟨d, rfl⟩ := Nat.exists_eq_add_of_le hij
  rw [Nat.add_sub_cancel_left, pow_add, mul_comm ((2 : ℚ) ^ i),
      mul_div_mul_left _ _ (by positivity : ((2 : ℚ) ^ d) ≠ 0)]

/-- The natural embedding of the UHF 2^∞ dimension group into `ℚ`. -/
def toRat : dimensionGroup uhf2_bratteli →+ ℚ :=
  AddCommGroup.DirectLimit.lift (fun n => Fin (uhf2_bratteli.ranks n) → ℤ)
    (fun i j h => uhf2_bratteli.transLe i j h) ℚ toRatStage toRatStage_comp

@[simp]
theorem toRat_of (n : ℕ) (v : Fin (uhf2_bratteli.ranks n) → ℤ) :
    toRat (of uhf2_bratteli n v) = (v (fin0 n) : ℚ) / (2 : ℚ) ^ n :=
  AddCommGroup.DirectLimit.lift_of ℚ toRatStage toRatStage_comp n v

theorem toRat_injective : Function.Injective toRat := by
  intro x y hxy
  have h_sub : toRat (x - y) = 0 := by rw [map_sub, hxy, sub_self]
  obtain ⟨n, v, heq⟩ : ∃ n v, of uhf2_bratteli n v = x - y := by
    induction (x - y) using AddCommGroup.DirectLimit.induction_on with
    | ih n v => exact ⟨n, v, rfl⟩
  rw [← heq, toRat_of] at h_sub
  have hv0 : (v (fin0 n) : ℚ) = 0 := by
    simpa [div_eq_zero_iff, (by positivity : ((2 : ℚ) ^ n) ≠ 0)] using h_sub
  have hv : v = 0 := by
    ext i
    rw [fin_eq_fin0 n i, (by exact_mod_cast hv0 : v (fin0 n) = 0), Pi.zero_apply]
  have hzero : of uhf2_bratteli n v = 0 := by rw [hv, map_zero]
  rw [hzero] at heq
  exact sub_eq_zero.mp heq.symm

/-- The additive subgroup of dyadic rationals `ℤ[1/2] ⊂ ℚ`. -/
def dyadicRationals : AddSubgroup ℚ := toRat.range

/-- Predicate for a rational being dyadic (a / 2^n for some integer a and natural n). -/
def IsDyadicRat (q : ℚ) : Prop := ∃ (n : ℕ) (a : ℤ), q = (a : ℚ) / (2 : ℚ) ^ n

theorem mem_dyadicRationals_iff (q : ℚ) : q ∈ dyadicRationals ↔ IsDyadicRat q := by
  constructor
  · rintro ⟨x, rfl⟩
    induction x using AddCommGroup.DirectLimit.induction_on with
    | ih n v => exact ⟨n, v (fin0 n), by simp [toRat_of]⟩
  · rintro ⟨n, a, rfl⟩
    refine ⟨of uhf2_bratteli n (fun _ => a), ?_⟩
    simp [toRat_of]

/-- The order unit (dimension 1 element) in the UHF 2^∞ dimension group. -/
def uhf2_unit : dimensionGroup uhf2_bratteli :=
  of uhf2_bratteli 0 (fun _ => 1)

@[simp]
theorem toRat_unit : toRat uhf2_unit = 1 := by
  dsimp [uhf2_unit]
  rw [toRat_of]
  simp

/-- Positive cone of UHF 2^∞ corresponds exactly to non-negative dyadic rationals. -/
theorem uhf2_nonneg_iff (x : dimensionGroup uhf2_bratteli) :
    uhf2_bratteli.Nonneg x ↔ 0 ≤ toRat x := by
  constructor
  · rintro ⟨n, v, hv, rfl⟩
    rw [toRat_of]
    exact div_nonneg (by exact_mod_cast hv (fin0 n)) (by positivity)
  · intro hx
    induction x using AddCommGroup.DirectLimit.induction_on with
    | ih n v =>
      rw [toRat_of] at hx
      have h2n : 0 < (2 : ℚ) ^ n := by positivity
      have hv_rat : 0 ≤ (v (fin0 n) : ℚ) := by
        have := mul_nonneg hx (le_of_lt h2n)
        rwa [div_mul_cancel₀ _ (ne_of_gt h2n)] at this
      exact ⟨n, v, fun i => by rw [fin_eq_fin0 n i]; exact_mod_cast hv_rat, rfl⟩

/-- Multiplicative closure: product of two dyadic rationals is dyadic. -/
theorem dyadic_mul_mem {p q : ℚ} (hp : p ∈ dyadicRationals) (hq : q ∈ dyadicRationals) :
    p * q ∈ dyadicRationals := by
  rw [mem_dyadicRationals_iff] at hp hq ⊢
  obtain ⟨n, a, rfl⟩ := hp
  obtain ⟨m, b, rfl⟩ := hq
  refine ⟨n + m, a * b, ?_⟩
  push_cast
  rw [pow_add]
  ring

/-- One is a dyadic rational. -/
theorem dyadic_one_mem : (1 : ℚ) ∈ dyadicRationals :=
  (mem_dyadicRationals_iff 1).mpr ⟨0, 1, by simp⟩

/-- The ring of dyadic rationals ℤ[1/2] as a subring of ℚ. -/
def dyadicSubring : Subring ℚ where
  carrier := dyadicRationals.carrier
  add_mem' := dyadicRationals.add_mem'
  zero_mem' := dyadicRationals.zero_mem'
  neg_mem' := dyadicRationals.neg_mem'
  one_mem' := dyadic_one_mem
  mul_mem' := dyadic_mul_mem

end BratteliDiagram
