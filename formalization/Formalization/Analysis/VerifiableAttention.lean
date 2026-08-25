import Mathlib.Data.Real.Basic
import Mathlib.Data.Fin.Basic
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

open scoped BigOperators Matrix
open Classical

set_option linter.unusedSectionVars false

noncomputable section

namespace VerifiableAttention

/-!
# Faithful Arithmetization of p-Adic Tree LCA Routing

This module formalizes the faithful arithmetization of lowest common ancestor (LCA)
routing on discrete p-adic trees into Rank-1 Constraint Systems (R1CS), proving:
1. **Discrete p-Adic Tree Paths**: `TreePath d p = Fin d → Fin p`.
2. **Prefix Equality Relation**: `PrefixEq u v r` at depth `r ≤ d`.
3. **LCA Depth Equivalence & Ultrametric Property**: `LCA_ge u v r ↔ PrefixEq u v r` and the ultrametric tree inequality.
4. **Digit R1CS Gadget**: Zero-check / Equality arithmetic constraints.
5. **Prefix R1CS & Conjunction Gate**: Arithmetization of branch prefixes via multiplicative accumulation.
6. **Faithful Arithmetization Soundness & Completeness**:
   - `PrefixEq u v r ↔ ∏ k < r, eq_k = 1`.
   - `¬ PrefixEq u v r → ∏ k < r, eq_k = 0`.
   - Wire uniqueness: `eq` is uniquely determined for all satisfying assignments.
7. **Non-Interference / Domain Isolation**: Cross-domain attention gates evaluate identically to `0`.
8. **Verifiable Attention Matrix**: Sparsity and block isolation on cluster routing matrices.
-/

/-! ### 1. Discrete p-Adic Tree Paths -/

/-- A path in a discrete p-adic tree of depth `d` and arity `p`. -/
def TreePath (d p : ℕ) := Fin d → Fin p

/-- Embedding a digit `Fin p` into the real field `ℝ`. -/
def digitToReal {p : ℕ} (a : Fin p) : ℝ := (a.val : ℝ)

lemma digit_val_inj {p : ℕ} (a b : Fin p) : (a.val : ℝ) = (b.val : ℝ) ↔ a = b := by
  simp [Fin.ext_iff]

lemma digit_sub_eq_zero_iff {p : ℕ} (a b : Fin p) : (a.val : ℝ) - (b.val : ℝ) = 0 ↔ a = b := by
  rw [sub_eq_zero, digit_val_inj]

lemma digit_sub_ne_zero_iff {p : ℕ} (a b : Fin p) : (a.val : ℝ) - (b.val : ℝ) ≠ 0 ↔ a ≠ b := by
  rw [ne_eq, sub_eq_zero, digit_val_inj]

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
    PrefixEq u v (r + 1) ↔ PrefixEq u v r ∧ u ⟨r, hr⟩ = v ⟨r, hr⟩ := by
  constructor
  · intro h
    refine ⟨prefixEq_monotone (Nat.le_succ r) h, h ⟨r, hr⟩ (Nat.lt_succ_self r)⟩
  · rintro ⟨hprev, hstep⟩ k hk
    rcases lt_or_eq_of_le (Nat.le_of_lt_succ hk) with hlt | heq
    · exact hprev k hlt
    · exact (Fin.ext heq : k = ⟨r, hr⟩) ▸ hstep

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
    r ≤ lcaDepth u v ↔ PrefixEq u v r := by
  constructor
  · exact fun hle => prefixEq_monotone hle (lcaDepth_prefixEq u v)
  · intro hpref
    have hmem : r ∈ prefixAgreementDepths u v :=
      Finset.mem_filter.mpr ⟨Finset.mem_range.mpr (Nat.lt_succ_of_le hr), hpref⟩
    exact Finset.le_max' (prefixAgreementDepths u v) r hmem

lemma lcaDepth_refl {d p : ℕ} (u : TreePath d p) : lcaDepth u u = d := by
  apply le_antisymm (lcaDepth_le_depth u u)
  exact (lcaDepth_ge_iff u u le_rfl).mpr (prefixEq_refl u d)

lemma lcaDepth_symm {d p : ℕ} (u v : TreePath d p) : lcaDepth u v = lcaDepth v u := by
  apply le_antisymm
  · exact (lcaDepth_ge_iff v u (lcaDepth_le_depth u v)).mpr (prefixEq_symm (lcaDepth_prefixEq u v))
  · exact (lcaDepth_ge_iff u v (lcaDepth_le_depth v u)).mpr (prefixEq_symm (lcaDepth_prefixEq v u))

/-- Non-Archimedean Ultrametric Inequality for tree LCA depth:
lcaDepth(u, w) ≥ min(lcaDepth(u, v), lcaDepth(v, w)). -/
theorem lcaDepth_ultrametric {d p : ℕ} (u v w : TreePath d p) :
    min (lcaDepth u v) (lcaDepth v w) ≤ lcaDepth u w := by
  set m := min (lcaDepth u v) (lcaDepth v w)
  have hm_le_d : m ≤ d := le_trans (min_le_left _ _) (lcaDepth_le_depth u v)
  rw [lcaDepth_ge_iff u w hm_le_d]
  exact prefixEq_trans (prefixEq_monotone (min_le_left _ _) (lcaDepth_prefixEq u v))
                       (prefixEq_monotone (min_le_right _ _) (lcaDepth_prefixEq v w))

/-! ### 4. Digit R1CS Constraints -/

/-- Rank-1 Constraint System (R1CS) gadget for single digit equality comparison:
Given inputs `x, y : ℝ`, witness wires `eq, inv : ℝ` satisfy:
1. `eq * (x - y) = 0` (Zero check)
2. `inv * (x - y) = 1 - eq` (Inverse check)
3. `eq * (1 - eq) = 0` (Booleanity)
-/
structure DigitR1CS (x y eq inv : ℝ) : Prop where
  zero_check : eq * (x - y) = 0
  inv_check  : inv * (x - y) = 1 - eq
  bool_check : eq * (1 - eq) = 0

lemma digitR1CS_of_eq (x : ℝ) : DigitR1CS x x 1 0 :=
  ⟨by ring, by ring, by ring⟩

lemma digitR1CS_of_ne {x y : ℝ} (h : x ≠ y) : DigitR1CS x y 0 (x - y)⁻¹ := by
  have hsub : x - y ≠ 0 := sub_ne_zero.mpr h
  exact ⟨by ring, by rw [inv_mul_cancel₀ hsub]; ring, by ring⟩

lemma digitR1CS_sound_eq {x y eq inv : ℝ} (hR : DigitR1CS x y eq inv) (heq : x = y) : eq = 1 := by
  have hinv := hR.inv_check
  rw [heq, sub_self, mul_zero] at hinv
  linarith

lemma digitR1CS_sound_ne {x y eq inv : ℝ} (hR : DigitR1CS x y eq inv) (hne : x ≠ y) : eq = 0 :=
  (mul_eq_zero.mp hR.zero_check).resolve_right (sub_ne_zero.mpr hne)

lemma digitR1CS_sound_ne_inv {x y eq inv : ℝ} (hR : DigitR1CS x y eq inv) (hne : x ≠ y) :
    inv = (x - y)⁻¹ := by
  have hinv := hR.inv_check
  rw [digitR1CS_sound_ne hR hne, sub_zero] at hinv
  exact eq_inv_of_mul_eq_one_left hinv

lemma digitR1CS_eq_iff {x y eq inv : ℝ} (hR : DigitR1CS x y eq inv) : eq = 1 ↔ x = y := by
  constructor
  · intro h
    by_contra hne
    have := digitR1CS_sound_ne hR hne
    linarith
  · exact digitR1CS_sound_eq hR

lemma digitR1CS_zero_iff {x y eq inv : ℝ} (hR : DigitR1CS x y eq inv) : eq = 0 ↔ x ≠ y := by
  constructor
  · rintro h rfl
    have := digitR1CS_sound_eq hR rfl
    linarith
  · exact digitR1CS_sound_ne hR

lemma digitR1CS_bool {x y eq inv : ℝ} (hR : DigitR1CS x y eq inv) : eq = 0 ∨ eq = 1 := by
  rcases mul_eq_zero.mp hR.bool_check with h0 | h1
  · exact Or.inl h0
  · exact Or.inr (by linarith)

/-! ### 5. Prefix R1CS and Conjunction Accumulator -/

/-- System of R1CS constraints enforcing digit-wise equality up to depth `r ≤ d`. -/
def PrefixR1CS {d p : ℕ} (u v : TreePath d p) (r : ℕ) (hr : r ≤ d) (eq inv : Fin r → ℝ) : Prop :=
  ∀ (k : Fin r),
    DigitR1CS ((u ⟨k.val, lt_of_lt_of_le k.isLt hr⟩).val : ℝ)
              ((v ⟨k.val, lt_of_lt_of_le k.isLt hr⟩).val : ℝ)
              (eq k) (inv k)

/-- The multiplicative prefix conjunction mask M_r = ∏_{k < r} eq_k. -/
def prefixMask (r : ℕ) (eq : Fin r → ℝ) : ℝ :=
  ∏ k : Fin r, eq k

/-- Canonical equality wire assignment. -/
def canonicalEq {d p : ℕ} (u v : TreePath d p) (r : ℕ) (hr : r ≤ d) : Fin r → ℝ :=
  fun k => if u ⟨k.val, lt_of_lt_of_le k.isLt hr⟩ = v ⟨k.val, lt_of_lt_of_le k.isLt hr⟩ then 1 else 0

/-- Canonical inverse wire assignment. -/
def canonicalInv {d p : ℕ} (u v : TreePath d p) (r : ℕ) (hr : r ≤ d) : Fin r → ℝ :=
  fun k =>
    let uk : ℝ := (u ⟨k.val, lt_of_lt_of_le k.isLt hr⟩).val
    let vk : ℝ := (v ⟨k.val, lt_of_lt_of_le k.isLt hr⟩).val
    if u ⟨k.val, lt_of_lt_of_le k.isLt hr⟩ = v ⟨k.val, lt_of_lt_of_le k.isLt hr⟩ then 0 else (uk - vk)⁻¹

theorem canonical_satisfies_prefixR1CS {d p : ℕ} (u v : TreePath d p) (r : ℕ) (hr : r ≤ d) :
    PrefixR1CS u v r hr (canonicalEq u v r hr) (canonicalInv u v r hr) := by
  intro k
  dsimp [canonicalEq, canonicalInv]
  split_ifs with heq
  · rw [(digit_val_inj _ _).mpr heq]
    exact digitR1CS_of_eq _
  · exact digitR1CS_of_ne ((digit_val_inj _ _).not.mpr heq)

lemma prefixMask_eq_one_of_all_one {r : ℕ} {eq : Fin r → ℝ} (h : ∀ k : Fin r, eq k = 1) :
    prefixMask r eq = 1 := by
  unfold prefixMask
  rw [Finset.prod_congr rfl (fun k _ => h k)]
  exact Finset.prod_const_one

lemma prefixMask_eq_zero_of_exists_zero {r : ℕ} {eq : Fin r → ℝ} (k₀ : Fin r) (h : eq k₀ = 0) :
    prefixMask r eq = 0 :=
  Finset.prod_eq_zero (Finset.mem_univ k₀) h

/-! ### 6. Faithful Arithmetization Soundness & Completeness -/

/-- Completeness: If `PrefixEq u v r`, there exists a satisfying assignment where all `eq = 1`, `inv = 0`, and `prefixMask = 1`. -/
theorem prefix_arithmetization_completeness {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (hpref : PrefixEq u v r) :
    ∃ (eq inv : Fin r → ℝ),
      PrefixR1CS u v r hr eq inv ∧
      (∀ k : Fin r, eq k = 1 ∧ inv k = 0) ∧
      prefixMask r eq = 1 := by
  use canonicalEq u v r hr, canonicalInv u v r hr
  have hk_eq : ∀ k : Fin r, u ⟨k.val, lt_of_lt_of_le k.isLt hr⟩ = v ⟨k.val, lt_of_lt_of_le k.isLt hr⟩ :=
    fun k => hpref ⟨k.val, lt_of_lt_of_le k.isLt hr⟩ k.isLt
  refine ⟨canonical_satisfies_prefixR1CS u v r hr, fun k => ?_, ?_⟩
  · dsimp [canonicalEq, canonicalInv]
    simp [hk_eq k]
  · exact prefixMask_eq_one_of_all_one (fun k => by dsimp [canonicalEq]; simp [hk_eq k])

/-- Soundness: Any satisfying assignment for matching prefixes must set all equality wires to 1. -/
theorem prefix_eq_wires_eq_one {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (hpref : PrefixEq u v r) (eq inv : Fin r → ℝ) (hR : PrefixR1CS u v r hr eq inv) :
    ∀ k : Fin r, eq k = 1 := by
  intro k
  have heq : ((u ⟨k.val, lt_of_lt_of_le k.isLt hr⟩).val : ℝ) = ((v ⟨k.val, lt_of_lt_of_le k.isLt hr⟩).val : ℝ) :=
    (digit_val_inj _ _).mpr (hpref ⟨k.val, lt_of_lt_of_le k.isLt hr⟩ k.isLt)
  exact digitR1CS_sound_eq (hR k) heq

/-- Wire Uniqueness: For any satisfying assignment, the equality wire vector `eq` is uniquely determined. -/
theorem prefixR1CS_eq_wires_unique {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (eq inv : Fin r → ℝ) (hR : PrefixR1CS u v r hr eq inv) :
    eq = canonicalEq u v r hr := by
  ext k
  dsimp [canonicalEq]
  split_ifs with heq
  · exact digitR1CS_sound_eq (hR k) ((digit_val_inj _ _).mpr heq)
  · exact digitR1CS_sound_ne (hR k) ((digit_val_inj _ _).not.mpr heq)

/-- Soundness: Any satisfying assignment for diverging prefixes forces `prefixMask = 0`. -/
theorem prefix_arithmetization_unsat_zero {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (hdiv : ¬ PrefixEq u v r) (eq inv : Fin r → ℝ) (hR : PrefixR1CS u v r hr eq inv) :
    prefixMask r eq = 0 := by
  have hdiv' : ∃ (k : Fin d), k.val < r ∧ u k ≠ v k := by
    by_contra h_all
    apply hdiv
    intro k hk
    by_contra hne
    exact h_all ⟨k, hk, hne⟩
  rcases hdiv' with ⟨k_d, hk_lt, hne⟩
  let k : Fin r := ⟨k_d.val, hk_lt⟩
  have hne_real : ((u ⟨k.val, lt_of_lt_of_le k.isLt hr⟩).val : ℝ) ≠ ((v ⟨k.val, lt_of_lt_of_le k.isLt hr⟩).val : ℝ) := by
    rw [ne_eq, digit_val_inj]
    exact (show (⟨k.val, lt_of_lt_of_le k.isLt hr⟩ : Fin d) = k_d from Fin.ext rfl) ▸ hne
  exact prefixMask_eq_zero_of_exists_zero k (digitR1CS_sound_ne (hR k) hne_real)

/-- Faithful Arithmetization Soundness & Completeness Theorem. -/
theorem faithful_arithmetization_soundness_and_completeness {d p r : ℕ} (hr : r ≤ d)
    (u v : TreePath d p) :
    PrefixEq u v r ↔
      ∃ (eq inv : Fin r → ℝ),
        PrefixR1CS u v r hr eq inv ∧
        (∀ k, eq k = 1 ∧ inv k = 0) ∧
        prefixMask r eq = 1 := by
  constructor
  · exact prefix_arithmetization_completeness hr u v
  · rintro ⟨eq, inv, hR, hall, -⟩ k hk
    have h_eq1 := (hall ⟨k.val, hk⟩).1
    have heq_real := (digitR1CS_eq_iff (hR ⟨k.val, hk⟩)).mp h_eq1
    rw [digit_val_inj] at heq_real
    have h_cast : (⟨(⟨k.val, hk⟩ : Fin r).val, lt_of_lt_of_le (⟨k.val, hk⟩ : Fin r).isLt hr⟩ : Fin d) = k := Fin.ext rfl
    rw [h_cast] at heq_real
    exact heq_real

/-- For ANY satisfying assignment, the prefix conjunction mask equals 1 iff the prefixes agree. -/
theorem prefixMask_eq_one_iff {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (eq inv : Fin r → ℝ) (hR : PrefixR1CS u v r hr eq inv) :
    prefixMask r eq = 1 ↔ PrefixEq u v r := by
  constructor
  · intro hmask
    by_contra hdiv
    have hzero := prefix_arithmetization_unsat_zero hr u v hdiv eq inv hR
    rw [hzero] at hmask
    norm_num at hmask
  · intro hpref
    exact prefixMask_eq_one_of_all_one (prefix_eq_wires_eq_one hr u v hpref eq inv hR)

/-- For ANY satisfying assignment, `prefixMask r eq` is identically `if PrefixEq u v r then 1 else 0`. -/
theorem prefixMask_eval {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (eq inv : Fin r → ℝ) (hR : PrefixR1CS u v r hr eq inv) :
    prefixMask r eq = if PrefixEq u v r then 1 else 0 := by
  split_ifs with h
  · exact (prefixMask_eq_one_iff hr u v eq inv hR).mpr h
  · exact prefix_arithmetization_unsat_zero hr u v h eq inv hR

/-! ### 7. Non-Interference and Attention Domain Isolation -/

/-- Verifiable attention routing gate modulated by the prefix conjunction mask. -/
def verifiableAttentionGate (r : ℕ) (eq : Fin r → ℝ) (raw_score : ℝ) : ℝ :=
  prefixMask r eq * raw_score

/-- Non-Interference Theorem: If two paths diverge at any step `k < r`,
the verifiable attention routing gate evaluates identically to `0`. -/
theorem non_interference {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (hdiv : ¬ PrefixEq u v r) (eq inv : Fin r → ℝ) (hR : PrefixR1CS u v r hr eq inv)
    (score : ℝ) :
    verifiableAttentionGate r eq score = 0 := by
  dsimp [verifiableAttentionGate]
  rw [prefix_arithmetization_unsat_zero hr u v hdiv eq inv hR, zero_mul]

/-- Non-Interference at an explicit divergence step `k < r`. -/
theorem non_interference_at_divergence {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    {k : Fin d} (hk : k.val < r) (hne : u k ≠ v k) (eq inv : Fin r → ℝ)
    (hR : PrefixR1CS u v r hr eq inv) (score : ℝ) :
    verifiableAttentionGate r eq score = 0 :=
  non_interference hr u v (fun hpref => hne (hpref k hk)) eq inv hR score

/-- Security Domain Isolation: Cross-domain queries between divergent paths yield zero attention mass. -/
theorem security_domain_isolation {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (eq inv : Fin r → ℝ) (hR : PrefixR1CS u v r hr eq inv) (score : ℝ) :
    PrefixEq u v r ∨ verifiableAttentionGate r eq score = 0 := by
  by_cases h : PrefixEq u v r
  · exact Or.inl h
  · exact Or.inr (non_interference hr u v h eq inv hR score)

/-- Faithful attention gate evaluation: the gate faithfully reflects prefix membership. -/
theorem verifiable_attention_faithful_eval {d p r : ℕ} (hr : r ≤ d) (u v : TreePath d p)
    (eq inv : Fin r → ℝ) (hR : PrefixR1CS u v r hr eq inv) (score : ℝ) :
    verifiableAttentionGate r eq score = if PrefixEq u v r then score else 0 := by
  dsimp [verifiableAttentionGate]
  rw [prefixMask_eval hr u v eq inv hR]
  split_ifs <;> ring

/-! ### 8. Verifiable Attention Routing Matrix and Cluster Sparsity -/

/-- Full verifiable attention routing matrix for `N` tokens with tree paths in a p-adic tree. -/
def verifiableAttentionMatrix {N d p r : ℕ} (hr : r ≤ d) (paths : Fin N → TreePath d p)
    (rawScores : Matrix (Fin N) (Fin N) ℝ) : Matrix (Fin N) (Fin N) ℝ :=
  fun i j => verifiableAttentionGate r (canonicalEq (paths i) (paths j) r hr) (rawScores i j)

/-- Cluster Sparsity Theorem: Tokens belonging to distinct clusters / security domains at depth `r`
have strictly 0 cross-attention entries. -/
theorem attention_cluster_sparsity {N d p r : ℕ} (hr : r ≤ d) (paths : Fin N → TreePath d p)
    (rawScores : Matrix (Fin N) (Fin N) ℝ) (i j : Fin N)
    (h_diff_cluster : ¬ PrefixEq (paths i) (paths j) r) :
    verifiableAttentionMatrix hr paths rawScores i j = 0 :=
  non_interference hr (paths i) (paths j) h_diff_cluster
    (canonicalEq (paths i) (paths j) r hr) (canonicalInv (paths i) (paths j) r hr)
    (canonical_satisfies_prefixR1CS (paths i) (paths j) r hr) (rawScores i j)

end VerifiableAttention
