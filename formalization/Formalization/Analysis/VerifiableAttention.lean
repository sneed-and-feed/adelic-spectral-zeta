import Mathlib.Data.Real.Basic
import Mathlib.Data.Fin.Basic
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

open scoped BigOperators Matrix
open Classical

noncomputable section

namespace VerifiableAttention

/-!
# Faithful Arithmetization of p-Adic Tree LCA Routing

This module formalizes the faithful arithmetization of lowest common ancestor (LCA)
routing on discrete p-adic trees into Rank-1 Constraint Systems (R1CS) over arbitrary fields, proving:
1. **Discrete p-Adic Tree Paths**: `TreePath d p = Fin d → Fin p`.
2. **Prefix Equality Relation**: `PrefixEq u v r` at depth `r ≤ d`.
3. **LCA Depth Equivalence & Ultrametric Property**: `LCA_ge u v r ↔ PrefixEq u v r` and the ultrametric tree inequality.
4. **Base-p Limb Range Proofs**: Vanishing polynomial `limbRangePolynomial` and root vanishing soundness.
5. **Composite Tree Path Reconstruction & Injectivity**: Unique scalar reconstruction `reconstructPath` and `reconstructPrefix`.
6. **Digit R1CS Gadget**: Zero-check / Equality arithmetic constraints over an arbitrary generic field `[Field F]`.
7. **Prefix R1CS & Conjunction Gate**: Arithmetization of branch prefixes via multiplicative accumulation.
8. **Faithful Arithmetization Soundness & Completeness**:
   - `PrefixEq u v r ↔ ∏ k < r, eq_k = 1`.
   - `¬ PrefixEq u v r → ∏ k < r, eq_k = 0`.
   - Wire uniqueness: `eq` is uniquely determined for all satisfying assignments.
9. **Non-Interference / Domain Isolation**: Cross-domain attention gates evaluate identically to `0`.
10. **Verifiable Attention Matrix**: Sparsity and block isolation on cluster routing matrices.
-/

/-! ### 1. Discrete p-Adic Tree Paths -/

/-- A path in a discrete p-adic tree of depth `d` and arity `p`. -/
def TreePath (d p : ℕ) := Fin d → Fin p

/-- Embedding a digit `Fin p` into a field `F`. -/
def digitToField {F : Type*} [Field F] {p : ℕ} (a : Fin p) : F := (a.val : F)

/-- Embedding a digit `Fin p` into the real field `ℝ`. -/
def digitToReal {p : ℕ} (a : Fin p) : ℝ := (a.val : ℝ)

lemma digit_val_inj {F : Type*} [Field F] [CharZero F] {p : ℕ} (a b : Fin p) : (a.val : F) = (b.val : F) ↔ a = b := by
  simp [Fin.ext_iff]

lemma digit_sub_eq_zero_iff {F : Type*} [Field F] [CharZero F] {p : ℕ} (a b : Fin p) : (a.val : F) - (b.val : F) = 0 ↔ a = b :=
  sub_eq_zero.trans (digit_val_inj a b)

lemma digit_sub_ne_zero_iff {F : Type*} [Field F] [CharZero F] {p : ℕ} (a b : Fin p) : (a.val : F) - (b.val : F) ≠ 0 ↔ a ≠ b :=
  not_congr (digit_sub_eq_zero_iff a b)

/-! ### 2. Prefix Equality Relation -/

/-- Prefix equality relation at depth `r`: paths `u` and `v` agree on all levels `k < r`. -/
def PrefixEq {d p : ℕ} (u v : TreePath d p) (r : ℕ) : Prop :=
  ∀ (k : Fin d), k.val < r → u k = v k

lemma prefixEq_refl {d p : ℕ} (u : TreePath d p) (r : ℕ) : PrefixEq u u r :=
  fun _ _ => rfl

lemma prefixEq_symm {d p : ℕ} {u v : TreePath d p} {r : ℕ} (h : PrefixEq u v r) : PrefixEq v u r :=
  fun k hk => (h k hk).symm

lemma prefixEq_trans {d p : ℕ} {u v w : TreePath d p} {r : ℕ}
    (huv : PrefixEq u v r) (hvw : PrefixEq v w r) : PrefixEq u w r :=
  fun k hk => (huv k hk).trans (hvw k hk)

lemma prefixEq_zero {d p : ℕ} (u v : TreePath d p) : PrefixEq u v 0 :=
  fun _ hk => (Nat.not_lt_zero _ hk).elim

lemma prefixEq_monotone {d p : ℕ} {u v : TreePath d p} {r₁ r₂ : ℕ} (hle : r₁ ≤ r₂)
    (h : PrefixEq u v r₂) : PrefixEq u v r₁ :=
  fun k hk => h k (lt_of_lt_of_le hk hle)

lemma prefixEq_succ {d p : ℕ} (u v : TreePath d p) (r : ℕ) (hr : r < d) :
    PrefixEq u v (r + 1) ↔ PrefixEq u v r ∧ u ⟨r, hr⟩ = v ⟨r, hr⟩ :=
  ⟨fun h => ⟨prefixEq_monotone (Nat.le_succ r) h, h ⟨r, hr⟩ (Nat.lt_succ_self r)⟩,
   fun ⟨hprev, hstep⟩ k hk => (lt_or_eq_of_le (Nat.le_of_lt_succ hk)).elim
     (hprev k) (fun heq => (Fin.ext heq : k = ⟨r, hr⟩) ▸ hstep)⟩

/-! ### 3. Lowest Common Ancestor (LCA) State, Depth, and Ultrametricity -/

/-- LCA depth state predicate: two paths share an ancestor at level at least `r`. -/
def LCA_ge {d p : ℕ} (u v : TreePath d p) (r : ℕ) : Prop := PrefixEq u v r

@[simp]
theorem lca_ge_iff_prefixEq {d p : ℕ} (u v : TreePath d p) (r : ℕ) :
    LCA_ge u v r ↔ PrefixEq u v r := Iff.rfl

/-- Set of prefix depths `r ≤ d` at which `u` and `v` agree. -/
def prefixAgreementDepths {d p : ℕ} (u v : TreePath d p) : Finset ℕ :=
  (Finset.range (d + 1)).filter (fun r => PrefixEq u v r)

lemma mem_prefixAgreementDepths_zero {d p : ℕ} (u v : TreePath d p) :
    0 ∈ prefixAgreementDepths u v := by
  simp [prefixAgreementDepths, prefixEq_zero]

/-- The Lowest Common Ancestor (LCA) depth of two paths `u, v` in a tree of depth `d`. -/
def lcaDepth {d p : ℕ} (u v : TreePath d p) : ℕ :=
  (prefixAgreementDepths u v).max' ⟨0, mem_prefixAgreementDepths_zero u v⟩

lemma lcaDepth_mem {d p : ℕ} (u v : TreePath d p) :
    lcaDepth u v ∈ prefixAgreementDepths u v :=
  Finset.max'_mem _ _

lemma lcaDepth_prefixEq {d p : ℕ} (u v : TreePath d p) :
    PrefixEq u v (lcaDepth u v) :=
  (Finset.mem_filter.mp (lcaDepth_mem u v)).2

lemma lcaDepth_le_depth {d p : ℕ} (u v : TreePath d p) :
    lcaDepth u v ≤ d :=
  Nat.le_of_lt_succ (Finset.mem_range.mp (Finset.mem_filter.mp (lcaDepth_mem u v)).1)

theorem lcaDepth_ge_iff {d p : ℕ} (u v : TreePath d p) {r : ℕ} (hr : r ≤ d) :
    r ≤ lcaDepth u v ↔ PrefixEq u v r :=
  ⟨fun hle => prefixEq_monotone hle (lcaDepth_prefixEq u v),
   fun hpref => Finset.le_max' (prefixAgreementDepths u v) r
     (Finset.mem_filter.mpr ⟨Finset.mem_range.mpr (Nat.lt_succ_of_le hr), hpref⟩)⟩

lemma lcaDepth_refl {d p : ℕ} (u : TreePath d p) : lcaDepth u u = d :=
  le_antisymm (lcaDepth_le_depth u u) ((lcaDepth_ge_iff u u le_rfl).mpr (prefixEq_refl u d))

lemma lcaDepth_symm {d p : ℕ} (u v : TreePath d p) : lcaDepth u v = lcaDepth v u :=
  le_antisymm
    ((lcaDepth_ge_iff v u (lcaDepth_le_depth u v)).mpr (prefixEq_symm (lcaDepth_prefixEq u v)))
    ((lcaDepth_ge_iff u v (lcaDepth_le_depth v u)).mpr (prefixEq_symm (lcaDepth_prefixEq v u)))

/-- Non-Archimedean Ultrametric Inequality for tree LCA depth:
lcaDepth(u, w) ≥ min(lcaDepth(u, v), lcaDepth(v, w)). -/
theorem lcaDepth_ultrametric {d p : ℕ} (u v w : TreePath d p) :
    min (lcaDepth u v) (lcaDepth v w) ≤ lcaDepth u w :=
  (lcaDepth_ge_iff u w (le_trans (min_le_left _ _) (lcaDepth_le_depth u v))).mpr
    (prefixEq_trans (prefixEq_monotone (min_le_left _ _) (lcaDepth_prefixEq u v))
                    (prefixEq_monotone (min_le_right _ _) (lcaDepth_prefixEq v w)))

/-! ### 4. Base-p Limb Range Proofs -/

/-- Base-p limb range polynomial: vanishing polynomial over the limb alphabet `{0, 1, ..., p - 1}`. -/
def limbRangePolynomial {F : Type*} [CommRing F] (p : ℕ) (x : F) : F :=
  ∏ j ∈ Finset.range p, (x - (j : F))

/-- Root vanishing soundness theorem for limb range polynomials:
For any field `F`, `limbRangePolynomial p x = 0` if and only if `x = (j.val : F)` for some digit `j : Fin p`. -/
theorem limbRangePolynomial_eq_zero_iff {F : Type*} [Field F] (p : ℕ) (x : F) :
    limbRangePolynomial p x = 0 ↔ ∃ (j : Fin p), x = (j.val : F) := by
  simp [limbRangePolynomial, Finset.prod_eq_zero_iff, sub_eq_zero]
  exact ⟨fun ⟨a, ha, h⟩ => ⟨⟨a, ha⟩, h⟩, fun ⟨j, hj⟩ => ⟨j.1, j.2, hj⟩⟩

/-- Completeness: Any valid digit `a : Fin p` is a root of the limb range polynomial. -/
lemma limbRangePolynomial_digit {F : Type*} [CommRing F] {p : ℕ} (a : Fin p) :
    limbRangePolynomial (F := F) p (a.val : F) = 0 :=
  Finset.prod_eq_zero (Finset.mem_range.mpr a.isLt) (sub_self _)

/-! ### 5. Composite Tree Path Reconstruction & Injectivity -/

/-- Composite tree path reconstruction: integer scalar value of a path in base `p`. -/
def reconstructPath {d p : ℕ} (u : TreePath d p) : ℕ :=
  ∑ k : Fin d, (u k).val * p ^ (k.val)

/-- Composite prefix reconstruction: integer scalar value of a length-`r` prefix in base `p`. -/
def reconstructPrefix {d p : ℕ} (u : TreePath d p) (r : ℕ) (hr : r ≤ d) : ℕ :=
  ∑ k : Fin r, (u ⟨k.val, lt_of_lt_of_le k.isLt hr⟩).val * p ^ (k.val)

lemma reconstructPath_zero {p : ℕ} (u : TreePath 0 p) : reconstructPath u = 0 := by
  simp [reconstructPath]

lemma fin_sum_univ_succ {M : Type*} [AddCommMonoid M] {n : ℕ} (f : Fin (n + 1) → M) :
    ∑ i : Fin (n + 1), f i = f 0 + ∑ i : Fin n, f i.succ := by
  rw [Fin.univ_succ, Finset.sum_cons, Finset.sum_map]
  rfl

lemma reconstructPath_succ {d p : ℕ} (u : TreePath (d + 1) p) :
    reconstructPath u = (u 0).val + p * reconstructPath (fun k : Fin d => u k.succ) := by
  dsimp [reconstructPath]
  rw [fin_sum_univ_succ]
  simp only [Fin.val_zero, pow_zero, mul_one, Fin.val_succ, Finset.mul_sum]
  congr 1
  apply Finset.sum_congr rfl
  intro k _
  rw [pow_succ']
  ring

/-- Injectivity of composite tree path reconstruction:
Two paths in a p-adic tree are identical iff their scalar reconstructions are equal. -/
theorem reconstructPath_injective {d p : ℕ} (u v : TreePath d p)
    (h : reconstructPath u = reconstructPath v) : u = v := by
  induction d with
  | zero => funext k; exact k.elim0
  | succ d ih =>
    have h_eq : (u 0).val + p * reconstructPath (fun k => u k.succ) =
                (v 0).val + p * reconstructPath (fun k => v k.succ) := by
      rw [← reconstructPath_succ u, h, reconstructPath_succ v]
    have h0 : u 0 = v 0 := Fin.ext <| by
      simpa [Nat.add_mul_mod_self_left, Nat.mod_eq_of_lt (u 0).isLt, Nat.mod_eq_of_lt (v 0).isLt]
        using congrArg (· % p) h_eq
    have hp_pos : 0 < p := (u 0).isLt.trans_le' (Nat.zero_le _)
    have hrest_val : reconstructPath (fun k => u k.succ) = reconstructPath (fun k => v k.succ) :=
      Nat.eq_of_mul_eq_mul_left hp_pos (Nat.add_left_cancel (by rw [congrArg Fin.val h0] at h_eq; exact h_eq))
    exact funext (Fin.cases h0 (congr_fun (ih _ _ hrest_val)))

theorem reconstructPath_inj_iff {d p : ℕ} (u v : TreePath d p) :
    reconstructPath u = reconstructPath v ↔ u = v :=
  ⟨reconstructPath_injective u v, congrArg reconstructPath⟩

theorem reconstructPrefix_inj_iff {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p) :
    reconstructPrefix u r hr = reconstructPrefix v r hr ↔ PrefixEq u v r := by
  let u_r : TreePath r p := fun k => u ⟨k.val, lt_of_lt_of_le k.isLt hr⟩
  let v_r : TreePath r p := fun k => v ⟨k.val, lt_of_lt_of_le k.isLt hr⟩
  change reconstructPath u_r = reconstructPath v_r ↔ PrefixEq u v r
  rw [reconstructPath_inj_iff]
  exact ⟨fun h k hk => congr_fun h ⟨k.val, hk⟩, fun h => funext fun ⟨k, hk⟩ => h ⟨k, _⟩ hk⟩

/-- Composite tree path reconstruction embedded in a ring `F`. -/
def reconstructPathField {F : Type*} [CommRing F] {d p : ℕ} (u : TreePath d p) : F :=
  ∑ k : Fin d, ((u k).val : F) * (p : F) ^ (k.val)

/-- Composite prefix reconstruction embedded in a ring `F`. -/
def reconstructPrefixField {F : Type*} [CommRing F] {d p : ℕ} (u : TreePath d p) (r : ℕ) (hr : r ≤ d) : F :=
  ∑ k : Fin r, ((u ⟨k.val, lt_of_lt_of_le k.isLt hr⟩).val : F) * (p : F) ^ (k.val)

lemma reconstructPathField_eq_cast {F : Type*} [CommRing F] {d p : ℕ} (u : TreePath d p) :
    reconstructPathField (F := F) u = (reconstructPath u : F) := by
  dsimp [reconstructPathField, reconstructPath]
  push_cast
  rfl

lemma reconstructPrefixField_eq_cast {F : Type*} [CommRing F] {d p : ℕ} (u : TreePath d p) (r : ℕ) (hr : r ≤ d) :
    reconstructPrefixField (F := F) u r hr = (reconstructPrefix u r hr : F) := by
  dsimp [reconstructPrefixField, reconstructPrefix]
  push_cast
  rfl

theorem reconstructPathField_injective {F : Type*} [Field F] [CharZero F] {d p : ℕ}
    (u v : TreePath d p) (h : reconstructPathField (F := F) u = reconstructPathField (F := F) v) :
    u = v :=
  reconstructPath_injective u v (Nat.cast_injective (by rwa [reconstructPathField_eq_cast, reconstructPathField_eq_cast] at h))

theorem reconstructPrefixField_inj_iff {F : Type*} [Field F] [CharZero F] {d p r : ℕ}
    (hr : r ≤ d) (u v : TreePath d p) :
    reconstructPrefixField (F := F) u r hr = reconstructPrefixField (F := F) v r hr ↔ PrefixEq u v r := by
  rw [reconstructPrefixField_eq_cast, reconstructPrefixField_eq_cast, Nat.cast_inj, reconstructPrefix_inj_iff hr]

/-! ### 6. Digit R1CS Constraints -/

/-- Rank-1 Constraint System (R1CS) gadget for single digit equality comparison over any field `F`:
Given inputs `x, y : F`, witness wires `eq, inv : F` satisfy:
1. `eq * (x - y) = 0` (Zero check)
2. `inv * (x - y) = 1 - eq` (Inverse check)
3. `eq * (1 - eq) = 0` (Booleanity)
-/
structure DigitR1CS {F : Type*} [Field F] (x y eq inv : F) : Prop where
  zero_check : eq * (x - y) = 0
  inv_check  : inv * (x - y) = 1 - eq
  bool_check : eq * (1 - eq) = 0

lemma digitR1CS_of_eq {F : Type*} [Field F] (x : F) : DigitR1CS x x 1 0 :=
  ⟨by ring, by ring, by ring⟩

lemma digitR1CS_of_ne {F : Type*} [Field F] {x y : F} (h : x ≠ y) : DigitR1CS x y 0 (x - y)⁻¹ :=
  ⟨by ring, by rw [inv_mul_cancel₀ (sub_ne_zero.mpr h)]; ring, by ring⟩

lemma digitR1CS_sound_eq {F : Type*} [Field F] {x y eq inv : F} (hR : DigitR1CS x y eq inv) (heq : x = y) : eq = 1 := by
  have h := hR.inv_check
  rw [heq, sub_self, mul_zero] at h
  exact (sub_eq_zero.mp h.symm).symm

lemma digitR1CS_sound_ne {F : Type*} [Field F] {x y eq inv : F} (hR : DigitR1CS x y eq inv) (hne : x ≠ y) : eq = 0 :=
  (mul_eq_zero.mp hR.zero_check).resolve_right (sub_ne_zero.mpr hne)

lemma digitR1CS_sound_ne_inv {F : Type*} [Field F] {x y eq inv : F} (hR : DigitR1CS x y eq inv) (hne : x ≠ y) :
    inv = (x - y)⁻¹ :=
  eq_inv_of_mul_eq_one_left (by simpa [digitR1CS_sound_ne hR hne] using hR.inv_check)

lemma digitR1CS_eq_iff {F : Type*} [Field F] {x y eq inv : F} (hR : DigitR1CS x y eq inv) : eq = 1 ↔ x = y :=
  ⟨fun h => not_not.mp fun hne => one_ne_zero (h.symm.trans (digitR1CS_sound_ne hR hne)), digitR1CS_sound_eq hR⟩

lemma digitR1CS_zero_iff {F : Type*} [Field F] {x y eq inv : F} (hR : DigitR1CS x y eq inv) : eq = 0 ↔ x ≠ y :=
  ⟨fun h rfl => zero_ne_one (h.symm.trans (digitR1CS_sound_eq hR rfl)), digitR1CS_sound_ne hR⟩

lemma digitR1CS_bool {F : Type*} [Field F] {x y eq inv : F} (hR : DigitR1CS x y eq inv) : eq = 0 ∨ eq = 1 :=
  (mul_eq_zero.mp hR.bool_check).imp_right fun h => (sub_eq_zero.mp h).symm

/-! ### 7. Prefix R1CS and Conjunction Accumulator -/

/-- System of R1CS constraints enforcing digit-wise equality up to depth `r ≤ d`. -/
def PrefixR1CS {F : Type*} [Field F] {d p : ℕ} (u v : TreePath d p) (r : ℕ) (hr : r ≤ d) (eq inv : Fin r → F) : Prop :=
  ∀ (k : Fin r),
    DigitR1CS ((u ⟨k.val, lt_of_lt_of_le k.isLt hr⟩).val : F)
              ((v ⟨k.val, lt_of_lt_of_le k.isLt hr⟩).val : F)
              (eq k) (inv k)

/-- The multiplicative prefix conjunction mask M_r = ∏_{k < r} eq_k. -/
def prefixMask {F : Type*} [CommMonoidWithZero F] (r : ℕ) (eq : Fin r → F) : F :=
  ∏ k : Fin r, eq k

/-- Canonical equality wire assignment. -/
def canonicalEq {F : Type*} [Field F] {d p : ℕ} (u v : TreePath d p) (r : ℕ) (hr : r ≤ d) : Fin r → F :=
  fun k => if u ⟨k.val, lt_of_lt_of_le k.isLt hr⟩ = v ⟨k.val, lt_of_lt_of_le k.isLt hr⟩ then 1 else 0

/-- Canonical inverse wire assignment. -/
def canonicalInv {F : Type*} [Field F] {d p : ℕ} (u v : TreePath d p) (r : ℕ) (hr : r ≤ d) : Fin r → F :=
  fun k =>
    let uk : F := (u ⟨k.val, lt_of_lt_of_le k.isLt hr⟩).val
    let vk : F := (v ⟨k.val, lt_of_lt_of_le k.isLt hr⟩).val
    if u ⟨k.val, lt_of_lt_of_le k.isLt hr⟩ = v ⟨k.val, lt_of_lt_of_le k.isLt hr⟩ then 0 else (uk - vk)⁻¹

theorem canonical_satisfies_prefixR1CS {F : Type*} [Field F] [CharZero F] {d p : ℕ} (u v : TreePath d p) (r : ℕ) (hr : r ≤ d) :
    PrefixR1CS u v r hr (canonicalEq (F := F) u v r hr) (canonicalInv (F := F) u v r hr) := by
  intro k
  dsimp [canonicalEq, canonicalInv]
  split_ifs with heq
  · exact heq ▸ digitR1CS_of_eq _
  · exact digitR1CS_of_ne ((digit_val_inj _ _).not.mpr heq)

lemma prefixMask_eq_one_of_all_one {F : Type*} [CommMonoidWithZero F] {r : ℕ} {eq : Fin r → F} (h : ∀ k : Fin r, eq k = 1) :
    prefixMask r eq = 1 :=
  Finset.prod_eq_one fun k _ => h k

lemma prefixMask_eq_zero_of_exists_zero {F : Type*} [CommMonoidWithZero F] {r : ℕ} {eq : Fin r → F} (k₀ : Fin r) (h : eq k₀ = 0) :
    prefixMask r eq = 0 :=
  Finset.prod_eq_zero (Finset.mem_univ k₀) h

/-! ### 8. Faithful Arithmetization Soundness & Completeness -/

/-- Completeness: If `PrefixEq u v r`, there exists a satisfying assignment where all `eq = 1`, `inv = 0`, and `prefixMask = 1`. -/
theorem prefix_arithmetization_completeness {F : Type*} [Field F] [CharZero F] {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (hpref : PrefixEq u v r) :
    ∃ (eq inv : Fin r → F),
      PrefixR1CS u v r hr eq inv ∧
      (∀ k : Fin r, eq k = 1 ∧ inv k = 0) ∧
      prefixMask r eq = 1 := by
  refine ⟨canonicalEq u v r hr, canonicalInv u v r hr,
          canonical_satisfies_prefixR1CS u v r hr, fun k => ?_, ?_⟩
  · have hk := hpref ⟨k.val, lt_of_lt_of_le k.isLt hr⟩ k.isLt
    simp [canonicalEq, canonicalInv, hk]
  · exact prefixMask_eq_one_of_all_one fun k => by
      simp [canonicalEq, hpref ⟨k.val, lt_of_lt_of_le k.isLt hr⟩ k.isLt]

/-- Soundness: Any satisfying assignment for matching prefixes must set all equality wires to 1. -/
theorem prefix_eq_wires_eq_one {F : Type*} [Field F] [CharZero F] {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (hpref : PrefixEq u v r) (eq inv : Fin r → F) (hR : PrefixR1CS u v r hr eq inv) :
    ∀ k : Fin r, eq k = 1 :=
  fun k => digitR1CS_sound_eq (hR k) ((digit_val_inj _ _).mpr (hpref ⟨k.val, lt_of_lt_of_le k.isLt hr⟩ k.isLt))

/-- Wire Uniqueness: For any satisfying assignment, the equality wire vector `eq` is uniquely determined. -/
theorem prefixR1CS_eq_wires_unique {F : Type*} [Field F] [CharZero F] {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (eq inv : Fin r → F) (hR : PrefixR1CS u v r hr eq inv) :
    eq = canonicalEq u v r hr := by
  ext k
  dsimp [canonicalEq]
  split_ifs with heq
  · exact digitR1CS_sound_eq (hR k) (congrArg digitToField heq)
  · exact digitR1CS_sound_ne (hR k) ((digit_val_inj _ _).not.mpr heq)

/-- Soundness: Any satisfying assignment for diverging prefixes forces `prefixMask = 0`. -/
theorem prefix_arithmetization_unsat_zero {F : Type*} [Field F] [CharZero F] {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (hdiv : ¬ PrefixEq u v r) (eq inv : Fin r → F) (hR : PrefixR1CS u v r hr eq inv) :
    prefixMask r eq = 0 := by
  dsimp [PrefixEq] at hdiv
  push Not at hdiv
  rcases hdiv with ⟨k_d, hk_lt, hne⟩
  have hne_real : ((u ⟨k_d.val, lt_of_lt_of_le hk_lt hr⟩).val : F) ≠ ((v ⟨k_d.val, lt_of_lt_of_le hk_lt hr⟩).val : F) := by
    rw [ne_eq, digit_val_inj]
    intro h
    exact hne ((Fin.ext rfl : (⟨k_d.val, lt_of_lt_of_le hk_lt hr⟩ : Fin d) = k_d) ▸ h)
  exact prefixMask_eq_zero_of_exists_zero ⟨k_d.val, hk_lt⟩ (digitR1CS_sound_ne (hR ⟨k_d.val, hk_lt⟩) hne_real)

/-- Faithful Arithmetization Soundness & Completeness Theorem. -/
theorem faithful_arithmetization_soundness_and_completeness {F : Type*} [Field F] [CharZero F] {d p r : ℕ} (hr : r ≤ d)
    (u v : TreePath d p) :
    PrefixEq u v r ↔
      ∃ (eq inv : Fin r → F),
        PrefixR1CS u v r hr eq inv ∧
        (∀ k, eq k = 1 ∧ inv k = 0) ∧
        prefixMask r eq = 1 := by
  refine ⟨prefix_arithmetization_completeness hr u v, ?_⟩
  rintro ⟨eq, inv, hR, hall, -⟩ k hk
  have heq := (digitR1CS_eq_iff (hR ⟨k.val, hk⟩)).mp (hall ⟨k.val, hk⟩).1
  rwa [digit_val_inj, show (⟨k.val, lt_of_lt_of_le hk hr⟩ : Fin d) = k from Fin.ext rfl] at heq

/-- For ANY satisfying assignment, the prefix conjunction mask equals 1 iff the prefixes agree. -/
theorem prefixMask_eq_one_iff {F : Type*} [Field F] [CharZero F] {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (eq inv : Fin r → F) (hR : PrefixR1CS u v r hr eq inv) :
    prefixMask r eq = 1 ↔ PrefixEq u v r :=
  ⟨fun h => not_not.mp fun hdiv => one_ne_zero (h ▸ prefix_arithmetization_unsat_zero hr u v hdiv eq inv hR),
   fun hpref => prefixMask_eq_one_of_all_one (prefix_eq_wires_eq_one hr u v hpref eq inv hR)⟩

/-- For ANY satisfying assignment, `prefixMask r eq` is identically `if PrefixEq u v r then 1 else 0`. -/
theorem prefixMask_eval {F : Type*} [Field F] [CharZero F] {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (eq inv : Fin r → F) (hR : PrefixR1CS u v r hr eq inv) :
    prefixMask r eq = if PrefixEq u v r then 1 else 0 := by
  split_ifs with h
  · exact (prefixMask_eq_one_iff hr u v eq inv hR).mpr h
  · exact prefix_arithmetization_unsat_zero hr u v h eq inv hR

/-! ### 9. Non-Interference and Attention Domain Isolation -/

/-- Verifiable attention routing gate modulated by the prefix conjunction mask. -/
def verifiableAttentionGate {F : Type*} [CommMonoidWithZero F] (r : ℕ) (eq : Fin r → F) (raw_score : F) : F :=
  prefixMask r eq * raw_score

/-- Non-Interference Theorem: If two paths diverge at any step `k < r`,
the verifiable attention routing gate evaluates identically to `0`. -/
theorem non_interference {F : Type*} [Field F] [CharZero F] {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (hdiv : ¬ PrefixEq u v r) (eq inv : Fin r → F) (hR : PrefixR1CS u v r hr eq inv)
    (score : F) :
    verifiableAttentionGate r eq score = 0 := by
  simp [verifiableAttentionGate, prefix_arithmetization_unsat_zero hr u v hdiv eq inv hR]

/-- Non-Interference at an explicit divergence step `k < r`. -/
theorem non_interference_at_divergence {F : Type*} [Field F] [CharZero F] {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    {k : Fin d} (hk : k.val < r) (hne : u k ≠ v k) (eq inv : Fin r → F)
    (hR : PrefixR1CS u v r hr eq inv) (score : F) :
    verifiableAttentionGate r eq score = 0 :=
  non_interference hr u v (fun hpref => hne (hpref k hk)) eq inv hR score

/-- Security Domain Isolation: Cross-domain queries between divergent paths yield zero attention mass. -/
theorem security_domain_isolation {F : Type*} [Field F] [CharZero F] {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (eq inv : Fin r → F) (hR : PrefixR1CS u v r hr eq inv) (score : F) :
    PrefixEq u v r ∨ verifiableAttentionGate r eq score = 0 :=
  (Classical.em (PrefixEq u v r)).imp_right (non_interference hr u v · eq inv hR score)

/-- Faithful attention gate evaluation: the gate faithfully reflects prefix membership. -/
theorem verifiable_attention_faithful_eval {F : Type*} [Field F] [CharZero F] {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (eq inv : Fin r → F) (hR : PrefixR1CS u v r hr eq inv) (score : F) :
    verifiableAttentionGate r eq score = if PrefixEq u v r then score else 0 := by
  simp [verifiableAttentionGate, prefixMask_eval hr u v eq inv hR, apply_ite (· * score)]

/-! ### 10. Verifiable Attention Routing Matrix and Cluster Sparsity -/

/-- Full verifiable attention routing matrix for `N` tokens with tree paths in a p-adic tree. -/
def verifiableAttentionMatrix {F : Type*} [Field F] {N d p r : ℕ} (hr : r ≤ d) (paths : Fin N → TreePath d p)
    (rawScores : Matrix (Fin N) (Fin N) F) : Matrix (Fin N) (Fin N) F :=
  fun i j => verifiableAttentionGate r (canonicalEq (paths i) (paths j) r hr) (rawScores i j)

/-- Cluster Sparsity Theorem: Tokens belonging to distinct clusters / security domains at depth `r`
have strictly 0 cross-attention entries. -/
theorem attention_cluster_sparsity {F : Type*} [Field F] [CharZero F] {N d p r : ℕ} (hr : r ≤ d) (paths : Fin N → TreePath d p)
    (rawScores : Matrix (Fin N) (Fin N) F) (i j : Fin N)
    (h_diff_cluster : ¬ PrefixEq (paths i) (paths j) r) :
    verifiableAttentionMatrix hr paths rawScores i j = 0 :=
  non_interference hr (paths i) (paths j) h_diff_cluster
    (canonicalEq (F := F) (paths i) (paths j) r hr) (canonicalInv (F := F) (paths i) (paths j) r hr)
    (canonical_satisfies_prefixR1CS (paths i) (paths j) r hr) (rawScores i j)

/-- Direct Cluster Sparsity for arbitrary fields `F` via canonical circuit evaluation. -/
theorem canonical_attention_cluster_sparsity {F : Type*} [Field F] {N d p r : ℕ}
    (hr : r ≤ d) (paths : Fin N → TreePath d p) (rawScores : Matrix (Fin N) (Fin N) F) (i j : Fin N)
    (h_diff_cluster : ¬ PrefixEq (paths i) (paths j) r) :
    verifiableAttentionMatrix hr paths rawScores i j = 0 := by
  dsimp [PrefixEq] at h_diff_cluster
  push Not at h_diff_cluster
  rcases h_diff_cluster with ⟨k_d, hk_lt, hne⟩
  have h_eq_zero : canonicalEq (F := F) (paths i) (paths j) r hr ⟨k_d.val, hk_lt⟩ = 0 := by
    simp [canonicalEq, (show (⟨k_d.val, lt_of_lt_of_le hk_lt hr⟩ : Fin d) = k_d from Fin.ext rfl) ▸ hne]
  simp [verifiableAttentionMatrix, verifiableAttentionGate,
        prefixMask_eq_zero_of_exists_zero ⟨k_d.val, hk_lt⟩ h_eq_zero]

end VerifiableAttention
