import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.RingTheory.RootsOfUnity.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Tactic

open Matrix
open scoped BigOperators

set_option linter.deprecated false
set_option linter.unusedSectionVars false

namespace DirectedTerrasTrace

/-!
# Target T2.1: General Non-Hermitian Directed Multigraph Trace Formula

This module formalizes:
1. The general directed affine transition operator on `ZMod N` with multiplier `a : ZMod N`
   and finite shift list `shifts : List (ZMod N)`:
   $$(D f)(x) = \sum_{s \in shifts} f(a x + s)$$
2. The additive character basis $\chi_k(x) = \zeta^{(k \cdot x).\text{val}}$ and the general
   multi-step monomial weight $W_m(k) = \prod_{j=0}^{m-1} \sum_{s \in shifts} \zeta^{(- a^j s k).\text{val}}$.
3. The Fourier monomial matrix representation $M_m(i, j) = \text{if } j = a^m i \text{ then } W_m(i) \text{ else } 0$.
4. The **Exact General Monomial Fixed Point Trace Formula**:
   $$\operatorname{Tr}(M_m) = \sum_{k : \text{ZMod } N} \mathbf{1}_{\{a^m k = k\}} W_m(k)$$
5. The **Unit Orbit Vanishing Theorem**: For any subgroup $\langle a \rangle \le (\text{ZMod } N)^\times$,
   at all intermediate powers $0 < m < \text{orderOf}(a)$, the fixed point trace contribution
   from all unit residues $k \in (\text{ZMod } N)^\times$ vanishes identically.
6. The **Full Cycle Return Trace Theorem**: At $m = \text{orderOf}(a)$, every unit residue satisfies
   $a^m k = k$, and the unit trace evaluates to the unconditioned sum of full-orbit weights.
7. The **Matrix Path Trace Identity**: For any abstract finite matrix $D : \text{Matrix } V \, V \, R$,
   $\operatorname{Tr}(D^m) = \sum_{v \in V} (D^m)_{v, v}$, together with length-1, length-2, and
   length-3 closed walk trace expansions.
8. The **Spatial Adjacency Matrix Representation**: Connection between the spatial graph operator
   and the directed affine operator on function spaces.
-/

-- ============================================================================
-- 1. DIRECTED AFFINE TRANSITION OPERATOR ON ZMod N
-- ============================================================================

section AffineOperator

variable {N : ℕ}

/-- The single-step directed affine transition on `ZMod N`: `x ↦ a * x + s`. -/
def affineStep (a : ZMod N) (s : ZMod N) (x : ZMod N) : ZMod N :=
  a * x + s

/-- Action of a sequence of shifts `w : List (ZMod N)` under the affine dynamical system with multiplier `a`. -/
def affineWordApply (a : ZMod N) : List (ZMod N) → ZMod N → ZMod N
  | [], x => x
  | s :: ss, x => affineWordApply a ss (affineStep a s x)

@[simp]
lemma affineWordApply_nil (a : ZMod N) (x : ZMod N) :
    affineWordApply a [] x = x := rfl

@[simp]
lemma affineWordApply_cons (a : ZMod N) (s : ZMod N) (ss : List (ZMod N)) (x : ZMod N) :
    affineWordApply a (s :: ss) x = affineWordApply a ss (affineStep a s x) := rfl

lemma affineWordApply_append (a : ZMod N) (w1 w2 : List (ZMod N)) (x : ZMod N) :
    affineWordApply a (w1 ++ w2) x = affineWordApply a w2 (affineWordApply a w1 x) := by
  induction w1 generalizing x <;> simp [*]

/-- The general directed affine transition operator on `ZMod N` with multiplier `a : ZMod N`
    and finite shift list `shifts : List (ZMod N)`:
    $$(D f)(x) = \sum_{s \in shifts} f(a x + s)$$ -/
def directedAffineOp {R : Type*} [AddCommMonoid R]
    (a : ZMod N) (shifts : List (ZMod N)) (f : ZMod N → R) (x : ZMod N) : R :=
  (shifts.map (fun s => f (a * x + s))).sum

@[simp]
lemma directedAffineOp_nil {R : Type*} [AddCommMonoid R] (a : ZMod N) (f : ZMod N → R) (x : ZMod N) :
    directedAffineOp a [] f x = 0 := rfl

@[simp]
lemma directedAffineOp_cons {R : Type*} [AddCommMonoid R] (a : ZMod N) (s : ZMod N) (ss : List (ZMod N))
    (f : ZMod N → R) (x : ZMod N) :
    directedAffineOp a (s :: ss) f x = f (a * x + s) + directedAffineOp a ss f x := rfl

lemma directedAffineOp_add {R : Type*} [AddCommMonoid R] (a : ZMod N) (shifts : List (ZMod N))
    (f g : ZMod N → R) (x : ZMod N) :
    directedAffineOp a shifts (f + g) x = directedAffineOp a shifts f x + directedAffineOp a shifts g x := by
  induction shifts with
  | nil => simp [directedAffineOp]
  | cons s ss ih => simp only [directedAffineOp_cons, ih, Pi.add_apply, add_add_add_comm]

end AffineOperator

-- ============================================================================
-- 2. FOURIER CHARACTER BASIS AND GENERAL MONOMIAL WEIGHT
-- ============================================================================

section FourierBasis

variable {N : ℕ} [NeZero N] {F : Type*} [CommRing F]

/-- The additive character basis on `ZMod N`:
    $$\chi_k(x) = \zeta^{(k \cdot x).\text{val}}$$ -/
def chi (zeta : F) (k x : ZMod N) : F :=
  zeta ^ (k * x).val

/-- Single-step monomial weight: $W_1(k) = \sum_{s \in shifts} \zeta^{(-s \cdot k).\text{val}}$. -/
def monomialWeightStep (zeta : F) (shifts : List (ZMod N)) (k : ZMod N) : F :=
  (shifts.map (fun s => zeta ^ (-(s * k)).val)).sum

/-- The general multi-step monomial weight along the affine multiplier orbit of length $m$:
    $$W_m(k) = \prod_{j=0}^{m-1} \left(\sum_{s \in shifts} \zeta^{(- a^j s k).\text{val}}\right)$$ -/
def monomialWeight (zeta : F) (a : ZMod N) (shifts : List (ZMod N)) (k : ZMod N) (m : ℕ) : F :=
  ∏ j ∈ Finset.range m, ((shifts.map (fun s => zeta ^ (-(a^j * s * k)).val)).sum)

@[simp]
lemma monomialWeight_zero (zeta : F) (a : ZMod N) (shifts : List (ZMod N)) (k : ZMod N) :
    monomialWeight zeta a shifts k 0 = 1 :=
  Finset.prod_range_zero _

lemma monomialWeight_succ (zeta : F) (a : ZMod N) (shifts : List (ZMod N)) (k : ZMod N) (m : ℕ) :
    monomialWeight zeta a shifts k (m + 1) =
    monomialWeight zeta a shifts k m * ((shifts.map (fun s => zeta ^ (-(a^m * s * k)).val)).sum) :=
  Finset.prod_range_succ _ _

lemma monomialWeight_succ' (zeta : F) (a : ZMod N) (shifts : List (ZMod N)) (k : ZMod N) (m : ℕ) :
    monomialWeight zeta a shifts k (m + 1) =
    ((shifts.map (fun s => zeta ^ (-(s * k)).val)).sum) * monomialWeight zeta a shifts (a * k) m := by
  simp only [monomialWeight, Finset.prod_range_succ', mul_comm (Finset.prod _ _)]
  congr 1
  · simp
  · refine Finset.prod_congr rfl fun j _ => ?_
    have hj (s : ZMod N) : -(a ^ (j + 1) * s * k) = -(a ^ j * s * (a * k)) := by
      rw [pow_succ]; ring
    have h_map : (fun s => zeta ^ (-(a ^ (j + 1) * s * k)).val) = (fun s => zeta ^ (-(a ^ j * s * (a * k))).val) := by
      ext s; rw [hj s]
    rw [h_map]

@[simp]
lemma monomialWeight_one (zeta : F) (a : ZMod N) (shifts : List (ZMod N)) (k : ZMod N) :
    monomialWeight zeta a shifts k 1 = (shifts.map (fun s => zeta ^ (-(s * k)).val)).sum := by
  simp [monomialWeight]

lemma pow_mod_eq_pow (zeta : F) (hzeta : IsPrimitiveRoot zeta N) (x : ℕ) :
    zeta ^ (x % N) = zeta ^ x := by
  have h1 : x = x % N + N * (x / N) := (Nat.mod_add_div x N).symm
  conv => rhs; rw [h1]
  rw [pow_add, pow_mul, hzeta.pow_eq_one, one_pow, mul_one]

lemma pow_val_add (zeta : F) (hzeta : IsPrimitiveRoot zeta N) (x y : ZMod N) :
    zeta ^ (x + y).val = zeta ^ x.val * zeta ^ y.val := by
  rw [ZMod.val_add, pow_mod_eq_pow zeta hzeta, pow_add]

lemma pow_val_eq_of_eq (zeta : F) (x y : ZMod N) (h : x = y) :
    zeta ^ x.val = zeta ^ y.val :=
  h ▸ rfl

/-- Character action under the directed affine operator:
    $$(D \chi_k)(x) = \left(\sum_{s \in shifts} \zeta^{(s \cdot k).\text{val}}\right) \chi_{a k}(x)$$ -/
theorem directedAffineOp_chi (zeta : F) (hzeta : IsPrimitiveRoot zeta N)
    (a : ZMod N) (shifts : List (ZMod N)) (k : ZMod N) :
    directedAffineOp a shifts (chi zeta k) =
    fun x => ((shifts.map (fun s => zeta ^ (s * k).val)).sum) * chi zeta (a * k) x := by
  ext x
  induction shifts with
  | nil => simp [directedAffineOp]
  | cons s ss ih =>
    simp only [directedAffineOp_cons, ih, chi, List.map_cons, List.sum_cons, add_mul]
    rw [show k * (a * x + s) = s * k + a * k * x by ring, pow_val_add zeta hzeta]

end FourierBasis

-- ============================================================================
-- 3. FOURIER MONOMIAL MATRIX REPRESENTATION
-- ============================================================================

section MonomialMatrix

variable {N : ℕ} [NeZero N] {F : Type*} [CommRing F]

/-- The Fourier monomial matrix representation $M_m$ of the directed operator:
    $$M_m(i, j) = \begin{cases} W_m(i) & \text{if } j = a^m i \\ 0 & \text{otherwise} \end{cases}$$ -/
def monomialMatrix (zeta : F) (a : ZMod N) (shifts : List (ZMod N)) (m : ℕ) :
    Matrix (ZMod N) (ZMod N) F :=
  fun i j => if j = a^m * i then monomialWeight zeta a shifts i m else 0

@[simp]
lemma monomialMatrix_apply (zeta : F) (a : ZMod N) (shifts : List (ZMod N)) (m : ℕ) (i j : ZMod N) :
    monomialMatrix zeta a shifts m i j =
    if j = a^m * i then monomialWeight zeta a shifts i m else 0 :=
  rfl

/-- Power composition of the Fourier monomial matrix: $(M_1)^m = M_m$. -/
theorem monomialMatrix_pow (zeta : F) (a : ZMod N) (shifts : List (ZMod N)) (m : ℕ) :
    (monomialMatrix zeta a shifts 1) ^ m = monomialMatrix zeta a shifts m := by
  induction m with
  | zero =>
    ext i j
    simp only [pow_zero, Matrix.one_apply, monomialMatrix_apply, monomialWeight_zero]
    split_ifs <;> aesop
  | succ m ih =>
    ext i j
    rw [pow_succ', Matrix.mul_apply]
    have h_sum : (∑ k : ZMod N, monomialMatrix zeta a shifts 1 i k * (monomialMatrix zeta a shifts 1 ^ m) k j) =
        monomialMatrix zeta a shifts 1 i (a * i) * (monomialMatrix zeta a shifts 1 ^ m) (a * i) j := by
      refine Finset.sum_eq_single (a * i) ?_ (fun h => (h (Finset.mem_univ _)).elim)
      intro b _ hb
      simp only [monomialMatrix_apply, pow_one]
      split_ifs with h <;> [exact (hb h).elim; rw [zero_mul]]
    rw [h_sum, ih]
    have h1 : monomialMatrix zeta a shifts 1 i (a * i) = (shifts.map (fun s => zeta ^ (-(s * i)).val)).sum := by
      simp only [monomialMatrix_apply, pow_one, ite_true, monomialWeight_one]
    have h_succ : a^(m + 1) * i = a^m * (a * i) := by rw [pow_succ']; ring
    rw [h1, monomialMatrix_apply, monomialMatrix_apply, h_succ]
    split_ifs with hj <;> [rw [monomialWeight_succ']; rw [mul_zero]]

end MonomialMatrix

-- ============================================================================
-- 4. EXACT GENERAL MONOMIAL FIXED POINT TRACE FORMULA
-- ============================================================================

section FixedPointTrace

variable {N : ℕ} [NeZero N] {F : Type*} [CommRing F]

/-- The fixed point trace sum of the $m$-th power directed operator:
    $$\sum_{k : \text{ZMod } N} \mathbf{1}_{\{a^m k = k\}} W_m(k)$$ -/
def fixedPointTrace (zeta : F) (a : ZMod N) (shifts : List (ZMod N)) (m : ℕ) : F :=
  ∑ k : ZMod N, if a^m * k = k then monomialWeight zeta a shifts k m else 0

/-- **Exact General Monomial Fixed Point Trace Formula**:
    The matrix trace of $M_m$ equals the sum over all fixed points of $x \mapsto a^m x$
    weighted by the orbit monomial factor $W_m(k)$:
    $$\operatorname{Tr}(M_m) = \sum_{k : \text{ZMod } N} \mathbf{1}_{\{a^m k = k\}} W_m(k)$$ -/
theorem directed_trace_eq_fixed_point_sum
    (zeta : F) (a : ZMod N) (shifts : List (ZMod N)) (m : ℕ) :
    Matrix.trace (monomialMatrix zeta a shifts m) = fixedPointTrace zeta a shifts m := by
  simp [Matrix.trace, Matrix.diag, fixedPointTrace, monomialMatrix_apply, eq_comm]

/-- Equivalent filter-sum expression for the fixed point trace. -/
lemma fixedPointTrace_eq_filter_sum (zeta : F) (a : ZMod N) (shifts : List (ZMod N)) (m : ℕ) :
    fixedPointTrace zeta a shifts m =
    ∑ k ∈ Finset.univ.filter (fun k : ZMod N => a^m * k = k), monomialWeight zeta a shifts k m := by
  simp [fixedPointTrace, ← Finset.sum_filter]

end FixedPointTrace

-- ============================================================================
-- 5. UNIT ORBIT VANISHING THEOREM
-- ============================================================================

section UnitVanishing

variable {N : ℕ} [NeZero N] {F : Type*} [CommRing F]

/-- The Finset of unit residues in `ZMod N`. -/
def unitResidues (N : ℕ) [NeZero N] : Finset (ZMod N) :=
  Finset.univ.filter (fun k : ZMod N => IsUnit k)

/-- The fixed point trace contribution from the unit sector:
    $$\sum_{k \in (\text{ZMod } N)^\times} \mathbf{1}_{\{a^m k = k\}} W_m(k)$$ -/
def unitFixedPointTrace (zeta : F) (a : ZMod N) (shifts : List (ZMod N)) (m : ℕ) : F :=
  ∑ k ∈ unitResidues N, if a^m * k = k then monomialWeight zeta a shifts k m else 0

/-- Multiplication by $a^m$ on unit residues has no fixed points for $0 < m < \text{orderOf } u_a$. -/
lemma unit_pow_mul_ne_self (u_a : (ZMod N)ˣ) (m : ℕ)
    (hm_pos : 0 < m) (hm_lt : m < orderOf u_a) (k : ZMod N) (hk : IsUnit k) :
    (u_a : ZMod N)^m * k ≠ k := by
  intro h_fix
  obtain ⟨u_k, rfl⟩ := hk
  have h_units : u_a^m * u_k = u_k := Units.ext (by push_cast; exact h_fix)
  have hu_m_eq_one : u_a^m = 1 := mul_right_cancel (show u_a^m * u_k = 1 * u_k by rw [one_mul, h_units])
  have h_le : orderOf u_a ≤ m := Nat.le_of_dvd hm_pos (orderOf_dvd_of_pow_eq_one hu_m_eq_one)
  omega

/-- **Unit Orbit Vanishing Theorem**:
    For any subgroup $\langle a \rangle \le (\text{ZMod } N)^\times$ generated by $u_a$,
    for all intermediate powers $0 < m < \text{orderOf}(u_a)$, the fixed point trace
    contribution from all unit residues $k \in (\text{ZMod } N)^\times$ vanishes identically:
    $$\operatorname{Tr}_{\text{units}}(M_m) = 0$$ -/
theorem unit_trace_vanishes (zeta : F) (u_a : (ZMod N)ˣ) (shifts : List (ZMod N)) (m : ℕ)
    (hm_pos : 0 < m) (hm_lt : m < orderOf u_a) :
    unitFixedPointTrace zeta (u_a : ZMod N) shifts m = 0 := by
  simp only [unitFixedPointTrace]
  refine Finset.sum_eq_zero (fun k hk => ?_)
  rw [unitResidues, Finset.mem_filter] at hk
  exact if_neg (unit_pow_mul_ne_self u_a m hm_pos hm_lt k hk.2)

end UnitVanishing

-- ============================================================================
-- 6. FULL CYCLE RETURN TRACE THEOREM
-- ============================================================================

section FullCycleReturn

variable {N : ℕ} [NeZero N] {F : Type*} [CommRing F]

lemma unit_pow_eq_one_of_dvd (u_a : (ZMod N)ˣ) (m : ℕ) (hm : orderOf u_a ∣ m) :
    (u_a : ZMod N)^m = 1 := by
  obtain ⟨c, rfl⟩ := hm
  rw [pow_mul, ← Units.val_pow_eq_pow_val, pow_orderOf_eq_one, Units.val_one, one_pow]

lemma unit_pow_orderOf_eq_one (u_a : (ZMod N)ˣ) :
    (u_a : ZMod N)^(orderOf u_a) = 1 :=
  unit_pow_eq_one_of_dvd u_a (orderOf u_a) dvd_rfl

lemma unit_pow_orderOf_mul (u_a : (ZMod N)ˣ) (k : ZMod N) :
    (u_a : ZMod N)^(orderOf u_a) * k = k := by
  rw [unit_pow_orderOf_eq_one, one_mul]

lemma unit_pow_multiple_mul (u_a : (ZMod N)ˣ) (m : ℕ) (hm : orderOf u_a ∣ m) (k : ZMod N) :
    (u_a : ZMod N)^m * k = k := by
  rw [unit_pow_eq_one_of_dvd u_a m hm, one_mul]

/-- **Full Cycle Return Trace Theorem (Unit Sector)**:
    At $m = \text{orderOf}(u_a)$, every unit residue satisfies the fixed point condition
    $a^m k = k$, and the unit trace evaluates to the unconditioned sum of full-orbit weights:
    $$\operatorname{Tr}_{\text{units}}(M_{\text{orderOf}(a)}) = \sum_{k \in (\text{ZMod } N)^\times} W_{\text{orderOf}(a)}(k)$$ -/
theorem unit_trace_full_cycle (zeta : F) (u_a : (ZMod N)ˣ) (shifts : List (ZMod N)) :
    unitFixedPointTrace zeta (u_a : ZMod N) shifts (orderOf u_a) =
    ∑ k ∈ unitResidues N, monomialWeight zeta (u_a : ZMod N) shifts k (orderOf u_a) := by
  simp [unitFixedPointTrace, unit_pow_orderOf_mul]

/-- **Full Cycle Return Trace Theorem (Total Trace)**:
    At $m = \text{orderOf}(u_a)$, every residue $k \in \mathbb{Z}/N\mathbb{Z}$ satisfies $a^m k = k$,
    and the total fixed point trace evaluates to the unconditioned sum of full-orbit weights:
    $$\operatorname{Tr}(M_{\text{orderOf}(a)}) = \sum_{k : \text{ZMod } N} W_{\text{orderOf}(a)}(k)$$ -/
theorem total_trace_full_cycle (zeta : F) (u_a : (ZMod N)ˣ) (shifts : List (ZMod N)) :
    fixedPointTrace zeta (u_a : ZMod N) shifts (orderOf u_a) =
    ∑ k : ZMod N, monomialWeight zeta (u_a : ZMod N) shifts k (orderOf u_a) := by
  simp [fixedPointTrace, unit_pow_orderOf_mul]

/-- Total trace at any positive multiple of the period: $m = c \cdot \text{orderOf}(u_a)$. -/
theorem total_trace_multiple_cycle (zeta : F) (u_a : (ZMod N)ˣ) (shifts : List (ZMod N))
    (m : ℕ) (hm : orderOf u_a ∣ m) :
    fixedPointTrace zeta (u_a : ZMod N) shifts m =
    ∑ k : ZMod N, monomialWeight zeta (u_a : ZMod N) shifts k m := by
  simp [fixedPointTrace, unit_pow_multiple_mul u_a m hm]

/-- Sector decomposition: The total trace decomposes into the unit sector and non-unit sector. -/
theorem fixedPointTrace_eq_units_add_nonunits (zeta : F) (a : ZMod N) (shifts : List (ZMod N)) (m : ℕ) :
    fixedPointTrace zeta a shifts m =
    unitFixedPointTrace zeta a shifts m +
    ∑ k ∈ Finset.univ.filter (fun k : ZMod N => ¬ IsUnit k),
      if a^m * k = k then monomialWeight zeta a shifts k m else 0 := by
  dsimp [fixedPointTrace, unitFixedPointTrace, unitResidues]
  exact (Finset.sum_filter_add_sum_filter_not Finset.univ (fun k => IsUnit k) _).symm

/-- Corollary: For intermediate powers $0 < m < \text{orderOf}(u_a)$, the total fixed point trace
    is supported entirely on the non-unit (singular) residues. -/
theorem total_trace_intermediate_eq_nonunits (zeta : F) (u_a : (ZMod N)ˣ) (shifts : List (ZMod N))
    (m : ℕ) (hm_pos : 0 < m) (hm_lt : m < orderOf u_a) :
    fixedPointTrace zeta (u_a : ZMod N) shifts m =
    ∑ k ∈ Finset.univ.filter (fun k : ZMod N => ¬ IsUnit k),
      if (u_a : ZMod N)^m * k = k then monomialWeight zeta (u_a : ZMod N) shifts k m else 0 := by
  rw [fixedPointTrace_eq_units_add_nonunits, unit_trace_vanishes zeta u_a shifts m hm_pos hm_lt, zero_add]

end FullCycleReturn

-- ============================================================================
-- 7. MATRIX PATH TRACE IDENTITY
-- ============================================================================

section MatrixPathTrace

variable {V : Type*} [Fintype V] [DecidableEq V] {R : Type*} [CommSemiring R]

/-- **Matrix Path Trace Identity**:
    For any abstract finite matrix $D : \text{Matrix } V \, V \, R$,
    $$\operatorname{Tr}(D^m) = \sum_{v \in V} (D^m)_{v, v}$$ -/
theorem matrix_trace_pow (D : Matrix V V R) (m : ℕ) :
    Matrix.trace (D^m) = ∑ v : V, (D^m) v v :=
  rfl

/-- Step expansion of matrix power squared: $(D^2)_{u, v} = \sum_{w} D_{u, w} D_{w, v}$. -/
lemma matrix_pow_two_apply (D : Matrix V V R) (u v : V) :
    (D^2) u v = ∑ w : V, D u w * D w v := by
  rw [sq, Matrix.mul_apply]

/-- Step expansion of matrix power cubed: $(D^3)_{u, v} = \sum_{w_1, w_2} D_{u, w_1} D_{w_1, w_2} D_{w_2, v}$. -/
lemma matrix_pow_three_apply (D : Matrix V V R) (u v : V) :
    (D^3) u v = ∑ w1 : V, ∑ w2 : V, D u w1 * D w1 w2 * D w2 v := by
  simp_rw [pow_succ' D 2, Matrix.mul_apply, matrix_pow_two_apply, Finset.mul_sum, mul_assoc]

/-- Path trace identity for length 1: $\operatorname{Tr}(D) = \sum_{v} D_{v, v}$. -/
theorem matrix_trace_one (D : Matrix V V R) :
    Matrix.trace (D^1) = ∑ v : V, D v v := by
  rw [pow_one]; rfl

/-- Path trace identity for length 2: $\operatorname{Tr}(D^2) = \sum_{u, v} D_{u, v} D_{v, u}$. -/
theorem matrix_trace_two (D : Matrix V V R) :
    Matrix.trace (D^2) = ∑ u : V, ∑ v : V, D u v * D v u := by
  simp_rw [matrix_trace_pow, matrix_pow_two_apply]

/-- Path trace identity for length 3: $\operatorname{Tr}(D^3) = \sum_{u, v, w} D_{u, v} D_{v, w} D_{w, u}$. -/
theorem matrix_trace_three (D : Matrix V V R) :
    Matrix.trace (D^3) = ∑ u : V, ∑ v : V, ∑ w : V, D u v * D v w * D w u := by
  simp_rw [matrix_trace_pow, matrix_pow_three_apply]

end MatrixPathTrace

-- ============================================================================
-- 8. SPATIAL ADJACENCY MATRIX AND SPATIAL TRACE
-- ============================================================================

section SpatialMatrix

variable {N : ℕ} [NeZero N]

/-- The spatial directed multigraph adjacency matrix:
    entry $(x, y)$ counts the number of shift edges $s \in shifts$ such that $a x + s = y$. -/
def spatialAdjacencyMatrix {R : Type*} [CommSemiring R] (a : ZMod N) (shifts : List (ZMod N)) : Matrix (ZMod N) (ZMod N) R :=
  fun x y => (shifts.map (fun s => if y = a * x + s then (1 : R) else 0)).sum

@[simp]
lemma spatialAdjacencyMatrix_apply {R : Type*} [CommSemiring R] (a : ZMod N) (shifts : List (ZMod N)) (x y : ZMod N) :
    spatialAdjacencyMatrix (R := R) a shifts x y =
    (shifts.map (fun s => if y = a * x + s then (1 : R) else 0)).sum :=
  rfl

/-- Spatial matrix multiplication corresponds to the directed affine operator on functions. -/
theorem spatial_mulVec_eq_directedAffineOp {R : Type*} [CommSemiring R] (a : ZMod N) (shifts : List (ZMod N)) (f : ZMod N → R) (x : ZMod N) :
    Matrix.mulVec (spatialAdjacencyMatrix a shifts) f x = directedAffineOp a shifts f x := by
  dsimp [Matrix.mulVec, dotProduct, spatialAdjacencyMatrix, directedAffineOp]
  induction shifts with
  | nil => simp
  | cons s ss ih =>
    simp only [List.map_cons, List.sum_cons, add_mul, Finset.sum_add_distrib, ih]
    congr 1
    rw [Finset.sum_eq_single (a * x + s)
      (fun y _ hy => by split_ifs with h <;> [exact (hy h).elim; rw [zero_mul]])
      (fun h => (h (Finset.mem_univ _)).elim)]
    simp

/-- Spatial matrix trace of $A^m$ equals the sum of diagonal entries $\sum_{x} (A^m)_{x, x}$. -/
theorem spatial_trace_pow {R : Type*} [CommSemiring R] (a : ZMod N) (shifts : List (ZMod N)) (m : ℕ) :
    (Matrix.trace ((spatialAdjacencyMatrix a shifts : Matrix (ZMod N) (ZMod N) R)^m) : R) =
    ∑ x : ZMod N, ((spatialAdjacencyMatrix a shifts : Matrix (ZMod N) (ZMod N) R)^m) x x :=
  rfl

end SpatialMatrix

#print axioms directed_trace_eq_fixed_point_sum
#print axioms unit_trace_vanishes
#print axioms unit_trace_full_cycle
#print axioms total_trace_full_cycle
#print axioms spatial_mulVec_eq_directedAffineOp

end DirectedTerrasTrace

